# boxCulling

[![previous](https://img.shields.io/badge/index-◀_previous_page-fcb434?labelColor=4f4f4f)](INDEX.md)
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![next](https://img.shields.io/badge/▶_next_page-developer-4f4f4f?labelColor=fcb434)](DEVELOPER.md)


One of Kui's module.
Used on point-cloud location to "remove" points using meshs locations.

> ⚠ This module is not completed yet, do not use. ⚠

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

[![previous](https://img.shields.io/badge/index-◀_previous_page-fcb434?labelColor=4f4f4f)](INDEX.md)
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![next](https://img.shields.io/badge/▶_next_page-developer-4f4f4f?labelColor=fcb434)](DEVELOPER.md)
