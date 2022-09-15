# boxCulling

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-fcb434)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)


One of Kui's module.
Used on point-cloud location to "remove" points using meshs locations.

> **Warning** This module is not completed yet, do not use.
>
> Follow issue #1 for updates.

# Features

- Multiple meshs as culling-inputs supported.
- Only the `bounding-box` from the culling input is used to determine the space
took by the culling mesh. As such it is recommended to only use "cube" primitive
to get an accurate viewer representation.


# Use

## Source configuration

See the section of the same name from [INDEX.md](INDEX.md#2-source-configuration).

The script will need at least the `translation` token (or the `matrix`) one to
work.

## OpScript Config

- location: point-cloud scene graph location
- applyWhere: at specific location
- User Arguments :
  - `user.culling_locations`(string array): list of scene graph locations whomse
  bounding box shall be used to prune points.

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-fcb434)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)
