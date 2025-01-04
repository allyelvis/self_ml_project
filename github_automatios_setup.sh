#!/bin/bash

# Exit on error
set -e

echo "============================="
echo "GitHub Automation Setup Script"
echo "============================="

# Variables
PROJECT_DIR=~/github-automation
SCRIPT_NAME="manage_github.py"
ENV_FILE=".env"
DOCKERFILE="Dockerfile"
GITHUB_ACTIONS_DIR=".github/workflows"
WORKFLOW_FILE="$GITHUB_ACTIONS_DIR/github_automation.yml"
REQUIREMENTS_FILE="requirements.txt"
TOKEN=""

# Step 1: Collect GitHub Token
echo "Enter your GitHub Personal Access Token (PAT):"
read -s TOKEN

if [ -z "$TOKEN" ]; then
    echo "Error: GitHub Token is required!"
    exit 1
fi

# Step 2: Create Project Directory
echo "Creating project directory at $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Step 3: Create Python Script
echo "Creating Python script..."
cat > "$SCRIPT_NAME" <<EOF
import requests
import os

# Load token from environment
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_API_URL = "https://api.github.com"
HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
}

def list_repositories(username):
    """List all repositories of the authenticated user."""
    url = f"{GITHUB_API_URL}/users/{username}/repos"
    response = requests.get(url, headers=HEADERS)
    if response.status_code == 200:
        repos = response.json()
        for repo in repos:
            print(f"Repository: {repo['name']} - {repo['html_url']}")
    else:
        print(f"Error: {response.status_code} - {response.json()}")

if __name__ == "__main__":
    # Replace with your GitHub username
    github_username = "AllyElvis"
    list_repositories(github_username)
EOF

# Step 4: Create .env File
echo "Creating .env file..."
cat > "$ENV_FILE" <<EOF
GITHUB_TOKEN=$TOKEN
EOF

# Step 5: Create requirements.txt
echo "Creating requirements.txt..."
cat > "$REQUIREMENTS_FILE" <<EOF
requests
EOF

# Step 6: Create Dockerfile
echo "Creating Dockerfile..."
cat > "$DOCKERFILE" <<EOF
FROM python:3.9
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "$SCRIPT_NAME"]
EOF

# Step 7: Create GitHub Actions Workflow
echo "Setting up GitHub Actions workflow..."
mkdir -p "$GITHUB_ACTIONS_DIR"
cat > "$WORKFLOW_FILE" <<EOF
name: GitHub Automation Script
on:
  schedule:
    - cron: '0 0 * * *' # Runs daily
jobs:
  run-script:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.x
      - name: Install Dependencies
        run: pip install requests
      - name: Run Script
        run: python $SCRIPT_NAME
EOF

# Step 8: Set Up Local Execution
echo "Setting up local execution..."
cat > run_local.sh <<EOF
#!/bin/bash
export \$(cat $ENV_FILE | xargs)
pip install -r $REQUIREMENTS_FILE
python $SCRIPT_NAME
EOF
chmod +x run_local.sh

# Step 9: Docker Build Instructions
echo "Creating Docker run instructions..."
cat > run_docker.sh <<EOF
#!/bin/bash
docker build -t github-automation .
docker run --env-file $ENV_FILE github-automation
EOF
chmod +x run_docker.sh

# Summary
echo "=========================================="
echo "Setup Complete!"
echo "Project Directory: $PROJECT_DIR"
echo "Python Script: $SCRIPT_NAME"
echo "Run locally: ./run_local.sh"
echo "Run with Docker: ./run_docker.sh"
echo "GitHub Actions workflow saved to: $WORKFLOW_FILE"
echo "=========================================="
