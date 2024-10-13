#!/bin/bash
# This script will copy the .gitignore file to the dockerignore file.
# This useful to have one source of truth for the files that should be ignored by git and docker.
# I have chosen to use the .gitignore file as the source of truth. But reversal is also possible.

# My idea is to one static path. This path will be point to workspace root.
# It will search for every project using Angular, React and Django.
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
WORKSPACE_ROOT=~C:/Users/User/work_space/digital-book

# Function to copy the content of .gitignore file to .dockerignore file
function copy_git_docker_ignore() {
    local project_root=$1
    local git_ignore=$project_root/.gitignore
    local docker_ignore=$project_root/.dockerignore

    if [ -f "$docker_ignore" ]; then
        # Check if the content of the .gitignore file is different from the content of the .dockerignore file
        diff=$(diff -q "$git_ignore" "$docker_ignore")
        if [ "$diff" != "" ]; then
            echo "Updating $docker_ignore with the content of $git_ignore"
            cp "$git_ignore" "$docker_ignore"
        else
            echo "The content of $git_ignore is the same as the content of $docker_ignore. Skipping the project."
        fi
    else
        echo "Creating $docker_ignore and copying the content of $git_ignore"
        cp "$git_ignore" "$docker_ignore"
    fi
}

# Function to check if the project is using Angular, React or Django
function check_project_type() {
    local project_root=$1

    if [ -f "$project_root/package.json" ]; then
        # Check if the project is using Angular or React
        if [ -f "$project_root/angular.json" ] || [ -f "$project_root/next-env.d.ts" ]; then
            return 0
        fi
    elif [ -f "$project_root/manage.py" ]; then
        # Check if the project is using Django
        return 0
    fi

    return 1
}

# Function to check if the project is using Git
function check_git_usage() {
    local project_root=$1

    if [ -d "$project_root/.git" ]; then
        return 0
    fi

    return 1
}

# Main logic to iterate over projects
for project in "$WORKSPACE_ROOT"/*; do
    if [ -d "$project" ]; then
        check_project_type "$project"
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            check_git_usage "$project"
            if [ $? -eq 0 ]; then
                copy_git_docker_ignore "$project"
            else
                echo "Skipping $project: Git not used."
            fi
        else
            echo "Skipping $project: Not an Angular, React, or Django project."
        fi
    fi
done
