#!/bin/bash

# Update the package list
sudo apt-get update

# Install software-properties-common to manage repositories
sudo apt-get install -y software-properties-common

# Depending on the availability, you might add a repository here that includes OpenJDK 21
# As of now, no standard PPA would include OpenJDK 21, this step is speculative:
# sudo add-apt-repository ppa:some/ppa-that-includes-openjdk-21 -y

# Update package list after adding repository
sudo apt-get update

# Install OpenJDK 21
sudo apt-get install openjdk-21-jdk -y

# Verify the installation
java -version
