terraform {
  backend "local" {
    path = "state.tfstate"
  }
}

module "fleet-provider-test" {
  source = "../"
  hosts = {
    "target_host1" = {
      install_user = "install_user1"
      target_user = "target_user1"
      target_port = 22
      ssh_private_key = "ssh_private_key1"
      healthcheck_script = "healthcheck_script1"
      ignore_systemd_errors = false
      flake_system_attr = ".#system1"
      flake_partitioner_attr = ".#disko1"
      file = null
    }
    "target_host2" = {
      nixos_system = "nixos_system2"
      install_user = "install_user2"
      target_host = "target_host2"
      target_user = "target_user2"
      target_port = 22
      ssh_private_key = "ssh_private_key2"
      healthcheck_script = "healthcheck_script2"
      ignore_systemd_errors = true
      flake_system_attr = ".#system2"
      flake_partitioner_attr = ".#disko2"
      file = null
    }
  }
}
