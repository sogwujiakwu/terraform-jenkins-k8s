output "controller_dns" {
  value = google_compute_instance.openstack_controller.network_interface[0].access_config[0].nat_ip
}

output "controller_ip" {
  value = google_compute_instance.openstack_controller.network_interface[0].network_ip
}

output "compute_dns" {
  value = google_compute_instance.openstack_compute.network_interface[0].access_config[0].nat_ip
}

output "compute_ip" {
  value = google_compute_instance.openstack_compute.network_interface[0].network_ip
}

output "ssh_private_key" {
  value = local_file.openstack_ssh_key.filename
}

output "ansible_inventory_content" {
  value = data.template_file.ansible_inventory.rendered
}


