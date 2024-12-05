#!/bin/bash

# Define Constants
HACKATHON_API_URL="https://api.devopshackathon.com/v1/upcoming"  # Replace with the hackathon platform API
GITHUB_REPO="https://github.com/allyelvis/self-improving-ml-hackathon"
PROJECT_DIR="auto-hackathon-project"
GCP_PROJECT_ID="auto-devops-project"
GCP_BUCKET="auto-devops-bucket"
JIRA_URL="https://your-jira-instance.atlassian.net"
JIRA_USERNAME="your-jira-email@example.com"
JIRA_API_TOKEN="your-jira-api-token"
FORGE_CONFIG_PATH="$PROJECT_DIR/forge/forge-config.yml"
CI_CD_PIPELINE_URL="https://ci-cd-service.com"
CI_CD_PIPELINE_TRIGGER="trigger-pipeline-url"

# Function to check if necessary tools are installed
check_tools() {
    for tool in forge gcloud git curl jq; do
        if ! command -v $tool &> /dev/null; then
            echo "$tool is not installed, installing..."
            if [ "$tool" == "forge" ]; then
                npm install -g forge
            elif [ "$tool" == "gcloud" ]; then
                curl https://sdk.cloud.google.com | bash
            elif [ "$tool" == "git" ]; then
                sudo apt-get install git
            elif [ "$tool" == "curl" ]; then
                sudo apt-get install curl
            elif [ "$tool" == "jq" ]; then
                sudo apt-get install jq
            fi
        fi
    done
}

# Function to detect eligible hackathons
detect_hackathons() {
    echo "Detecting live and eligible hackathons..."
    hackathons=$(curl -s $HACKATHON_API_URL | jq '.hackathons | map(select(.status == "live" and .eligibility == "eligible"))')
    
    if [ -z "$hackathons" ]; then
        echo "No eligible hackathons found."
        exit 1
    fi

    echo "Found eligible hackathons:"
    echo "$hackathons" | jq -r '.[] | .name, .deadline'
    
    # Select the first eligible hackathon
    selected_hackathon=$(echo "$hackathons" | jq -r '.[0].id')
    echo "Selected hackathon: $selected_hackathon"
}

# Function to create cloud resources based on detected hackathon
create_cloud_resources() {
    echo "Creating cloud resources for the project..."

    # Google Cloud Setup
    gcloud auth activate-service-account --key-file=$GCP_SERVICE_ACCOUNT_KEY
    gcloud config set project $GCP_PROJECT_ID

    # Create Bucket for storage
    gcloud storage buckets create gs://$GCP_BUCKET

    # Generate other resources if necessary (VMs, DBs, etc.)
    echo "Cloud resources created."
}

# Function to configure project dynamically based on detected hackathon
configure_project() {
    echo "Configuring the project for the hackathon..."
    
    # Check if the project needs specific dependencies or tech stack
    tech_stack="python, node.js"
    if [[ $tech_stack == *"python"* ]]; then
        echo "Setting up Python environment..."
        pip install -r requirements.txt
    fi
    if [[ $tech_stack == *"node.js"* ]]; then
        echo "Setting up Node.js environment..."
        npm install
    fi
    
    # Set up Forge configuration
    cat <<EOL > $FORGE_CONFIG_PATH
project_name: auto-hackathon-project
version: 1.0.0
hosting:
  platform: google-cloud
  region: us-central1
  service: appengine
  runtime: python
env:
  GOOGLE_CLOUD_PROJECT: $GCP_PROJECT_ID
  GOOGLE_CLOUD_BUCKET: $GCP_BUCKET
deployment:
  method: ci/cd
  pipeline_url: $CI_CD_PIPELINE_URL
  trigger_url: $CI_CD_PIPELINE_TRIGGER
  rollback_enabled: true
auto_update:
  enabled: true
  frequency: daily
  trigger:
    source: trends
EOL
    echo "Project configured for the hackathon."
}

# Function to submit the project to the hackathon platform
submit_project() {
    echo "Submitting project to the hackathon..."

    # Submit via API
    response=$(curl -X POST -H "Content-Type: application/json" -d '{
        "repo_url": "'$GITHUB_REPO'",
        "project_name": "Auto Hackathon Project",
        "category": "DevOps",
        "description": "An autonomous DevOps project that configures itself."
    }' "https://api.devopshackathon.com/v1/submit")

    if [[ "$response" == *"success"* ]]; then
        echo "Project successfully submitted."
    else
        echo "Failed to submit the project."
        exit 1
    fi
}

# Function to create Jira issue
create_jira_issue() {
    echo "Creating Jira issue for the project..."

    response=$(curl -u "$JIRA_USERNAME:$JIRA_API_TOKEN" -X POST --data '{
        "fields": {
           "project": {
              "key": "DEVOPS"
           },
           "summary": "Auto Hackathon Project Submission",
           "description": "Automated submission of the hackathon project.",
           "issuetype": {
              "name": "Task"
           }
        }
    }' -H "Content-Type: application/json" $JIRA_URL/rest/api/2/issue/)

    if [[ "$response" == *"key"* ]]; then
        echo "Jira issue created successfully."
    else
        echo "Failed to create Jira issue."
        exit 1
    fi
}

# Main function
main() {
    check_tools
    detect_hackathons
    create_cloud_resources
    configure_project
    submit_project
    create_jira_issue
}

# Run the script
main
