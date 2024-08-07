variable "hosts" {
  type = map(object({
    install_user = string
    target_user = string
    target_port = number
    install_ssh_private_key = string
    install_kexec_tarball_url = string
    ignore_systemd_errors = bool
    healthcheck_script = string
    flake_system_attr = string
    flake_partitioner_attr = string
    file = string
  }))
  description = "List of the target hosts, NixOS configurations and healthcheck scripts."
}

variable "nix_options" {
  type = map(string)
  description = "Options passed to nix-build"
  default = {}
}
