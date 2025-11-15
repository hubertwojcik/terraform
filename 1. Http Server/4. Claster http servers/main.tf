provider "aws" {
    region = "eu-north-1"
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0a664360bb4a53714"
    instance_type = "t3.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                command -v python3 >/dev/null 2>&1 || (yum install -y python3 || dnf install -y python3 || apt-get update ** apt-get install -y python3)
                echo "Hello worlds" >> index.html
                nphup python3 -m http.server ${var.server_port} &
                EOF   
    
    lifecycle { 
        create_before_destroy = true
    }
}

resource "aws_autoscalling_group" "example" {
    launch_configuration = aws_launch_configuration.example
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}