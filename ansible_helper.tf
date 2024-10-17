# Template for the Ansible inventory file
data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tftpl")

  vars = {
    controller_dns  = google_compute_instance.openstack_controller.network_interface[0].access_config[0].nat_ip # public IP
    controller_ip   = google_compute_instance.openstack_controller.network_interface[0].network_ip              # private IP
    compute_dns     = google_compute_instance.openstack_compute.network_interface[0].access_config[0].nat_ip    # public IP
    compute_ip      = google_compute_instance.openstack_compute.network_interface[0].network_ip                 # private IP
    ansible_user    = "devopsokeke"
    ssh_private_key = local_file.openstack_ssh_key.filename
  }
}

# Output the generated inventory to a local file
resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "${path.module}/inventory.ini"
  depends_on = [
    google_compute_instance.openstack_controller,
    google_compute_instance.openstack_compute,
    tls_private_key.ssh,
    local_file.openstack_ssh_key
  ]
}

