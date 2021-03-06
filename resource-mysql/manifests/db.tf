resource "aws_db_instance" "default" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "application_db"
  username             = ${env.DB_USERNAME}
  password             = ${env.DB_PASSWORD}
  parameter_group_name = "default.mysql5.7"
}

