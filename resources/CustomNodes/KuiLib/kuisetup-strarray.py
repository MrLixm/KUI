"""
version=7
Python 2+

This snippet is used on KUI Setup node ScriptButtons parameters.
The script is modulated based on the name of the parameter.
"""
import logging

from Katana import (
    KatanaFile,
    NodegraphAPI,
    Utils,
)

logger = logging.getLogger("ScriptButton.KUI.ArrayUtil")


def getTeleparamData(sourcenode, path):
    """
    Retrieve some data about the actual parameter referenced by the teleparam at the given
    path on the givenr sourcenode.

    Args:
        sourcenode(NodegraphAPI.Node):
        path(str): paramater path, with a dot as seprator

    Returns:
        dict:
            with 4 keys
    """

    teleparam = sourcenode.getParameter(path)
    teleparam_value = teleparam.getValue(0)  # "nodeName.paramName"
    # we know the teleparamater always point to an AttributeSet node
    refnode, refparam = teleparam_value.split(".", 1)
    refnode = NodegraphAPI.GetNode(refnode)
    refparam = refnode.getParameter(refparam)  # string array parameter

    # get current parameter structure
    array_size = refparam.getNumChildren()
    tuple_size = refparam.getTupleSize()

    return {
        "node": refnode,
        "param": refparam,
        "array": array_size,
        "tuple": tuple_size,
    }


def updateNodeInterface(node2update):
    """
    Because I didn't find any way to force an UI refresh of a node parameter
    we will "cut and paste" the node to kind of force refresh it.
    """

    # Get the original node and gather all the data we need for copy
    NodegraphAPI.SetAllSelectedNodes([node2update])
    source_node, parent_node = NodegraphAPI.GetAllSelectedNodesAndParent()
    katana_xml = NodegraphAPI.BuildNodesXmlIO(source_node, forcePersistant=True)
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
    if sn_port_in:
        sn_port_in.connect(new_node.getInputPortByIndex(0))
    for port in sn_port_out_list:
        port.connect(new_node.getOutputPortByIndex(0))

    NodegraphAPI.SetNodeEdited(new_node, True, exclusive=True)
    logger.info(
        "[update_node] Finished.\n"
        "Previous node was deleted and replace by the new node {}.".format(new_node)
    )
    return


def run():
    """
    This function runs for all buttons.
    """

    # ex: parameter.getName() = "add_row_arbitrary"
    context = parameter.getName().rsplit("_", 1)[-1]
    op = parameter.getName().rsplit("_", 1)[0]

    data = getTeleparamData(node, "user.{}.array".format(context))
    param_array = data["param"]
    array_size = data["array"]
    tuple_size = data["tuple"]

    if op == "add_row":

        param_array.resizeArray(array_size + tuple_size)

        if context == "sources":
            param_array.getChildByIndex(array_size + 0).setValue("SOURCE LOCATION", 0)
            param_array.getChildByIndex(array_size + 1).setValue("SOURCE INDEX", 0)

        elif context == "common":
            tokenparam = node.getParameter("user.common.token2add")
            tokenparam_value = tokenparam.getValue(0)  # type: str
            param_array.getChildByIndex(array_size + 0).setValue("ATTRIBUTE", 0)
            param_array.getChildByIndex(array_size + 1).setValue(tokenparam_value, 0)
            param_array.getChildByIndex(array_size + 2).setValue("GROUPING", 0)

        elif context == "arbitrary":
            param_array.getChildByIndex(array_size + 0).setValue("SOURCE", 0)
            param_array.getChildByIndex(array_size + 1).setValue("TARGET", 0)
            param_array.getChildByIndex(array_size + 2).setValue("GROUPING", 0)
            param_array.getChildByIndex(array_size + 3).setValue("", 0)

    elif op == "remove_row":
        param_array.resizeArray(array_size - tuple_size)

    # this is executed no matter what button the user clicked
    updateNodeInterface(node)

    logger.info("[run] Finished for contex={}, op={}".format(context, op))
    return


run()
