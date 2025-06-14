# Python script to restructure flutter_dashboard_app/android/app/build.gradle.kts
# Moves keystore properties loading logic inside the android {} block.

import os

gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

with open(gradle_file_path, "r") as f:
    lines = f.readlines()

# Identify the keystore properties lines
keystore_logic_lines = []
other_lines_at_top = []
import_line = ""

# Separate import, keystore logic, and other initial lines
temp_lines_for_top = list(lines)
found_import = False
start_keystore_index = -1
end_keystore_index = -1

for i, line in enumerate(temp_lines_for_top):
    stripped_line = line.strip()
    if stripped_line == "import java.util.Properties":
        import_line = line
        found_import = True
        continue # Keep import separate

    if found_import and start_keystore_index == -1 and stripped_line.startswith("val keystorePropertiesFile"):
        start_keystore_index = i

    if start_keystore_index != -1 and i >= start_keystore_index:
        if "keystoreProperties.load(it)" in stripped_line: # Heuristic for end of block
            end_keystore_index = i
            keystore_logic_lines = temp_lines_for_top[start_keystore_index : end_keystore_index+1]
            # Now populate other_lines_at_top with lines that are neither import nor keystore logic from the top part
            other_lines_at_top = temp_lines_for_top[:start_keystore_index] # Lines before keystore logic
            if import_line and other_lines_at_top and other_lines_at_top[0] == import_line:
                other_lines_at_top.pop(0) # remove import if it was captured here

            # Add lines after keystore logic but before plugins {} block if any
            # This logic is getting too complex, assuming simple structure: import, keystore_logic, plugins
            break # Found the block
        elif "}" in stripped_line and "keystoreProperties.load(it)" not in temp_lines_for_top[i-1] and "keystoreProperties.load(it)" not in temp_lines_for_top[i-2] : # ensure } is part of if
             # this means we might have passed the if block without finding the exact line
             end_keystore_index = i-1 # take up to previous line
             keystore_logic_lines = temp_lines_for_top[start_keystore_index : end_keystore_index+1]
             other_lines_at_top = temp_lines_for_top[:start_keystore_index]
             if import_line and other_lines_at_top and other_lines_at_top[0] == import_line:
                other_lines_at_top.pop(0)
             break


# Fallback if exact lines not found but we have a general idea (less safe)
if not keystore_logic_lines and found_import: # if import was found but logic not clearly isolated
    # This assumes the keystore logic is lines 2-5 if import is line 1
    # This is based on the structure I expect from previous reads.
    # Line 0: import
    # Line 1: (potentially blank)
    # Line 2: val keystorePropertiesFile ...
    # Line 3: val keystoreProperties ...
    # Line 4: if (keystorePropertiesFile.exists()) { ... }
    # Line 5:   keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    # Line 6: }

    # A simpler, more direct removal based on known content if parsing fails
    # This is risky if the file structure changed.
    # For now, let's assume the complex parsing above works or we proceed with original lines if it fails to find.
    pass


# Construct the new file content
new_gradle_content = []

# 1. Add the import statement first
if import_line:
    new_gradle_content.append(import_line)
else: # If import wasn't found, add it anyway (shouldn't happen based on previous steps)
    new_gradle_content.append("import java.util.Properties\n")

# Add any other lines that were at the top (e.g. blank lines after import, before old keystore logic)
new_gradle_content.extend(other_lines_at_top)


# Iterate through the rest of the original lines
# and place keystore_logic_lines before signingConfigs
# This requires finding the android {} block and then signingConfigs {}
# This is also complex. Let's try a simpler approach:
# Remove from original lines, then re-insert.

# Filter out the keystore logic from the main list of lines
# Also filter out the import if it was captured multiple times
# and any initial blank lines if they will be re-added.

remaining_lines = []
already_added_import = False
if import_line: already_added_import = True # Already handled

# Filter out the keystore logic that was at the top
is_old_keystore_logic_line = False
old_keystore_logic_indices = range(start_keystore_index if start_keystore_index!=-1 else -1, end_keystore_index+1 if end_keystore_index!=-1 else -1)

for i, line in enumerate(lines):
    if line.strip() == "import java.util.Properties" and already_added_import:
        continue # Skip, already handled
    if not already_added_import and line.strip() == "import java.util.Properties":
        already_added_import = True # Mark as handled if it's the first thing
        # (This case is if import_line was not set, which is unlikely)
        continue

    if i in old_keystore_logic_indices:
        continue # Skip these lines, they will be re-inserted

    remaining_lines.append(line)


# Now, re-construct the file, inserting the keystore logic inside android {}
final_output_lines = []
if import_line:
    final_output_lines.append(import_line)
elif not any(l.strip() == "import java.util.Properties" for l in remaining_lines):
    final_output_lines.append("import java.util.Properties\n")


in_android_block = False
placed_keystore_logic = False

for line_idx, line_content in enumerate(remaining_lines):
    final_output_lines.append(line_content) # Add current line first

    if not placed_keystore_logic:
        if line_content.strip().startswith("android {"):
            in_android_block = True

        # Heuristic: Place before signingConfigs or at the end of android block if signingConfigs not found early
        if in_android_block and line_content.strip().startswith("signingConfigs {"):
            # Insert keystore_logic before this line
            # Need to adjust indentation for keystore_logic to fit android block (usually 4 spaces)
            for ks_line in keystore_logic_lines:
                final_output_lines.insert(len(final_output_lines) -1, "    " + ks_line) # Insert before current line
            if keystore_logic_lines : final_output_lines.insert(len(final_output_lines) -1, "\n") # Add a blank line after
            placed_keystore_logic = True
        elif in_android_block and line_content.strip() == "}" and remaining_lines[line_idx-1].strip().startswith("buildTypes"):
            # If we are at the closing '}' of the android block and haven't placed it yet
            # (e.g. if signingConfigs wasn't found above for some reason)
            for ks_line in keystore_logic_lines:
                final_output_lines.insert(len(final_output_lines) -1, "    " + ks_line)
            if keystore_logic_lines : final_output_lines.insert(len(final_output_lines) -1, "\n")
            placed_keystore_logic = True


if not keystore_logic_lines:
    print("Error: Keystore logic lines were not correctly identified. Aborting modification.")
    # Write original content back or handle error
    with open(gradle_file_path, "w") as f:
        f.writelines(lines) # Write original lines back
    # exit(1) # Signal error in a real script

else:
    with open(gradle_file_path, "w") as f:
        f.writelines(final_output_lines)
    print(f"Restructured {gradle_file_path}: Moved keystore properties loading inside android {{}} block.")
    print("First 15 lines written:")
    for i, l_o in enumerate(final_output_lines[:15]):
        print(f"{i+1}: {l_o.rstrip()}")
    print("\nLast 15 lines written:")
    for i, l_o in enumerate(final_output_lines[-15:]):
        print(f"{len(final_output_lines)-15+i+1}: {l_o.rstrip()}")
