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

