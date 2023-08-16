locals {
  main_md5       = md5(file("${path.module}/function/main.py"))
  requirements_md5 = md5(file("${path.module}/function/requirements.txt"))
  combined_md5   = md5("${local.main_md5}${local.requirements_md5}")
}

variable "project_id" {
  description = "The project ID"
  default     = "your-project-id"
}

variable "region" {
  description = "The project region"
  default     = "us-central1"
}

variable "location" {
  description = "The project location id (eur3 or nam5)"
  default     = "nam5"

}
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_iam_member" "cloudfunction_firestore_access" {
  project = var.project_id
  role   = "roles/datastore.user"
  member = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
}

resource "google_firestore_database" "your-amazing-database" {
  project     = var.project_id
  name        = "your-amazing-database"
  location_id = var.location
  type        = "FIRESTORE_NATIVE"
  
  depends_on = [google_project_service.firestore]
}

## Bucket
resource "google_storage_bucket" "image_bucket" {
  name = "your-amazing-image-bucket"
  location = "US"
}

resource "google_pubsub_topic" "bucket_notifications" {
  name = "bucket-notifications-topic"
  labels = {
    zip-md5 = local.combined_md5
  }
}

resource "google_pubsub_topic_iam_binding" "bucket_pubsub_publisher" {
  topic = google_pubsub_topic.bucket_notifications.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:service-417091814016@gs-project-accounts.iam.gserviceaccount.com"
  ]
}

resource "google_storage_notification" "bucket_notification" {
  bucket        = google_storage_bucket.image_bucket.name
  payload_format = "JSON_API_V1"
  topic         = google_pubsub_topic.bucket_notifications.name

  depends_on = [google_pubsub_topic_iam_binding.bucket_pubsub_publisher]
}

resource "google_cloudfunctions_function" "process_image_function" {
  name                  = "process-image"
  description           = "Processes uploaded image data"
  available_memory_mb   = 1024
  source_archive_bucket = google_storage_bucket.cloudfunction_bucket.name
  source_archive_object = google_storage_bucket_object.function_archive.name
  entry_point           = "process_image"
  runtime               = "python311"

  labels = {
    zip-md5 = local.combined_md5
  }
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.bucket_notifications.name
  }
}

resource "google_storage_bucket" "cloudfunction_bucket" {
  name = "my-cloudfunction-source-bucket"
  location = "US"
}

resource "null_resource" "create_zip" {
  # Trigger the local-exec provisioner only when there's a change in the file checksums
  triggers = {
    file1_checksum = md5(file("${path.module}/function/main.py"))
    file2_checksum = md5(file("${path.module}/function/requirements.txt"))
    # Add more files as necessary
  }

  provisioner "local-exec" {
    command = "zip -j ${path.module}/${local.combined_md5}.zip ${path.module}/function/*"
  }
}

resource "google_storage_bucket_object" "function_archive" {
  depends_on = [null_resource.create_zip]
  name   = "${local.combined_md5}.zip"
  bucket = google_storage_bucket.cloudfunction_bucket.name
  source = "${path.module}/${local.combined_md5}.zip"
}
