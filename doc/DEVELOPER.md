# Developer

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-fcb434)](DEVELOPER.md)


Section related to code development.

Code mostly try to follow Python standards (PEP).
Indent used are `2` white-space

Code tests were made on Katana 4.5v1.

## Comments

"Docstrings" (multi-line comments) are formatted as they were Python's Google docstrings. 

- Docstrings can be a bit confusing as sometimes `instance` is referring to 
the Lua class object that is instanced, and sometimes to the Katana instance object.

- When you see `-- /!\ perfs` means the bloc might be run a heavy amount of time and
  had to be written with this in mind.

## Implementing a new attribute

Modifications will mostly be in [PointCloudData](../kui/PointCloudData.lua).

TODO

# Macros

macros found in [`../resources/Macros`](../resources/Macros) are auto-generated
by [`../dev/macroGen.py`](../dev/macroGen.py).

`macroGen` need to be called from a Katana session and will use the `katananodling` custom nodes
as a source to be converted to XML.

# Tests

To test KUI you can open the Katana scene [kui.tests.katana](../dev/scenes/kui.tests.katana).

A scene from RenderMan is also available at the same location that allow you
to test motion-blur using a different pointcloud.

To launch these scenes you can use the launchers located in
[`../dev`](../dev) (they are made for Windows + git bash)

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-fcb434)](DEVELOPER.md)
