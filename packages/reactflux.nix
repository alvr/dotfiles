{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  nodejs,
  pnpm,
  pnpmConfigHook,
  stdenvNoCC,

  baseurl ? "/",
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "reactflux";
  version = "2026.06.22";

  src = fetchFromGitHub {
    owner = "electh";
    repo = "ReactFlux";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ECeNkmp03NWmHuA2khWpdJQUTBt1uaQucbF5X8KZXRc=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-SAAzakX65xHagWZKY3nFcV8DiQL0LR6WRtXVCnSQ+tw=";
    fetcherVersion = 3;
  };

  postPatch = ''
    substituteInPlace src/scripts/version-info.js \
      --replace-fail 'execSync("git rev-parse --short HEAD").toString().trim()' '"-"' \
      --replace-fail 'execSync("git log -1 --format=%cd --date=iso").toString().trim()' '"${finalAttrs.version}"'

    substituteInPlace src/App.jsx \
      --replace-fail 'useVersionCheck()' '{ hasUpdate: false }'
  '';

  buildPhase = ''
    runHook preBuild
    pnpm run build --base=${baseurl}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r build $out
    runHook postInstall
  '';

  meta = {
    description = "A third-party web frontend for Miniflux RSS reader";
    homepage = "https://github.com/electh/ReactFlux";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
