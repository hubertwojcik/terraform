variable "bucket_name" {
    description = "The name of the S3 bucket"
    type = string
    default = "hubert-wojcik-terraform-state"
}

variable "table_name" {
    description = "The name of the DynamoDB table"
    type = string
    default = "hubert-terraform-state"
}