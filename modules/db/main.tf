data "google_compute_network" "default" {
  name = "default"
}

resource "google_sql_database_instance" "main" {
  name = "main"

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
      ipv4_enabled    = false # No _public_ IP.
      private_network = data.google_compute_network.default.self_link
      require_ssl     = true
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
  }
}
