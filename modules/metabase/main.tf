locals {
  compute_roles = [
    "roles/secretmanager.secretAccessor",
  ]
}

terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.3"
    }
  }
}

resource "google_cloud_run_service" "metabase" {
  name     = "metabase"
  location = var.location

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = "1"
        "autoscaling.knative.dev/maxScale"      = "3"
        "run.googleapis.com/cloudsql-instances" = "${data.sops_file.metabase-creds.data["metabase_instance_connection_name"]},${data.sops_file.db-creds.data["instance_connection_name"]}"
        "run.googleapis.com/client-name"        = "terraform"
        "run.googleapis.com/cpu-throttling"     = "false" # Keep CPU always on, required for metabase to work
        "client.knative.dev/user-image"         = "eu.gcr.io/salamlab-development/metabase/metabase:v0.42.2"
      }
    }

    spec {
      containers {
        image   = "eu.gcr.io/${var.gcp_project}/metabase/metabase:v0.42.2"
        command = ["/bin/bash"]
        args = [
          "-c",
          # XXX(mlazowik): slightly cursed. Can be removed after the v0.43 mteabase release.
          #  See: https://github.com/metabase/metabase/issues/11414
          trimspace(
            <<-EOT
            ln -s /cloudsql/${data.sops_file.metabase-creds.data["metabase_instance_connection_name"]}/.s.PGSQL.5432 pg.sock &&
            wget -O socat https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/socat?raw=true &&
            chmod +x socat &&
            nohup ./socat -d -d TCP4-LISTEN:5432,fork UNIX-CONNECT:pg.sock &
            /app/run_metabase.sh
            EOT
          )
        ]

        ports {
          name           = "http1"
          container_port = 3000
        }

        env {
          name  = "MB_DB_TYPE"
          value = "postgres"
        }

        env {
          name  = "MB_DB_PORT"
          value = "5432"
        }

        env {
          name  = "MB_DB_HOST"
          value = "127.0.0.1"
        }

        env {
          name = "MB_DB_DBNAME"
          value_from {
            secret_key_ref {
              name = "metabase_db_name"
              key  = "latest"
            }
          }
        }

        env {
          name = "MB_DB_USER"
          value_from {
            secret_key_ref {
              name = "metabase_db_user"
              key  = "latest"
            }
          }
        }

        env {
          name = "MB_DB_PASS"
          value_from {
            secret_key_ref {
              name = "metabase_db_pass"
              key  = "latest"
            }
          }
        }

        # TODO(mlazowik): Separate for dev/prod
        env {
          name  = "MB_APPLICATION_DB_MAX_CONNECTION_POOL_SIZE"
          value = 2
        }

        # TODO(mlazowik): Separate for dev/prod, consider read replicas.
        env {
          name  = "MB_JDBC_DATA_WAREHOUSE_MAX_CONNECTION_POOL_SIZE"
          value = 5
        }

        resources {
          limits = {
            "cpu"    = "1"
            "memory" = "2Gi"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.roles,
  ]
}

data "google_compute_default_service_account" "default" {
}

resource "google_project_iam_member" "roles" {
  for_each = toset(local.compute_roles)
  project  = var.gcp_project
  role     = each.value
  member   = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

data "sops_file" "db-creds" {
  source_file = var.db_creds_path
}

data "sops_file" "metabase-creds" {
  source_file = var.metabase_db_creds_path
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Auth is handled by metabase itself
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.metabase.location
  project  = google_cloud_run_service.metabase.project
  service  = google_cloud_run_service.metabase.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
