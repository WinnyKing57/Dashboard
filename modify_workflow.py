# Python script to modify the .github/workflows/android_build.yml content
import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    workflow_content_lines = f.readlines()

new_workflow_content_lines = []
build_apk_step_found = False
secrets_step_added = False

# Note: The indentation here is crucial for correct YAML output.
# Each line of the YAML step starts with 8 spaces, then the content.
# The 'run: |' block content starts with 10 spaces.
# Double curly braces are used for GitHub Actions expressions like ${{{{ secrets.XYZ }}}}
# to escape them for the f-string that will process this block.

new_steps_yaml = '''      - name: Create keystore.properties
        if: |
          secrets.RELEASE_STORE_PASSWORD != null &&
          secrets.RELEASE_KEY_ALIAS != null &&
          secrets.RELEASE_KEY_PASSWORD != null &&
          secrets.RELEASE_STORE_FILE_BASE64 != null
        working-directory: ./flutter_dashboard_app/android
        run: |
          echo "storeFile=my-release-key.keystore" > keystore.properties
          echo "storePassword=${{{{ secrets.RELEASE_STORE_PASSWORD }}}}" >> keystore.properties
          echo "keyAlias=${{{{ secrets.RELEASE_KEY_ALIAS }}}}" >> keystore.properties
          echo "keyPassword=${{{{ secrets.RELEASE_KEY_PASSWORD }}}}" >> keystore.properties

      - name: Decode Keystore
        if: |
          secrets.RELEASE_STORE_PASSWORD != null &&
          secrets.RELEASE_KEY_ALIAS != null &&
          secrets.RELEASE_KEY_PASSWORD != null &&
          secrets.RELEASE_STORE_FILE_BASE64 != null
        working-directory: ./flutter_dashboard_app/android
        run: echo "${{{{ secrets.RELEASE_STORE_FILE_BASE64 }}}}" | base64 --decode > my-release-key.keystore

'''

for line_content in workflow_content_lines:
    if "name: Build Android APK (Release)" in line_content and not secrets_step_added:
        build_apk_step_found = True
        # Correctly indent the new_steps_yaml block before adding it
        # The steps are typically indented by 6 spaces for the '-'
        # but since the text block already starts with '      - name:',
        # we add it directly.
        new_workflow_content_lines.append(new_steps_yaml)
        secrets_step_added = True
    new_workflow_content_lines.append(line_content)

if build_apk_step_found and secrets_step_added:
    with open(workflow_file_path, "w") as f:
        f.writelines(new_workflow_content_lines)
    print(f"Successfully modified {workflow_file_path} to include keystore creation steps.")
else:
    print(f"Could not find the 'Build Android APK (Release)' step in {workflow_file_path}, or secrets_step_added was false.")
    # Consider exiting with an error if this is critical
    # import sys
    # sys.exit(1)
