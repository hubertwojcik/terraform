output "address" {
    value = aws_db_instance.mysql.address
    description = "The address of the database"
}

output "port" {
    value = aws_db_instance.mysql.port
    description = "The port of the database"
}

