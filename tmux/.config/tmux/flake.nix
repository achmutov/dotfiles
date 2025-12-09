{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          gnumake
          tmux
        ];

        shellHook = ''
          CONFIG_HOME="$HOME/.config"
          export XDG_CONFIG_HOME=$(mktemp -d)
          shopt -s dotglob
          ln -s $CONFIG_HOME/* "$XDG_CONFIG_HOME/"
          ln -sfn $(pwd) "$XDG_CONFIG_HOME/"

          make clean install PLUGINS_HOME="$XDG_CONFIG_HOME/tmux" CONFIG_HOME="$XDG_CONFIG_HOME"
        '';
      };
    });
}
