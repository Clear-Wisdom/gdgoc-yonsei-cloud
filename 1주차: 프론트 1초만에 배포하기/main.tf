provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "website_bucket" {
  name          = var.bucket_name
  location      = var.region
  # 버킷 안에 파일이 있어도 terraform destroy 시 버킷을 삭제하는 기능
  # 실제 프로덕션 환경에서는 주의할 것
  force_destroy = true

  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.website_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
