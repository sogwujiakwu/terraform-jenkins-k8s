# Backend service for the load balancer (regional scope)
resource "google_compute_region_backend_service" "k8s_control_backend_service" {
  name                  = "k8s-control-backend"
  protocol              = "TCP"
  health_checks         = [google_compute_region_health_check.k8s_control_tcp_health_check.self_link] # Use regional health check
  load_balancing_scheme = "EXTERNAL"
  region                = var.region # Specify the region to match the forwarding rule

  backend {
    group          = google_compute_instance_group.k8s_control_instance_group.self_link
    balancing_mode = "CONNECTION" # Set balancing mode to CONNECTION for Network Load Balancer
  }
}

# Instance group for the control plane nodes
resource "google_compute_instance_group" "k8s_control_instance_group" {
  name = "k8s-control-group"
  zone = var.zone
  instances = [
    for control in google_compute_instance.k8s_control : control.self_link
    #google_compute_instance.k8s_control["01"].self_link
  ]
}

# Regional health check for the backend service
resource "google_compute_region_health_check" "k8s_control_tcp_health_check" {
  name               = "k8s-control-tcp-health-check"
  region             = var.region # Make the health check regional
  check_interval_sec = 5
  timeout_sec        = 5
  tcp_health_check {
    port = 6443 # For the Kubernetes API
  }
}

# Reserve a regional external IP address for the regional load balancer
resource "google_compute_address" "k8s_lb_ip" {
  name   = "k8s-lb-ip"
  region = var.region # Specify your region here
}

# Forwarding rule for the load balancer (regional scope)
resource "google_compute_forwarding_rule" "k8s_control_forwarding_rule" {
  name                  = "k8s-control-forwarding-rule"
  backend_service       = google_compute_region_backend_service.k8s_control_backend_service.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "6443"
  ip_address            = google_compute_address.k8s_lb_ip.address
  region                = var.region # Ensure the region matches
}

# Define your region as a variable
variable "region" {
  default = "us-east1"
}

