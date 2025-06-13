# Python script to replace the content of .github/workflows/android_build.yml
# with a minimal workflow for diagnostic purposes.

import os

workflow_file_path = ".github/workflows/android_build.yml"

minimal_workflow_content = '''name: Android Build Minimal Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test_job:
    name: Test Job Execution
    runs-on: ubuntu-latest
    steps:
      - name: Run a test command
        run: echo "Test job is running successfully!"
'''

try:
    with open(workflow_file_path, "w") as f:
        f.write(minimal_workflow_content)
    print(f"Successfully replaced content of {workflow_file_path} with a minimal test workflow.")
except Exception as e:
    print(f"Error writing minimal workflow to {workflow_file_path}: {e}")
    # If there's an error, we might want to indicate failure or attempt to restore.
    # For now, just print the error.
