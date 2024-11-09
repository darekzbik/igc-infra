locals {
  igc_ecr_name = "igc-server"
  ecrs = toset([
    local.igc_ecr_name
  ])
}

resource "aws_ecr_repository" "ecr" {
  for_each = local.ecrs
  name = each.value
}

data "aws_iam_policy_document" "read_ecr" {
  count = length(var.external_ecr_readers) > 0 ? 1 : 0
  statement {
    sid    = "ReadingImages"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.external_ecr_readers
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
  }
}

resource "aws_ecr_repository_policy" "policy" {
  for_each = length(var.external_ecr_readers) > 0 ? aws_ecr_repository.ecr : {}
  repository = each.value.name
  policy = data.aws_iam_policy_document.read_ecr[0].json
}

variable "external_ecr_readers" {
  type        = set(number)
  default     = []
  description = "AWS account IDs of external accounts that can read from the ECR repository"
}