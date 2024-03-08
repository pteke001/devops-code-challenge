resource "aws_ecr_repository" "code_app_ecr_repo" {
  name = var.ecr_repo_name
}