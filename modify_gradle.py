# Python script to modify the build.gradle.kts content
import os

# Path to the build.gradle.kts file
gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

# Read the original content
with open(gradle_file_path, "r") as f:
    original_content = f.read()

new_content = original_content

# 1. Add keystore properties loading at the top
keystore_properties_load = '''\
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

'''
if "val keystorePropertiesFile" not in new_content:
    new_content = keystore_properties_load + new_content

# 2. Add signingConfigs block inside android { ... }
# Find the end of the defaultConfig block to insert signingConfigs before buildTypes
default_config_end_marker = "multiDexEnabled = true" # Assuming this is the last line of defaultConfig
default_config_index = new_content.find(default_config_end_marker)

if default_config_index != -1:
    insertion_point_for_signing_config = new_content.find("}", default_config_index) + 1
    if new_content.find("signingConfigs", insertion_point_for_signing_config, new_content.find("buildTypes")) == -1: # check if not already present
        signing_config_block = '''\

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) } ?: System.getenv("STORE_FILE")?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("STORE_PASSWORD")
        }
    }
'''
        new_content = new_content[:insertion_point_for_signing_config] + signing_config_block + new_content[insertion_point_for_signing_config:]

# 3. Modify release build type
release_build_type_marker = "buildTypes {"
release_build_type_start_index = new_content.find(release_build_type_marker)

if release_build_type_start_index != -1:
    release_block_start = new_content.find("release {", release_build_type_start_index)
    if release_block_start != -1:
        signing_config_debug_line = 'signingConfig = signingConfigs.getByName("debug")'
        debug_line_index = new_content.find(signing_config_debug_line, release_block_start)
        if debug_line_index != -1:
            # Replace the debug signing line with the release signing line
            new_release_signing_line = 'signingConfig = signingConfigs.getByName("release")'
            # Also ensure ProGuard/R8 settings are present for release builds, as they are good practice.
            # This is a common place to put them.
            proguard_lines = '''\
            isMinifyEnabled = false // Or true if you want to enable it
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro") // Uncomment if you have a proguard-rules.pro
'''
            # Remove existing signingConfig line and potentially comments around it
            # Find the start of the line for signingConfig = signingConfigs.getByName("debug")
            line_start = new_content.rfind("\n", 0, debug_line_index) + 1
            # Find the end of the line
            line_end = new_content.find("\n", debug_line_index)

            # Remove comments TODO and Signing with the debug keys...
            comment_todo_line_start = new_content.rfind("\n// TODO: Add your own signing config", 0, line_start)
            if comment_todo_line_start == -1: # If it's at the very start of the block
                 comment_todo_line_start = new_content.rfind("{", 0, line_start) +1

            comment_signing_debug_line_start = new_content.rfind("\n            // Signing with the debug keys", 0, line_start)

            if comment_todo_line_start != -1 and comment_signing_debug_line_start != -1 and comment_signing_debug_line_start > comment_todo_line_start :
                 # We want to remove from the start of "// TODO:" up to the end of the signingConfig line
                 block_to_replace = new_content[comment_todo_line_start:line_end]
                 replacement_block = "\n            " + new_release_signing_line + "\n" + proguard_lines
                 new_content = new_content.replace(block_to_replace, replacement_block, 1)

# Write the modified content back to the file
with open(gradle_file_path, "w") as f:
    f.write(new_content)

print(f"Successfully modified {gradle_file_path} for release signing.")
