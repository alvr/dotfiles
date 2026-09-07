{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  nodejs,
  pnpm_11,
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
    hash = "sha256-YpOYNBvDe0w7q4WocHtVm8CmowjqP5YdpmRCoLg8vaQ=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_11
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-I4WJ+f0mIKXdrKdjhc3j6LfvG+mKNY8qwrX3xYJrpAs=";
    pnpm = pnpm_11;
    fetcherVersion = 4;
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
