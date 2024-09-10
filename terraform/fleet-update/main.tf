module "system-build" {
  for_each = var.hosts
  source = "../nix-build"
  attribute = each.value.flake_system_attr
  file = each.value.file
  nix_options = var.nix_options
}

module "partitioner-build" {
  for_each = var.hosts
  source = "../nix-build"
  attribute = each.value.flake_partitioner_attr
  file = each.value.file
  nix_options = var.nix_options
}

module "install" {
  for_each                     = var.hosts
  source                       = "../install"
  kexec_tarball_url            = each.value.install_kexec_tarball_url
  target_user                  = each.value.install_user
  target_host                  = each.key
  target_port                  = each.value.target_port
  nixos_partitioner            = module.partitioner-build[each.key].result.out
  nixos_system                 = module.system-build[each.key].result.out
  ssh_private_key              = each.value.install_ssh_private_key
  debug_logging                = false
  stop_after_disko             = false
  extra_files_script           = each.value.install_extra_files_script
  disk_encryption_key_scripts  = []
  extra_environment            = {}
  instance_id                  = each.key
  no_reboot                    = false
}

resource "null_resource" "nixos-fleet-update" {
  triggers = {
    hosts = jsonencode(var.hosts)
    system_build = jsonencode(module.system-build)
  }
  provisioner "local-exec" {
    environment = {
      HOSTS = jsonencode(var.hosts)
      SYSTEM_CLOSURES = jsonencode(module.system-build)
      MODULEPATH = path.module
    }
    command = "${path.module}/deploy-fleet.sh"
  }
}
