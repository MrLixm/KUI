"""
version=2
Python 2+
"""
from Katana import (
    UI4,
    NodegraphAPI
)

frame = NodegraphAPI.GetCurrentTime()
NAME = "KUIs.sources.remove_row"


def run():

    teleparam = node.getParameter("user.sources.array")
    teleparam_value = teleparam.getValue(frame)  # "nodeName.paramName"

    asnode, asparam = teleparam_value.split(".", 1)
    asnode = NodegraphAPI.GetNode(asnode)
    asparam = asnode.getParameter(asparam)  # string array parameter

    # get current parameter structure
    array_size = asparam.getNumChildren()
    tuple_size = asparam.getTupleSize()  # will be 2 for this button

    # delete last row
    asparam.resizeArray(array_size - tuple_size)

    UI4.Widgets.MessageBox.Information(
        '{} Finished'.format(NAME),
        'Think to open/close the `stringValue` group to refresh it else you'
        'might not see your change.'
    )
    print("[ButtonScript][{}][run] Finished.".format(NAME))
    return


run()
