{
  description = "Moxxy v2";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.android_sdk.accept_license = true;
    };
    android = pkgs.androidenv.composeAndroidPackages {
      # TODO: Find a way to pin these
      #toolsVersion = "26.1.1";
      #platformToolsVersion = "31.0.3";
      #buildToolsVersions = [ "31.0.0" ];
      #includeEmulator = true;
      #emulatorVersion = "30.6.3";
      platformVersions = [ "28" ];
      includeSources = false;
      includeSystemImages = true;
      systemImageTypes = [ "default" ];
      abiVersions = [ "x86_64" ];
      includeNDK = false;
      useGoogleAPIs = false;
      useGoogleTVAddOns = false;
    };
    pinnedJDK = pkgs.jdk11;

    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      requests pyyaml
    ]);
  in {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        flutter pinnedJDK android.platform-tools pythonEnv jq gnumake
      ];

      ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
      JAVA_HOME = pinnedJDK;
      ANDROID_AVD_HOME = (toString ./.) + "/.android/avd";
    };
  });
}
