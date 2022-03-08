module "codebuild" {
  source   = "../modules/codebuild"
  project  = var.project
  location = var.location
}