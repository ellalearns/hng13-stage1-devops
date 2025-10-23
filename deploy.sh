#!/bin/bash

# DEFINE LOG FILE
logFile="deploy.log"
: > $logFile

# GET USER INPUT 
while true; do
    read -p "What's your Git repo? => " gitRepo
    [[ $gitRepo =~ ^https://github.com/[a-zA-Z0-9./_-]+$ ]] && break
    printf "invalid gitRepo, try again\n\n"
done
printf "gitRepo: $gitRepo \n\n" | tee -a $logFile

read -p "Enter your PAT => " pat
printf "PAT: $pat \n\n" | tee -a $logFile

read -p "Enter the branch name (optional, default is main) => " branchName
branchName=${branchName:-main}
printf "branchName: $branchName \n\n" | tee -a $logFile

read -p "Enter your remote server SSH username => " username
printf "username: $username \n\n" | tee -a $logFile

read -p "Enter your remote server SSH IP address => " ipAddress
printf "ipAddress: $ipAddress \n\n" | tee -a $logFile

read -p "Enter your remote server SSH key path => " keyPath
printf "keyPath: $keyPath \n\n" | tee -a $logFile

while true; do
    read -p "Enter the application port => " port
    [[ $port =~ ^[0-9]+$ ]] && break
    printf "Invalid port, try again \n\n"
done
printf "port: $port \n\n" | tee -a $logFile

# CLONE REPO, PULL REPO, SWITCH TO BRANCH
$repoName = ${basename -s .git "$gitRepo"}
printf "repoFolder: $repoName \n\n" | tee -a $logFile

if [ -d $repoName ]; then
    printf "repo folder exists... pulling latest changes... \n\n"
    cd $repoName || exit
    git pull
else
    printf "cloning repo... \n\n"
    git clone "https://$pat@${gitRepo#https://}"
    cd $repoName || exit
fi

git checkout $branchName

if [[ -f "dockerfile" || -f "docker-compose.yml" ]]; then
    printf "Docker configuration file present \n\n" | tee -a $logFile
else
    printf "No docker configuration file was found. Add one and try again. \n\n" | tee -a $logFile
    exit
fi

read -p "press enter to exit... \n\n"
