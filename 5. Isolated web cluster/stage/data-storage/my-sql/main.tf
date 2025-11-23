provider "aws" {
    region = "eu-north-1"
}

resource "aws_db_instance" "mysql" {
    identifier_prefix = "stage-mysql"
    engine = "my_sql"
    allocated_storage = 10
    instance_class = "db.t2.micro"
    skip_final_snapshot = true
    db_name = "example_database"

    username = var.db_username
    password = var.db_password
}

terraform {
    backend "s3" {
        bucket = "hubert-wojcik-terraform-state"
        key = "stage/data-storage/my-sql/terraform.tfstate"
        region = "eu-north-1"
        dynamodb_table = "hubert-terraform-state"
        encrypt = true
    }
}