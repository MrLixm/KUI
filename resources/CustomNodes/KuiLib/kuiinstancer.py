import os.path

from Katana import DrawingModule, NodegraphAPI

from katananodling.entities import BaseCustomNode


OPSCRIPT_ARRAY_CONTENT = os.path.join(
    os.path.dirname(__file__), "kuiinstancer-array.lua"
)
with open(OPSCRIPT_ARRAY_CONTENT) as file:
    OPSCRIPT_ARRAY_CONTENT = str(file.read())

OPSCRIPT_HIERA_CONTENT = os.path.join(
    os.path.dirname(__file__), "kuiinstancer-hiera.lua"
)
with open(OPSCRIPT_HIERA_CONTENT) as file:
    OPSCRIPT_HIERA_CONTENT = str(file.read())


class KuiInstancerNode(BaseCustomNode):

    name = "KuiInstancer"
    version = (0, 2, 0)
    color = BaseCustomNode.Colors.yellow
    description = 'Part of KUI. This node hold the "instancing" part OpScript that requires the pointcloud source to be configured in a defined way.'
    author = "<Liam Collod monsieurlixm@gmail.com>"
    documentation = "https://github.com/MrLixm/KUI/blob/main/doc/CONFIG_NODE.md"

    def buildTopInterface(self):

        userparam = self.user_param

        p = userparam.createChildString("instance_name", "instances")
        hint = {
            "help": """<p>For hierarchical, 3 tokens are available :</p>
<ul dir="auto">
<li><code>$id</code> <em>(mandatory)</em>: replaced by point number
<ul dir="auto">
<li>can be suffixed by a number to add a digit padding, ex: <code>$id3</code> can give <code>008</code></li>
</ul>
</li>
<li><code>$sourcename</code> : basename of the instance source location used</li>
<li><code>$sourceindex</code> : index attribute that was used to determine the instance source to pick.</li>
</ul>
<p>For <code>array</code> method this is just the basename of the single instance location.</p>"""
        }
        p.setHintString(repr(hint))

        p = userparam.createChildString("instance_location", "/root/world/geo")
        hint = {
            "help": '"Group"/ target location where the instance(s) must be created. (doesn\'t need to exist).',
            "widget": "scenegraphLocation",
        }
        p.setHintString(repr(hint))

        p = userparam.createChildString("pointcloud", "/root/world/geo")
        hint = {"widget": "scenegraphLocation"}
        p.setHintString(repr(hint))

        p = userparam.createChildNumber("method", 1)
        hint = {"widget": "mapper", "options": {"array": 1.0, "hierarchical": 0.0}}
        p.setHintString(repr(hint))

        p = userparam.createChildString("log_level", "INFO")
        hint = {
            "widget": "popup",
            "help": (
                "<p>You better use the <code>debug</code> level ONLY if you have very "
                "few amounts of points (&lt; 100) else you might see your console "
                "flooded with very long messages.</p>"
            ),
            "options": ["DEBUG", "INFO", "WARNING"],
        }
        p.setHintString(repr(hint))

        data = userparam.createChildGroup("Data")
        hint = {"label": ""}
        data.setHintString(repr(hint))
        p = data.createChildString("array_name", "")
        p.setExpression(
            """"{}/{}".format(user.instance_location, str(user.instance_name).replace("$id", "0").replace("$sourcename", "").replace("$sourceindex", ""))"""
        )

        return

    def buildInternal(self):

        node_dot_top = NodegraphAPI.CreateNode("Dot", self)
        node_dot_top.setName("Dot_kui0001")

        node_ops_hiera = NodegraphAPI.CreateNode("OpScript", self)
        node_ops_hiera.setName("OpScript_hiera_kui0001")
        node_ops_hiera.getParameter("location").setExpression(
            "=^/user.instance_location"
        )
        node_ops_hiera.getParameter("script.lua").setValue(OPSCRIPT_HIERA_CONTENT, 0)
        node_ops_hiera.getParameter("applyWhere").setValue("at specific location", 0)

        puser = node_ops_hiera.getParameters().createChildGroup(
            "user"
        )  # type: NodegraphAPI.Parameter
        p = puser.createChildString("pointcloud_sg", "")
        p.setExpression("=^/user.pointcloud")
        p = puser.createChildString("instance_name", "")
        p.setExpression("=^/user.instance_name")
        p = puser.createChildString("log_level", "")
        p.setExpression("=^/user.log_level")

        node_ops_array = NodegraphAPI.CreateNode("OpScript", self)
        node_ops_array.setName("OpScript_array_kui0001")
        node_ops_array.getParameter("location").setExpression("=^/user.Data.array_name")
        node_ops_array.getParameter("script.lua").setValue(OPSCRIPT_ARRAY_CONTENT, 0)
        node_ops_array.getParameter("applyWhere").setValue("at specific location", 0)

        puser = node_ops_array.getParameters().createChildGroup(
            "user"
        )  # type: NodegraphAPI.Parameter
        p = puser.createChildString("pointcloud_sg", "")
        p.setExpression("=^/user.pointcloud")
        p = puser.createChildString("log_level", "")
        p.setExpression("=^/user.log_level")

        node_switch = NodegraphAPI.CreateNode("Switch", self)
        node_switch.setName("SwitchMethod_kui0001")
        node_switch.getParameter("in").setExpression("=^/user.method")
        node_switch.addInputPort("hiera")
        node_switch.addInputPort("array")

        self.wireInsertNodes([node_dot_top, node_switch], 250)

        port_src = node_dot_top.getOutputPortByIndex(0)
        port_trg = node_ops_hiera.getInputPortByIndex(0)
        port_src.connect(port_trg)

        port_src = node_dot_top.getOutputPortByIndex(0)
        port_trg = node_ops_array.getInputPortByIndex(0)
        port_src.connect(port_trg)

        port_src = node_ops_hiera.getOutputPortByIndex(0)
        port_trg = node_switch.getInputPort("hiera")
        port_src.connect(port_trg)

        port_src = node_ops_array.getOutputPortByIndex(0)
        port_trg = node_switch.getInputPort("array")
        port_src.connect(port_trg)

        pos = NodegraphAPI.GetNodePosition(node_dot_top)
        posa = (pos[0] - 100, pos[1])
        posb = (pos[0] + 100, pos[1])
        NodegraphAPI.SetNodePosition(node_ops_hiera, posa)
        NodegraphAPI.SetNodePosition(node_ops_array, posb)

        return

    def upgrade(self):
        def updateOpScript(identifier="hiera"):
            """
            Args:
                identifier(str): "hiera" or "array"
            """
            node = None
            attrset_nodes = NodegraphAPI.GetAllNodesByType("OpScript")
            for attrset_node in attrset_nodes:
                if attrset_node.getParent() != self:
                    continue
                if identifier in attrset_node.getName():
                    node = attrset_node
            assert node, 'Can\'t find OpScript node "{}" in {}'.format(identifier, self)
            g = node.getParameter("script.lua")
            if identifier == "hiera":
                g.setValue(OPSCRIPT_HIERA_CONTENT, 0)
            else:
                g.setValue(OPSCRIPT_ARRAY_CONTENT, 0)
            return

        if str(self.about.version) == "0.1.0":

            updateOpScript("hiera")
            self.about.__update__()

        return

    def _build(self):

        self.buildTopInterface()
        self.buildInternal()

        DrawingModule.SetCustomNodeColor(self, *self.color)
        self.moveAboutParamToBottom()
        return
