provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "example" {
    ami = "ami-0a664360bb4a53714"
    instance_type = terraform.workspace == "default" ? "t3.micro" : "t3.small"
}

terraform {
    backend "s3" {
        bucket = "hubert-wojcik-terraform-state"
        key = "workspaces-example/terraform.tfstate"
        region = "eu-north-1"

        dynamodb_table = "hubert-terraform-state"
        encrypt = true
    }
}