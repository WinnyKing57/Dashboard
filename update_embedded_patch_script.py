# Python script to update the embedded Python script within .github/workflows/android_build.yml

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_workflow_lines = []
in_patch_script_step = False
in_python_heredoc = False
# python_script_lines = [] # Not needed as we are replacing directly

for line in lines:
    if line.strip() == "- name: Patch build.gradle.kts after flutter create":
        new_workflow_lines.append(line)
        in_patch_script_step = True
    elif in_patch_script_step and line.strip() == "run: |":
        new_workflow_lines.append(line)
    elif in_patch_script_step and line.strip() == "python << 'EOF'":
        new_workflow_lines.append(line)
        in_python_heredoc = True
        # The next line in the input 'lines' will be the start of the old script.
        # We will discard old script lines until 'EOF' by not appending them in the 'else'
        # and then insert the new script when we hit 'EOF'.
    elif in_python_heredoc and line.strip() == "EOF":
        # This is where we insert the modified Python script

        modified_python_script = '''          import os
          gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

          with open(gradle_file_path, "r") as f:
              original_lines = f.readlines()

          # Keystore logic to be moved/ensured
          keystore_logic_to_insert = [
              "    val keystorePropertiesFile = rootProject.file(\\"keystore.properties\\")\\n",
              "    val keystoreProperties = java.util.Properties()\\n",
              "    if (keystorePropertiesFile.exists()) {\\n",
              "        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }\\n",
              "    }\\n"
          ]

          has_import = any(line.strip() == "import java.util.Properties" for line in original_lines)

          filtered_lines = []
          skip_old_keystore_block = False
          for orig_line_idx, orig_line_content in enumerate(original_lines): # Use enumerate for index
              stripped_line = orig_line_content.strip()
              if stripped_line == "import java.util.Properties":
                  continue
              if stripped_line.startswith("val keystorePropertiesFile = rootProject.file("):
                  skip_old_keystore_block = True
                  continue
              if skip_old_keystore_block:
                  # Check if original_lines has enough elements before trying to access original_lines.index(orig_line_content)-1
                  prev_line_exists = orig_line_idx > 0
                  prev_line_content = original_lines[orig_line_idx-1].strip() if prev_line_exists else ""

                  if "keystoreProperties.load(it)" in stripped_line and "}" in stripped_line:
                      skip_old_keystore_block = False
                  # Check prev_line_content instead of re-finding index
                  elif stripped_line == "}" and "keystoreProperties.load(it)" in prev_line_content:
                      skip_old_keystore_block = False
                  continue
              filtered_lines.append(orig_line_content)

          # Ensure final_lines starts fresh for this construction pass
          final_lines = ["import java.util.Properties\\n", "\\n"]

          in_android_block = False
          placed_keystore_logic = False

          temp_processed_lines = [] # Use a temporary list for the first pass of placing keystore logic

          for line_content in filtered_lines:
              temp_processed_lines.append(line_content)

              if not placed_keystore_logic:
                  if line_content.strip().startswith("android {"):
                      in_android_block = True

                  if in_android_block and line_content.strip().startswith("signingConfigs {"):
                      current_line = temp_processed_lines.pop()
                      temp_processed_lines.extend(keystore_logic_to_insert)
                      temp_processed_lines.append("\\n")
                      temp_processed_lines.append(current_line)
                      placed_keystore_logic = True
                  # Check if current line is the closing '}' of 'android' block and if 'buildTypes' was the previous block
                  elif in_android_block and line_content.strip() == "}" and \\
                       (len(temp_processed_lines) > 1 and temp_processed_lines[-2].strip().startswith("buildTypes")):
                      current_line = temp_processed_lines.pop()
                      temp_processed_lines.extend(keystore_logic_to_insert)
                      temp_processed_lines.append("\\n")
                      temp_processed_lines.append(current_line)
                      placed_keystore_logic = True

          # Second pass for buildType corrections and namespace/applicationId
          final_lines_pass2 = [] # Use this for the final output of the gradle file
          # Start with the import and blank line
          final_lines_pass2.extend(["import java.util.Properties\\n", "\\n"])


          active_buildtypes_block = False # More specific than in_buildtypes_release_block
          active_release_sub_block = False

          for line_to_process in temp_processed_lines: # Iterate over lines from first pass

              # Namespace & AppID correction
              if "namespace = \\"com.example.flutter_dashboard_app\\"" in line_to_process:
                  line_to_process = line_to_process.replace("com.example.flutter_dashboard_app", "com.jules.flutter_dashboard_app")
              if "applicationId = \\"com.example.flutter_dashboard_app\\"" in line_to_process:
                  line_to_process = line_to_process.replace("com.example.flutter_dashboard_app", "com.jules.flutter_dashboard_app")

              # Kotlin DSL corrections for buildTypes.release
              # Determine current block
              stripped_line_to_process = line_to_process.strip()
              if stripped_line_to_process == "buildTypes {":
                  active_buildtypes_block = True
              elif active_buildtypes_block and stripped_line_to_process == "}": # Potential end of buildTypes
                  # This simplistic check needs refinement based on indentation matching 'buildTypes {'
                  # For now, assume if we hit a '}' at low indent after buildTypes, it's its end.
                  # A proper parser would be better. This is a heuristic.
                  if line_to_process.startswith("    }"): # Assuming buildTypes is at 4 spaces, its closing is too.
                       active_buildtypes_block = False
                       active_release_sub_block = False # also exit release block

              if active_buildtypes_block and stripped_line_to_process == "release {":
                  active_release_sub_block = True
              elif active_release_sub_block and stripped_line_to_process == "}":
                  # This '}' is for the 'release {' block
                  active_release_sub_block = False

              if active_release_sub_block and "signingConfig = signingConfigs.getByName(\\"release\\")" in line_to_process:
                  line_to_process = line_to_process.replace("signingConfig = signingConfigs.getByName(\\"release\\")", "signingConfig = signingConfigs.getByName(\\"release\\")")

              if active_release_sub_block and "isMinifyEnabled = false" in line_to_process:
                  line_to_process = line_to_process.replace("isMinifyEnabled = false", "isMinifyEnabled = false")
              elif active_release_sub_block and "isMinifyEnabled = true" in line_to_process:
                  line_to_process = line_to_process.replace("isMinifyEnabled = true", "isMinifyEnabled = true")

              final_lines_pass2.append(line_to_process)

          with open(gradle_file_path, "w") as f:
              f.writelines(final_lines_pass2)
          print(f"Patched {gradle_file_path} with Kotlin DSL awareness and ensured keystore logic placement.")
'''
        # Add the modified Python script lines, ensuring correct YAML indentation for the heredoc content
        # Each line of the script needs to be indented to align with the YAML heredoc style.
        # The heredoc itself starts after "run: |", and "python << 'EOF'" is indented.
        # The script lines should be indented further relative to "python << 'EOF'".
        # The provided script string already has '          ' (10 spaces)
        for script_line in modified_python_script.splitlines():
            new_workflow_lines.append(script_line + "\n") # Script lines already have their own relative indentation.

        new_workflow_lines.append(line) # Append the 'EOF' line (which is '          EOF\n')
        in_python_heredoc = False
        in_patch_script_step = False # Finished this step
    elif not (in_patch_script_step and in_python_heredoc): # Only append if not inside the python script part we are replacing
        new_workflow_lines.append(line)
    # If in_patch_script_step and in_python_heredoc, we are inside the old script, so we skip those lines.

with open(workflow_file_path, "w") as f:
    f.writelines(new_workflow_lines)

print(f"Updated the embedded Python script in {workflow_file_path} with revised logic.")
