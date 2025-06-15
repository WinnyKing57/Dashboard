# Python script to comment out the Build APK and Upload Artifact steps
# in .github/workflows/android_build.yml for diagnosis.

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_build_apk_step = False
in_upload_artifact_step = False

for line in lines:
    stripped_line = line.lstrip()

    if stripped_line.startswith("- name: Build Android APK (Release)"):
        in_build_apk_step = True
    elif stripped_line.startswith("- name: Upload APK Artifact (Release)"):
        in_upload_artifact_step = True
        in_build_apk_step = False # Reset previous state if we somehow enter here directly

    # If in one of the target blocks, comment out the line
    if in_build_apk_step or in_upload_artifact_step:
        if line.strip(): # Don't comment out empty lines, just preserve them
            new_lines.append("#" + line)
        else:
            new_lines.append(line) # Preserve empty lines as is
    else:
        new_lines.append(line)

    # Logic to reset flags if we are clearly past the step definition
    # This relies on the next step starting with "- name:" or being end of file
    # A simple way: if a line is not indented and not part of the current block, reset.
    if not line.startswith(" ") and not line.startswith("#") and not stripped_line.startswith("- name:"):
        # This condition might be too broad or not specific enough.
        # A better way is to detect the start of a *new* step.
        # However, for commenting out, once we are in a block, we comment until the block ends.
        # The current logic comments out everything from the start of "Build Android APK"
        # or "Upload APK Artifact" to the end of those step definitions.
        # A step ends when a new unindented line or a new "- name:" appears.
        # This is complex for simple string processing.

        # Simpler reset: if the current line starts a new step, reset flags.
        # This is implicitly handled as we only set flags when we see the specific names.
        # If we enter a new step, the old flags won't cause commenting unless the new step
        # is one of the targeted ones.
        pass # Current logic should be okay for commenting out contiguous blocks

# The above logic for exiting a block is a bit loose.
# A more robust way for commenting is to identify the start of the block
# and comment out lines until the indentation level returns to the level of a step definition,
# or another step definition ("- name:") is found.

# Let's refine the commenting to be more precise about block boundaries.
# This script will comment out the "Build Android APK (Release)" and "Upload APK Artifact (Release)" steps.

final_lines_for_commenting = []
comment_mode = None # Can be 'build_apk', 'upload_artifact', or None

for line_content in lines:
    strip_content = line_content.lstrip()

    # Detect start of a new step; if so, and we were in a comment_mode, turn it off.
    if strip_content.startswith("- name:") and comment_mode:
        if (comment_mode == 'build_apk' and strip_content != "- name: Build Android APK (Release)") or \
           (comment_mode == 'upload_artifact' and strip_content != "- name: Upload APK Artifact (Release)"):
            comment_mode = None # Exited the block we were commenting

    # Check if we should enter comment_mode
    if strip_content.startswith("- name: Build Android APK (Release)"):
        comment_mode = 'build_apk'
    elif strip_content.startswith("- name: Upload APK Artifact (Release)"):
        comment_mode = 'upload_artifact'

    if comment_mode:
        if line_content.strip(): # If not an empty line
            final_lines_for_commenting.append("#" + line_content)
        else:
            final_lines_for_commenting.append(line_content) # Preserve empty line
    else:
        final_lines_for_commenting.append(line_content)

with open(workflow_file_path, "w") as f:
    f.writelines(final_lines_for_commenting)

print(f"Commented out 'Build Android APK (Release)' and 'Upload APK Artifact (Release)' steps in {workflow_file_path}.")
