# Template for the Ansible inventory file
data "template_file" "ansible_inventory" {
  template = file("${path.module}/templates/inventory.tftpl")

  vars = {
    k8s_control_dns  = google_compute_instance.k8s_control.network_interface[0].access_config[0].nat_ip # public IP
    k8s_control_ip   = google_compute_instance.k8s_control.network_interface[0].network_ip              # private IP
    k8s_worker_dns     = google_compute_instance.k8s_worker.network_interface[0].access_config[0].nat_ip    # public IP
    k8s_worker_ip      = google_compute_instance.k8s_worker.network_interface[0].network_ip                 # private IP
    ansible_user    = "devopsokeke"
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

