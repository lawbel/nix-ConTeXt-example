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
      project-name = "ConTeXt template";

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
          # control how the document gets built.
          #
          # For example, suppose that:
          #
          # (1) we need to pass some extra arguments to `context` when
          #     building - let's use the Dutch interface and the
          #     LuaJIT compiler.
          # (2) the project spans multiple files, organized within a 'source'
          #     folder as illustrated below.
          #
          #     .
          #     |-- flake.nix
          #     `-- source/
          #         |-- main.tex
          #         |-- chapter-one.tex
          #         |-- chapter-two.tex
          #         |-- fonts.tex
          #         `-- style.tex
          #
          # Then a suitable 'buildPhase' might be:
          #
          #     buildPhase = ''
          #       export FONTCONFIG_FILE=${fonts}
          #       context --interface=nl --jit source/main.tex
          #     '';
          #
          # and for the 'installPhase' we could still use the one below.
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

        # this tool is provided for convenience - if you run a command like
        # `nix run .#query-fonts -- ...` then you can check what fonts
        # ConTeXt is able to see, and what names it refers to them by.
        #
        # For example, if you want to use the Fira Code fonts (pkgs.fira-code)
        # as we have above, then TODO: finish this comment
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
