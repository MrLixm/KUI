"""
version=7
Python 2+
"""
from Katana import(
    NodegraphAPI,
    UI4
)

time = NodegraphAPI.GetCurrentTime()
NAME = "KUIs.common.add_row"


def run():

    teleparam = node.getParameter("user.common.array")
    teleparam_value = teleparam.getValue(time)  # "nodeName.paramName"
    tokenparam = node.getParameter("user.common.token2add")
    tokenparam_value = tokenparam.getValue(time)  # type: str

    asnode, asparam = teleparam_value.split(".", 1)
    asnode = NodegraphAPI.GetNode(asnode)
    asparam = asnode.getParameter(asparam)  # string array parameter

    # get current parameter structure
    array_size = asparam.getNumChildren()
    tuple_size = asparam.getTupleSize()  # will be 5 for this button

    # add new row
    asparam.resizeArray(array_size + tuple_size)

    # modify each column of the new row
    asparam.getChildByIndex(array_size + 0).setValue("ATTRIBUTE", time)
    asparam.getChildByIndex(array_size + 1).setValue(tokenparam_value, time)
    asparam.getChildByIndex(array_size + 2).setValue("GROUPING", time)
    asparam.getChildByIndex(array_size + 3).setValue("1", time)
    asparam.getChildByIndex(array_size + 4).setValue("0", time)
    asparam.finalizeValue()

    UI4.Widgets.MessageBox.Information(
        '{} Finished'.format(NAME),
        'Think to open/close the `stringValue` group to refresh it else you'
        'might not see your change.'
    )
    print("[ButtonScript][{}][run] Finished.".format(NAME))
    return


run()
