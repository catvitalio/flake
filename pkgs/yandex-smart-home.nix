{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
}:

buildHomeAssistantComponent (finalAttrs: {
  owner = "dext0r";
  domain = "yandex_smart_home";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "dext0r";
    repo = "yandex_smart_home";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KPN0lcp2CWICY6Lz1HY+Nmam+nBwmLkAhPqdMzU4QcQ=";
  };

  meta = {
    description = "Expose Home Assistant devices to Yandex Smart Home (Alice)";
    homepage = "https://github.com/dext0r/yandex_smart_home";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
})
