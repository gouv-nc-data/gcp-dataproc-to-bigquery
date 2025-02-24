locals {
  parent_folder_id      = 658965356947 # production folder
  ojdbc_remote_url      = "https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc8/23.2.0.0/ojdbc8-23.2.0.0.jar"
  spark_avro_remote_url = "https://repo1.maven.org/maven2/org/apache/spark/spark-avro_2.13/3.4.1/spark-avro_2.13-3.4.1.jar"

  secret-managment-project = "prj-dinum-p-secret-mgnt-aaf4"
}

resource "google_service_account" "service_account" {
  account_id   = "sa-${var.dataset_name}"
  display_name = "Service Account created by terraform for ${var.project_id}"
  project      = var.project_id
}

resource "google_project_iam_member" "bigquery_editor_bindings" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "bigquery_user_bindings" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "dataflow_developer_bindings" {
  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "dataproc_admin_bindings" {
  project = var.project_id
  role    = "roles/dataproc.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "dataflow_worker_bindings" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_custom_role" "dataproc-custom-role" {
  project     = var.project_id
  role_id     = "dataproc_custom_role_${var.dataset_name}"
  title       = "Dataproc Custom Role"
  description = "Role custom pour pouvoir créer des job dataproc depuis scheduler"
  permissions = ["iam.serviceAccounts.actAs", "dataproc.workflowTemplates.instantiate"]
}


resource "google_project_iam_member" "dataflow_custom_worker_bindings" {
  project    = var.project_id
  role       = "projects/${var.project_id}/roles/${google_project_iam_custom_role.dataproc-custom-role.role_id}"
  member     = "serviceAccount:${google_service_account.service_account.email}"
  depends_on = [google_project_iam_custom_role.dataproc-custom-role]
}

resource "google_service_account_iam_member" "gce-default-account-iam" {
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
  service_account_id = google_service_account.service_account.name
}

resource "google_project_iam_member" "cloud_scheduler_runner_bindings" {
  project = var.project_id
  role    = "roles/cloudscheduler.jobRunner"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

####
# Bucket
####

resource "google_storage_bucket" "bucket" {
  project                     = var.project_id
  name                        = "bucket-${var.dataset_name}"
  location                    = var.region
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true
}

# # driver ojdb
# data "http" "ojdbc_driver" {
#   url = local.ojdbc_remote_url
# }

# resource "local_sensitive_file" "ojdbc_driver_local" {
#   content  = data.http.ojdbc_driver.response_body
#   filename = "${path.module}/ojdbc8.jar"
# }

# resource "google_storage_bucket_object" "ojdbc_driver" {
#   name       = "ojdbc.jar"
#   source     = "${path.module}/ojdbc8.jar"
#   bucket     = google_storage_bucket.bucket.name
#   depends_on = [local_sensitive_file.ojdbc_driver_local]
# }

# # driver spark avro
# data "http" "spark_avro_driver" {
#   url = local.spark_avro_remote_url
# }

# resource "local_sensitive_file" "spark_avro_driver_local" {
#   content  = data.http.spark_avro_driver.response_body
#   filename = "${path.module}/spark-avro_2.13-3.4.1.jar"
# }

# resource "google_storage_bucket_object" "spark_avro_driver" {
#   name       = "spark-avro_2.13-3.4.1.jar"
#   source     = "${path.module}/spark-avro_2.13-3.4.1.jar"
#   bucket     = google_storage_bucket.bucket.name
#   depends_on = [local_sensitive_file.spark_avro_driver_local]
# }

####
# Dataproc
####
resource "google_project_service" "secretmanagerapi" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "cloudschedulerapi" {
  project = var.project_id
  service = "cloudscheduler.googleapis.com"
}

resource "google_project_service" "dataprocrapi" {
  project = var.project_id
  service = "dataproc.googleapis.com"
}

data "google_secret_manager_secret_version" "jdbc-url-secret" {
  project = local.secret-managment-project
  secret  = var.jdbc-url-secret-name
}

resource "google_cloud_scheduler_job" "job" {
  for_each         = var.queries
  project          = var.project_id
  name             = "job-${var.dataset_name}-${each.key}"
  schedule         = "${index(keys(var.queries), each.key) % 60} ${var.schedule}"
  time_zone        = "Pacific/Noumea"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://dataproc.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/batches/"
    oauth_token {
      service_account_email = google_service_account.service_account.email
    }
    body = base64encode(<<EOT
{
    "sparkBatch": {
        "jarFileUris": [
        "gs://dataproc-templates-binaries/latest/java/dataproc-templates.jar",
        "gs://bucket-${var.dataset_name}/ojdbc8-21.7.0.0.jar",
        "gs://bucket-${var.dataset_name}/postgresql-42.2.6.jar",
        "gs://bucket-${var.dataset_name}/spark-avro_2.13-3.4.1.jar",
        "gs://bucket-${var.dataset_name}/spark-bigquery-with-dependencies_2.13-0.32.2.jar"
        ],
        "args": [
        "--template",
        "JDBCTOBIGQUERY",
        "--templateProperty",
        "project.id=${var.project_id}",
        "--templateProperty",
        "jdbctobq.bigquery.location=${var.dataset_name}.${each.value.bigquery_location}",
        "--templateProperty",
        "jdbctobq.sql=${each.value.query}",
        "--templateProperty",
        "jdbctobq.jdbc.url=${data.google_secret_manager_secret_version.jdbc-url-secret.secret_data}",
        "--templateProperty",
        "jdbctobq.jdbc.driver.class.name=${var.type_database == "oracle" ? "oracle.jdbc.driver.OracleDriver" : "org.postgresql.Driver"}",
        "--templateProperty",
        "jdbctobq.temp.gcs.bucket=${google_storage_bucket.bucket.name}",
        "--templateProperty",
        "jdbctobq.write.mode=Overwrite",
        "--templateProperty",
        "spark.sql.parquet.int96RebaseModeInWrite=CORRECTED"
        ],
        "mainClass": "com.google.cloud.dataproc.templates.main.DataProcTemplate"
    },
    "labels": {
        "goog-dataproc-batch-id": "batch-11-with-overwrite",
        "goog-dataproc-batch-uuid": "eab65216-38cb-471a-ba6f-002e7ce56c19",
        "goog-dataproc-location": "${var.region}"
    },
    "runtimeConfig": {
        "version": "1.1",
        "properties": {
        "spark.executor.instances": "2",
        "spark.driver.cores": "4",
        "spark.executor.cores": "4",
        "spark.dynamicAllocation.executorAllocationRatio": "0.3",
        "spark.app.name": "projects/${var.project_id}/locations/${var.region}/batches/batch-c461",
        "spark.driver.memory": "12200m",
        "spark.executor.memory": "12200m"
        }
    },
    "environmentConfig": {
        "executionConfig": {
        "serviceAccount": "${google_service_account.service_account.email}",
        "subnetworkUri": "subnet-for-vpn"
        }
    }
}
EOT
    )
  }
  depends_on = [google_project_service.cloudschedulerapi]
}

###############################
# Supervision
###############################
resource "google_monitoring_alert_policy" "errors" {
  display_name = "Errors in logs alert policy on ${var.dataset_name}"
  project      = var.project_id
  combiner     = "OR"
  conditions {
    display_name = "Error condition"
    condition_matched_log {
      filter = "severity=ERROR AND resource.type=cloud_dataproc_batch"
    }
  }

  notification_channels = var.notification_channels
  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }
}
