"""
Copy the kui module to the LUA_PATH directory registered by Katana for testing.

Python 3+
"""
import subprocess
from pathlib import Path


CONFIG = {
    "source": Path("../kui").resolve(),
    "target": Path(r"Z:\dccs\katana\library\shelf0006\lua"),
    # determine from which git branch should llloger.lua be copied from
    "lllogger_branch": "main",
}


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


def run():

    src_path = CONFIG.get("source")
    target_path = CONFIG.get("target") / src_path.name

    # build command line arguments
    args = [
        'robocopy',
        str(src_path),
        str(target_path),
        # copy option
        "/E",
        # logging options
        "/nfl",  # no file names are not to be logged.
        "/ndl",  # no directory names logged.
        "/np",  # no progress of the copying operation
        "/njh",  # no job header.
        # "/njs",  # no job summary.
    ]
    print(f"[{__name__}][run] copying src to target ...")
    subprocess.call(args)

    copy_llloger(CONFIG.get("target"), CONFIG.get("lllogger_branch"))

    print(
        f"[{__name__}][run] Finished. Copied :\n"
        f"    <{src_path}> to\n"
        f"    <{target_path}>"
    )
    return


if __name__ == '__main__':

    run()
