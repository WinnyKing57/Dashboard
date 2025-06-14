# Python script to further sanitize flutter_dashboard_app/android/app/build.gradle.kts

import os

gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

with open(gradle_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
import_found_in_original = False

# First, check if import exists and remove it to avoid duplication if script runs multiple times
for line in lines:
    if line.strip() == "import java.util.Properties":
        import_found_in_original = True
        # Don't add it to new_lines yet, we'll add it definitively at the top
    elif line.strip().startswith("val keystoreProperties = java.util.Properties()"):
        # Re-type this line to ensure no hidden characters
        new_lines.append("val keystoreProperties = java.util.Properties()\n")
    else:
        new_lines.append(line)

# Remove any leading blank lines from new_lines
while new_lines and new_lines[0].strip() == "":
    new_lines.pop(0)

# Add the import statement at the very beginning
final_lines = ["import java.util.Properties\n"]

# Add a blank line after the import, if there's content following
if new_lines:
    final_lines.append("\n")

final_lines.extend(new_lines)

with open(gradle_file_path, "w") as f:
    f.writelines(final_lines)

print(f"Sanitized and ensured 'import java.util.Properties' is at the top of {gradle_file_path}.")
print(f"Original import found: {import_found_in_original}")

# For debugging, print the first few lines that will be written
print("First 5 lines to be written:")
for i, line_to_write in enumerate(final_lines[:5]):
    print(f"{i+1}: {line_to_write.rstrip()}")
