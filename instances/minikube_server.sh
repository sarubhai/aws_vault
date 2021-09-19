#!/bin/bash
# Name: minikube_server.sh
# Owner: Saurav Mitra
# Description: Install Minikube v1.23.1

sudo apt-get --assume-yes --quiet update                                        >> /dev/null
sudo apt-get --assume-yes --quiet install apt-transport-https curl conntrack    >> /dev/null

# Install Docker
sudo apt-get --assume-yes --quiet install software-properties-common ca-certificates gnupg lsb-release  >> /dev/null

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get --assume-yes --quiet update                                >> /dev/null
sudo apt-get --assume-yes --quiet install docker-ce=5:20.10.8~3-0~ubuntu-focal docker-ce-cli=5:20.10.8~3-0~ubuntu-focal containerd.io   >> /dev/null

# Install Minikube
cd /root
export MINIKUBE_HOME="/root/.minikube"
export CHANGE_MINIKUBE_NONE_USER=true

sudo curl -s -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod 755 /usr/local/bin/minikube
sudo sysctl fs.protected_regular=0

minikube start --driver=none        >> /dev/null
minikube config set driver none     >> /dev/null

sudo chown -R root /root/.minikube
sudo chmod -R u+wrx /root/.minikube

minikube addons enable dashboard
minikube addons enable metrics-server

# Install Kubectl
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo chown -R root /root/.kube/config
