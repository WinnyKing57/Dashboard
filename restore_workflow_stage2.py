# Python script to update .github/workflows/android_build.yml
# with the second set of restored steps.

import os

workflow_file_path = ".github/workflows/android_build.yml"

restored_workflow_content_stage2 = '''name: Android Build - Step Restore 2

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

      - name: Upgrade Flutter dependencies
        working-directory: ./flutter_dashboard_app
        run: flutter pub upgrade --major-versions

      - name: Regenerate Android project
        working-directory: ./flutter_dashboard_app
        run: flutter create . --platforms android

      - name: Set Gradle version
        working-directory: ./flutter_dashboard_app/android
        run: ./gradlew wrapper --gradle-version 8.9 --distribution-type all

      - name: Get Flutter dependencies
        working-directory: ./flutter_dashboard_app
        run: flutter pub get

      - name: Generate files
        working-directory: ./flutter_dashboard_app
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Clean Android build
        working-directory: ./flutter_dashboard_app/android
        run: ./gradlew clean

      - name: Test command after Flutter/Gradle steps
        run: echo "Flutter/Gradle setup and clean steps completed."
'''

try:
    with open(workflow_file_path, "w") as f:
        f.write(restored_workflow_content_stage2)
    print(f"Successfully updated {workflow_file_path} with Flutter/Gradle steps (Stage 2).")
except Exception as e:
    print(f"Error writing restored workflow (Stage 2) to {workflow_file_path}: {e}")
