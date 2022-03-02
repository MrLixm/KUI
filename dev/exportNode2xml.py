"""
version=1
Python 2+
"""
import os

from Katana import NodegraphAPI

kui_repo = r"G:\personal\code\KUI\workspace\v0001\KUI"
target_path = os.path.join(kui_repo, "KUI_Nodes.xml")

nodes = NodegraphAPI.GetAllSelectedNodes()
xml = NodegraphAPI.BuildNodesXmlIO(nodes)

xml.write(
    file=target_path,
    outputStyles=None
)

print("[exportNodes2xml] Finished. XML written to <{}>".format(target_path))