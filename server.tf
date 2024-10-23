resource "google_compute_instance" "k8s_control" {
  for_each             = toset(["01", "03", "02"])
  name         = "k8s-control-${each.value}"
  machine_type = "n1-standard-4"
  zone         = var.zone
  tags         = ["k8s-control", "kubernetes"]
  boot_disk {
    initialize_params {
      size  = 200
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  can_ip_forward = true
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata = {
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"
  }
}
resource "google_compute_instance" "k8s_worker" {
  for_each = toset(["01", "02"])
  name         = "k8s-worker-${each.value}"
  machine_type = "n1-standard-4"
  zone         = var.zone
  tags         = ["k8s-worker", "kubernetes"]
  boot_disk {
    initialize_params {
      size  = 200
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  can_ip_forward = true
  network_interface {
    #network = google_compute_network.default.name
    network = "default"
    access_config {
    }
  }

  metadata = {
    #    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}"
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"

  }

}
resource "google_compute_instance" "k8s_workstation" {
  name         = "k8s-workstation"
  machine_type = "n1-standard-4"
  zone         = var.zone
  tags         = ["k8s-workstation", "kubernetes"]
  boot_disk {
    initialize_params {
      size  = 200
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  can_ip_forward = true
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata = {
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"

  }
}
