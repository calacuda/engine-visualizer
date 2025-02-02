{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      overlays = [
        rust-overlay.overlays.default
        (final: prev: {
          rustToolchain =
            let
              rust = prev.rust-bin;
            in
            if builtins.pathExists ./rust-toolchain.toml then
              rust.fromRustupToolchainFile ./rust-toolchain.toml
            else if builtins.pathExists ./rust-toolchain then
              rust.fromRustupToolchainFile ./rust-toolchain
            else
              rust.stable.latest.default.override {
                extensions = [ "rust-src" "rustfmt" ];
              };
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          packages = with pkgs; [
            # rustToolchain
            clang
            gdb
            lld
            openssl
            pkg-config
            # cargo-deny
            # cargo-edit
            # cargo-watch
            # rust-analyzer
            alsa-lib
            udev
            # libudev-zero
            # libudev0-shim
            vulkan-loader
            xorg.libX11
            # x11
            xorg.libXrandr
            xorg.libXcursor
            xorg.libXi            
            # dbus
            libxkbcommon
            ldtk
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [
              pkgs.libxkbcommon
              pkgs.udev
              pkgs.alsa-lib
              pkgs.vulkan-loader
            ]}"
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib";
          '';
        };
      });
    };
}
