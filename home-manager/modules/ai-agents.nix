{ config, pkgs, lib, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  platformInfo = {
    "x86_64-linux" = {
      claudePlatform = "linux-x64";
      codexAsset = {
        name = "codex-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-qkoT2tww6m6ybalOe5LgGDTBwEtc9Fr4HJTW83PS+C0=";
      };
      copilotAsset = {
        name = "copilot-linux-x64.tar.gz";
        hash = "sha256-IovYAqNprWs0d74cCFENVVYoux/IpTomM38zZln4F9s=";
      };
    };
    "aarch64-linux" = {
      claudePlatform = "linux-arm64";
      codexAsset = {
        name = "codex-aarch64-unknown-linux-gnu.tar.gz";
        hash = "sha256-VAY9+AcnH7XkSJHGR1gXVjv21qzVF/ngIzw7h04XTaE=";
      };
      copilotAsset = {
        name = "copilot-linux-arm64.tar.gz";
        hash = "sha256-IlyHdCOUCWVX7F0cxVk2JlTaiVpnLVp6pv3CBLHJXTY=";
      };
    };
    "x86_64-darwin" = {
      claudePlatform = "darwin-x64";
      codexAsset = {
        name = "codex-x86_64-apple-darwin.tar.gz";
        hash = "sha256-j11kKOwjatRpytxhluAAqJg2ZHTBtUM9i1O8WIyfucA=";
      };
      copilotAsset = {
        name = "copilot-darwin-x64.tar.gz";
        hash = "sha256-j3pxBbegJb9XMxs0Q1eNzT+uJSl3yCRr55egHP+6tCY=";
      };
    };
    "aarch64-darwin" = {
      claudePlatform = "darwin-arm64";
      codexAsset = {
        name = "codex-aarch64-apple-darwin.tar.gz";
        hash = "sha256-fwHZr05y5HNVf6qjI936Bk0VBqdZ9CWYOoWqX6cJo+o=";
      };
      copilotAsset = {
        name = "copilot-darwin-arm64.tar.gz";
        hash = "sha256-RI9VC4zsshbGDP9c36pG/phGBsMW/bYrW17YMkju8K4=";
      };
    };
  }.${system} or (throw "Unsupported system: ${system}");

  claudePlatform = platformInfo.claudePlatform;
  codexArtifact = platformInfo.codexAsset;
  copilotArtifact = platformInfo.copilotAsset;

  codexInnerName = lib.removeSuffix ".tar.gz" codexArtifact.name;
  opensslLib = pkgs.openssl.out;
  copilotRpath = lib.makeLibraryPath [ pkgs.glibc pkgs.stdenv.cc.cc.lib ];

  claude-code = pkgs.stdenv.mkDerivation rec {
    pname = "claude-code";
    version = "2.1.1";

    src = pkgs.fetchurl {
      name = "claude-code-${version}-${claudePlatform}";
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${claudePlatform}/claude";
      sha256 = "sha256-fWMBJr1vqDcnIKSAVahYaXQbB2sUNEAEXIlWXPPGWig=";
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 $src $out/bin/claude
    '' + lib.optionalString pkgs.stdenv.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
               $out/bin/claude
    '' + ''
      runHook postInstall
    '';

    meta = with lib; {
      description = "Claude Code - AI-powered coding assistant CLI";
      homepage = "https://claude.ai/code";
      license = licenses.unfree;
      mainProgram = "claude";
    };
  };

  codex-cli = pkgs.stdenv.mkDerivation rec {
    pname = "codex-cli";
    version = "0.79.0";

    src = pkgs.fetchurl {
      name = "codex-cli-${version}-${codexArtifact.name}";
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/${codexArtifact.name}";
      hash = codexArtifact.hash;
    };

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf pkgs.makeWrapper ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib opensslLib ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin ${codexInnerName}
      mv $out/bin/${codexInnerName} $out/bin/codex
    '' + lib.optionalString pkgs.stdenv.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
               --set-rpath "${opensslLib}/lib:${pkgs.stdenv.cc.cc.lib}/lib" \
               $out/bin/codex
      wrapProgram $out/bin/codex \
        --set LD_LIBRARY_PATH "${opensslLib}/lib:${pkgs.stdenv.cc.cc.lib}/lib"
    '' + ''
      chmod +x $out/bin/codex
      runHook postInstall
    '';

    meta = with lib; {
      description = "OpenAI Codex CLI";
      homepage = "https://github.com/openai/codex";
      license = licenses.asl20;
      mainProgram = "codex";
    };
  };

  copilot-cli = pkgs.stdenv.mkDerivation rec {
    pname = "copilot-cli";
    version = "1.0.61";

    src = pkgs.fetchurl {
      name = "copilot-cli-${version}-${copilotArtifact.name}";
      url = "https://github.com/github/copilot-cli/releases/download/v${version}/${copilotArtifact.name}";
      hash = copilotArtifact.hash;
    };

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.glibc pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin copilot
    '' + lib.optionalString pkgs.stdenv.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
               --set-rpath "${copilotRpath}" \
               $out/bin/copilot
    '' + ''
      chmod +x $out/bin/copilot
      runHook postInstall
    '';

    meta = with lib; {
      description = "GitHub Copilot CLI";
      homepage = "https://github.com/github/copilot-cli";
      license = licenses.mit;
      mainProgram = "copilot";
    };
  };

in
{
  home.packages = [
    claude-code
    codex-cli
    copilot-cli
  ];
}
