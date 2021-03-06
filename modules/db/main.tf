terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.3"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.15.0"
    }
  }
}

resource "google_sql_database_instance" "main-v2" {
  name = "main-v2"

  lifecycle {
    prevent_destroy = true
  }

  # https://cloud.google.com/sql/docs/postgres/db-versions
  database_version = "POSTGRES_13"

  settings {
    tier = var.tier

    availability_type = var.availability_type

    # Do NOT set `disk_size` when `disk_autoresize` is on, otherwise terraform  calls will attempt to resize the disk to
    # the value specified in `disk_size`.
    #
    # TODO(https://github.com/KoalicjaOtwartyKrakow/iac/issues/15): add alerting in case things go haywire.
    disk_autoresize = true

    backup_configuration {
      enabled    = true
      start_time = "02:00"

      backup_retention_settings {
        retained_backups = var.retained_backups_count
        retention_unit   = "COUNT"
      }

      point_in_time_recovery_enabled = true
    }

    ip_configuration {
      # Access to the public IP is limited to cloud sql proxy, which does IAM based authorization. See the
      # organization-policies module.
      #
      # Why not private IP only? See:
      # https://medium.com/google-cloud/cloud-sql-with-private-ip-only-the-good-the-bad-and-the-ugly-de4ac23ce98a
      ipv4_enabled = true
      require_ssl  = true

      # Do NOT set any `authorized_networks`! The plan is to always access via the cloud sql proxy, as it checks
      # IAM perms. This will be enforced via `constraints/sql.restrictAuthorizedNetworks` after gcp projects are brought
      # under the g workspace org.
    }

    # Note that cloudsql can have downtime during updates, even when using a HA regional instance. So we really do want
    # this to be at night.
    #
    # > During a maintenance event, a Cloud SQL for PostgreSQL instance loses connectivity for less than 30 seconds on
    # > average.Downtime might be higher for instances that have high activity at the beginning of maintenance or have
    # > very large datasets. Cloud SQL typically schedules maintenance once every few months.
    # https://cloud.google.com/sql/docs/postgres/maintenance
    maintenance_window {
      day          = 1
      hour         = 1
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled = true
    }
  }
}

data "sops_file" "apartments-creds" {
  source_file = var.db_creds_path
}

resource "google_sql_database" "apartments" {
  name     = data.sops_file.apartments-creds.data["db_name"]
  instance = google_sql_database_instance.main-v2.name
}

resource "google_sql_user" "apartments" {
  name     = data.sops_file.apartments-creds.data["db_user"]
  instance = google_sql_database_instance.main-v2.name
  password = data.sops_file.apartments-creds.data["db_pass"]
}

provider "postgresql" {
  scheme    = "gcppostgres"
  host      = google_sql_database_instance.main-v2.connection_name
  username  = google_sql_user.apartments.name
  password  = google_sql_user.apartments.password
  superuser = false
}

resource "postgresql_role" "apartments_ro" {
  name     = data.sops_file.apartments-creds.data["db_readonly_user"]
  login    = true
  password = data.sops_file.apartments-creds.data["db_readonly_pass"]
}

resource "postgresql_grant" "apartments_ro" {
  database    = google_sql_database.apartments.name
  role        = postgresql_role.apartments_ro.name
  schema      = "public"
  object_type = "table"
  objects     = [] # An empty list (the default) means to grant permissions on all objects of the specified type
  privileges  = ["SELECT"]
}

module "db-creds" {
  source = "../secrets-from-file"

  creds_path = var.db_creds_path
}

data "sops_file" "metabase-creds" {
  source_file = var.metabase_db_creds_path
}

resource "google_sql_database" "metabase" {
  name     = data.sops_file.metabase-creds.data["metabase_db_name"]
  instance = google_sql_database_instance.main-v2.name
}

resource "google_sql_user" "metabase" {
  name     = data.sops_file.metabase-creds.data["metabase_db_user"]
  instance = google_sql_database_instance.main-v2.name
  password = data.sops_file.metabase-creds.data["metabase_db_pass"]
}

module "metabase-db-creds" {
  source = "../secrets-from-file"

  creds_path = var.metabase_db_creds_path
}
