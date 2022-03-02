# API

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-fcb434)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)

Developer documentation for usage of [../kui](../kui) module.

See [DEVELOPER.md](DEVELOPER.md) for modifications documentation.

# Content

- [../kui/array.lua](../kui/array.lua)

> Expose functions to create an instance array location.

- [../kui/boxCulling.lua](../kui/boxCulling.lua)

> Used for point culling on the point-cloud. Not finished yet.

- [../kui/hierarchical.lua](../kui/hierarchical.lua)

> Expose functions to create hierarchical instances locations.

- [../kui/PointCloudData.lua](../kui/PointCloudData.lua)

> Read a point-cloud attributes and convert it to a Lua objet for easy manipulation.

- [../kui/utils.lua](../kui/utils.lua)

> Utility functions common to all modules.


# ![module](https://img.shields.io/badge/module-5663B3) array.lua

## ![method](https://img.shields.io/badge/method-4f4f4f) array:run

Read the user argument and create an instance-array location.

## ![method](https://img.shields.io/badge/method-4f4f4f) array:set_logger_level

Change the logger level used for the module, and it's dependencies.
Default is `debug`.

```
Args :
    level(str): 
        log level to set
``` 

## ![attribute](https://img.shields.io/badge/attribute-4f4f4f) array.logger

```
table: 
    The llloger instance being used for this module.
    See llloger module documentation.
``` 

# ![module](https://img.shields.io/badge/module-5663B3) boxCulling.lua

_Not implemented yet._

# ![module](https://img.shields.io/badge/module-5663B3) hierarchical.lua

As hierarchical create several locations, the script can be dividided in
2 parts for performances optimization. When the OpScript is evaluating
the current location (at root), we create all the children location and store them.
And then the part where the OpScript is running on every child created, where
we just set its attributes (not at root). 

## ![method](https://img.shields.io/badge/method-4f4f4f) hierarchical:run_root

Read the user argument and pre-create the hierarchical children location.
95% of the work is done here. To run first.

## ![method](https://img.shields.io/badge/method-4f4f4f) hierarchical:run_not_root

For each child created, just set its attributes defined in the previous method
run_root(). It is not recommened to log anything here as this method
will be repeated times the number of child created.

## ![method](https://img.shields.io/badge/method-4f4f4f) hierarchical:set_logger_level

Change the logger level used for the module, and it's dependencies.
Default is `debug`.

```
Args :
    level(str): 
        log level to set
``` 

## ![attribute](https://img.shields.io/badge/attribute-4f4f4f) hierarchical.logger

```
table: 
    The llloger instance being used for this module.
    See llloger module documentation.
``` 

# ![module](https://img.shields.io/badge/module-5663B3) PointCloudData.lua

Read a source location (a point-cloud) and convert its attribute to a
Lua object ofr easier manipulation by other modules.

## ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:new

```
Args :
    location(str): 
        scene graph location of the source.
    time(num):
        which time must the attribute be queried at.
Returns:
    table:
        PointCloudData class instance for the given location
``` 

## ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:set_logger_level

Change the logger level used for the module, and it's dependencies.
Default is `debug`.

```
Args :
    level(str): 
        log level to set
``` 

## ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.logger

```
table: 
    The llloger instance being used for this module.
    See llloger module documentation.
``` 

## ![class](https://img.shields.io/badge/class-6F5ADC) PointCloudData

The class with everything you will ever need (for instancing with KUI).
Use it by getting an instance from `PointCloudData:new` describe above.

The class instance is by default empty and must be initialized using `:build()`

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.time
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.location
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.common
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.sources
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.arbitrary
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.point_count
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.settings

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:build

Start processing the location and build all the attribute for later use.

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:get_instance_source_data

```
Args:
    pid(num):
         point index. Which point to use. !! starts at 0 !!
         
Returns:
    table:
        table from PointCloudData.sources.X
        {
          ["path(str)"]="scene graph location of the instance source",
          ["index(num)"]="index it's correspond to on the pointCloud, same as the parent key (indexN).",
          ["attrs(table)"] = "Group of local attribute from the instance source location to copy on the instance"
        }
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:is_point_hidden

Return false is the point at given index must not be created (hidden).
This is determined by using the <hide> token.

```
Args:
    pid(num):
         point index. Which point to use. !! starts at 0 !!
         
Returns:
      bool: 
        true if the point is hidden and thus should not be created
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:get_index_at_point

Return the instance source index used at the given point.

```
Args:
    pid(num):
         point index. Which point to use. !! starts at 0 !!
         
Returns:
      num: 
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:get_attr_value

Return the values for the given attribute name.
It can be a slice for the given pid, or the entire range of values.
The values have already been processed and is a DataAttribute instance except
if raw=true.

```
    Args:
      attr_name(str):
        name for the key to query.
        Can be one of <common>/<arbiratry> or just <sources>.

      pid(int or nil):
        point index: which point to use. If not specified return
        the whole table. !! starts at 0 !!

      raw(bool or nil):
        If true return the values as their corresponding DataAttribute instance.
        false by default (if nil)

    Returns:
      DataAttribute or table or nil:
        DataAttribute instance or nil if <attr_name> is empty (=false).
        table if <raw>=true
```

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-fcb434)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)
