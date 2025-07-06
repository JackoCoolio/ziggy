{
  description = "A data serialization language for expressing clear API messages, config files, etc.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig2nix = {
      url = "github:Cloudef/zig2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { inputs', system, lib, config, ... }:
        let
          zig-env = inputs.zig2nix.zig-env.${system} {
            zig = inputs'.zig2nix.packages.zig-0_14_0;
          };
          inherit (zig-env) pkgs;
        in {
        packages = {
          ziggy = zig-env.package {
            src = ./.;
            zigBuildZon = ./build.zig.zon;
            zigBuildZonLock = ./build.zig.zon2json-lock;

            # note: name and version are pulled from build.zig.zon
          };
          default = config.packages.ziggy;
          update-deps = pkgs.writeShellApplication {
            name = "update-deps";
            text = "${lib.getExe zig-env.zig2nix} zon2lock ./build.zig.zon";
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [ config.packages.default.nativeBuildInputs ];
        };
      };
    };
}
