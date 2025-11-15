terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = "vpc-terraform"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.20.20.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.20.21.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "proxy_only" {
  provider      = google-beta
  name          = "proxy-only-terraform"
  ip_cidr_range = "10.20.22.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "router" {
  name    = "cloud-router-terraform"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-terraform"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_service_account" "vm_sa" {
  account_id   = "vm-service"
  display_name = "Terraform VM Service Account"
}

resource "google_compute_instance_template" "template" {
  name         = "ins-tem-terraform"
  machine_type = "e2-micro"

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "hello from $(hostname)" > /var/www/html/index.nginx-debian.html
    systemctl enable nginx
    systemctl restart nginx
  EOT

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  name               = "mig-terraform"
  region             = var.region
  base_instance_name = "mig-terra"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.template.id
    name              = "primary"
  }

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "autoscaler-terraform"
  region = var.region
  target = google_compute_region_instance_group_manager.mig.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 4
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.id

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["35.235.240.0/20"]

  target_service_accounts = [google_service_account.vm_sa.email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "lb_health" {
  name    = "allow-lb-healthcheck"
  network = google_compute_network.vpc.id

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]

  target_service_accounts = [google_service_account.vm_sa.email]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "lb_proxies" {
  name    = "allow-proxy-subnet-to-backends"
  network = google_compute_network.vpc.id

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [google_compute_subnetwork.proxy_only.ip_cidr_range]

  target_service_accounts = [google_service_account.vm_sa.email]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_region_health_check" "http" {
  provider = google-beta
  name     = "hc-terraform"
  region   = var.region

  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = "/"
  }
}

resource "google_compute_region_backend_service" "backend" {
  provider              = google-beta
  name                  = "backend-terraform"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.http.id]
  timeout_sec           = 30
  port_name             = "http"

  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
  }
}

resource "google_compute_region_url_map" "url_map" {
  provider       = google-beta
  name           = "urlmap-terraform"
  region         = var.region
  default_service = google_compute_region_backend_service.backend.id
}

resource "google_compute_region_target_http_proxy" "http_proxy" {
  provider = google-beta
  name     = "http-proxy-terraform"
  region   = var.region
  url_map  = google_compute_region_url_map.url_map.id
}

resource "google_compute_address" "lb_ip" {
  provider    = google-beta
  name        = "lb-ip-terraform"
  region      = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM" # STANDARD도 가능
}

resource "google_compute_forwarding_rule" "http" {
  provider              = google-beta
  name                  = "fr-terraform"
  region                = var.region
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "80" # EXTERNAL_MANAGED에 유효
  target                = google_compute_region_target_http_proxy.http_proxy.id
  network               = google_compute_network.vpc.id
  ip_address            = google_compute_address.lb_ip.id
  network_tier          = "PREMIUM"

  depends_on = [google_compute_subnetwork.proxy_only]
}