# Python script to remove the orphaned heredoc block from .github/workflows/android_build.yml

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_orphaned_block = False

# Heuristic start and end markers for the orphaned block
# The start is a unique line from within the Python script content.
# The heredoc content itself is what we need to match against.
# A very specific line from the script:
orphaned_block_start_content = 'keystore_logic_to_insert = ['
# The heredoc ends with an indented 'EOF'
orphaned_block_end_content = "EOF"


for line_content in lines:
    stripped_content_for_check = line_content.strip() # For checking content like EOF

    # We need to check the line_content itself for the start marker because of indentation
    # "          keystore_logic_to_insert = ["
    # So, we check if the non-whitespace part starts with our marker.

    if not in_orphaned_block:
        if line_content.lstrip().startswith(orphaned_block_start_content):
            in_orphaned_block = True
            # Do not append this line, as it's the start of the block to remove
        else:
            new_lines.append(line_content)
    else: # We are in the orphaned block
        # Check for the end of the heredoc
        if stripped_content_for_check == orphaned_block_end_content:
            in_orphaned_block = False
            # Do not append this line (the EOF line itself)
        # else: still in the block, so skip the line (do nothing)

with open(workflow_file_path, "w") as f:
    f.writelines(new_lines)

print(f"Attempted to remove orphaned heredoc block from {workflow_file_path}.")
