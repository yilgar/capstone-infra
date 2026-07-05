# Only create an execution role when an external one is not provided.
resource "aws_iam_role" "ecs_task_execution_role" {
  count              = var.execution_role_arn == "" ? 1 : 0
  name               = var.iam_execution_role_name
  assume_role_policy = file("files/ecs_task_execution_role.json")
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {
  count      = var.execution_role_arn == "" ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "secrets_manager_policy" {
  count       = var.execution_role_arn == "" && length(var.secret_arns) > 0 ? 1 : 0
  name        = var.iam_execution_role_name
  path        = "/"
  description = "ECS task execution role policy to access secrets manager"
  policy      = data.aws_iam_policy_document.secrets_manager_policy_document.json
}

data "aws_iam_policy_document" "secrets_manager_policy_document" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = length(var.secret_arns) > 0 ? var.secret_arns : ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  count      = var.execution_role_arn == "" && length(var.secret_arns) > 0 ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = aws_iam_policy.secrets_manager_policy[0].arn
}
