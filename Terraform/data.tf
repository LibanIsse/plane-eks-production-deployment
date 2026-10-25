data "aws_secretsmanager_secret" "plane_signing_keys" {
  name = "plane/app/signing-keys"
}