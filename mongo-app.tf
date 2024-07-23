resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Security group for MongoDB"
  vpc_id      = var.vpc_id

   ingress {
    from_port   = 57018  // Updated from 27017 to match the new MongoDB port
    to_port     = 57018
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Consider narrowing this down to specific IPs for better security
  }
   ingress {
    from_port   = 27017  // Updated from 27017 to match the new MongoDB port
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Consider narrowing this down to specific IPs for better security
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Consider restricting this to a more specific IP range for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb-sg"
  }
}

resource "aws_instance" "mongodb" {
  ami           = var.ami  // Ensure this AMI has MongoDB installed or use user_data to install it
  instance_type = "t2.micro"  // Choose appropriate instance type
  subnet_id     = var.subnet_id
  security_groups = [aws_security_group.mongodb_sg.id]

                user_data = <<-EOF
                          #!/bin/bash
                          sudo apt-get update
                          sudo apt-get install gnupg curl
                          curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
                          echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list              sudo apt-get update
                          sudo apt-get update
                          sudo apt-get install -y mongodb-org
                          
                          # Configure MongoDB to listen on all IP addresses and use a custom port
                          sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
                          sudo sed -i 's/port: 27017/port: 57018/' /etc/mongod.conf
                          
                          sudo systemctl restart mongod
                          systemctl enable mongod
                          sleep 30
                                    counter=0
                                    max_attempts=500
                                    until mongosh --port 57018 --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
                                      echo "Waiting for MongoDB to start... attempt $(( ++counter ))"  # Log the attempt count
                                      if [ $counter -ge $max_attempts ]; then
                                        echo "MongoDB failed to start after $max_attempts attempts."  # Failure message after max attempts
                                        break
                                      fi
                                      sleep 1  # Pause for 1 second between attempts to prevent flooding
                                    done

                                    if [ $counter -lt $max_attempts ]; then
                                      echo "MongoDB has started successfully."  # Success message if MongoDB starts within the max attempts
                                    else
                                      echo "Script is terminating due to failure in starting MongoDB."  # Additional log for script termination
                                    fi

                          mongosh --port 57018

                                use admin
                                db.createUser(
                                  {
                                    user: "admin",
                                    pwd: "admin", 
                                    roles: [
                                      { role: "userAdminAnyDatabase", db: "admin" },
                                      { role: "readWriteAnyDatabase", db: "admin" }
                                    ]
                                  }
                                )
                                exit
                          sudo sed -i '$ a security:\n  authorization: enabled' /etc/mongod.conf
                          sudo systemctl restart mongod

                          EOF

  tags = {
    Name = "MongoDBInstance"
  }
}
