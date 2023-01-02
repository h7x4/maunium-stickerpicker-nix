{ python3Packages, fetchFromGitHub, mauniumStickerpicker, cacert }:
python3Packages.buildPythonPackage {
  name = "stickerpicker-tools";
  src = mauniumStickerpicker;

  propagatedBuildInputs = with python3Packages; [
    aiohttp
    yarl
    pillow
    telethon
    cryptg
    python-magic
    cacert
  ];
  doCheck = false;
}