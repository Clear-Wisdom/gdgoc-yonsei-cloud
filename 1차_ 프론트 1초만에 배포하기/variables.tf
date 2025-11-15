variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
}

variable "bucket_name" {
  description = "The globally unique name for the Cloud Storage bucket."
  type        = string
}
