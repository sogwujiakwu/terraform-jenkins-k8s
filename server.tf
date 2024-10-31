resource "google_compute_instance" "k8s_control" {
  for_each     = toset(["01", "03", "02"])
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
    #network = "default"
    network    = google_compute_network.k8s_vpc_network.self_link
    subnetwork = google_compute_subnetwork.k8s_network_private_subnet.self_link
    /*access_config {
    }*/
  }
  metadata = {
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"
  }
}
resource "google_compute_instance" "k8s_worker" {
  for_each     = toset(["01", "02"])
  name         = "k8s-worker-${each.value}"
  machine_type = "n1-standard-2"
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
    #network = "default"
    network    = google_compute_network.k8s_vpc_network.self_link
    subnetwork = google_compute_subnetwork.k8s_network_private_subnet.self_link
    /*access_config {
    }*/
  }

  metadata = {
    #    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}"
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"

  }

}

resource "google_compute_instance" "k8s_workstation" {
  name         = "k8s-workstation"
  machine_type = "n1-standard-2"
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
    #network = "default"
    network    = google_compute_network.k8s_vpc_network.self_link
    subnetwork = google_compute_subnetwork.k8s_network_public_subnet.self_link
    access_config {
    }
  }
  metadata = {
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"
  }

  metadata_startup_script = <<-EOF
      #!/bin/bash
      # Configure SSH to accept rsa keys
      echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config.d/10-insecure-rsa-keysig.conf
      systemctl reload sshd

      # Add private key for user authentication
      echo "${tls_private_key.ssh.private_key_pem}" >> /home/${var.username}/.ssh/id_rsa      
      chown ${var.username}:${var.username} /home/${var.username}/.ssh/id_rsa
      chgrp ${var.username} /home/${var.username}/.ssh/id_rsa      
      chmod 600 /home/${var.username}/.ssh/id_rsa

      # Install Ansible
      echo "Starting Ansible installation"
      apt-add-repository ppa:ansible/ansible -y
      apt update
      apt install ansible -y

      # Log the completion of the startup script
      echo "Startup script completed successfully" >> /var/log/startup-script.log

    EOF

}

