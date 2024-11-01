# Template for the Ansible inventory file
data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tftpl")

  vars = {
    # Encode the complex data into JSON strings
    k8s_controls = jsonencode([
      for control in google_compute_instance.k8s_control :
      {
        name = control.name # Node Name
        #dns  = control.network_interface[0].access_config[0].nat_ip # Public IP
        ip = control.network_interface[0].network_ip # Private IP
      }
    ])

    k8s_workers = jsonencode([
      for worker in google_compute_instance.k8s_worker :
      {
        name = worker.name # Node Name
        #dns  = worker.network_interface[0].access_config[0].nat_ip # Public IP
        ip = worker.network_interface[0].network_ip # Private IP
      }
    ])

    ansible_user    = var.username
    ssh_private_key = local_file.k8s_ssh_key.filename
  }
}



# Output the generated inventory to a local file
resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "${path.module}/inventory.ini"
  depends_on = [
    google_compute_instance.k8s_control,
    google_compute_instance.k8s_worker,
    tls_private_key.ssh,
    local_file.k8s_ssh_key
  ]
}

# Output the IP address of the load balancer to a local file
resource "local_file" "ansible_lb_vars_file" {
  content  = <<-DOC
      k8s_control_lb: ${google_compute_address.k8s_lb_ip.address}
  DOC
  filename = "ansible/ansible_lb_vars.yaml"
}

resource "null_resource" "wait_for_workstation_init" {
  depends_on = [google_compute_instance.k8s_workstation]

  triggers = {
    always_run = timestamp()
  }

  provisioner "file" {
    source      = "${path.module}/wait_for_workstation_init.sh"
    destination = "/tmp/wait_for_workstation_init.sh"
  }

  connection {
    type        = "ssh"
    host        = google_compute_instance.k8s_workstation.network_interface[0].access_config[0].nat_ip
    user        = var.username
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/wait_for_workstation_init.sh",
      "/tmp/wait_for_workstation_init.sh"
    ]
  }
}

resource "null_resource" "provisioner" {
  depends_on = [
    local_file.ansible_inventory,
    null_resource.wait_for_workstation_init,
    google_compute_instance.k8s_workstation
  ]

  triggers = {
    "always_run" = timestamp()
  }

  provisioner "file" {
    source      = "${path.module}/inventory.ini"
    destination = "/home/${var.username}/inventory.ini"

    connection {
      type        = "ssh"
      host        = google_compute_instance.k8s_workstation.network_interface[0].access_config[0].nat_ip
      user        = var.username
      private_key = tls_private_key.ssh.private_key_pem
      agent       = false
      insecure    = true
    }
  }
}

resource "null_resource" "copy_ansible_playbooks" {
  depends_on = [
    null_resource.provisioner,
    null_resource.wait_for_workstation_init,
    google_compute_instance.k8s_workstation,
    local_file.ansible_lb_vars_file
  ]

  triggers = {
    "always_run" = timestamp()
  }

  provisioner "file" {
    source      = "${path.module}/ansible"
    destination = "/home/${var.username}/ansible/"

    connection {
      type        = "ssh"
      host        = google_compute_instance.k8s_workstation.network_interface[0].access_config[0].nat_ip
      user        = var.username
      private_key = tls_private_key.ssh.private_key_pem
      insecure    = true
      agent       = false
    }

  }
}
