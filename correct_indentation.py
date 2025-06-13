# Python script to ensure correct indentation for the jobs block
# in .github/workflows/android_build.yml

import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_jobs_block = False
jobs_line_found = False
build_job_line_found = False

for line in lines:
    stripped_line = line.lstrip() # Remove leading whitespace to check content

    if stripped_line.startswith("jobs:"):
        new_lines.append("jobs:\n") # Ensure jobs: is at the start of a line
        in_jobs_block = True
        jobs_line_found = True
        continue
    elif stripped_line.startswith("build:") and in_jobs_block and not build_job_line_found:
        # This is the job_id 'build'
        new_lines.append("  build:\n") # Explicit 2-space indent
        build_job_line_found = True
        continue
    elif jobs_line_found and build_job_line_found and not stripped_line.startswith("- name:"):
        # These are lines like 'name: Build Flutter Android App', 'runs-on:', 'steps:'
        # These should be indented under 'build:' (4 spaces total)
        if line.strip(): # if not an empty line
            new_lines.append("    " + stripped_line)
        else:
            new_lines.append("\n") # Keep empty lines
        continue
    elif build_job_line_found and stripped_line.startswith("steps:"):
        # steps: itself should be at 4 spaces
        new_lines.append("    steps:\n")
        continue
    elif build_job_line_found and stripped_line.startswith("- name:"):
        # These are the actual steps, should be indented under 'steps:'
        # (6 spaces for the dash)
        new_lines.append("      " + stripped_line) # Dash + name
        continue
    elif in_jobs_block and build_job_line_found and line.strip().startswith("uses:"):
        # uses: or with: or run: for a step, indented further
        new_lines.append("        " + stripped_line) # 8 spaces
        continue
    elif in_jobs_block and build_job_line_found and line.strip().startswith("with:"):
        new_lines.append("        " + stripped_line) # 8 spaces
        continue
    elif in_jobs_block and build_job_line_found and line.strip().startswith("run:"):
         # Handle multi-line run commands carefully
        if "|" in stripped_line or ">" in stripped_line : # an actual run command with multiline indicator
            new_lines.append("        " + stripped_line)
        else: # just the run: keyword
            new_lines.append("        run:" + line[line.find("run:")+4:]) # Preserve original content after run:
        continue
    elif in_jobs_block and build_job_line_found and line.strip().startswith("if:"):
        new_lines.append("        " + stripped_line)
        continue


    # Default case: if not part of the specific restructuring, keep the line as is.
    # This part of the script might be too aggressive if the above conditions aren't perfect.
    # A safer approach for lines *within* a step (like multiline run commands or 'with' args)
    # is to preserve their original spacing relative to their step definition,
    # but the primary goal here is `jobs:` and `build:`

    # Fallback for lines not matching specific restructuring logic for jobs/build/steps headers
    # This part needs to be careful not to mess up indentation within multi-line run commands
    # or complex step definitions.

    # For simplicity, if we are past the 'build:' job definition,
    # assume the rest of the file has correct relative indentation for now
    # and just append. The main focus is `jobs:` and `build:`.
    if jobs_line_found and build_job_line_found:
        # If we are inside a step's multiline script (e.g. run: |)
        # the lines should maintain their existing relative indentation
        # The script above is trying to re-indent based on keywords which is risky for content.

        # Let's refine: The script above is trying to reformat *everything*.
        # It's better to *only* reformat the `jobs:` and `build:` lines and their direct children like `name:`, `runs-on:`, `steps:`.
        # The content of `steps:` (the list of `- name: ...`) should be preserved or handled by a more robust YAML parser.

        # Given the difficulty of perfect YAML re-indentation with string manipulation for all cases,
        # I will simplify the script to *only* ensure `jobs:` is at column 0 and `build:` is at column 2.
        # Other lines will be passed through as they are. This is less risky.

        pass # Will be handled by the refined script below.


