resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "openstack_ssh_key" {
  filename        = "openstack_ssh_key.pem"
  file_permission = "600"
  content         = tls_private_key.ssh.private_key_pem
}

