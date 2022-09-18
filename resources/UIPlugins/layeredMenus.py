import logging
import katananodling.menu

from Katana import LayeredMenuAPI


logger = logging.getLogger(__name__)


def registerLayeredMenus():

    layered_menu_name = "katananodling"

    layered_menu = katananodling.menu.getLayeredMenuForAllCustomNodes()
    LayeredMenuAPI.RegisterLayeredMenu(layered_menu, layered_menu_name)
    logger.info(
        "[registerLayeredMenus] Registered <{}> with shortcut <{}>"
        "".format(layered_menu_name, layered_menu.getKeyboardShortcut())
    )
    return


registerLayeredMenus()
