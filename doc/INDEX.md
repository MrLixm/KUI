
# ![kui logo](./img/logo.svg) INDEX

Welcome on the KUI module's documentation.

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-blue?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)

# Use

Kui is meant to be used with an OpScript node.

You will first need to install the script (see under), then you will need
to choose how you want to use the module :

- Use the pre-built nodes for fast and easy setup. See [CONFIG_NODE](CONFIG_NODE.md).
- Manually config the scene. See [CONFIG_MANUAL](CONFIG_MANUAL.md).

It is recommended to read at leat [CONFIG_MANUAL](CONFIG_MANUAL.md) fully and
then [CONFIG_NODE](CONFIG_NODE.md) to properly understand how KUI works.

## Installation

Kui is shipped as a lua module ~~but also as an "all in one file" script~~.

> Kui also require the [lllogger](https://github.com/MrLixm/llloger) module to work.

### As module

To register the kui module, you need to put the [kui](../kui) directory in a 
location registered by the `LUA_PATH` environment variable.

For exemple we put the `kui` directory in :

```
Z:\config\katana
└── kui
    ├── array.lua
    ├── hierarchical.lua
    └── ...
```

then our variable will be

```batch
set "LUA_PATH=%LUA_PATH%Z:\config\katana\?.lua"
```

See [Lua | 8.1 – The require Function](https://www.lua.org/pil/8.1.html) for 
more details.

---

The same need to be done for the `lllogger` module that you can find here :

> https://github.com/MrLixm/llloger

You need to place in the root of the registered folder like :

```
Z:\config\katana
├── llloger.lua
└── kui
    └── ...
```

So we can simply do `local logging = require("lllogger")` (this  line is used in all the modules).

---

You can then have a look at the CONFIG pages for the next steps.

### As one file script.

TODO not built yet.

Goal would be to remove the module dependencies and have the whole code
in one big-ass lua file for whoever might need this special case.

Comment on issue #8 if you need this special case.

## Utilisation

Once installed you can use the pre-made node for a fast and easy setup
or configure manually the scene. See [CONFIG_NODE.md](CONFIG_NODE.md) and
[CONFIG_MANUAL.md](CONFIG_MANUAL.md).


# Version support

KUI has been developed on Katana 4.5.1, tested on 4.0.2 and 3.6.5. Lower versions
should be supported but with no guarantees.


# Misc

The code use Lua tables that cannot store more than 2^27 (134 million) values.
I hope you never reach this amount of values. (something like 44mi points
with XYZ values and 8,3 mi points for a Matrix attribute). A fix would be
to instead use Katana's `Array` attribute class internally. Which is already
logged as issue #3


# Performances

Performances were measured only for hierarchical for now, as it the most heavy
method. I should also specify that this is not some highly accurate measurement. 
It was only to give me a rough idea or wether I needed to run some optimisation
on the code or not.

> time given is  Geolib Pre-traversal Report total time for a preview render
> using Arnold.

For Hierarchical :
 
| version | time |
|---------|------|
| 3.6.5   | ~10s |
| 4.5.1   | ~15s |

_Time to process for Array method is too short to be worth measured._

You can have a look at all the tests I runned, compared to my original "straight-forward"
script, here :

> https://liamcollod.notion.site/kui-tests-afa7d35c08eb4c36be68e96c98923b47

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-blue?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)
