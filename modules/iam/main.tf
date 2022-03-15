locals {
  devs_roles = [
    "roles/cloudfunctions.viewer",
  ]
}

data "google_project" "project" {}

resource "google_project_iam_member" "roles" {
  for_each = toset(local.devs_roles)
  project  = data.google_project.project.project_id
  role     = each.value
  member   = "group:${var.devs_group_email}"
}
