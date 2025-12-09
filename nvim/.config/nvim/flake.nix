{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pre-commit-fhs = pkgs.buildFHSEnv {
        name = "pre-commit";
        targetPkgs = pkgs: with pkgs; [
          pkgs.gcc
          pkgs.glibc
          pkgs.pre-commit
        ];
        runScript = "/usr/bin/pre-commit";
      };

    in {
      devShells.default = pkgs.mkShell {

        packages = with pkgs; [
          alejandra
          git
          luajitPackages.luacheck
          neovim
          pre-commit-fhs
          lua-language-server
          statix
        ];
        shellHook = ''
          CONFIG_HOME="$HOME/.config"
          export XDG_CONFIG_HOME=$(mktemp -d)
          shopt -s dotglob
          ln -s $CONFIG_HOME/* "$XDG_CONFIG_HOME/"
          ln -sfn $(pwd) "$XDG_CONFIG_HOME/"
        '';
      };
    });
}
