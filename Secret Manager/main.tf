resource "aws_secretsmanager_secret" "ssh-key" {
  name = "ssh-key"
}