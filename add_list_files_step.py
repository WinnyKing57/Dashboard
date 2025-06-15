# Python script to add a listing step to .github/workflows/android_build.yml
# before the 'Set Gradle version' step.

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
set_gradle_version_step_found = False

# The new step to add, properly formatted as a Python multiline string
# Indentation within this string is critical for correct YAML output.
list_files_step_yaml = '''      - name: List files in android directory
        working-directory: ./flutter_dashboard_app/android
        run: |
          echo "Listing files in $(pwd):"
          ls -la
'''

# Find the line where "- name: Set Gradle version" occurs and insert before it.
# This assumes that the name of the step is unique and consistently named.
insertion_index = -1
for i, line_content in enumerate(lines):
    if line_content.lstrip().startswith("- name: Set Gradle version"):
        insertion_index = i
        break

if insertion_index != -1:
    # Split the list_files_step_yaml into lines and prepend to new_lines at insertion_index
    # Ensure correct indentation for each line of the new step if not already handled by the string itself.
    # The string already has leading spaces for YAML, so it should be fine.
    new_lines = lines[:insertion_index]
    new_lines.extend(list_files_step_yaml.splitlines(True)) # splitlines(True) keeps newlines
    new_lines.extend(lines[insertion_index:])
else:
    print("Warning: 'Set Gradle version' step not found. Listing step not added as intended.")
    # If the target step wasn't found, write back the original lines to avoid accidental damage.
    new_lines = lines


with open(workflow_file_path, "w") as f:
    f.writelines(new_lines)

if insertion_index != -1:
    print(f"Added 'List files in android directory' step before 'Set Gradle version' in {workflow_file_path}.")
else:
    print(f"Did not modify {workflow_file_path} as target insertion point not found.")