# --- Refined approach: Only fix critical 'jobs:' and 'build:' indentation ---
new_lines_refined = []
processed_jobs_indent = False
for current_line_index, line_content in enumerate(lines):
    stripped_content = line_content.lstrip()

    if not processed_jobs_indent:
        if stripped_content.startswith("jobs:"):
            new_lines_refined.append("jobs:\n") # Ensure 'jobs:' is at column 0
            # Assuming 'build:' is the next significant line or few lines down.
            # This is a bit fragile but aims to fix the most common issue.
            for i in range(current_line_index + 1, len(lines)):
                next_line_stripped = lines[i].lstrip()
                if next_line_stripped.startswith("build:"):
                    new_lines_refined.append("  build:" + lines[i][lines[i].find("build:")+6:]) # Indent 'build:' by 2 spaces
                    # Mark as processed and skip adding these lines in the outer loop again for a bit
                    # This is getting complicated. A simple string replace might be better if the structure is known.
                    break
                elif lines[i].strip() != "": # if we hit another non-empty line before build:
                    new_lines_refined.append(lines[i]) # append it as is
                else:
                    new_lines_refined.append(lines[i])


            processed_jobs_indent = True # Avoid reprocessing these lines
            # This logic is flawed for inserting lines correctly.

            # Let's use a state machine instead.
            # State 0: Before jobs
            # State 1: Found jobs, looking for build
            # State 2: Found build, processing build's children (name, runs-on, steps)
            # State 3: Inside steps list
            # State 4: Deep inside a step definition (e.g. multiline run)

            # This is too complex for a simple subtask script without a YAML parser.
            # I will revert to targeted replacement if possible, or recommend manual check.

            # The most robust thing I can do with string manipulation is ensure
            # `jobs:` is at column 0 if it exists, and the line starting with `build:`
            # (if it's the job id) is indented.

            # If the file is reasonably well-formed otherwise, this might be enough.
            # Let's try a simpler replacement strategy for known lines.
            # This assumes 'jobs:' and '  build:' are the main issue.

            # Simpler strategy:
            # If line contains 'jobs:', replace with 'jobs:'.
            # If line contains '  build:' (as job id), replace with '  build:'.
            # This doesn't fix if 'build:' was '    build:'.

            # I will construct the beginning of the jobs section directly.
            # This is risky if there are other jobs than 'build'.
            # The user's provided workflow only shows one job 'build'.

            break # Breaking out to use a different strategy for new_lines_refined

    # If the above complex logic is abandoned, this loop doesn't run,
    # new_lines_refined would be empty.

# --- A more targeted and less destructive approach ---
# Try to find 'jobs:' and 'build:' and ensure their indentation.
# This is still tricky with pure string manipulation if current indentation is unknown.

# Final attempt at a controlled re-indentation of the critical job block:
# Read all lines.
# Find the line index for 'jobs:'. If found, rewrite it.
# Find the line index for 'build:' (the job_id). If found, rewrite it relative to 'jobs:'.
# Find 'name:', 'runs-on:', 'steps:' under 'build:' and rewrite them.
# Rewrite '  - name:' for steps.

temp_lines = list(lines) # Make a mutable copy

try:
    jobs_idx = -1
    for i, line_content in enumerate(temp_lines):
        if line_content.lstrip().startswith("jobs:"):
            jobs_idx = i
            temp_lines[i] = "jobs:\n"
            break

    if jobs_idx != -1:
        build_idx = -1
        for i in range(jobs_idx + 1, len(temp_lines)):
            if temp_lines[i].lstrip().startswith("build:"): # Assuming 'build' is the job_id
                build_idx = i
                # Preserve content after 'build:' token
                original_build_line_content = temp_lines[i].lstrip()
                rest_of_build_line = original_build_line_content[len("build:"):]
                temp_lines[i] = "  build:" + rest_of_build_line + ("" if rest_of_build_line.endswith("\n") else "\n")
                break

        if build_idx != -1:
            # Process 'name:', 'runs-on:', 'steps:' directly under 'build:'
            for i in range(build_idx + 1, len(temp_lines)):
                line_content_stripped = temp_lines[i].lstrip()
                if line_content_stripped.startswith("name:") or \
                   line_content_stripped.startswith("runs-on:") or \
                   line_content_stripped.startswith("steps:"):
                    # Preserve content after the token
                    token_end_idx = temp_lines[i].find(":") + 1
                    rest_of_line = temp_lines[i][token_end_idx:]
                    leading_token = line_content_stripped[:line_content_stripped.find(":")+1]
                    temp_lines[i] = "    " + leading_token + rest_of_line + ("" if rest_of_line.endswith("\n") else "\n")
                elif line_content_stripped.startswith("- name:"): # Start of steps list
                    # Once we hit the steps list, assume subsequent lines are okay or too complex to naively re-indent
                    break
                elif not line_content_stripped: # Empty line
                    temp_lines[i] = "\n"
                # else: other lines we don't touch for now to avoid breaking them.

    # Write the potentially modified lines
    with open(workflow_file_path, "w") as f:
        f.writelines(temp_lines)
    print(f"Attempted to correct critical indentation in {workflow_file_path}.")

except Exception as e:
    print(f"Error during script execution: {e}")
    # Fallback: write original content if error
    with open(workflow_file_path, "w") as f:
        f.writelines(lines)
    print("Original content restored due to error.")
