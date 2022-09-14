"""
version=7
Python 2+

This snippet is used on KUI Setup node ScriptButtons parameters.
The script is modulated based on the name of the parameter.
"""
from Katana import (
    KatanaFile,
    NodegraphAPI,
    UI4,
    Utils,
)


def get_data(sourcenode, path):

    teleparam = sourcenode.getParameter(path)
    teleparam_value = teleparam.getValue(0)  # "nodeName.paramName"

    asnode, asparam = teleparam_value.split(".", 1)
    asnode = NodegraphAPI.GetNode(asnode)
    asparam = asnode.getParameter(asparam)  # string array parameter

    # get current parameter structure
    array_size = asparam.getNumChildren()
    tuple_size = asparam.getTupleSize()

    return {"node": asnode, "param": asparam, "array": array_size, "tuple": tuple_size}


def update_node(node2update, logger):
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
    print(
        "[ButtonScript][{}][update_node] Finished.\n"
        "Previous node was deleted and replace by the new node <{}>."
        "".format(logger, new_node)
    )
    return


def run():
    """
    This function runs for all buttons.
    """

    # ex: parameter.getName() = "add_row_arbitrary"
    context = parameter.getName().rsplit("_", 1)[-1]
    op = parameter.getName().rsplit("_", 1)[0]
    name = "KUIs.{}.{}".format(context, op)

    data = get_data(node, "user.{}.array".format(context))
    param = data["param"]
    array_size = data["array"]
    tuple_size = data["tuple"]

    if op == "add_row":

        param.resizeArray(array_size + tuple_size)

        if context == "sources":
            param.getChildByIndex(array_size + 0).setValue("SOURCE LOCATION", 0)
            param.getChildByIndex(array_size + 1).setValue("SOURCE INDEX", 0)

        elif context == "common":
            tokenparam = node.getParameter("user.common.token2add")
            tokenparam_value = tokenparam.getValue(0)  # type: str
            param.getChildByIndex(array_size + 0).setValue("ATTRIBUTE", 0)
            param.getChildByIndex(array_size + 1).setValue(tokenparam_value, 0)
            param.getChildByIndex(array_size + 2).setValue("GROUPING", 0)

        elif context == "arbitrary":
            param.getChildByIndex(array_size + 0).setValue("SOURCE", 0)
            param.getChildByIndex(array_size + 1).setValue("TARGET", 0)
            param.getChildByIndex(array_size + 2).setValue("GROUPING", 0)
            param.getChildByIndex(array_size + 3).setValue("", 0)

    elif op == "remove_row":
        param.resizeArray(array_size - tuple_size)

    # this is executed no matter what button the user clicked
    update_node(node, name)

    print("[ScriptButton][{}][run] Finished.".format(name))
    return


run()
