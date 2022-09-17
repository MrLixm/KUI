import os

from Katana import NodegraphAPI

from katananodling.entities import BaseCustomNode


SCRIPTBUTTON_CONTENT = os.path.join(os.path.dirname(__file__), "kuisetup-strarray.py")
with open(SCRIPTBUTTON_CONTENT) as file:
    SCRIPTBUTTON_CONTENT = str(file.read())

OPSCRIPT_PWIDTH_CONTENT = os.path.join(os.path.dirname(__file__), "kuisetup-pwidth.lua")
with open(OPSCRIPT_PWIDTH_CONTENT) as file:
    OPSCRIPT_PWIDTH_CONTENT = str(file.read())


def buildAttributeGroupParamContent(param, teleparam_node_name):
    """
    For group parameters named with the "#" prefix.

    Args:
        param(NodegraphAPI.Parameter):
        teleparam_node_name(str):
    """
    _p = param.createChildString("add_row_arbitrary", "")
    _hints = {
        "widget": "scriptButton",
        "buttonText": "Add New Row",
        "scriptText": SCRIPTBUTTON_CONTENT,
    }
    _p.setHintString(repr(_hints))

    _p = param.createChildString("remove_row_arbitrary", "")
    _hints = {
        "widget": "scriptButton",
        "buttonText": "Remove Last Row",
        "scriptText": SCRIPTBUTTON_CONTENT,
    }
    _p.setHintString(repr(_hints))

    _p = param.createChildString("array", "")
    _hints = {"widget": "teleparam"}
    _p.setExpression(
        'getParam("{}.stringValue").param.getFullName()'.format(teleparam_node_name)
    )
    _p.setHintString(repr(_hints))

    return


