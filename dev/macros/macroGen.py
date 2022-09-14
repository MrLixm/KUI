"""
Main script to run that will genereate the 2 KUI macros file using the other
files in this directory.
"""
__all__ = ("",)

import logging
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import List


logger = logging.getLogger("macroGen")

KUI_ROOT = Path(__file__).parent.parent.parent
THIS_DIR = Path(__file__).parent

MACRO_TARGET_DIR = KUI_ROOT / "resources" / "Macros"

DRYRUN = False


def stringToXmlString(source, opscript_mode=False):
    # type: (str, bool) -> str
    """
    Convert the given string to a xml compatible one line string.
    All not supported characters will be escaped.

    SRC: https://stackoverflow.com/a/65450788/13806195

    Args:
        opscript_mode:
        source:

    Returns:

    """
    subtable = {
        "<": "&lt;",
        ">": "&gt;",
        "&": "&amp;",
        r"\\'": "&apos;",
        '"': "&quot;",
    }
    if opscript_mode:
        subtable[r"\\n"] = "&#0010;"

    source = repr(source)
    if opscript_mode:
        source = source[1:][:-1]

    out = source
    for pattern, replace in subtable.items():
        pattern = re.compile(pattern)
        out = pattern.sub(replace, out)

    return out


@dataclass
class TemplateData:
    """
    A token to replace in a macro template with the content of the given file
    """

    filepath: Path
    token: str
    opscript: bool = False


class BaseMacro:

    target_path: Path = None
    template_path: Path = None

    data: List[TemplateData] = None

    @classmethod
    def generate(cls):

        template = cls.template_path.read_text(encoding="utf-8")

        for template_data in cls.data:

            assert (
                template_data.filepath.exists()
            ), f"{template_data.filepath} doesn't exists."

            assert (
                template_data.token in template
            ), f"Token {template_data.token} not found in {cls.template_path}"

            token_content = template_data.filepath.read_text(encoding="utf-8")
            token_content = stringToXmlString(
                token_content, opscript_mode=template_data.opscript
            )
            template = template.replace(template_data.token, token_content)
            logger.debug(f"[{cls.__name__}][generate] Replaced {template_data.token}")

        if not DRYRUN:
            cls.target_path.write_text(template, encoding="utf-8")

        logger.info(f"[{cls.__name__}][generate] Finished. Write: {cls.target_path}")
        return


class KUIInstancer(BaseMacro):

    target_path = MACRO_TARGET_DIR / "KUI_Instancer.macro"
    template_path = THIS_DIR / "kuiinstancer-base.macro"

    data = [
        TemplateData(
            THIS_DIR / "opscript.kui.array.lua",
            token="$$OPS_ARRAY$$",
            opscript=True,
        ),
        TemplateData(
            THIS_DIR / "opscript.kui.hierarchical.lua",
            token="$$OPS_HIERA$$",
            opscript=True,
        ),
    ]


class KUISetup(BaseMacro):

    target_path = MACRO_TARGET_DIR / "KUI_Setup.macro"
    template_path = THIS_DIR / "kuisetup-base.macro"

    data = [
        TemplateData(
            THIS_DIR / "scriptButton_strarray.py",
            token="$$SB_STRARRAY$$",
        ),
    ]


def run():

    if DRYRUN:
        logger.warning("DRYRUN=True")

    # Delete and recreate the Macros/ dir
    if MACRO_TARGET_DIR.exists():
        if not DRYRUN:
            shutil.rmtree(MACRO_TARGET_DIR)
        logger.info(f"[run] removed {MACRO_TARGET_DIR}")
    if not DRYRUN:
        MACRO_TARGET_DIR.mkdir()
    logger.info(f"[run] created {MACRO_TARGET_DIR}")

    KUISetup.generate()
    KUIInstancer.generate()

    logger.info("[run] Finished.")
    return


if __name__ == "__main__":

    # DRYRUN = True
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(levelname)-7s %(asctime)s [%(name)s]%(message)s",
    )
    run()
