"""
python>=2.7
Must be called in Katana
"""
import os
import logging

from Katana import NodegraphAPI

import KuiLib

logger = logging.getLogger("macroGen-katanaScript")


def run(dry_run=False):

    target_dir = os.environ["KUI_DEV_MACRO_TARGET_DIR"]
    assert os.path.exists(
        target_dir
    ), "target dir from env variable doesn't exists on disk."

    node = NodegraphAPI.CreateNode(KuiLib.KuiInstancer.name, NodegraphAPI.GetRootNode())
    xml = NodegraphAPI.BuildNodesXmlIO([node])
    path = os.path.join(target_dir, "KuiInstancerMacro.macro")
    if not dry_run:
        xml.write(path, outputStyles=None)
    logger.info("[run] Wrote {}".format(path))

    node = NodegraphAPI.CreateNode(KuiLib.KuiSetup.name, NodegraphAPI.GetRootNode())
    xml = NodegraphAPI.BuildNodesXmlIO([node])
    path = os.path.join(target_dir, "KuiSetupMacro.macro")
    if not dry_run:
        xml.write(path, outputStyles=None)
    logger.info("[run] Wrote {}".format(path))

    logger.info("[run] Finished")
    return


run(dry_run=False)
