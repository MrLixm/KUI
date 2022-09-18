# Manual Source Configuration

[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-fcb434)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)


The order of operation is as follows :

- Create supported attributes on the instancing source (pointcloud).
- Create the OpScript to read the source and produce the instances.


## 1. Source attribute configuration

The script is able to support a lot of point-cloud configurations thanks to
pre-defined attributes that must be created on the source location 
(the point-cloud) :

- `instancing.data.points` (string array)
  - `[1*n]` = path to the attribute to use to determine number of points.
  - `[2*n]` = tuple size (how many values correspond to one point).
- `instancing.data.sources` (string array) :
  - `[1*n]` = instance source location.
  - `[2*n]` = instance source index.
- `instancing.data.common` (string array) :
  These attributes are the most common ones like rotation, matrix, scale, ...
  - `[1*n]` = attribute path relative to the source.
  - `[2*n]` = token to specify what kind of data [1] corresponds to.
  - `[3*n]` = tuple size : how many values belongs to an individual point.
- `instancing.data.arbitrary` (string array) :
  Only you know why this attribute will be useful, they will just be transfered
  to the instance for whatever you need them for.
  - `[1*n]` = attribute path relative to the source.
  - `[2*n]` = target attribute path relative to the instance.
  - `[3*n]` = tuple size : how many values belongs to an individual point.
  - `[4*n]` = (optional) additional attributes that must be created on instance. Must be a valid Lua table.

*See under for detailed explanations.*


### instancing.data.points

Give an attribute that will be used to determine the number of unique points.

```lua
point_count = #points_attr / tupleSize
```

### instancing.data.sources

![attribute set screenshot for instancing.data.sources](./img/config.sources.png)

#### column 1

Instance Source's scene graph location to use.

#### column 2 
Instance Source's corresponding index.

> **Index is excepted to start at 0** (important for the `array` method)


### instancing.data.common

![attribute set screenshot for instancing.data.common](./img/config.common.png)

List of supported tokens for column `[2]`
```
$index
$skip
$hide
$matrix
$scale
$translation
$rotation
$rotationX
$rotationY
$rotationZ
```

#### index

>`tupleSize` can be any (expected to be usually 3 or 1 though).
> 
> _(Values are anyway converted to `tupleSize=1` internally )_

**Index is excepted to start at 0** (important for the `array` method)

