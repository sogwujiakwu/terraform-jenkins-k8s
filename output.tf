output "k8s_control_dns" {
  value = google_compute_instance.k8s_control.network_interface[0].access_config[0].nat_ip
}

output "k8s_control_ip" {
  value = google_compute_instance.k8s_control.network_interface[0].network_ip
}

output "k8s_worker_dns" {
  value = google_compute_instance.k8s_worker.network_interface[0].access_config[0].nat_ip
}

output "k8s_worker_ip" {
  value = google_compute_instance.k8s_worker.network_interface[0].network_ip
}

output "ssh_private_key" {
  value = local_file.openstack_ssh_key.filename
}

output "ansible_inventory_content" {
  value = data.template_file.ansible_inventory.rendered
}


