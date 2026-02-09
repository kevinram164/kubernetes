# ------------------------------------------------------------------------------
# GKE với Terraform – Main
# ------------------------------------------------------------------------------
# Chuẩn bị: gcloud auth application-default login, gcloud config set project PROJECT_ID
# Chạy: terraform init -> terraform plan -> terraform apply
# Kubeconfig: gcloud container clusters get-credentials CLUSTER --region REGION --project PROJECT_ID
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Bật Kubernetes Engine API cho project
resource "google_project_service" "container" {
  project                    = var.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = true
}

# ------------------------------------------------------------------------------
# VPC và subnet (GKE cần secondary range cho Pod và Service)
# ------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  depends_on              = [google_project_service.container]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_secondary_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_secondary_cidr
  }
}

# ------------------------------------------------------------------------------
# GKE cluster (regional, dùng subnet có secondary range)
# ------------------------------------------------------------------------------
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  network  = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [
    google_project_service.container,
    google_compute_subnetwork.subnet
  ]
}

# ------------------------------------------------------------------------------
# Node pool
# ------------------------------------------------------------------------------
resource "google_container_node_pool" "main" {
  name     = "main"
  location = google_container_cluster.primary.location
  cluster  = google_container_cluster.primary.name

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }
}
