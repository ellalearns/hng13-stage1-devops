#!/bin/bash

while true; do
    read -p "What's your Git repo? => " gitRepo
    [[ $gitRepo =~ ^https://github.com/[a-zA-Z0-9./_-]+$ ]] && break
    printf "invalid gitRepo, try again\n\n"
done
printf "gitRepo: $gitRepo \n\n"

read -p "Enter your PAT => " pat
printf "PAT: $pat \n\n"

read -p "Enter the branch name (optional, default is main) => " branchName
branchName=${branchName:-main}
printf "branchName: $branchName \n\n"

read -p "Enter your remote server SSH username => " username
printf "username: $username \n\n"

read -p "Enter your remote server SSH IP address => " ipAddress
printf "ipAddress: $ipAddress \n\n"

read -p "Enter your remote server SSH key path => " keyPath
printf "keyPath: $keyPath \n\n"

while true; do
    read -p "Enter the application port => " port
    [[ $port =~ ^[0-9]+$ ]] && break
    printf "Invalid port, try again \n\n"
done
printf "port: $port \n\n"

read -p "press enter to exit... \n\n"

