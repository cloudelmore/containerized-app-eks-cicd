resource "aws_ecr_repository" "app" {
  name = var.project_name

  # A tag, once pushed, can never point at a different image.
  # Every build gets a new tag (the git commit), so you always know exactly
  # what's running and can roll back to any earlier tag.
  image_tag_mutability = "IMMUTABLE"

  # Lets `terraform destroy` delete the repository even if it still holds images
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true # check every pushed image for known vulnerabilities (CVEs)
  }
}

# Keep the 20 newest images and expire older ones, so storage doesn't grow forever
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}
