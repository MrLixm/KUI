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

## ![method](https://img.shields.io/badge/method-4f4f4f) array.run

Read the user argument and create an instance-array location.


# ![module](https://img.shields.io/badge/module-5663B3) boxCulling.lua

_Not implemented yet._

# ![module](https://img.shields.io/badge/module-5663B3) hierarchical.lua

As hierarchical create several locations, the script can be dividided in
2 parts for performances optimization. When the OpScript is evaluating
the current location (at root), we create all the children location and store them.
And then the part where the OpScript is running on every child created, where
we just set its attributes (not at root). 

## ![method](https://img.shields.io/badge/method-4f4f4f) hierarchical.atroot

Read the user argument and pre-create the hierarchical children location.
95% of the work is done here. To run first.

## ![method](https://img.shields.io/badge/method-4f4f4f) hierarchical.run_not_root

For each child created, just set its attributes defined in the previous method
run_root(). It is not recommened to log anything here as this method
will be repeated times the number of child created.


# ![module](https://img.shields.io/badge/module-5663B3) PointCloudData.lua

Read a source location (a point-cloud) and convert its attribute to a
Lua object ofr easier manipulation by other modules.

## ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData:new

```
Args :
    location(str): 
        scene graph location of the source.
Returns:
    table:
        PointCloudData class instance for the given location
``` 

## ![class](https://img.shields.io/badge/class-6F5ADC) PointCloudData.PointCloudData

The class with everything you will ever need (for instancing with KUI).
Use it by getting an instance from `PointCloudData:new` describe above.

The class instance is by default empty and must be initialized using `:build()`

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.PointCloudData.location
> `string`
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.PointCloudData.common
> `table of string`
```
{
    "token name": CommonAttribute,
    ...
}
```

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.PointCloudData.arbitrary
> `table of string`
```
{
    "target attribute location": ArbitraryAttribute,
    ...
}
```

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.PointCloudData.points
> `table of string`
```
{
    "count": number
}
```

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.PointCloudData.settings
> `table of string`
```
{
    "convert_degree_to_radian": 0 or 1,
    "convert_trs_to_matrix": 0 or 1,
    "enable_motion_blur": 0 or 1,
}
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.PointCloudData:build

Start processing the location and build all the attribute for later use.

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.PointCloudData:get_common_by_name

```
Args:
    name(string):
         name of the common attribute to get
         
    Returns:
      BaseAttribute or nil: nil if not found
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.PointCloudData:is_point_hidden

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

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.PointCloudData:get_commons

```
Returns:
      table of CommonAttribute:
       unordered table of CommonAttribute with key=attribute name, value=CommonAttribute
```

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.PointCloudData:get_arbitrary

Same as above but return ArbitraryAttribute instead of CommonAttribute

## ![class](https://img.shields.io/badge/class-6F5ADC) PointCloudData.BaseAttribute

Base class for attributes manipulation. Values are usually stored per point
at each time samples. Basically we could say this converts a scene graph
location attribute to a Lua standard object for easy manipulation.

Must be subclassed for use.

```
Args:
    parent(PointCloudData):
    source_path(string): attribute path relative to parent's location
    static(true or nil): If true then "Disable motion-blur" for this attribute.
```

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.parent
> `PointCloudData`
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.path
> `string` attribute path relative to parent's location
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.class
> `DataAttribute` class to use when instancing back the lua table to use in Interface.SetAttr()
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.tupleSize
> `number`  number of value belonging to the same "group". Ex: 3 is commonly used for x-y-z values.
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.length
> `number` as the values attribute hold multiple time samples, it can be complex to
simply get the number of values. Thta's why this attribute exists.

### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.values
> `table`  unordered table of time samples with their corresponding table of values
> 
> Not recommended to be use directly. Use one of the method like `get_value_at` or `set_values`
### ![attribute](https://img.shields.io/badge/attribute-4f4f4f) PointCloudData.BaseAttribute.static
> `boolean`  If true return the default time sample 0.0 instead of a table of time samples.

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:build

Query the attribute from `path` on the `parent` location and then set attributes
using the result.

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:new
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:rescale_points
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:set_static
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:set_tuple_size
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:set_values
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:set_data_class
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:get_value_at
### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.BaseAttribute:get_data_at

## ![function](https://img.shields.io/badge/function-6F5ADC) PointCloudData.CommonAttribute

Return a subclass of BaseAttribute

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.CommonAttribute:resize_tuple


## ![function](https://img.shields.io/badge/function-6F5ADC) PointCloudData.SourcesAttribute

Return a subclass of CommonAttribute

List of instances sources locations with their associated index + source attributes
Require the `common.index` token to be build on the PointCloudData parent

beware of the 3 getter method returned values :
- `get_instance_source_data_at()`: return a table like
```
{"instance source location", "index", DataAttribute("source attributes")...}
```

- `get_data_at()` ; `get_value_at()` : return a list of `instance source`
locations only

Motion-blur is disabled. (hardcoded)

`self.values` is an ordered table of successing instance source location, 
corresponding index, and source attributes like 
`{"/root/A", 0, GroupAttribute(...), "/root/B", 1, GroupAttribute(...), ...}`


### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.SourcesAttribute:get_source_at

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.SourcesAttribute:get_instance_source_data_at

## ![function](https://img.shields.io/badge/function-6F5ADC) PointCloudData.ArbitraryAttribute

Return a subclass of BaseAttribute

### ![method](https://img.shields.io/badge/method-4f4f4f) PointCloudData.ArbitraryAttribute:set_additional_from_string

---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-4f4f4f)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-fcb434)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)
