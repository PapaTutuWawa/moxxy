{
  description = "Moxxy v2";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bab.url = "git+https://codeberg.org/PapaTutuWawa/bits-and-bytes.git";
  };

  outputs = { self, nixpkgs, flake-utils, bab }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config = {
        android_sdk.accept_license = true;
        allowUnfree = true;
        # Fix to allow building the NDK package
        # TODO: Remove once https://github.com/tadfisher/android-nixpkgs/issues/62 is resolved
        # permittedInsecurePackages = [
        #   "python-2.7.18.6"
        #   "openssl-1.1.1w"
        # ];
      };
    };
    # Everything to make Flutter happy
    android = pkgs.androidenv.composeAndroidPackages {
      # TODO: Find a way to pin these
      #toolsVersion = "26.1.1";
      #platformToolsVersion = "31.0.3";
      #buildToolsVersions = [ "31.0.0" ];
      #includeEmulator = true;
      #emulatorVersion = "30.6.3";
      cmakeVersions = [ "3.18.1" ];
      platformVersions = [ "30" "31" "32" "33" "34" ];
      ndkVersions = [ "21.4.7075529" "23.1.7779620" ];
      buildToolsVersions = [ "30.0.3" "33.0.2" "34.0.0" ];
      includeSources = false;
      includeSystemImages = false;
      systemImageTypes = [ "default" ];
      abiVersions = [ "x86_64" "arm6" ];
      includeNDK = true;
      useGoogleAPIs = false;
      useGoogleTVAddOns = false;
    };
    lib = pkgs.lib;
    babPkgs = bab.packages."${system}";
    pinnedJDK = pkgs.jdk17;
    flutterVersion = pkgs.flutter;

    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      requests pyyaml # For the build scripts
      pycryptodome # For the Monal UDP Logger
    ]);
  in {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Android
        pinnedJDK android.platform-tools ktlint
        scrcpy

        # Flutter
        flutterVersion

        # Build scripts
	      pythonEnv gnumake

        # Code hygiene
	      gitlint jq ripgrep
      ];

      ANDROID_SDK_ROOT = "${android.androidsdk}/libexec/android-sdk";
      ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
      JAVA_HOME = pinnedJDK;

      # Fix an issue with Flutter using an older version of aapt2, which does not know
      # an used parameter.
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android.androidsdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
    };

    apps = let
      providerArg = pkgs.writeText "provider-arg.cfg" ''
        name = OpenSC-PKCS11
        description = SunPKCS11 via OpenSC
        library = ${pkgs.opensc}/lib/opensc-pkcs11.so
        slotListIndex = 0
      '';
      mkBuildScript = skipBuild: pkgs.writeShellScript "build-moxxy.sh" ''
        ${babPkgs.flutter-build}/bin/flutter-build \
          --name Moxxy \
          --not-signed \
          --zipalign ${android.androidsdk}/libexec/android-sdk/build-tools/34.0.0/zipalign \
          --apksigner ${android.androidsdk}/libexec/android-sdk/build-tools/34.0.0/apksigner \
          --pigeon ./pigeon/quirks.dart \
          --flutter ${flutterVersion}/bin/flutter \
          --dart ${flutterVersion}/bin/dart \
          --provider-config ${providerArg} ${lib.optionalString skipBuild "--skip-build"}
      '';
    in {
      # Skip the build and just sign
      onlySign = {
        type = "app";
        program = "${mkBuildScript true}";
      };

      # Build everything and sign
      build = {
        type = "app";
        program = "${mkBuildScript false}";
      };
    };
  });
}
