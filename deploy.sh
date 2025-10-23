#!/bin/bash

# CREATE TIMESTAMP AND DEFINE LOG FILE
TIMESTAMP=$(date + "%Y%m%d_%H%M%S")
logFile="deploy.log"
: > $logFile

# DEFINE A CUSTOM LOG AND PRINT FUNCTION WITH TIMESTAMP
log() {
    printf "%s %s\n\n" "$(date + %Y%m%d %H:%M:%S) => " "$1" | tee -a $logFile
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

# SSH connect
ssh -i "$keyPath" -o BatchMode=yes -o ConnectTimeout=5 "$username@$ipAddress" "echo 'SSH OK'" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    log "✅ SSH connection successful."
else
    log "SSH connection failed. Check credentials or key path."
    exit 1
fi

# SETTING UP REMOTE HOST
log "Updating system..."
sudo apt update -y && sudo apt upgrade -y

log "Installing Docker, Compose, and Nginx..."
sudo apt install -y docker.io docker-compose nginx

log "Adding user to docker group..."
sudo usermod -aG docker \$USER

log "Enabling and starting services..."
sudo systemctl enable docker nginx
sudo systemctl start docker nginx

elog "Confirming versions..."
docker --version
docker-compose --version
nginx -v
EOF
log "Remote environment is ready."

# DEPLOY DOCKERIZED APPLICATION
log "Deploying Docker app..."

scp -i "$keyPath" -r "./$repoName" "$username@$ipAddress:~/"

ssh -i "$keyPath" "$username@$ipAddress" bash <<EOF
set -e
cd ~/$repoName
docker compose down || true
docker compose up -d --build
sleep 5
docker ps
EOF
log "Containers built and running."

# CONFIGURE NGINX REVERSE PROXY
log "Configuring Nginx reverse proxy..."

ssh -i "$keyPath" "$username@$ipAddress" bash <<EOF
sudo bash -c 'cat > /etc/nginx/sites-available/app.conf <<CONF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
CONF'
sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
sudo nginx -t && sudo systemctl reload nginx
EOF
log "Nginx reverse proxy configured."


# VALIDATE DEPLOYMENT
log "Validating deployment..."

ssh -i "$keyPath" "$username@$ipAddress" bash <<EOF
docker info >/dev/null && echo "Docker is running."
docker ps | grep "$repoName" && echo "Container active."
sudo systemctl status nginx --no-pager | grep active
curl -I http://localhost:$port || echo "App not responding locally."
EOF

log "Deployment validation complete."

read -p "press enter to exit... \n\n"
