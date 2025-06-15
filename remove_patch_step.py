# Python script to remove the 'Patch build.gradle.kts after flutter create' step (Corrected Logic)
# from .github/workflows/android_build.yml

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_step_to_remove = False

# Name of the step to remove
step_name_to_remove_prefix = "- name: Patch build.gradle.kts after flutter create"

for line_content in lines:
    stripped_line = line_content.lstrip()

    if in_step_to_remove:
        # If the current line is the start of a new step definition (i.e., less or equally indented
        # than the step definition itself, and starts with "- name:")
        # then we've exited the step-to-remove block.
        # A simple check is if it starts with "- name:" as all our steps do.
        # More robust would be to check indentation level against the original step's indent.
        if stripped_line.startswith("- name:"):
            in_step_to_remove = False
            new_lines.append(line_content) # This new step should be kept
        # else, this line is part of the multi-line step to remove, so we skip it (do nothing)
    else:
        if stripped_line.startswith(step_name_to_remove_prefix):
            in_step_to_remove = True
            # Skip this line (the - name: line itself)
        else:
            new_lines.append(line_content) # Not in step to remove, and not starting it

with open(workflow_file_path, "w") as f:
    f.writelines(new_lines)

print(f"Attempted removal of 'Patch build.gradle.kts after flutter create' step (Corrected Logic) from {workflow_file_path}.")
