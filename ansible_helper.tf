# Template for the Ansible inventory file
data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tftpl")

  vars = {
    # Encode the complex data into JSON strings
    k8s_controls = jsonencode([
      for control in google_compute_instance.k8s_control :
      {
        dns = control.network_interface[0].access_config[0].nat_ip, # Public IP
        ip  = control.network_interface[0].network_ip               # Private IP
      }
    ])

    k8s_workers = jsonencode([
      for worker in google_compute_instance.k8s_worker :
      {
        dns = worker.network_interface[0].access_config[0].nat_ip, # Public IP
        ip  = worker.network_interface[0].network_ip               # Private IP
      }
    ])

    ansible_user    = var.username
    ssh_private_key = local_file.openstack_ssh_key.filename
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
    local_file.openstack_ssh_key
  ]
}