class KuiSetup(BaseCustomNode):

    name = "KuiSetup"
    version = (0, 1, 0)
    color = None
    description = "Part of KUI setup. Configure attributes on the source (point-cloud) for the Instancer to pick-up."
    author = "<Liam Collod monsieurlixm@gmail.com>"
    documentation = "https://github.com/MrLixm/KUI/blob/main/doc/CONFIG_NODE.md"

    def builInternal(self):

        node = NodegraphAPI.CreateNode("OpScript", self)
        node.setName("OpScript_kuis0001")
        node.getParameter("location").setExpression("=^/user.pointcloud")
        node.getParameter("script.lua").setValue(OPSCRIPT_PWIDTH_CONTENT, 0)
        node.getParameter("applyWhere").setValue("at specific location", 0)
        g = node.getParameters().createChildGroup("user")
        p = g.createChildNumber("point_size", 1)
        p.setExpression("=^/user.display.point_width")
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("VisibilityAssign", self)
        node.setName("VisibilityAssign_kuis0001")
        node.getParameter("CEL").setExpression("=^/user.pointcloud")
        node.getParameter("args.visible.value").setExpression(
            "=^/user.display.visible_in_render"
        )
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_points_kuis0001")
        node.getParameter("mode").setValue("paths", 0)
        node.getParameter("paths").insertArrayElement(0).setExpression(
            "=^/user.pointcloud"
        )
        node.getParameter("attributeName").setValue("instancing.data.points.attr", 0)
        node.getParameter("attributeType").setValue("string", 0)
        node.getParameter("stringValue").setExpression("=^/user.points.attr")
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_points_count_kuis0001")
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_sources_kuis0001")
        self.wireInsertNodes([node])
        self.attribute_set_sources = node

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_common_kuis0001")
        self.wireInsertNodes([node])
        self.attribute_set_common = node

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_arbitrary_kuis0001")
        self.wireInsertNodes([node])
        self.attribute_set_arbitrary = node

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_settings_degree2radian_kuis0001")
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_settings_matrix_kuis0001")
        self.wireInsertNodes([node])

        node = NodegraphAPI.CreateNode("AttributeSet", self)
        node.setName("AttributeSet_settings_mb_kuis0001")
        self.wireInsertNodes([node])

    def buildTopInterface(self):

        userparam = self.user_param
        p = userparam.createChildString("pointcloud", "/root/world/geo/asset")
        hints = {"widget": "scenegraphLocation"}
        p.setHintString(repr(hints))

        g = userparam.createChildGroup("display")
        p = g.createChildNumber("point_width", 1)

        p = g.createChildNumber("visible_in_render", 0)
        hints = {"widget": "boolean"}
        p.setHintString(repr(hints))

        # SETTINGS
        g = userparam.createChildGroup("settings")
        p = g.createChildNumber("convert_degree_to_radian", 1)
        hints = {
            "widget": "mapper",
            "label": "Degree to Radian Conversion",
            "options": {"degree2radian": 1.0, "radian2degree": -1.0, "disable": 0.0},
            "help": "Applied on all rotations attributes.\nHappens before the matrix conversion (if enabled)",
        }
        p.setHintString(repr(hints))
        p = g.createChildNumber("convert_trs_to_matrix", 1)
        hints = {
            "widget": "boolean",
            "label": "TRS to Matrix Conversion",
            "help": "If enabled, the translation, rotationX/Y/Z and scale attributes are converted to a 4x4 identity matrix (the matrix attribute.). Make sure at least one of the TRS attribute is specified.\n",
        }
        p.setHintString(repr(hints))
        p = g.createChildNumber("enable_motion_blur", 1)
        hints = {
            "widget": "boolean",
            "label": "Motion Blur",
            "help": 'Faster if off, but time samples are not processed which disable motion blur. ("Faster" is vague so test a before/after)',
        }
        p.setHintString(repr(hints))

        # POINTS
        g = userparam.createChildGroup("points")
        hints = {"label": "#points"}
        g.setHintString(repr(hints))

        p = g.createChildStringArray("attr", 0)
        hints = {
            "conditionalVisOps": {
                "conditionalVisOp": "lessThanOrEqualTo",
                "conditionalVisPath": "../count_manual",
                "conditionalVisValue": 0,
            },
            "help": (
                "<p>First index is the path to the attribute to compute the number of "
                "points from.</p><p>Second index is the tupleSize.</p>"
                "<p>Final formula is : <code>#attr / tupleSize</code></p>"
            ),
        }
        p.setHintString(repr(hints))
        pp = p.insertArrayElement(0)
        pp.setValue("geometry.point.P", 0)
        pp = p.insertArrayElement(1)
        pp.setValue("3", 0)

        p = g.createChildNumber("count_manual", 0)
        hints = {
            "int": True,
            "help": (
                "<p>If at 0 (disabled), use the above parameter attr.</p>"
                "<p>Else this can be used to reduce the number of points/instances "
                "by giving a smaller count than what should actually be. BUt don't "
                "try to give a higher count though.</p>"
            ),
        }
        p.setHintString(repr(hints))

        # SOURCES
        g = userparam.createChildGroup("sources")
        hints = {"label": "#sources"}
        g.setHintString(repr(hints))

        buildAttributeGroupParamContent(
            param=g, teleparam_node_name=self.attribute_set_sources.getName()
        )

        # COMMON
        g = userparam.createChildGroup("common")
        hints = {"label": "#common"}
        g.setHintString(repr(hints))

        p = g.createChildString("token2add", "$rotation")
        hints = {
            "widget": "popup",
            "label": "Token to Add",
            "options": [
                "$index",
                "$skip",
                "$hide",
                "$matrix",
                "$scale",
                "$translation",
                "$rotation",
                "$rotationX",
                "$rotationY",
                "$rotationZ",
            ],
        }
        p.setHintString(repr(hints))

        buildAttributeGroupParamContent(
            param=g, teleparam_node_name=self.attribute_set_common.getName()
        )

        # ARBITRARY
        g = userparam.createChildGroup("arbitrary")
        hints = {"label": "#arbitrary"}
        g.setHintString(repr(hints))

        buildAttributeGroupParamContent(
            param=g, teleparam_node_name=self.attribute_set_arbitrary.getName()
        )

    def _build(self):

        self.builInternal()
        self.buildTopInterface()

        self.moveAboutParamToBottom()
        return
