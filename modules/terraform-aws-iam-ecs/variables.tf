variable "namespace" {
  type        = string
  description = "Project namespace"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "secret_arns" {
  type        = list(string)
  description = "List of Secrets Manager ARNs the execution role can read"
  default     = []
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket the task role can access"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
