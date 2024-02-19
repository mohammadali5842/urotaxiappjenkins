output "databaseendpoint" {
  value = aws_db_instance.urotaxi_db.endpoint
}

output "ec2publicip" {
  value = aws_instance.urotaxiec2.public_ip
}