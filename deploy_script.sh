#!/bin/bash

# Configuration
REPO_URL="https://github.com/Deus8ez/JackBot.git"
LOCAL_DIR="/root/JackBot"
SERVICE_NAME="jackboxer.service"
OUTPUT_DIR="/root/jokbok"

# Function to build the .NET project
build_and_start_service() {
  # Navigate to the local directory
  cd $LOCAL_DIR || { echo "Failed to change directory to $LOCAL_DIR"; exit 1; }

  # Restore dependencies
  dotnet restore || { echo "Failed to restore dependencies."; exit 1; }

  # Build the project
  dotnet build --configuration Release || { echo "Failed to build the project."; exit 1; }

  # Publish the project
  dotnet publish --configuration Release --output $OUTPUT_DIR || { echo "Failed to publish the project."; exit 1; }

  # Restart the service
  systemctl restart $SERVICE_NAME || { echo "Failed to restart the service."; exit 1; }
}

# Check if the local directory exists
if [ -d "$LOCAL_DIR" ]; then
  cd $LOCAL_DIR || { echo "Failed to change directory to $LOCAL_DIR"; exit 1; }
  # Fetch the latest changes from the repository
  git fetch || { echo "Failed to fetch updates."; exit 1; }

  # Check for changes
  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u})
  BASE=$(git merge-base @ @{u})

  if [ $LOCAL = $REMOTE ]; then
    echo "No changes detected in the repository."
  elif [ $LOCAL = $BASE ]; then
    echo "Changes detected. Pulling the latest changes..."
    systemctl stop $SERVICE_NAME || { echo "Failed to stop the service."; exit 1; }
    git pull origin master || { echo "Failed to pull changes."; exit 1; }

    # Build and restart the service
    build_and_start_service
  else
    echo "Local repository has diverged from the remote. Manual intervention required."
    exit 1
  fi
else
  echo "Local directory does not exist. Cloning the repository..."
  git clone $REPO_URL $LOCAL_DIR || { echo "Failed to clone repository."; exit 1; }

  # Build and start the service for the first time
  build_and_start_service
fi
