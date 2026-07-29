{
  nixpkgs ? builtins.fetchTarball {
    url = "https://github.com/lexe-app/nixpkgs/archive/30b0ae7066bc61d6f271bbdc119933b005769f6b.tar.gz";
    sha256 = "sha256-T/m2ilmeLjtUCvT33T8+P0HNGA6Vg+L3CVP8RZgKJME=";
  },
  system ? builtins.currentSystem,
}:

assert builtins.elem system [
  "aarch64-darwin"
  "x86_64-linux"
];

let
  pkgs = import nixpkgs { inherit system; };

  # Rust's musl target links libc statically. Use nixpkgs' fully static package
  # set as well so native dependencies such as RocksDB are statically linked.
  targetPkgs = if system == "x86_64-linux" then pkgs.pkgsStatic else pkgs;
in
{
  blockstream-electrs = targetPkgs.rustPlatform.buildRustPackage {
    pname = "blockstream-electrs";
    version = "0.4.1-unstable-2026-07-20";

    src = targetPkgs.fetchFromGitHub {
      owner = "Blockstream";
      repo = "electrs";
      rev = "ef15bf97b97814bc8ac771e8537dcf1c1779dade";
      hash = "sha256-sObkyuS/BcoKMDvrpUnIhl2NlB/gJKESfUbgVLe6PGU=";
    };

    cargoHash = "sha256-P8slOt07Fu6NNzYLEso3UQtfx7Yj+C4w98lq/Wr8oTk=";

    nativeBuildInputs = [ targetPkgs.rustPlatform.bindgenHook ];

    # Use the platform allocator and build the bundled RocksDB. The latter
    # avoids the crashes we have observed with dynamically linked RocksDB.
    postPatch = ''
      substituteInPlace Cargo.toml \
        --replace-fail 'tikv-jemallocator = "0.6"' ""
      substituteInPlace src/bin/electrs.rs \
        --replace-fail $'#[global_allocator]\nstatic GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;\n\n' ""
    '';

    cargoBuildFlags = [
      "--package=electrs"
      "--bin=electrs"
    ];

    # The release package only needs the service binary; upstream integration
    # tests require additional dynamically linked daemons.
    doCheck = false;

    doInstallCheck = true;
    installCheckPhase = ''
      $out/bin/electrs --version
    '';

    meta = {
      description = "Blockstream's Electrum server and Esplora backend";
      homepage = "https://github.com/Blockstream/electrs";
      license = targetPkgs.lib.licenses.mit;
      mainProgram = "electrs";
      platforms = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    };
  };
}
