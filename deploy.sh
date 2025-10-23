#!/bin/bash

# DEFINE LOG FILE
logFile="deploy.log"
: > $logFile

# DEFINE A CUSTOM LOG AND PRINT FUNCTION
log() {
    printf "%s\n\n" "$1" | tee -a $logFile
}

# GET USER INPUT 
while true; do
    read -p "What's your Git repo? => " gitRepo
    [[ $gitRepo =~ ^https://github.com/[a-zA-Z0-9./_-]+$ ]] && break
    log "invalid gitRepo, try again"
done
log "gitRepo: $gitRepo"

read -p "Enter your PAT => " pat
log "PAT: $pat"

read -p "Enter the branch name (optional, default is main) => " branchName
branchName=${branchName:-main}
log "branchName: $branchName"

read -p "Enter your remote server SSH username => " username
log "username: $username"

read -p "Enter your remote server SSH IP address => " ipAddress
log "ipAddress: $ipAddress"

read -p "Enter your remote server SSH key path => " keyPath
log "keyPath: $keyPath"

while true; do
    read -p "Enter the application port => " port
    [[ $port =~ ^[0-9]+$ ]] && break
    log "Invalid port, try again"
done
log "port: $port"

# CLONE REPO, PULL REPO, SWITCH TO BRANCH
$repoName = $(basename -s .git "$gitRepo")
log "repoFolder: $repoName"

if [ -d $repoName ]; then
    log "repo folder exists... pulling latest changes..."
    cd $repoName || { log "failed to cd into repo folder"; exit 1; }
    git pull || { log "git pull failed"; exit 1; }
else
    log "cloning repo..."
    git clone "https://$pat@${gitRepo#https://}" || { log "git clone failed"; exit 1; }
    cd $repoName || { log "failed to cd into repo folder"; exit 1; }
fi

git checkout $branchName || { log "failed to checkout into specified branch name"; exit 1; }

# CHECK FOR DOCKER FILE
if [[ -f "dockerfile" || -f "docker-compose.yml" ]]; then
    log "Docker configuration file present"
else
    log "No docker configuration file was found. Add one and try again"
    exit
fi

read -p "press enter to exit... \n\n"
