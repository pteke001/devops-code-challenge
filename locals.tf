locals {
  bucket_name = "cc-tf-code"
  table_name  = "ccTfcode"

  ecr_repo_name = "code-app-ecr-repo"

  code_app_cluster_name        = "code-app-cluster"
  availability_zones           = ["us-east-1a", "us-east-1b", "us-east-1c"]
  code_app_task_famliy         = "code-app-task"
  container_port               = 3000
  code_app_task_name           = "code-app-task"
  ecs_task_execution_role_name = "code-app-task-execution-role"

  application_load_balancer_name = "cc-code-app-alb"
  target_group_name              = "cc-code-alb-tg"

  code_app_service_name = "cc-code-app-service"
}