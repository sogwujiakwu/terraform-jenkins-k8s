output "ssh_private_key" {
  value = local_file.openstack_ssh_key.filename
}

output "ansible_inventory_content" {
  value = data.template_file.ansible_inventory.rendered
}

output "k8s_controls_name" {
  value = [for control in google_compute_instance.k8s_control : control.name]
}

output "k8s_controls_dns" {
  value = [for control in google_compute_instance.k8s_control : control.network_interface[0].access_config[0].nat_ip]
}

output "k8s_controls_ip" {
  value = [for control in google_compute_instance.k8s_control : control.network_interface[0].network_ip]
}

output "k8s_workers_name" {
  value = [for worker in google_compute_instance.k8s_worker : worker.name]
}

output "k8s_workers_dns" {
  value = [for worker in google_compute_instance.k8s_worker : worker.network_interface[0].access_config[0].nat_ip]
}

output "k8s_workers_ip" {
  value = [for worker in google_compute_instance.k8s_worker : worker.network_interface[0].network_ip]
}

output "k8s_controls_info" {
  value = [
    for control in google_compute_instance.k8s_control :
    "${control.name} ${control.network_interface[0].access_config[0].nat_ip} ${control.network_interface[0].network_ip}"
  ]
}
