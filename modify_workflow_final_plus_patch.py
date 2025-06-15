# Python script to modify .github/workflows/android_build.yml
# 1. Remove 'List files in android directory' step.
# 2. Re-add 'Regenerate Android project' step.
# 3. Add a new step to 'Patch build.gradle.kts after flutter create'.

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
processing_step_to_remove = None # Can be 'list_files'

# Lines for the 'Regenerate Android project' step
regenerate_step_yaml = '''      - name: Regenerate Android project
        working-directory: ./flutter_dashboard_app
        run: flutter create . --platforms android
'''

# Lines for the new 'Patch build.gradle.kts' step
# Note the use of triple single quotes for the multiline Python script embedded in YAML
patch_gradle_step_yaml = '''      - name: Patch build.gradle.kts after flutter create
        run: |
          echo "Patching flutter_dashboard_app/android/app/build.gradle.kts..."
          python << 'EOF'
          import os
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

          temp_lines = []
          # Remove existing keystore logic if it's at the top (potentially re-added by flutter create)
          # and ensure import is present and at the top.
          # Also remove if it's already inside android {} but wrongly formatted/placed by flutter create.

          # Basic approach: filter out known patterns of the keystore logic from all locations first
          # This is simpler than trying to track its exact old location if flutter create moves it.

          # Ensure import is present
          has_import = any(line.strip() == "import java.util.Properties" for line in original_lines)

          # Filter out old keystore logic and the import (will re-add import cleanly)
          filtered_lines = []
          skip_old_keystore_block = False
          for line in original_lines:
              stripped_line = line.strip()
              if stripped_line == "import java.util.Properties":
                  continue # Skip, will re-add cleanly
              if stripped_line.startswith("val keystorePropertiesFile = rootProject.file("):
                  skip_old_keystore_block = True # Start skipping
                  continue
              if skip_old_keystore_block:
                  if "keystoreProperties.load(it)" in stripped_line and "}" in stripped_line : # common end
                      skip_old_keystore_block = False
                  elif stripped_line == "}" and "keystoreProperties.load(it)" in original_lines[original_lines.index(line)-1]: # if } is on next line
                      skip_old_keystore_block = False
                  continue # Continue skipping

              filtered_lines.append(line)

          # Start constructing the new file content
          final_lines = ["import java.util.Properties\\n", "\\n"] # Import and a blank line

          in_android_block = False
          placed_keystore_logic = False

          for line_idx, line_content in enumerate(filtered_lines):
              final_lines.append(line_content)

              if not placed_keystore_logic:
                  if line_content.strip().startswith("android {"):
                      in_android_block = True

                  if in_android_block and line_content.strip().startswith("signingConfigs {"):
                      # Insert keystore_logic before this line, after removing its current indent from final_lines
                      current_line = final_lines.pop()
                      final_lines.extend(keystore_logic_to_insert)
                      final_lines.append("\\n") # Blank line after inserted logic
                      final_lines.append(current_line) # Add back the signingConfigs line
                      placed_keystore_logic = True
                  elif in_android_block and line_content.strip() == "}" and (line_idx > 0 and filtered_lines[line_idx-1].strip().startswith("buildTypes")):
                      # Fallback: if at the end of android block
                      current_line = final_lines.pop()
                      final_lines.extend(keystore_logic_to_insert)
                      final_lines.append("\\n")
                      final_lines.append(current_line)
                      placed_keystore_logic = True

          # Correct namespace and applicationId if necessary
          # This is a simplified way, assuming they are present. A more robust script would parse more carefully.
          for i in range(len(final_lines)):
              if "namespace = \\"com.example.flutter_dashboard_app\\"" in final_lines[i]:
                  final_lines[i] = final_lines[i].replace("com.example.flutter_dashboard_app", "com.jules.flutter_dashboard_app")
              if "applicationId = \\"com.example.flutter_dashboard_app\\"" in final_lines[i]:
                  final_lines[i] = final_lines[i].replace("com.example.flutter_dashboard_app", "com.jules.flutter_dashboard_app")


          with open(gradle_file_path, "w") as f:
              f.writelines(final_lines)
          print(f"Patched {gradle_file_path} successfully.")
          EOF
'''


# This script rebuilds the new_lines list.
# It will first remove the 'List files...' step.
# Then, when it finds the 'Set Gradle version' step, it will insert
# the 'Regenerate Android project' and 'Patch build.gradle.kts' steps before it.

temp_new_lines = []
# Phase 1: Remove 'List files in android directory'
step_to_remove_name = "- name: List files in android directory"
in_step_to_remove = False
for line in lines:
    stripped_line = line.lstrip()
    if stripped_line.startswith(step_to_remove_name):
        in_step_to_remove = True
        continue # Skip this line

    if in_step_to_remove:
        if stripped_line.startswith("- name:"): # Next step starts
            in_step_to_remove = False
            temp_new_lines.append(line) # Add this new step line
        else: # Line is part of the step to remove
            continue
    else:
        temp_new_lines.append(line)

lines = temp_new_lines # Update lines with the removal
new_lines = [] # Reset for insertion phase

# Phase 2: Insert 'Regenerate...' and 'Patch...' before 'Set Gradle version'
set_gradle_version_step_name = "- name: Set Gradle version"
inserted_new_steps = False
for line_content in lines:
    if line_content.lstrip().startswith(set_gradle_version_step_name) and not inserted_new_steps:
        new_lines.extend(regenerate_step_yaml.splitlines(True))
        new_lines.append("\n") # Ensure a blank line
        new_lines.extend(patch_gradle_step_yaml.splitlines(True))
        new_lines.append("\n") # Ensure a blank line
        inserted_new_steps = True

    new_lines.append(line_content)

if not inserted_new_steps:
    print("Warning: Target 'Set Gradle version' step not found. New steps not added as intended.")
    # Fallback to avoid breaking file if insertion point not found
    with open(workflow_file_path, "w") as f:
        f.writelines(lines)
    print(f"Original content of {workflow_file_path} (with list step removed) written due to insertion error.")
else:
    with open(workflow_file_path, "w") as f:
        f.writelines(new_lines)
    print(f"Modified {workflow_file_path}: Removed listing step, re-added Regenerate project, and added Patch step.")
