provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "example" {
    ami = "ami-0a664360bb4a53714"
    instance_type = "t3.micro"

    tags = {
        Name = "terraform-example"
    }

}