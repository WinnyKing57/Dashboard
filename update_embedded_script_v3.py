# Python script to update the *embedded* Python script within .github/workflows/android_build.yml
# This version has hardcoded replacements in the embedded script string.

import os

workflow_file_path = ".github/workflows/android_build.yml"

# Define the literal strings the embedded script will search for and replace with
# These are still useful for clarity if we were building it dynamically, but now we hardcode them below.
# signing_config_find_val = r'signingConfig = signingConfigs.getByName("release")'
# signing_config_replace_val = r'signingConfig.set(signingConfigs.getByName("release"))'
# minify_false_find_val = r'isMinifyEnabled = false'
# minify_false_replace_val = r'isMinifyEnabled.set(false)'
# minify_true_find_val = r'isMinifyEnabled = true'
# minify_true_replace_val = r'isMinifyEnabled.set(true)'

new_embedded_python_script = '''\
          import os
          gradle_file_path = "flutter_dashboard_app/android/app/build.gradle.kts"

          with open(gradle_file_path, "r") as f:
              lines = f.readlines()

          keystore_logic_to_insert = [
              "    val keystorePropertiesFile = rootProject.file(\\"keystore.properties\\")\\n",
              "    val keystoreProperties = java.util.Properties()\\n",
              "    if (keystorePropertiesFile.exists()) {{\\n",
              "        keystorePropertiesFile.inputStream().use {{ keystoreProperties.load(it) }}\\n",
              "    }}\\n"
          ]

          temp_filtered_lines = []
          skip_block = False
          for i, line in enumerate(lines):
              stripped_line = line.strip()
              if stripped_line == "import java.util.Properties": continue
              if stripped_line.startswith("val keystorePropertiesFile = rootProject.file("):
                  skip_block = True; continue
              if skip_block:
                  is_keystore_if_closer = False
                  if stripped_line == "}}":
                      for j in range(i - 1, -1, -1):
                          prev_line_strip_check = lines[j].strip()
                          if not prev_line_strip_check: continue
                          if "keystorePropertiesFile.exists()" in prev_line_strip_check and prev_line_strip_check.endswith("{{"):
                              is_keystore_if_closer = True; break
                          if prev_line_strip_check.startswith("val keystorePropertiesFile"): break
                      if is_keystore_if_closer: skip_block = False
                  continue
              temp_filtered_lines.append(line)

          final_lines_stage1 = ["import java.util.Properties\\n", "\\n"]
          in_android_block = False; placed_keystore_logic = False
          while temp_filtered_lines and temp_filtered_lines[0].strip() == "": temp_filtered_lines.pop(0)

          for line_content in temp_filtered_lines:
              final_lines_stage1.append(line_content)
              if not placed_keystore_logic:
                  if line_content.strip().startswith("android {{"): in_android_block = True
                  if in_android_block and line_content.strip().startswith("signingConfigs {{"):
                      current_line_popped = final_lines_stage1.pop()
                      final_lines_stage1.extend(keystore_logic_to_insert)
                      final_lines_stage1.append("\\n")
                      final_lines_stage1.append(current_line_popped)
                      placed_keystore_logic = True
                  elif in_android_block and line_content.strip() == "}}" and final_lines_stage1[-2].strip().startswith("buildTypes {{"):
                      current_line_popped = final_lines_stage1.pop()
                      final_lines_stage1.extend(keystore_logic_to_insert)
                      final_lines_stage1.append("\\n")
                      final_lines_stage1.append(current_line_popped)
                      placed_keystore_logic = True

          if in_android_block and not placed_keystore_logic: print("Warning: Keystore logic not placed.")

          corrected_lines_final = []
          in_release_block_active = False
          for line_idx, current_line_text in enumerate(final_lines_stage1):
              if 'namespace = "com.example.flutter_dashboard_app"' in current_line_text:
                  current_line_text = current_line_text.replace('namespace = "com.example.flutter_dashboard_app"', 'namespace = "com.jules.flutter_dashboard_app"')
              if 'applicationId = "com.example.flutter_dashboard_app"' in current_line_text:
                  current_line_text = current_line_text.replace('applicationId = "com.example.flutter_dashboard_app"', 'applicationId = "com.jules.flutter_dashboard_app"')

              stripped_current_line = current_line_text.strip()
              if stripped_current_line == "release {{": in_release_block_active = True
              elif stripped_current_line == "}}" and in_release_block_active:
                  if line_idx > 0 and (len(final_lines_stage1[line_idx-1]) - len(final_lines_stage1[line_idx-1].lstrip()) > len(current_line_text) - len(current_line_text.lstrip())):
                      in_release_block_active = False

              if in_release_block_active:
                  # HARDCODED replacements for Kotlin DSL .set()
                  if 'signingConfig = signingConfigs.getByName("release")' in current_line_text:
                      current_line_text = current_line_text.replace('signingConfig = signingConfigs.getByName("release")', 'signingConfig.set(signingConfigs.getByName("release"))')
                  if 'isMinifyEnabled = false' in current_line_text:
                      current_line_text = current_line_text.replace('isMinifyEnabled = false', 'isMinifyEnabled.set(false)')
                  elif 'isMinifyEnabled = true' in current_line_text:
                      current_line_text = current_line_text.replace('isMinifyEnabled = true', 'isMinifyEnabled.set(true)')
              corrected_lines_final.append(current_line_text)

          with open(gradle_file_path, "w") as f: f.writelines(corrected_lines_final)
          print(f"Patched {{gradle_file_path}} with Kotlin DSL fixes (.set syntax) and ensured keystore logic placement.")
'''

# Read the current workflow file
with open(workflow_file_path, "r") as f:
    workflow_lines = f.readlines()

output_workflow_lines = []
in_patch_step_script = False

for wf_line in workflow_lines:
    stripped_wf_line = wf_line.strip()

    if stripped_wf_line == "- name: Patch build.gradle.kts after flutter create":
        output_workflow_lines.append(wf_line)
    elif output_workflow_lines and output_workflow_lines[-1].strip() == "- name: Patch build.gradle.kts after flutter create" and \
         stripped_wf_line == "run: |":
        output_workflow_lines.append(wf_line)
    elif output_workflow_lines and output_workflow_lines[-1].strip() == "run: |" and \
         "- name: Patch build.gradle.kts after flutter create" in output_workflow_lines[-2].strip() and \
         stripped_wf_line == "python << 'EOF'":
        output_workflow_lines.append(wf_line)
        # Append the new embedded script.
        # The new_embedded_python_script string already starts with the correct indentation (10 spaces)
        # because of how it's defined with '''\ and then subsequent lines have that indent.
        # However, to be safe, splitlines and add indent, as before.
        for script_line in new_embedded_python_script.splitlines(True):
             output_workflow_lines.append("          " + script_line)
        in_patch_step_script = True
    elif stripped_wf_line == "EOF" and in_patch_step_script:
        output_workflow_lines.append(wf_line)
        in_patch_step_script = False
    elif not in_patch_step_script:
        output_workflow_lines.append(wf_line)

with open(workflow_file_path, "w") as f:
    f.writelines(output_workflow_lines)

print(f"Successfully updated the embedded Python script in {workflow_file_path} (Hardcoded Version).")
