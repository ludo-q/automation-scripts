#!/bin/bash
# This script will copy the .gitignore file to the dockerignore file.
# This useful to have one source of truth for the files that should be ignored by git and docker.
# I have chosen to use the .gitignore file as the source of truth. But reversal is also possible.

# My idea is to one static path. This path will be point to workspace root.
# It will search for every project using Angular, Next and Django.
# For now, we will only focus on these three. For simplicity.

# 1. Verify the project type and the root folder of the project. If not found, skip the project.
# 2. Ensure that Git and Docker are used. If not, it will skip the project.
# Assumption:
# The .gitignore is present in the root folder of the project and has the necessary
# content for the project.
# 3. Check if the .dockerignore file is present in the root folder.
#    If not, it will create the .dockerignore file and copy the content
#    of the .gitignore file to the .dockerignore file.
# 4. If the .dockerignore file is present, it will copy the content of the .gitignore file
#    to the .dockerignore file.
# 5. If the content of the .gitignore file is different from the content of the .dockerignore file,
#    it will update the .dockerignore file with the content of the .gitignore file.
# 6. If the content of the .gitignore file is the same as the content of the .dockerignore file,
#    it will skip the project.

# The script will be run using the following command:
# ./sync-git-docker-ignore.sh

# Static path
WORKSPACE_ROOT=../../digital-book

# Function to copy the content of .gitignore file to .dockerignore file
function copy_git_docker_ignore() {
  local project_root=$1
  local git_ignore=$project_root/.gitignore
  local docker_ignore=$project_root/.dockerignore

  # Check if the .dockerignore file is present in the root folder
  if [ ! -f "$docker_ignore" ]; then
    echo "Creating and updating .dockerignore with the content of .gitignore"
    cp "$git_ignore" "$docker_ignore"
    return 0
  fi

  # Check if the content of the .gitignore file is different from the content of the .dockerignore file
  diff=$(diff -q "$git_ignore" "$docker_ignore")
  if [ "$diff" != "" ]; then
    echo "Updating .dockerignore with the content of .gitignore"
    cp "$git_ignore" "$docker_ignore"
    return 0
  else
    echo "Skipping, .dockerignore is up to date."
    return 1
  fi
}

# Function to check if the project is using Angular, Next or Django
function check_project_type() {
  local project_root=$1

  if [ -f "$project_root/angular.json" ] || [ -f "$project_root/next.config.mjs" ] || [ -f "$project_root/digital_book_backend_django/settings.py" ]; then
    return 0
  fi
  return 1
}

# Function to check if the project is using Git and Docker
function check_git_docker_usage() {
  local project_root=$1

  if [ -f "$project_root/.gitignore" ] && [ -f "$project_root/Dockerfile" ] ; then
    return 0
  fi

  return 1
}

echo "****************************************************************"
# Main logic to iterate over projects
for project in "$WORKSPACE_ROOT"/*; do
  if [ -d "$project" ]; then
    echo "================="
    echo "Checking project: $project"
    check_project_type "$project"
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
      check_git_docker_usage "$project"
      if [ $? -eq 0 ]; then
        copy_git_docker_ignore "$project"
      else
        echo "Skipping, Git or Docker not used."
      fi
    else
      echo "Skipping, Not an Angular, Next, or Django!!!"
    fi
else
  echo "Skipping, Not a directory."

  echo "================="
  fi
done

echo "****************************************************************"