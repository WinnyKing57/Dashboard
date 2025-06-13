# Python script to update .github/workflows/android_build.yml
# with the first set of restored steps.

import os

workflow_file_path = ".github/workflows/android_build.yml"

restored_workflow_content_stage1 = '''name: Android Build - Step Restore 1

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    name: Build Flutter Android App
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Test command after initial setup
        run: echo "Initial setup steps (Java, Flutter) completed."
'''

try:
    with open(workflow_file_path, "w") as f:
        f.write(restored_workflow_content_stage1)
    print(f"Successfully updated {workflow_file_path} with initial restored steps (Checkout, Java, Flutter).")
except Exception as e:
    print(f"Error writing restored workflow (stage 1) to {workflow_file_path}: {e}")
