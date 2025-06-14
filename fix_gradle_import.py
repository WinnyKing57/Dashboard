# Python script to fix flutter_dashboard_app/android/app/build.gradle.kts

import os

gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

with open(gradle_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
import_added = False
properties_line_found = False

# Add the import if not already present and ensure it's at the top
if not lines or not lines[0].strip().startswith("import java.util.Properties"):
    new_lines.append("import java.util.Properties\n")
    import_added = True

for line in lines:
    # Skip adding duplicate import if somehow present later
    if import_added and line.strip().startswith("import java.util.Properties"):
        continue

    new_lines.append(line)

    # Check if this is the line where java.util.Properties is used
    if "java.util.Properties()" in line:
        properties_line_found = True

# If the properties line was found but the import wasn't at the top initially,
# this ensures it's there. If the file was empty, it adds it.
if properties_line_found and not import_added and not (new_lines[0].strip().startswith("import java.util.Properties")):
    # This case is tricky, means import was missing but not caught by first check.
    # Prepending again if the first line isn't it.
    current_first_line = new_lines[0] if new_lines else ""
    if not current_first_line.startswith("import java.util.Properties"):
        new_lines.insert(0, "import java.util.Properties\n")


# No changes to the storeFile line for now as it seems syntactically correct
# and the primary error was the missing import. The second error might be a cascade.

with open(gradle_file_path, "w") as f:
    f.writelines(new_lines)

if import_added or (properties_line_found and new_lines[0].strip().startswith("import java.util.Properties")):
    print(f"Successfully added 'import java.util.Properties' to {gradle_file_path}.")
else:
    print(f"Could not verify addition of import in {gradle_file_path}. Check file content.")
