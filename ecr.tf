# create ecr repository

resource "aws_ecr_repository" "ecr" {
  name = "${local.name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}

# create lifecycle policy ecr repository
# manter somente as imagens dos últimos 14 dias mantendo sempre 6 imagnes

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 6 images",
        selection    = {
          tagStatus    = "any",
          countType    = "imageCountMoreThan",
          countNumber  = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}