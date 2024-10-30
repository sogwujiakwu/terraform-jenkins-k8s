resource "google_compute_network" "k8s_vpc_network" {
  name                    = "k8s-vpc-network"
  auto_create_subnetworks = false
}

# Define a private subnet for the VPC
resource "google_compute_subnetwork" "k8s_network_private_subnet" {
  name                     = "k8s-network-private-subnet"
  ip_cidr_range            = "10.0.0.0/24" # Adjust CIDR block as needed
  region                   = var.region
  network                  = google_compute_network.k8s_vpc_network.self_link
  private_ip_google_access = true # Enable Google API access without public IP
}

# Define a public subnet for the VPC
resource "google_compute_subnetwork" "k8s_network_public_subnet" {
  name                     = "k8s-network-public-subnet"
  ip_cidr_range            = "10.1.0.0/24" # Adjust CIDR block as needed
  region                   = var.region
  network                  = google_compute_network.k8s_vpc_network.self_link
  private_ip_google_access = true # Enable Google API access without public IP  
}


# Configure Cloud NAT for internet access on the subnet
resource "google_compute_router" "k8s_network_nat_router" {
  name    = "k8s-network-nat-router"
  region  = var.region
  network = google_compute_network.k8s_vpc_network.self_link
}

resource "google_compute_router_nat" "k8s_network_nat_config" {
  name                   = "k8s-network-nat-config"
  router                 = google_compute_router.k8s_network_nat_router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY" # Auto-allocates IPs for NAT
  #source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # Limits NAT to specific subnets
  subnetwork {
    name                    = google_compute_subnetwork.k8s_network_private_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"] # Allows all IP ranges within this subnet
  }

}

# Allow SSH ingress on port 22 from any IP to instances in the private subnet
resource "google_compute_firewall" "allow_ssh_ingress_k8s_network_private_subnet" {
  name    = "allow-ssh-ingress-k8s-network-private-subnet"
  network = google_compute_network.k8s_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction          = "INGRESS"
  source_ranges      = ["0.0.0.0/0"] # Allow SSH access from any IP
  destination_ranges = [google_compute_subnetwork.k8s_network_private_subnet.ip_cidr_range]
}

# Allow SSH ingress on port 22 from any IP to instances in the public subnet
resource "google_compute_firewall" "allow_ssh_ingress_k8s_network_public_subnet" {
  name    = "allow-ssh-ingress-k8s-network-public-subnet"
  network = google_compute_network.k8s_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction          = "INGRESS"
  source_ranges      = ["0.0.0.0/0"] # Allow SSH access from any IP
  destination_ranges = [google_compute_subnetwork.k8s_network_public_subnet.ip_cidr_range]
}


# Define a firewall rule to allow egress from instances in the public subnet to the internet
resource "google_compute_firewall" "allow_egress_internet" {
  name    = "allow-egress-internet"
  network = google_compute_network.k8s_vpc_network.name

  # Allow all egress traffic
  direction = "EGRESS"
  allow {
    protocol = "all"
  }

  # Only apply to instances in the public subnet
  destination_ranges = ["0.0.0.0/0"]
  source_ranges      = [google_compute_subnetwork.k8s_network_public_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "k8s_network_allow_internal" {
  name          = "k8s-network-allow-internal"
  network       = google_compute_network.k8s_vpc_network.name
  description   = "Allow internal traffic on the k8s vpc network"
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = [google_compute_subnetwork.k8s_network_public_subnet.ip_cidr_range, google_compute_subnetwork.k8s_network_private_subnet.ip_cidr_range]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
