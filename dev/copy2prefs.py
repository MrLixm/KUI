"""
version=2
python>=3.6.8

Copy to prefs

Copy the kui module to the LUA_PATH directory registered by Katana for testing.
"""
import json
import re
import shutil
import subprocess
from pathlib import Path


CONFIG = {
    "root": Path("..").resolve(),
    "source": Path("../kui").resolve(),
    "targets": [
        Path("./prefs/shelfA/lua"),
        Path("./prefs/shelfB/lua")
    ],
    "copy_llloger": True,
    # determine from which git branch should llloger.lua be copied from
    "lllogger_branch": "main",
}


def increment(repo_root: Path):
    """
    Increment the package.json file <version> key.
    Each call to this fill is considered as a new build.
    """

    pkg_path = repo_root / "package.json"
    code = pkg_path.read_text(encoding="utf-8")  # type: str
    code = json.loads(code)  # type: dict

    version = code["version"]

    build_version = re.search(r"build\.(\d+)", version)
    assert build_version, f"Can't find build's version in <{pkg_path}> !"
    new_version = int(build_version.group(1)) + 1
    new_code = f"build.{new_version}"
    version = version.replace(build_version.group(0), str(new_code))
    code["version"] = version

    with pkg_path.open("w", encoding="utf-8") as pkg_file:
        json.dump(code, pkg_file, indent=4)

    print(f"[{__name__}][increment] Incremented package.json to <build.{new_version}>.")
    return


def _copy_dir(src: Path, target_dir: Path):
    """
    Copy the given directory to the given directory.
    """

    # build command line arguments
    args = [
        'robocopy',
        str(src),
        str(target_dir),
        # copy option
        "/E",
        # logging options
        "/nfl",  # no file names are not to be logged.
        "/ndl",  # no directory names logged.
        "/np",  # no progress of the copying operation
        "/njh",  # no job header.
        # "/njs",  # no job summary.
    ]
    print(f"[{__name__}][_copy_dir] copying src to target ...")
    subprocess.call(args)

    print(
        f"[{__name__}][_copy_dir] Finished. Copied :\n"
        f"    <{src}> to\n"
        f"    <{target_dir}>"
    )
    return


def _copy_file(src: Path, target_dir: Path):
    """
    Copy the given file to the given directory
    """
    shutil.copy2(src, target_dir)
    print(
        f"[{__name__}][_copy_file] Finished. Copied :\n"
        f"    <{src}> to\n"
        f"    <{target_dir}>"
    )

    return


def copy(src: Path, target_dir: Path):
    """
    Copy the given object (dir or file) to the given directory.
    """
    if not target_dir.exists():
        target_dir.mkdir(parents=True)
        print(f"[{__name__}][copy] Created directory <{target_dir}>")

    if src.is_dir():
        _copy_dir(src=src, target_dir=target_dir)
    else:
        _copy_file(src=src, target_dir=target_dir)

    return


def copy_llloger(target_dir, branch="main"):

    print(f"[{__name__}][copy_llloger] Started with target_dir={target_dir}")

    args = [
        "curl",
        "-o",
        str(target_dir / "lllogger.lua"),
        "--silent",
        "--progress-bar",
        f"https://raw.githubusercontent.com/MrLixm/llloger/{branch}/lllogger.lua"
    ]
    print(" ".join(args))
    print(f"[{__name__}][copy_llloger] Downloading of llloger started ...")
    subprocess.call(args)

    print(f"[{__name__}][copy_llloger] Finished")
    return


def copy_version(repo_root: Path, target_dir: Path):
    """
    Copy the package.json file to the given directory.
    """

    pkg_path = repo_root / "package.json"
    copy(pkg_path, target_dir)

    print(f"[{__name__}][copy_version] Finished.")
    return


def run():

    src_path = CONFIG.get("source")
    target_path_list = CONFIG.get("targets")
    root_path = CONFIG.get("root")

    increment(repo_root=root_path)

    for target_path in target_path_list:

        # ex: kui_target_path = "dev/prefs/shelfA/lua" / "kui"
        kui_target_path = target_path / src_path.name
        copy(src=src_path, target_dir=kui_target_path)
        copy_version(repo_root=root_path, target_dir=kui_target_path)

        if CONFIG.get("copy_llloger"):
            copy_llloger(target_path, CONFIG.get("lllogger_branch"))

        continue

    print(f"[{__name__}][run] Finished.")
    return


if __name__ == '__main__':

    run()
