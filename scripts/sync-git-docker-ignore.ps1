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
$WORKSPACE_ROOT = "C:\Users\User\work_space\digital-book"

# Function to copy the content of .gitignore file to .dockerignore file
function CopyGitDockerIgnore {
    param (
        [string]$projectRoot
    )

    $gitIgnore = Join-Path $projectRoot ".gitignore"
    $dockerIgnore = Join-Path $projectRoot ".dockerignore"

    if (Test-Path $dockerIgnore) {
        $diff = Compare-Object (Get-Content $gitIgnore) (Get-Content $dockerIgnore)
        if ($diff) {
            Write-Output "Updating $dockerIgnore with the content of $gitIgnore"
            Copy-Item $gitIgnore $dockerIgnore -Force
        } else {
            Write-Output "The content of $gitIgnore is the same as the content of $dockerIgnore. Skipping the project."
        }
    } else {
        Write-Output "Creating $dockerIgnore and copying the content of $gitIgnore"
        Copy-Item $gitIgnore $dockerIgnore -Force
    }
}

# Function to check if the project is using Angular, React or Django
function CheckProjectType {
    param (
        [string]$projectRoot
    )

    if (Test-Path (Join-Path $projectRoot "package.json")) {
        if ((Test-Path (Join-Path $projectRoot "angular.json")) -or (Test-Path (Join-Path $projectRoot "next-env.d.ts"))) {
            return $true
        }
    } elseif (Test-Path (Join-Path $projectRoot "manage.py")) {
        return $true
    }

    return $false
}

# Function to check if the project is using Git
function CheckGitUsage {
    param (
        [string]$projectRoot
    )

    $gitUsed = Test-Path (Join-Path $projectRoot ".git")
    $dockerUsed = Test-Path (Join-Path $projectRoot "Dockerfile")

    if ($gitUsed -and $dockerUsed) {
        return $true
    }

    return $false
}

# Main logic to iterate over projects
Get-ChildItem -Path $WORKSPACE_ROOT -Directory | ForEach-Object {
    $project = $_.FullName
    if (CheckProjectType -projectRoot $project) {
        if (CheckGitUsage -projectRoot $project) {
            CopyGitDockerIgnore -projectRoot $project
        } else {
            Write-Output "Skipping ${project}: Git not used."
        }
    } else {
        Write-Output "Skipping ${project}: Not an Angular, React, or Django project."
    }
}