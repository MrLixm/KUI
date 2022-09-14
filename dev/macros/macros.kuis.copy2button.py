"""
version=3
Python 2+

This snippet is used on KUI Setup node.
"""
from ast import literal_eval

FRAME = NodegraphAPI.GetCurrentTime()


code = node.getParameter("user.data.btn_code").getValue(FRAME)

btn_list = list()
loclist = ["sources", "common", "arbitrary"]
for loc in loclist:
    btn_list.append("user.{0}.add_row_{0}".format(loc))
    btn_list.append("user.{0}.remove_row_{0}".format(loc))
del loclist

for btn in btn_list:
    btn = node.getParameter(btn)
    hint = literal_eval(btn.getHintString())  # type: dict
    hint["scriptText"] = code
    btn.setHintString(repr(hint))

    print(
        "[ScriptButton][copy2button] Code on button <{}> replaced."
        "".format(btn.getName())
    )
    continue