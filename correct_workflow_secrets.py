# Python script to correct the GitHub Actions workflow secrets syntax.
import os

workflow_file_path = ".github/workflows/android_build.yml"

with open(workflow_file_path, "r") as f:
    content = f.read()

# Replace the incorrect quadruple braces with double braces for secrets
corrected_content = content.replace("${{{{ secrets.RELEASE_STORE_PASSWORD }}}}", "${{ secrets.RELEASE_STORE_PASSWORD }}")
corrected_content = corrected_content.replace("${{{{ secrets.RELEASE_KEY_ALIAS }}}}", "${{ secrets.RELEASE_KEY_ALIAS }}")
corrected_content = corrected_content.replace("${{{{ secrets.RELEASE_KEY_PASSWORD }}}}", "${{ secrets.RELEASE_KEY_PASSWORD }}")
corrected_content = corrected_content.replace("${{{{ secrets.RELEASE_STORE_FILE_BASE64 }}}}", "${{ secrets.RELEASE_STORE_FILE_BASE64 }}")

with open(workflow_file_path, "w") as f:
    f.write(corrected_content)

print(f"Corrected secrets syntax in {workflow_file_path}")
