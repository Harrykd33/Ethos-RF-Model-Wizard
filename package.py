"""Build the standalone Ethos wizard ZIP using only the Python standard library."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
FILES = ("main.lua", "icon.png", "lib/register_model_wizard.lua", "app/lib/model_wizard.lua", "README.md")


def main():
    subprocess.run([sys.executable, str(ROOT / "assets/build_icon.py")], check=True)
    manifest = ROOT / "ethos_lua_manifest.json"
    folder = json.loads(manifest.read_text(encoding="utf-8"))["folder"]
    archive = ROOT / "rotorflight-model-wizard-standalone-en.zip"
    with ZipFile(archive, "w", ZIP_DEFLATED) as package:
        package.write(manifest, manifest.name)
        for name in FILES:
            source = ROOT / folder / name
            package.write(source, f"{folder}/{name}")
    with ZipFile(archive) as package:
        assert package.testzip() is None, "Corrupt ZIP"
        for name in FILES:
            assert package.read(f"{folder}/{name}") == (ROOT / folder / name).read_bytes()
    print(f"Created and verified {archive}")


if __name__ == "__main__":
    main()
