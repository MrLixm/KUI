--[[
version=6

[LICENSE]

Copyright 2022 Liam Collod

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]
local _M_ = {}
local logging = require("lllogger")
local logger = logging.getLogger(...)


--[[ __________________________________________________________________________
  LUA UTILITIES
]]

-- we make some global functions local as this will improve performances in
-- heavy loops.
local tostring = tostring
local select = select
local tableconcat = table.concat
local mathpi = math.pi
local mathabs = math.abs
local type = type

function _M_:conkat(...)
  --[[
  The loop-safe string concatenation method.
  ]]
  local buf = {}
  for i=1, select("#",...) do
    buf[ #buf + 1 ] = tostring(select(i,...))
  end
  return tableconcat(buf)
end

function _M_:logerror(...)
  --[[
  log an error first then stop the script by raising a lua error()

  Args:
    ...(any): message to log, composed of multiple arguments that will be
      converted to string using tostring()
  ]]
  local logmsg = self:conkat(...)
  logger:error(logmsg)
  error(logmsg)

end

function _M_:logassert(toassert, ...)
  --[[
  Check is toassert is true else log an error.

  Args:
    ...(any): arguments used for log's message. Converted to string.
  ]]
  if not toassert then
    self:logerror(...)
  end
  return toassert
end

--[[ __________________________________________________________________________
  Katana UTILITIES
]]


local function _get_attribute_class(kattribute)
  --[[
  Returned a non-instanced version of the class type used by the given arg.

  Args:
    kattribute(IntAttribute or FloatAttribute or DoubleAttribute or StringAttribute)
  Returns:
    table: DataAttribute
  ]]
  if Attribute.IsInt(kattribute) == true then
    return IntAttribute
  elseif Attribute.IsFloat(kattribute) == true then
    return FloatAttribute
  elseif Attribute.IsDouble(kattribute) == true then
    return DoubleAttribute
  elseif Attribute.IsString(kattribute) == true then
    return StringAttribute
  else
    _M_:logerror(
      "[_get_attribute_class] passed attribute <",
      kattribute,
      ">is not supported."
    )
  end
end


local function _get_attr_data(location, attr_path, static)
  --[[
  Get the given attribute on the location.
  Return it as a lua table describing the DataAttribute structure it had.

  Args:
    location(str): scene graph location to extract teh attribute from
    attr_path(str): path of the attribute on the location
    static(bool or nil): if false the attribute is multi-sampled
  Returns:
    table or nil:
      table[class] = DataAttribute class not instanced
      table[tuple] = num, tuple size of the orignal DataAttribute
      table[values] = table of values with time samples
      table[length] = number of values in each values' key time-sample
  ]]

  local lattr = Interface.GetAttr(attr_path, location)
  if not lattr then
    return nil
  end

  local out = {}
  local values = {}
  out["class"] = _get_attribute_class(lattr)
  out["tuple"] = lattr:getTupleSize()
  out["length"] = lattr:getNumberOfValues()

  if static then
    values[0.0] = lattr:getNearestSample(0)
  else
    for smplindex=0, lattr:getNumberOfTimeSamples() - 1 do
      smplindex = lattr:getSampleTime(smplindex)
      values[smplindex] = lattr:getNearestSample(smplindex)
    end
  end

  out["values"] = values

  return out

end


-- PUBLIC -----------------


function _M_:get_attr_data(location, attr_path, default, static)
  --[[
  Get the given attribute on the location.
  Return it as a lua table describing the DataAttribute structure it had.

  Supports motion-blur if static=false or nil.

  Args:
    location(str): scene graph location to extract teh attribute from
    attr_path(str): path of the attribute on the location
    default(any or error): value to return if attr_path not found
      you can use the <error> builtin to raise an error instead
    static(bool or nil): if true only query time sample 0 (no motion blur)
  Returns:
    table or nil:
      table[class] = DataAttribute class not instanced
      table[tuple] = num, tuple size of the orignal DataAttribute
      table[values] = table of values with time samples
      table[length] = number of values in each values' key time-sample
  ]]

  local out = _get_attr_data(location, attr_path, static)

  if not out then

    if default==error then
      self:logerror(
          "[utils][get_attr_data] location <",
          location,
          "> doesn't have the attr_path <",
          attr_path,
          ">."
      )
    else
      return default
    end

  end

  return out

end


function _M_:get_attr_value(location, attr_path, default)
  --[[
  Get the given attribute value on the location.
  Queried attribute is not multi-sampled and only it's value is returned
  compared to using <get_attr_data()>.

  Args:
    location(str): scene graph location to extract teh attribute from
    attr_path(str): path of the attribute on the location
    default(any or error): value to return if attr_path not found
      you can use the <error> builtin to raise an error instead
  Returns:
    any or nil: type depends of original data queried
  ]]
  local out = _get_attr_data(location, attr_path, true)

  if not out then

    if default==error then
      self:logerror(
          "[utils][get_attr_data] location <",
          location,
          "> doesn't have the attr_path <",
          attr_path,
          ">."
      )
    else
      return default
    end

  end

  out = out["values"][0.0]
  return out

end


function _M_:get_user_attr(name, default_value)
    --[[
    Return an OpScipt user attribute.
    If not found return the default_value. (unless asked to raise an error)

    Args:
        name(str): attribute location (don't need the <user.>)
        default_value(any): value to return if user attr not found
          you can use the <error> builtin to raise an error instead
    Returns:
        table or any: table of value on attribute or default value
    ]]
    local argvalue = Interface.GetOpArg(self:conkat("user.",name))

    if argvalue then
      return argvalue:getNearestSample(0)

    elseif default_value==error then
      self:logerror("[get_user_attr] user attribute <",name,"> not found.")

    else
      return default_value

    end

end


-- TODO see if the bottom method need to be deleted
function _M_:slice_attribute(attr, at_index, usearray)
  --[[
  From the given DataAttribute return itself but with just the values at the
  specified tuple index. This means getNumberOfValues==getTupleSize.

  Support multiple time samples.
  Expensive method, and ~ 75% slower if usearray==true

  Args:
    attr(DataAttribute): DataAttribute instance
    at_index(num): starts at 0. Index of the tuple to return
    usearray(bool or nil): if true use an Array instance instead of a DataAttribute one.

  Returns:
    DataAttribute: same DataAttribute as attr arg except with only the value asked.
  ]]
  local out = {}
  local buf
  local array
  local class = self:get_attribute_class(attr)

  if at_index > attr:getNumberOfTuples() then
    self:logerror(
        "[slice_attribute] at_index arg <",
        at_index,
        "> specified for attr is not valid: should be inferior to",
        attr:getNumberOfTuples()
    )
  end

  if usearray then

    for _, smpl in ipairs(attr:getSamples()) do

      buf = {}
      array = smpl:toArray()
      for i=0, attr:getTupleSize() - 1 do
        buf[#buf+1] = array:get(at_index + i)
      end

      out[smpl:getSampleTime()] = buf

    end

  else

    for smplindex=0, attr:getNumberOfTimeSamples() - 1 do
      buf = {}
      smplindex = attr:getSampleTime(smplindex)
      array = attr:getNearestSample(smplindex)

      for i=1, attr:getTupleSize() do
        buf[#buf+1] = array[at_index + i]
      end

      out[smplindex] = buf

    end

  end

  out = class(out, attr:getTupleSize())
  return out

end


function _M_.degree_to_radian(rotation)
  --[[
  Args:
    rotation(num): rotation value to convert to radian
  Returns:
    num:
      rotation value converted to radian
  ]]
  return rotation * (mathpi/180.0)
end


function _M_.radian_to_degree(radian)
  --[[
  Args:
    radian(num): radian value to convert to degree
  Returns:
    num:
      radian value converted to degree
  ]]
  return radian * (180.0/mathpi)
end


function _M_.get_katana_version()
  --[[
  Returns:
    num:
      Katana version as a float number like 451.00008
  ]]

  local version = Config.Get("KATANA_VERSION") -- "4.5.1.000008"
  version = version:gsub("%.", "", 2)
  version = tonumber(version)
  return version

end


function _M_:get_nearest_from_samples(samples, nearest)
  --[[
  Source: https://stackoverflow.com/a/5464961/13806195

  Args:
    samples(table): tables of samples like {-0.25:..., 0.0: ..., ...}
    nearest(number): time samples as float to return the closest sample from

  Returns:
    number: sample in <samples> closest to given <nearest>
  ]]

  local smallestSoFar

  for sample, _ in pairs(samples) do

      if not smallestSoFar or
      (mathabs(nearest - smallestSoFar) > mathabs(sample - nearest)) then
          smallestSoFar = sample
      end

  end

  return smallestSoFar

end

function _M_:get_samples_list_from(...)
  --[[
  Args:
    ...(table(s) or nil): multiple tables of time samples

  Returns:
    table: ordered table of unordered time samples like {0.0, -0.25, 0.25}
  ]]

  local samples_list = {}  -- unordered table to avoid duplicate in <out>
  local out = {}
  local t

  for i=1, select("#",...) do

    t = select(i,...)

    if t and type(t)=="table" then

      for smpl, _ in pairs(t) do
        if not samples_list[smpl] then
          samples_list[smpl] = true
          out[#out+1] = smpl
        end
      end

    end

  end

  return out

end


function _M_:path_rel_to_abs(rel_path, source_path)
  --[[
  Args:
    rel_path(string): relative path starting (or not) with dot(s)
    source_path(table): ordered table of strings
  Returns:
    string: rel_path turned to an absolute path based on source_path.
  ]]

  local match = rel_path:match("^(%.+)")
  if not match then
    return rel_path
  end

  local out = {}

  for i=1, #source_path - (#match - 1) do
    out[#out+1] = source_path[i]
  end
  -- delete the relatives dot found while adding
  out[#out+1] = rel_path:gsub(("^%s"):format(match), "")
  return tableconcat(out, ".")
end

return _M_