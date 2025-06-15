# Python script to update .github/workflows/android_build.yml
# with the final build and artifact upload steps.

import os

workflow_file_path = ".github/workflows/android_build.yml"

# Read existing lines to find where to insert/remove
with open(workflow_file_path, "r") as f:
    lines = f.readlines()

# Remove the previous test echo line:
# "- name: Test command after Flutter/Gradle steps"
# and its "run:" line
new_lines = []
skip_next_line = False
for i, line in enumerate(lines):
    if skip_next_line:
        skip_next_line = False
        continue
    if "- name: Test command after Flutter/Gradle steps" in line:
        # This will skip the current line (- name: ...)
        # and the next line (run: ...)
        if i + 1 < len(lines) and lines[i+1].strip().startswith("run:"):
            skip_next_line = True
        continue # Skip adding this line

    # Revert workflow name
    if line.strip().startswith("name: Android Build - Step Restore"):
        new_lines.append("name: Android Build\n")
    else:
        new_lines.append(line)

# Define the steps to add (keystore, build, upload)
final_steps_yaml = '''      - name: Create keystore.properties
        if: |
          secrets.RELEASE_STORE_PASSWORD != null &&
          secrets.RELEASE_KEY_ALIAS != null &&
          secrets.RELEASE_KEY_PASSWORD != null &&
          secrets.RELEASE_STORE_FILE_BASE64 != null
        working-directory: ./flutter_dashboard_app/android
        run: |
          echo "storeFile=my-release-key.keystore" > keystore.properties
          echo "storePassword=${{ secrets.RELEASE_STORE_PASSWORD }}" >> keystore.properties
          echo "keyAlias=${{ secrets.RELEASE_KEY_ALIAS }}" >> keystore.properties
          echo "keyPassword=${{ secrets.RELEASE_KEY_PASSWORD }}" >> keystore.properties

      - name: Decode Keystore
        if: |
          secrets.RELEASE_STORE_PASSWORD != null &&
          secrets.RELEASE_KEY_ALIAS != null &&
          secrets.RELEASE_KEY_PASSWORD != null &&
          secrets.RELEASE_STORE_FILE_BASE64 != null
        working-directory: ./flutter_dashboard_app/android
        run: echo "${{ secrets.RELEASE_STORE_FILE_BASE64 }}" | base64 --decode > my-release-key.keystore

      - name: Build Android APK (Release)
        working-directory: ./flutter_dashboard_app
        run: flutter build apk --release --verbose
        timeout-minutes: 30

      - name: Upload APK Artifact (Release)
        uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: flutter_dashboard_app/build/app/outputs/flutter-apk/app-release.apk
'''

# Append the final steps to the new_lines list
# Ensure correct indentation if new_lines doesn't end with newline
if new_lines and not new_lines[-1].endswith('\n'):
    new_lines[-1] += '\n'

new_lines.append(final_steps_yaml)

try:
    with open(workflow_file_path, "w") as f:
        f.writelines(new_lines)
    print(f"Successfully updated {workflow_file_path} with final build steps and reverted name to 'Android Build'.")
except Exception as e:
    print(f"Error writing final workflow to {workflow_file_path}: {e}")
