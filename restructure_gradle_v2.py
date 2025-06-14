# Python script to restructure flutter_dashboard_app/android/app/build.gradle.kts (v2)
# Moves keystore properties loading logic inside the android {} block.

import os

gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"
print(f"Attempting to restructure: {gradle_file_path}")

with open(gradle_file_path, "r") as f:
    original_lines = f.readlines()
print(f"Read {len(original_lines)} lines from file.")

# Normalize line endings to avoid mixed endings issues
original_lines = [line.rstrip('\r\n') + '\n' for line in original_lines]

import_line_content = "import java.util.Properties\n"
keystore_logic_to_move = []
lines_before_keystore_block = []
lines_after_keystore_block = []

# --- Stage 1: Identify and separate sections ---
found_import = False
found_keystore_start = False
found_keystore_end = False
keystore_start_index = -1
keystore_end_index = -1

# First, ensure import is captured if present, and identify keystore block
temp_capture_lines = list(original_lines)
print("\n--- Identifying Keystore Block ---")

for i, line in enumerate(temp_capture_lines):
    stripped_line = line.strip()
    # print(f"Processing line {i}: '{stripped_line}'")

    if stripped_line == "import java.util.Properties":
        found_import = True
        # print(f"  Found import at line {i}")
        continue

    if not found_keystore_start and stripped_line.startswith("val keystorePropertiesFile"):
        found_keystore_start = True
        keystore_start_index = i
        print(f"  Keystore start detected at line {i}: '{stripped_line}'")

    if found_keystore_start and not found_keystore_end:
        keystore_logic_to_move.append(line)
        # print(f"    Added to keystore_logic_to_move: '{line.strip()}'")
        if stripped_line == "}":
            print(f"  Potential keystore end '}}' found at line {i}")
            prev_meaningful_line = ""
            if len(keystore_logic_to_move) > 1: # Need at least one line before the '}'
                for j in range(len(keystore_logic_to_move) - 2, -1, -1):
                    # print(f"    Checking prev_meaningful_line candidate: '{keystore_logic_to_move[j].strip()}'")
                    if keystore_logic_to_move[j].strip() != "":
                        prev_meaningful_line = keystore_logic_to_move[j].strip()
                        # print(f"    Prev meaningful line for '}}' is: '{prev_meaningful_line}'")
                        break

            if "keystoreProperties.load(it)" in prev_meaningful_line:
                 print(f"    Confirmed keystore end: 'keystoreProperties.load(it)' found in previous line.")
                 found_keystore_end = True
                 keystore_end_index = i
            else:
                print(f"    Rejected potential keystore end: 'keystoreProperties.load(it)' NOT found in '{prev_meaningful_line}'")
        elif found_keystore_start and stripped_line.startswith("plugins {") and not found_keystore_end :
            print(f"  WARNING: Hit 'plugins {{' at line {i} before keystore end was confirmed. This might indicate an issue.")
            # This implies the '}' was missed or structure is unexpected.


print(f"\nIdentification Results:")
print(f"  found_import: {found_import}")
print(f"  found_keystore_start: {found_keystore_start} (index: {keystore_start_index})")
print(f"  found_keystore_end: {found_keystore_end} (index: {keystore_end_index})")
if keystore_logic_to_move:
    print(f"  Identified keystore_logic_to_move ({len(keystore_logic_to_move)} lines):")
    for k_line in keystore_logic_to_move:
        print(f"    {k_line.strip()}")

if not (found_keystore_start and found_keystore_end):
    print("\nError: Keystore logic block not clearly identified. Aborting script execution.")
    # Writing original_lines back to be safe for this step.
    with open(gradle_file_path, "w") as f:
        f.writelines(original_lines)
    print("Original file content has been restored due to identification error.")
    exit() # Stop script execution here

# --- Stage 2: Prepare lines_before and lines_after the keystore block ---
print("\n--- Preparing Processed Lines (original lines without import and keystore block) ---")
processed_lines = []
for i, line in enumerate(original_lines):
    if line.strip() == "import java.util.Properties":
        continue
    if keystore_start_index <= i <= keystore_end_index:
        continue
    processed_lines.append(line)

# Remove leading blank lines
while processed_lines and processed_lines[0].strip() == "":
    processed_lines.pop(0)
# print(f"  Processed_lines (first 5 after cleaning):")
# for p_line in processed_lines[:5]:
#    print(f"    {p_line.strip()}")


# --- Stage 3: Reconstruct the file content ---
print("\n--- Reconstructing Final File Content ---")
final_lines = []

final_lines.append(import_line_content)
# print(f"Added import: {import_line_content.strip()}")

if processed_lines and processed_lines[0].strip() != "":
    final_lines.append("\n")
    # print("Added blank line after import.")

in_android_block = False
placed_keystore_logic = False
android_indentation = "    "

for line_content in processed_lines:
    if not placed_keystore_logic:
        if line_content.strip().startswith("android {"):
            in_android_block = True
            # print(f"Entered android block. Current line: {line_content.strip()}")

        if in_android_block and line_content.strip().startswith("signingConfigs {"):
            # print(f"Found 'signingConfigs {{'. Inserting keystore logic before it.")
            if keystore_logic_to_move: final_lines.append("\n")
            for ks_line in keystore_logic_to_move:
                final_lines.append(android_indentation + ks_line.lstrip())
            if keystore_logic_to_move: final_lines.append("\n")
            placed_keystore_logic = True
            # print(f"  Keystore logic placed. placed_keystore_logic: {placed_keystore_logic}")

    final_lines.append(line_content)

if not placed_keystore_logic:
    print("\nWarning: Keystore logic was not placed. This usually means 'signingConfigs {' was not found inside 'android {}'.")
    print("The script will write the file without moving the keystore block if it was already removed, or with it if not identified.")


with open(gradle_file_path, "w") as f:
    f.writelines(final_lines)

print(f"\nScript finished. Attempted restructure (v2_debug) of {gradle_file_path}.")
# print("First 25 lines written:")
# for i, l_o in enumerate(final_lines[:25]):
# print(f"{i+1}: {l_o.rstrip()}")
