variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name (optional for SSM)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for the EC2 instance"
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    # Install SSM Agent
    cd /tmp
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install Docker
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install N8N
    docker run -d \
      --name n8n \
      -p 5678:5678 \
      -v n8n_data:/home/node/.n8n \
      -e N8N_HOST=0.0.0.0 \
      -e N8N_PORT=5678 \
      -e N8N_PROTOCOL=http \
      n8nio/n8n:latest
  EOF
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 8
}

variable "volume_type" {
  description = "Type of the root EBS volume"
  type        = string
  default     = "gp2"
}

variable "alb_subnets" {
  description = "List of subnet IDs for the Application Load Balancer"
  type        = list(string)
}

variable "domain" {
  description = "Domain name for the ACM certificate"
  type        = string
}