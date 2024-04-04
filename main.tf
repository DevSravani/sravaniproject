# Provider configuration
provider "google" {
  credentials = "sravanikey.json"
  project     = "sravani-418405"
  region      = "us-west1"
}

# Define VPC network
resource "google_compute_network" "my_vpcnetwork" {
  name = "my-vpc-network"
}

# Define router
resource "google_compute_router" "my_router" {
  name    = "my-router"
  network = google_compute_network.my_vpcnetwork.self_link
}

# Define public subnetwork
resource "google_compute_subnetwork" "my_public_subnet" {
  name          = "my-public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network = google_compute_network.my_vpcnetwork.self_link
  purpose = "PUBLIC"

  secondary_ip_range {
    range_name    = "my-public-secondary-range"
    ip_cidr_range = "10.0.2.0/24"
  }
}

# Define NAT configuration
resource "google_compute_router_nat" "nat" {
  name                               = "cloud-nat"
  router                             = google_compute_router.my_router.name
  region                             = google_compute_router.my_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Define VM instance
resource "google_compute_instance" "my_vm" {
  name         = "vm-1"
  zone         = "us-west1-a"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata_startup_script = "apt-get update && apt-get install -y python3 /home/sravanichedurupaku/sravaniproject/app.py"

  network_interface {
    network    = google_compute_network.my_vpcnetwork.self_link
    subnetwork = google_compute_subnetwork.my_public_subnet.self_link
    access_config {}
  }
}

# Define firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.my_vpcnetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Define firewall rule to allow HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.my_vpcnetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.0.2.0/24"]
}