If you need to offset the index it is recommended to use an OpScript on
the attribute before the KUI instancer. Have a look at 
[attrMath](https://github.com/MrLixm/Foundry_Katana/tree/main/src/attributes/attrMath)
for this.



#### skip


>`tupleSize` can be any. (expected to be usually 3 or 1 though).
> 
> _(Values are anyway converted to `tupleSize=1` internally )_

List of points index to skip (don't render). 
For *hierarchical* the instance location is just not generated while for
*array* the values are copied to the `geometry.instanceSkipIndex` attribute.


#### hide

>`tupleSize` must be 1.

Table where each index correspond to a point and the value wheter it's hiden
or not. Where `1=hidden`, `0=visible`. Similar to `$skip` but have a value for every
point.


#### matrix

>`tupleSize` must be 16 (4*4 matrix).

Specify translations, rotations and scale in one attribute.

If specified, take priority over all the other transforms attributes.


#### scale

>`tupleSize` can be any. #TODO should be 3 ?

Source attribute is expected to store values in X-Y-Z order.


#### translation

>`tupleSize` must be 3.

Source attribute is expected to store values in X-Y-Z order.

You can of course specify the same attribute used for `$points`.


#### rotation

>`tupleSize` must be 3 .

Source attribute is expected to store values in X-Y-Z order.
Values are excepted to be in degree. See 
[instancing.settings.convert_degree_to_radian](#instancingsettingsconvert_degree_to_radian) .

When the `$rotation` token is declared, it is always internally converted 
to individual `$rotationX/Y/Z` attributes. These new attributes also specify
the axis which is assumed to be by default :
```lua
axis = {
    x = {1,0,0},
    y = {0,1,0},
    z = {0,0,1}
}
```
If you'd like to change the axis you have to use the `$rotationX/Y/Z` tokens.


#### rotation X/Y/Z

>`tupleSize` can only be 4 :

Values on source attributes are excepted to be as : `rotation value, X axis, Y axis, Z axis.`

The `$rotation` token, if specified, take over the priority on these one.


### instancing.data.arbitrary

![attribute set screenshot for instancing.data.arbitrary](./img/config.arbitrary.png)


#### column 4

> **Warning** You must know that this parameter has a potential security flaw as everything
inside is compiled to Lua code using `loadstring("return "..content)` where
`content` is the string submitted.

Arbitrary attributes might require to not only set the value but also its
`scope`,  `inputType`, ... attributes. To do so you can provide a
Lua-formatted table that describe how they must be created :

```lua
{ ["target path"]=DataAttribute(value), ... }
```

Here is an example for an arbitrary `geometry.arbitrary.randomColor.value` attribute:
```lua
{
    ["geometry.arbitrary.randomColor.inputType"]=StringAttribute("color3"),
    ["..scope"]=StringAttribute("primitive"),
}
```

You can notice the weird syntax of the second key. Relative path are supported
to specify your attribute path _(relative to the target attribute path (column 2))_ .
Each dot represent the current attribute level for the column 2 so in our case
, two `..` means "go one level up" which means `geometry.arbitrary.randomColor`.
Putting 3 dots `...` would resolve to `geometry.arbitrary` in our case.

Arbitrary attributes are not multi-sampled by default. If you need to have
it multi-sampled you can specify it in this column by adding a `multi_sampled` 
key with any non-nil value like :

```lua
{
  ["multi_sampled"]=true
}
```

Arbitrary attributes are considered as per-point by default. (a different tuple
 of value for each instance/point). If that's not the case you can specify it in
this column by adding a `not_per_point` key with any non-nil value like :

```lua
{
  ["not_per_point"]=true
}
```

### instancing.settings

#### instancing.settings.convert_degree_to_radian

- (optional)(int) : 
  - `0` to disable any conversion.  
  - `1` to convert degree to radian.
  - `-1` to convert radian to degree.
  
Internally the conversion is applied only on the `processed`'s key values and
happens **after** the initial values have been _multiplied/offseted_.

#### instancing.settings.convert_trs_to_matrix

- (optional)(int) : 
  - `0` to disable any conversion.  
  - `1` to convert trs attributes to a 4x4 matrix

If enabled, the `translation`, `rotationX/Y/Z` and `scale` attributes 
are converted to a 4x4 identity matrix (the `matrix` attribute.). Make sure 
at least one of the TRS attribute is specified. 

The rotations values are excepted to be degree. Use 
`instancing.settings.convert_degree_to_radian=-1` if that's not the case.

For motion-blur, the list of time samples are computed from the `translation`
or `rotationX` or `scale` token. The biggest list of time-samples from the 3
is used.


#### instancing.settings.enable_motion_blur

- (optional)(int) : 
  - `0` to disable motion-blur support.  
  - `1` to enable motion blur support (reading multiple time samples on attributes)

If the original attributes have time samples, disabling this (0) can make the
instancing processing a bit faster but will of course disable motion-blur.

## 2. OpScript

To configure on the OpScript node. Configuration change depending on the 
instancing method. 

### Hierarchical

Use the file [kuiinstancer-hiera.lua](../resources/CustomNodes/KuiLib/kuiinstancer-hiera.lua)
in the `script.lua` parameters.

- `location` = target group location for instances 
- `applyWhere` = at specific location

#### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)

#### `user.instance_name`

Naming template used for instances. 3 tokens available :

- `$id` _(mandatory)_: replaced by point number
  - can be suffixed by a number to add a digit padding, ex: `$id3` can give `008`
- `$sourcename` : basename of the instance source location used
- `$sourceindex` : index attribute that was used to determine the instance
source to pick.

#### `user.log_level`

Logging level to use. Availables are `DEBUG, INFO, WARNING, ERROR`.

### Array

Use the file [kuiinstancer-array.lua](../resources/CustomNodes/KuiLib/kuiinstancer-array.lua)
in the `script.lua` parameters.

- `location` = target location for the instance array location (include its name)
- `applyWhere` = at specific location

#### `user.pointcloud_sg`

Scene graph location of the source (pointcloud)

#### `user.log_level`

Logging level to use. Availables are `DEBUG, INFO, WARNING, ERROR`.


---
[![root](https://img.shields.io/badge/back_to_root-536362?)](../README.md)
[![INDEX](https://img.shields.io/badge/index-4f4f4f?labelColor=blue)](INDEX.md)
[![CONFIG_NODE](https://img.shields.io/badge/config--node-4f4f4f)](CONFIG_NODE.md)
[![CONFIG_MANUAL](https://img.shields.io/badge/config--manual-fcb434)](CONFIG_MANUAL.md)
[![CULLING](https://img.shields.io/badge/culling-4f4f4f)](CULLING.md)
[![API](https://img.shields.io/badge/api-4f4f4f)](API.md)
[![DEVELOPER](https://img.shields.io/badge/developer-4f4f4f)](DEVELOPER.md)


