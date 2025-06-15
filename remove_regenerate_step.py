# Python script to remove the 'Regenerate Android project' step
# from .github/workflows/android_build.yml

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_regenerate_step = False

for line_content in lines:
    strip_content = line_content.lstrip()

    if strip_content.startswith("- name: Regenerate Android project"):
        in_regenerate_step = True
        # Skip this line and subsequent lines of this step
        continue

    if in_regenerate_step:
        # If it's an indented line, it's part of the step to remove
        if line_content.startswith(" ") or line_content.startswith("\t"):
            # Check if it's a new step starting, if so, stop skipping
            if strip_content.startswith("- name:"):
                in_regenerate_step = False
                new_lines.append(line_content) # Add this new step line
            else:
                continue # Skip this line as it's part of regenerate step
        else: # No longer indented, so regenerate step is over
            in_regenerate_step = False
            new_lines.append(line_content) # Add this line
    else:
        new_lines.append(line_content)

with open(workflow_file_path, "w") as f:
    f.writelines(new_lines)

print(f"Removed 'Regenerate Android project' step from {workflow_file_path}.")
