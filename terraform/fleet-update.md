# NixOS Fleet Update Provider

**status**: bleeding edge, very unstable, may eat your kittens.

This is a terraform provider aiming to manage updates for a homogeneous fleet of NixOS machines. By homogeneous, we mean machines sharing the same configuration. We originally designed this provider to update the nodes of a Kubernetes cluster.

Provided a list of hostnames, their associated NixOS configurations, and a healthcheck script to perform, this provider updates the various hosts one by one. If the healthcheck fails on a host, the host configuration is rollbacked and the overall deployment canceled.

## Inputs



This module takes a list of hosts. Each host is defined with:


- **install_user**: user used for the first NixOS installation on the
  remote machine. This user is usually provisionned by your
  bare-metal/VM provider original image.
- **target_user**: user used to perform the subsequent NixOS updates. This is
  provisionned by your NixOS closure. `root` is a good default.
- **target_port**: remote openssh listening port.
- **install_ssh_private_key**: plaintext of the secret key used to
  connect to the remote machine for the original install. Usually
  provisionned by your bare-metal/VM provider original image (or
  cloudinit).
- **install_kexec_tarball_url**: installer tarball we'll kexec onto
  during the original installation.
  `https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-x86_64-linux.tar.gz`
  is a good default.
- **ignore_systemd_errors**: ignore the systemd errors during the
  NixOS activation phase. Meaning the terraform run won't be
  considered as failed if some systemd units fail to start.
- **healthcheck_script**: plaintext bash script containing the various
  post-activation healthchecks. Should exit with code 0 if it
  succeeded. Any other code in case of failure.
- **flake_system_attr**: flake attribute containing the NixOS system
  closure.
- **flake_partitioner_attr**: flake attribute containing the disko
  filesystem description.
- **file**: if set to a non-null value, evaluate this regular nix file
  instead of the flake.

## Usage Example

```hcl
module "fleet_provider_test" {
  source = "git::https://github.com/picnoir/nixos-anywhere.git//terraform/fleet-update"
  hosts = { for i, host in var.nodes :
    host => {
      install_user = "debian"
      target_user = "root"
      target_port = 22
      # Note: we're setting the key as non-sensitive as a workaround:
      # It won't be displayed to stdout/stderr.
      # If we don't do so, the output logs will be supressed by terraform.
      install_ssh_private_key = nonsensitive(module.dedicated_servers[host].ssh_key)
      install_kexec_tarball_url = "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-x86_64-linux.tar.gz"
      ignore_systemd_errors = false
      healthcheck_script = file("${path.module}/healthcheck.sh")
      flake_system_attr = ".#nixosConfigurations.node-${i + 1}.toplevel"
      flake_partitioner_attr = ".#nixosConfigurations.node-${i + 1}.config.system.build.disko"
      file = null
    }
  }
}
```
