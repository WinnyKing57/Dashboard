# Python script to comment out the keystore-related steps
# in .github/workflows/android_build.yml for diagnosis.
# This assumes the Build APK and Upload Artifact steps are already commented out.

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
comment_mode = None # Can be 'keystore_props', 'decode_keystore', or None

for line_content in lines:
    strip_content = line_content.lstrip()

    # Detect start of a new step; if so, and we were in a comment_mode, turn it off.
    # This is important if the steps are not contiguous or if other steps are between them.
    if strip_content.startswith("- name:") and comment_mode:
        if not (strip_content.startswith("- name: Create keystore.properties") or \
                strip_content.startswith("- name: Decode Keystore")):
            comment_mode = None # Exited the block we were commenting

    # Check if we should enter comment_mode for keystore steps
    if strip_content.startswith("- name: Create keystore.properties"):
        comment_mode = 'keystore_props'
    elif strip_content.startswith("- name: Decode Keystore"):
        comment_mode = 'decode_keystore'

    # If current line is part of a step to be commented, or is already commented (from previous diagnostic)
    if comment_mode or line_content.strip().startswith("#- name: Build Android APK (Release)") \
                   or line_content.strip().startswith("#- name: Upload APK Artifact (Release)") \
                   or (line_content.startswith("#") and ("run: flutter build apk" in line_content or "uses: actions/upload-artifact@v4" in line_content)): # check if it's a content line of already commented block
        # If it's one of the keystore steps we are now targeting, comment it.
        # If it's an already commented line (build/upload), keep it commented.
        if comment_mode and not line_content.startswith("#"):
            if line_content.strip(): # If not an empty line
                new_lines.append("#" + line_content)
            else:
                new_lines.append(line_content) # Preserve empty line
        else:
            # Line is already commented (part of build/upload) or is a keystore step to be commented
            new_lines.append(line_content)
    else:
        new_lines.append(line_content)

with open(workflow_file_path, "w") as f:
    f.writelines(new_lines)

print(f"Commented out keystore-related steps in {workflow_file_path}.")
print("Build APK and Upload Artifact steps remain commented out from previous operation.")
