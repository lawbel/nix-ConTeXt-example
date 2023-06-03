{
  description = "A simple PDF document built with ConTeXt";

  inputs = {
    # Nixpkgs / NixOS version can be specified by setting e.g.
    # `nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";`
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {self, nixpkgs}:
    let
      # set your system
      system = "x86_64-linux";

      # the name of the Nix project
      project-name = "ConTeXt example";

      # add fonts here - `pkgs.cascadia-code` is a popular font for example
      fonts = pkgs.makeFontsConf {
        fontDirectories = [
          pkgs.cascadia-code
        ];
      };

      pkgs = nixpkgs.legacyPackages.${system};

    in {
      packages.${system} = {
        # controls what `nix build` will do by default
        default = self.packages.${system}.document;

        # the main workhorse of this file
        document = pkgs.stdenv.mkDerivation {
          name = project-name;
          src = ./.;

          # this instructs nix to build the project in the following phases:
          #
          # (1) the default 'unpackPhase' - it copies over any files in this
          #     folder to whichever location Nix uses for the build
          # (2) the below 'buildPhase'
          # (3) the below 'installPhase'
          phases = [
            "unpackPhase"
            "buildPhase"
            "installPhase"
          ];

          # This (together with 'installPhase' below) is the main place to
          # control how the document gets built. For example, to use the
          # Dutch interface and the LuaJIT compiler a suitable 'buildPhase'
          # might be:
          #
          #   buildPhase = ''
          #     export FONTCONFIG_FILE=${fonts}
          #     cd source
          #     context --interface=nl --jit main.tex
          #   '';
          buildPhase = ''
            export FONTCONFIG_FILE=${fonts}
            cd source
            context main.tex
          '';

          # simply outputs the PDF and the log file
          installPhase = ''
            mkdir -p $out
            cp main.log $out
            cp main.pdf $out
          '';

          # if you require any other tools in the above phases, add them here
          buildInputs = [
            pkgs.texlive.combined.scheme-context
          ];
        };

        # this output is provided for convenience - if you run a command like
        # `nix run .#query-fonts -- ...` then you can check what fonts
        # ConTeXt is able to see, and what names it refers to them by.
        #
        # For example, to use the Cascadia Code fonts (pkgs.cascadia-code)
        # as configured above, run
        #
        #   nix run .#query-fonts -- --list --all cascadia
        #
        # and look in the 'filename' column to get the base file names for the
        # regular / bold / italic etc. font variants. See source/fonts.tex for
        # more details.
        query-fonts = pkgs.writeShellApplication {
          name = "query-fonts";
          runtimeInputs = [pkgs.texlive.combined.scheme-context];
          text = ''
            export FONTCONFIG_FILE=${fonts}
            mtxrun --script font --reload > /dev/null
            mtxrun --script font "$@"
          '';
        };
      };
    };
}
