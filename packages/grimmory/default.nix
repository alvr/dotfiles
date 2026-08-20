{
  fetchFromGitHub,
  fetchPnpmDeps,
  ffmpeg-headless,
  gradle_9,
  jdk25_headless,
  kepubify,
  lib,
  libarchive,
  libepubgen,
  makeWrapper,
  nix-update,
  nixosTests,
  nodejs_24,
  pnpm_11,
  pnpmConfigHook,
  stdenvNoCC,
  temurin-jre-bin-25,
  writeShellScript,
}:
let
  version = "3.3.2";

  src = fetchFromGitHub {
    owner = "grimmory-tools";
    repo = "grimmory";
    rev = "v${version}";
    hash = "sha256-2mc8R9PXgTRKApFobREvnSbGoZFfCuS2WLXxD/FPQ8k=";
  };

  frontend = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "grimmory-frontend";
    inherit version src;

    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [
      nodejs_24
      pnpm_11
      pnpmConfigHook
    ];

    pnpmWorkspaces = [ "grimmory" ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs)
        pname
        version
        src
        pnpmWorkspaces
        ;
      pnpm = pnpm_11;
      fetcherVersion = 4;
      hash = "sha256-vAXmwrC80rIRYav6zmF30uwu3GixgkB7QctRtf6+vmE=";
    };

    env = {
      CI = "1";
      NG_CLI_ANALYTICS = "false";
    };

    buildPhase = ''
      runHook preBuild
      pnpm --filter=grimmory run build:prod
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r frontend/dist/grimmory/browser $out
      runHook postInstall
    '';
  });
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grimmory";
  inherit version src;

  env.APP_VERSION = finalAttrs.version;
  env.APP_REVISION = "nix";

  __darwinAllowLocalNetworking = true;

  gradleBuildTask = "bootJar";

  sourceRoot = "${finalAttrs.src.name}/backend";

  strictDeps = true;
  __structuredAttrs = true;

  buildInputs = [
    ffmpeg-headless
    kepubify
    libarchive
    libepubgen
  ];

  nativeBuildInputs = [
    frontend
    gradle_9
    jdk25_headless
    makeWrapper
  ];

  gradleFlags = [
    "-Dfile.encoding=utf-8"
    "-Dorg.gradle.java.home=${jdk25_headless.home}"
    "-Dorg.gradle.java.installations.auto-download=false"
  ];

  mitmCache = gradle_9.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  preConfigure = ''
    cp -r ${frontend} frontend-dist
    chmod -R u+w frontend-dist
    gradleFlagsArray+=("-PfrontendDistDir=$PWD/frontend-dist")
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/grimmory}
    cp build/libs/backend-${finalAttrs.version}.jar $out/share/grimmory/grimmory.jar

    makeWrapper ${lib.getExe temurin-jre-bin-25} $out/bin/grimmory \
      --set APP_VERSION ${finalAttrs.env.APP_VERSION} \
      --set APP_REVISION ${finalAttrs.env.APP_REVISION} \
      --prefix PATH : "${lib.makeBinPath finalAttrs.buildInputs}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --add-flags "-Djava.library.path=${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --add-flags "--enable-native-access=ALL-UNNAMED --enable-preview -jar $out/share/grimmory/grimmory.jar"

    runHook postInstall
  '';

  passthru = {
    inherit frontend src;
    tests.grimmory = nixosTests.grimmory;

    updateScript = writeShellScript "update-grimmory" ''
      ${lib.getExe nix-update} grimmory --src-only
      ${lib.getExe nix-update} --subpackage grimmory-frontend grimmory --no-src
      $(nix-build -A grimmory.mitmCache.updateScript)
    '';
  };

  meta = {
    description = "Self-hosted digital library for EPUB, PDF and comics (community fork of Booklore)";
    homepage = "https://github.com/grimmory-tools/grimmory";
    license = lib.licenses.agpl3Only;
    mainProgram = "grimmory";
    maintainers = with lib.maintainers; [ alvr ];
    platforms = lib.platforms.linux;
  };
})
