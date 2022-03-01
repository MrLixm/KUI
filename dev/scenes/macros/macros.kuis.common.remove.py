"""
version=8
Python 2+
"""
from Katana import (
    UI4,
    NodegraphAPI
)

frame = NodegraphAPI.GetCurrentTime()
NAME = "KUIs.common.remove_row"


def update_node(node2update):
    """
    Because I didn't find any way to force an UI refresh of a node parameter
    we will "cut and paste" the node to kind of force refresh it.
    """

    # Get the original node and gather all the data we need for copy
    NodegraphAPI.SetAllSelectedNodes([node2update])
    source_node, parent_node = NodegraphAPI.GetAllSelectedNodesAndParent()
    katana_xml = NodegraphAPI.BuildNodesXmlIO(
        source_node,
        forcePersistant=True
    )
    source_node = source_node[0]  # type: NodegraphAPI.Node
    sn_pos = NodegraphAPI.GetNodePosition(source_node)  # type: tuple
    sn_port_in = source_node.getInputPortByIndex(0)  # type: NodegraphAPI.Port
    sn_port_in = sn_port_in.getConnectedPort(0)  # type: NodegraphAPI.Port
    sn_port_out_list = source_node.getOutputPortByIndex(0)  # type: NodegraphAPI.Port
    sn_port_out_list = sn_port_out_list.getConnectedPorts()  # type:list

    # We delete the previous node before creating the new one
    source_node.delete()
    del source_node
    Utils.EventModule.ProcessEvents()  # make sure the delete is processed

    # Now create the new node
    new_node = KatanaFile.Paste(katana_xml, parent_node)  # type: list
    new_node = new_node[0]  # type: NodegraphAPI.Node
    NodegraphAPI.SetNodePosition(new_node, sn_pos)
    sn_port_in.connect(new_node.getInputPortByIndex(0))
    for port in sn_port_out_list:
        port.connect(new_node.getOutputPortByIndex(0))

    NodegraphAPI.SetNodeEdited(new_node, True, exclusive=True)
    print(
        "[ButtonScript][{}][update_node] Finished.\n"
        "Previous node was deleted and replace by the new node <{}>."
        "".format(NAME, new_node)
    )
    return


def run():

    teleparam = node.getParameter("user.common.array")
    teleparam_expr = teleparam.getExpression()
    teleparam_value = teleparam.getValue(frame)  # "nodeName.paramName"

    asnode, asparam = teleparam_value.split(".", 1)
    asnode = NodegraphAPI.GetNode(asnode)
    asparam = asnode.getParameter(asparam)  # string array parameter

    # get current parameter structure
    array_size = asparam.getNumChildren()
    tuple_size = asparam.getTupleSize()  # will be 5 for this button

    # delete last row
    asparam.resizeArray(array_size - tuple_size)

    update_node(node)
    print("[ButtonScript][{}][run] Finished.".format(NAME))
    return


run()
