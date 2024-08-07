{
  description = "dummy test flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {

      packages.x86_64-linux.system1 = nixpkgs.legacyPackages.x86_64-linux.hello;
      packages.x86_64-linux.system2 = nixpkgs.legacyPackages.x86_64-linux.hello;
      packages.x86_64-linux.disko1 = nixpkgs.legacyPackages.x86_64-linux.hello;
      packages.x86_64-linux.disko2 = nixpkgs.legacyPackages.x86_64-linux.hello;

      packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    };
}
