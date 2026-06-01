{
  description = "agdovana — formally verified Prometheus alerts";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511.912939";
    piforge = {
      url   = "path:../piforge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, piforge }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # ── Libreria Agda: SRE/*.agda + .agda-lib con include assoluto ──────
      # Il campo include usa il percorso Nix store in modo che i consumer
      # trovino i moduli senza conoscere la struttura locale.
      agdovanaLib = pkgs.stdenv.mkDerivation {
        name     = "agdovana-agda-lib";
        src      = builtins.path { path = ./.; name = "agdovana-src"; };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r SRE $out/
          cat > $out/agdovana.agda-lib <<EOF
          name: agdovana
          include: $out
          depend: standard-library
          EOF
        '';
      };

      # ── AGDA_DIR con stdlib + agdovana, usato da mkShell e dal devShell ─
      # piforge.packages."stdlib-28" è il sorgente della stdlib già buildato.
      # useRuntimeLibraries = true in mkShell bypassa il --library-file
      # hardcoded nel wrapper piforge, quindi AGDA_DIR viene letto.
      # La derivazione buildAgda (raw) è già in store come dipendenza del
      # wrapper, quindi non causa rebuild aggiuntivi.
      agdaDir = pkgs.runCommand "agda-libraries-dir" {} ''
        mkdir -p $out
        printf '%s\n%s\n' \
          "${piforge.packages.${system}."stdlib-28"}/standard-library.agda-lib" \
          "${agdovanaLib}/agdovana.agda-lib" \
          > $out/libraries
      '';

      # ── CLI script ───────────────────────────────────────────────────────
      # Letto a evaluation-time dal file sorgente; verrà eseguito con bash.
      agdovanaCli = pkgs.writeScriptBin "agdovana"
        (builtins.readFile ./bin/agdovana);

    in
    {
      # ── packages ──────────────────────────────────────────────────────────
      packages.${system} = {
        lib     = agdovanaLib;   # la libreria Agda (SRE/*.agda + .agda-lib)
        cli     = agdovanaCli;   # solo il CLI script
        default = agdovanaCli;
      };

      # ── app (nix run github:…/agdovana) ──────────────────────────────────
      apps.${system}.default = {
        type    = "app";
        program = "${agdovanaCli}/bin/agdovana";
      };

      # ── devShell per sviluppare agdovana stessa ───────────────────────────
      devShells.${system}.default = piforge.lib.agda.mkShell {
        inherit pkgs;
        version = "v28";
        useRuntimeLibraries = true;
        extraPackages = with pkgs; [
          haskell.packages.ghc910.ghc
          watchexec
          agdovanaCli
        ];
        shellHook = ''
          export AGDA_DIR="${agdaDir}"
        '';
      };

      # ── lib.mkShell: API per i consumer di agdovana ───────────────────────
      #
      # Uso nel flake del consumer:
      #
      #   inputs.agdovana.url = "github:…/agdovana";
      #
      #   devShells.x86_64-linux.default =
      #     inputs.agdovana.lib.mkShell {
      #       pkgs    = nixpkgs.legacyPackages.x86_64-linux;
      #     };
      #
      # Il consumer scrive il proprio SreGen.agda con:
      #   depend: standard-library agdovana
      # e trova SRE.Core, SRE.Proofs, SRE.Render senza configurazione extra.
      lib.mkShell = { pkgs, extraPackages ? [], shellHook ? "" }:
        let sys = pkgs.system;
        in piforge.lib.agda.mkShell {
          inherit pkgs;
          version = "v28";
          useRuntimeLibraries = true;
          extraPackages = with pkgs; [
            haskell.packages.ghc910.ghc
            watchexec
            (self.packages.${sys}.cli)
          ] ++ extraPackages;
          shellHook = ''
            export AGDA_DIR="${agdaDir}"
          '' + shellHook;
        };
    };
}
