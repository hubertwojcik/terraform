provider "aws" {
  region = "eu-north-1"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
}

resource "aws_instance" "example" {
    ami = "ami-0a664360bb4a53714"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.terraform_server_aws_security_group.id]

    user_data = <<-EOF
                #!/bin/bash
                command -v python3 >/dev/null 2>&1 || (yum install -y python3 || dnf install -y python3 || apt-get update ** apt-get install -y python3)
                echo "Hello worlds" >> index.html
                nphup python3 -m http.server ${var.server_port} &
                EOF   

    user_data_replace_on_change = true

    tags = {
        Name = "Terraform configurable server"
    }
}


resource "aws_security_group" "terraform_server_aws_security_group" {
    name = "terraform-example-sg"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "public_ip" {
    value = aws_instance.example.public_ip
    description = "Public http server ip"
}