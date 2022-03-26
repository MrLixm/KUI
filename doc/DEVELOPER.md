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

# Tests

You can use the 2 point-clouds in [./test-data](./test-data) to test KUI
while developing. They have all the TRS attributes + a randomColor one (
! actually name colorRandom on the 100k one 😬)

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-fcb434)](DEVELOPER.md)
