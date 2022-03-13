--[[
version=9

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

local logging = require("lllogger")
local utils = require("kui.utils")

local logger = logging:get_logger("kui.PointCloudData")
logger:set_level("debug")
logger.formatting:set_tbl_display_functions(false)

-- we make some global functions local as this will improve performances in
-- heavy loops. Note: this is not that useful for PointCloudData
local tostring = tostring


local function set_logger_level(self, level)
  --[[
  Propagate the level to all modules too
  ]]
  logger:set_level(level)
  utils.logger:set_level(level)
end


--[[ __________________________________________________________________________
  API
]]


--[[
list of supported tokens with useful info used internally
<force_type==false or DataAttribute>
   force use of this type of DoubleAttribute for values.
<static==bool>
  true to "disable motio-blur" (use only time sample at 0.0)
]]
local Tokens = {
      ["list"] = {
        ["sources"]      = { ["force_type"]=StringAttribute, ["static"]=true },
        ["index"]        = { ["force_type"]=IntAttribute, ["static"]=true },
        ["skip"]         = { ["force_type"]=IntAttribute, ["static"]=true },
        ["hide"]         = { ["force_type"]=IntAttribute, ["static"]=true },
        ["matrix"]       = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["translation"]  = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["scale"]        = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["rotation"]     = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["rotationX"]    = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["rotationY"]    = { ["force_type"]=DoubleAttribute, ["static"]=false },
        ["rotationZ"]    = { ["force_type"]=DoubleAttribute, ["static"]=false }
      }
}
function Tokens:check_token(token)
  --[[
  Check if the given token is a valid token and if so return it without the $

  Args:
    token(str): string that should start with <$>
    source(str): scene graph location where this token is stored
  Returns:
    str: token without the <$>
  ]]
  for token_supported, _ in pairs(self.list) do
    -- add the <$> in font of the known token for comparison with the arg
    token_supported = utils:conkat("$", token_supported)
    -- if similar retur the arg token without the <$>
    if token_supported == token then
      return token:gsub("%$", "")
    end
  end

  utils:logerror(
    "[Tokens:check_token] Invalid token <",
      token,">."
  )

end


-- expected number of value per different attribute on source
local AttrGrp = {
  ["common"] = 3,
  ["arbitrary"] = 4,
  ["sources"] = 2,
  ["points"] = 2  -- not actually used
}


local BaseAttribute = {}
function BaseAttribute:new(parent, source_path, is_static)
  --[[

  Args:
    parent(PointCloudData):
    source_path(string): attribute path relative to parent's location
    static(true or nil): If true then "Disable motion-blur" for this attribute.

  Attributes:
    length(number):
      as the values attribute hold multiple time samples, it can be complex to
      simply get the number of values. Thta's why this attribute exists.
    static(bool or nil):
      If true return the default time sample 0.0 instead of a table of time samples.
  ]]

  local attrs = {
    ["parent"] = parent,
    ["path"] = source_path,
    ["class"] = false,
    ["tupleSize"] = false,
    ["length"] = false,
    ["values"] = false,
    ["static"] = is_static or false
  }

  function attrs:build()
    --[[
    Build self attributes.
    Require <parent> and <path> to be set.

    Only override <values> and <length> if it's already set. (not false)
    ]]

    local data = utils:get_attr_data(
      self.parent.location,
      self.path,
      error,
      self.static
    )  -- table

    self.class = self.class or data.class
    self.tupleSize = self.tupleSize or data.tuple
    self.length =  self.length
    self.values = self.values

  end

  function attrs:set_static(static)
    --[[

    If static=true then "Disable motion-blur" for this attribute.
     (Only the time sample 0.0 is used.)

    Recommended to set BEFORE calling build() to gain a maximum of performances

    Args:
      static(bool or nil):
    ]]
    self.static = static
  end

  function attrs:set_tuple_size(size)
    --[[
    Args:
      size(number):
    ]]
    self.tupleSize = tonumber(size)
  end

  function attrs:set_data_class(data_class)
    --[[
    Args:
      data_class(DataAttribute table): DataAttribute NOT instanced
    ]]
    self.class = data_class
  end

  function attrs:__value_get(pid, raw)
    --[[
    Return the values for this attribute.
    It can be a slice for the given pid, or the entire range of values.
    The returned values are a DataAttribute instance except if raw=true.
    If self.static=true only the time samples 0.0 will be returned.

    ! Must be loop safe.

    Args:

      pid(int or nil):
        point index: which point to use. If not specified return
        the whole table. !! starts at 0 !!

      raw(bool or nil):
        If true return the values as their corresponding DataAttribute instance.
        false by default (if nil)

    Returns:
      DataAttribute or table or nil:
        If a table is returned there is always at least the key <0.0>
        DataAttribute instance or nil if <attr_name> is empty (=false).
    ]]

    local buf
    local smplbuf

    if not self.values then
      return nil
    end

    -- no point specified, return all the values
    if pid == nil then

      smplbuf = self.values  -- table of time samples
      if self.static == true then
        smplbuf[0.0] = self.values[0.0]
      end

    -- else return a slice of the table
    else

      -- we can't filter the time samples AFTER as we would loss the performance
      -- improvement. So yeah a bit of duplicated code.
      if self.static == true then

        buf = {}
        -- grouping usually vary between 1 and 16(matrices), so small loop.
        for grpi=1, self.tupleSize do
          buf[#buf + 1] = self.values[0.0][self.tupleSize * pid + grpi]
        end

       smplbuf[0.0] = buf

      else
        -- process all time samples :
        smplbuf = {}
        for smpl, processedvalue in pairs(self.values) do

          buf = {}
          -- grouping usually vary between 1 and 16(matrices), so small loop.
          for grpi=1, self.tupleSize do
            buf[#buf + 1] = processedvalue[self.tupleSize * pid + grpi]
          end

          smplbuf[smpl] = buf

        end
      -- end if static
      end
    -- end if pid
    end

    if raw==true then
      return smplbuf
    else
      -- return as Katana DataAttribute, with the tuple size specified from grouping
      return self.class(smplbuf, self.tupleSize)
    end

  end

  function attrs:get_value_at(pid)
    --[[
    Returns a table of value at the given optional point index.
    Time sample 0.0 is at least present.
    ]]
    return self:__value_get(pid, true)
  end

  function attrs:get_data_at(pid)
    --[[
    Returns a DataAttribute instance at the given optional point index
    ]]
    return self:__value_get(pid, false)
  end

  return attrs

end

local function ArbitraryAttribute(parent, source_path, is_static)

  local inner = BaseAttribute:new(parent, source_path, is_static)

  function inner:set_additional_from_string(a_string)
    --[[
    To call before build() !

    Args:
      a_string(string): string representing a valid Lua table.
    ]]

    if not a_string then
      return
    end

    a_string = utils:logassert(
        loadstring(utils:conkat("return ", a_string)),
        "[PointCloudData][_build_arbitrary] Error while converting \z
        <instancing.data.arbitrary> additional column to Lua.",
        " Issue in: ",
        a_string
    )
    a_string = a_string()  -- this should be a table

    if a_string.multi_sampled then
      self.static = false
      a_string.multi_sampled = nil
    end

    self.additional = a_string

  end

  return inner

end

local function CommonAttribute(parent, source_path, is_static)

  local inner = BaseAttribute:new(parent, source_path, is_static)

  function inner:resize_tuple(new_size)
    --[[
    Remove new_si

    To execute after build() (we need <values>)

    Args:
      new_size(number): number of index per tuple to keep, cannot be bigger than
        the current tupleSize.
    ]]
    if not self.values then
      return
    end

    if new_size > self.tupleSize then
      utils:logerror("[CommonAttribute][resize_tuple] new_size<",new_size,
          "> can't be bigger than current tupleSize<", self.tupleSize, ">")
    end

    local samples = {}
    local newvalues

    local invalues = self:__value_get(nil, true)
    for smpl, oldvalues in pairs(invalues) do
      newvalues = {}
      for i=0, self.length / self.tupleSize - 1 do
        -- this will keep only the last item of the tuple
        for tuple_i=1, new_size do
          newvalues[#newvalues + 1] = oldvalues[i*self.tupleSize + tuple_i]
        end
      end
      samples[smpl] = newvalues
    end
    self.values = samples
    self.tupleSize = new_size

  end

  return inner

end

local function SourcesAttribute(parent, source_path)
  --[[
  List of instances sources locations with their associated index.

  beware of the 3 getter method returned values :
    - get_instance_source_data_at() :
        return a table of {"instance source location", "index", ...}
    - get_data_at() ; get_value_at() :
        return a list of `instance source` locations only

  Motion-blur is disabled.

  Note: Don't use <pid> with <__value_get()> as the values are not per-point.
  ]]

  local inner = BaseAttribute:new(parent, source_path, true)

  function inner:get_instance_source_data_at(pid)
    --[[
    Return the instance source location + index to use at given point index.
    Returns:
      table: {"instance source location", "index", [...]}
    ]]

    local sources = self:__value_get(nil, true)  -- table of time samples
    sources = sources[0.0]  -- motion blur is disabled for this one

    -- return a list of instance sources locations with indexes
    if not pid then
      return sources
    end

    -- else if pid return the instance source + index for the given point

    local index = self.parent:get_common_by_name("index"):get_value_at(pid)
    index = index[1] -- string

    for i=0, self.length / self.tupleSize - 1 do

      if index == sources[i*self.tupleSize + 2] then
        return {sources[i*self.tupleSize + 1], sources[i*self.tupleSize + 2]}
      end

    end

    -- if the function didn't return yet mean we didn't find an instance source
    utils:logerror("[SourcesAttribute][get_instance_source_data_at] Can't \z
    find an instance source for pid<", pid, "> from data=", sources)

  end

  -- override the methods

  function inner:get_value_at(pid)
    --[[
    Return the instance source location (only) to use at given point index.
    Returns:
      table: {"instance source location", [...]}
    ]]
    local out = {}
    local sources = self:get_instance_source_data_at(pid)
    -- filter to only keep locations
    for i=0, #sources / self.tupleSize - 1 do
      out[#out + 1] = sources[i * self.tupleSize + 1]
    end
    return out

  end

  function inner:get_data_at(pid)
    --[[
    Returns a StringAttribute instance at the given optional point index.
    The StringAttribute is an array of instances sources (without the index)
    ]]
    local out = self:get_value_at(pid)
    out = StringAttribute(out, 1)
    return out

  end

  return inner

end


local PointCloudData = {}
function PointCloudData:new(location)

  local attrs = {
  ["__attrdata"]=false,
  ["location"]=location,
  ["common"]={},
  ["arbitrary"]={},
  ["points"]=false,
  ["settings"] = {}
}

  -- build the common key with all the supported tokens
  for token_name, _ in pairs(Tokens.list) do
    attrs.common[token_name] = false
  end

  function attrs:_build_settings()
    --[[
    Build the <settings> keys.
    ]]

    local setting

    setting = utils:get_attr_value(
        self.location,
        "instancing.settings.convert_degree_to_radian",
        { 0 }
    ) -- type: table
    self.settings.convert_degree_to_radian = setting[1]

    setting = utils:get_attr_value(
        self.location,
        "instancing.settings.convert_trs_to_matrix",
        { 0 }
    ) -- type: table
    self.settings.convert_trs_to_matrix = setting[1]

    setting = utils:get_attr_value(
        self.location,
        "instancing.settings.enable_motion_blur",
        { 0 }
    ) -- type: table
    self.settings.enable_motion_blur = setting[1]

  end

  function attrs:_build_points()
  --[[
  Set the self.points.count attribute based on the point token submitted.
  ]]

  local data_points = utils:get_attr_value(
    self.location,
    "instancing.data.points",
    error
  ) -- table of 2 values, first is attribute location, second is tupleSize

  local points = utils:get_attr_value(
    self.location,
    data_points[1],
    error
  )

  self.points.count = #points / data_points[2]

  end

  function attrs:_build_common()
    --[[
    Build the <common> attribute.
    ]]
    local idata

    local token
    local path
    local tuplesize
    local attribute

    -- 1. Build <sources> token  ---------------------------------

    attribute = SourcesAttribute(
        self,
        "instancing.data.sources",
        Tokens.list.sources.static
    )
    attribute:build()
    self["common"]["sources"] = attribute


    -- 2. Build the other tokens --------------------------------------------
    -- get the attribute on the pc
    idata = utils:get_attr_value(
        self.location,
        "instancing.data.common",
        error
    )

    for i=0, #idata / AttrGrp.common - 1 do

      path = idata[AttrGrp.common*i+1]
      token = Tokens:check_token(idata[AttrGrp.common*i+2]) -- return without the "$" !
      tuplesize = idata[AttrGrp.common*i+3]
      if tuplesize == "" then
        tuplesize = -1
      else
        tuplesize = tonumber(tuplesize)
      end
      attribute = CommonAttribute(
          self,
          path,
          Tokens.list[token].static
      )
      attribute:build()

      -- -1 mean the tupleSize was not specified so let the one found by build
      if tuplesize ~= -1 then
        attribute:set_tuple_size(tuplesize)
      end

      -- for <index> and <skip> token, make sure to convert tuple to 1
      -- the last index from the group is used ({2,2,<2>})
      if token == "index" or token == "skip" then
        attribute:resize_tuple(1)
      end

      -- force some tokens with a pre-defined DataAttribute type.
      if Tokens.list[token].force_type then
        attribute:set_data_class(Tokens.list[token].force_type)
      end

      self["common"][token] = attribute

    end

    -- end _build_common
  end

  function attrs:_build_arbitrary()
      --[[
    Build the <common> attribute.
    ]]
    local idata

    local token
    local path
    local tuplesize
    local additional
    local attribute

    -- get the attribute on the pc
    idata = utils:get_attr_value(
        self.location,
        "instancing.data.arbitrary",
        false
    )

    if not idata then
      return
    end

    for i=0, #idata / AttrGrp.arbitrary - 1 do

      path = idata[AttrGrp.arbitrary*i+1]
      token = Tokens:check_token(idata[AttrGrp.arbitrary*i+2]) -- return without the "$" !
      tuplesize = idata[AttrGrp.arbitrary*i+3]
      if tuplesize == "" then
        tuplesize = -1
      else
        tuplesize = tonumber(tuplesize)
      end
      additional = idata[AttrGrp.arbitrary*i+4]
      attribute = ArbitraryAttribute(
          self,
          path,
          true
          -- all arbitrary attributes are NOT multi-sampled by default
          -- you need to specify it in additional if you want it
      )
      -- to execute before build() (set static)!
      attribute:set_additional_from_string(additional)
      attribute:build()
      -- -1 mean the tupleSize was not specified so let the one found by build
      if tuplesize ~= -1 then
        attribute:set_tuple_size(tuplesize)
      end

      -- force some tokens with a pre-defined DataAttribute type.
      if Tokens.list[token].force_type then
        attribute:set_data_class(Tokens.list[token].force_type)
      end

      self["common"][token] = attribute

    end

    -- end _build_common
  end

  function attrs:_validate()
    --[[
    To call after built operations.
    Verify that self table is properly built.
    Also clean the unusable attributes.
    TODO see if arbitrary is also needed to be validated
    ]]

    -- attr points must always exists
    if not self.points.count then
      utils:logerror(
          "[PointCloudData][_validate] points.count was not found for <",
          self.location,
          ">."
      )
    end

    -- we need at least one instance source
    if not self.common.sources then
      utils:logerror(
          "[PointCloudData][_validate] No instance sources specified \z
           for location <",
          self.location,
          ">."
      )
    end

    -- instance sources index must start at 0
    -- TODO update get_index once finished
    if self.common.sources:get_index("0") == nil then
      utils:logerror(
        "[PointCloudData][_validate] No index 0 found on <common.sources> attribute."
      )
    end

    -- every instance source need the index to be declared
    -- TODO update once SourcesAttribute finished
    for _, isource_data in ipairs(self.sources) do
      if not isource_data["index"] then
        utils:logerror(
            "[PointCloudData][_validate] No index specified for \z
            instance source <",
            self.isource_data["path"],
            "> for source location <",
            self.location,
            ">."
        )
      end
    end

    -- it's best to only specify one if needed, warn user
    if self.common.hide and self.common.skip then
      logger:warning(
          "[PointCloudData][_validate] Source <", self.location,
          "> declare a <$hide> token but also the <$skip> one.\z
           In that case $hide will override $skip."
      )
    end

    -- there is no point to have the matrix token + one of the trs so warn
    -- and reset the trs attributes
    if self.common.matrix and (
        self.common.translation or
        self.common.rotation or
        self.common.scale or
        self.common.rotationX
    ) then
      logger:warning(
          "[PointCloudData][_validate] Source <", self.location,
          "> declare a $matrix token but also one of the trs. In that case \z
           $matrix take the priority."
      )
      self.common.translation = false
      self.common.rotation = false
      self.common.scale = false
      self.common.rotationX = false
      self.common.rotationY = false
      self.common.rotationZ = false
    end
    if self.common.matrix and self.settings.convert_trs_to_matrix ~= 0 then
      self.settings.convert_trs_to_matrix = 0
      logger:warning(
        "[PointCloudData][_validate] Source <", self.location,
        "> declare a $matrix token but also ask to convert TRS to matrix. \z
         <convert_trs_to_matrix> is as such disabled"
      )

    end

    -- verify that if one rotationX/Y/Z is declared, all other 2 also are
    if not (
        self.common.rotationX and
        self.common.rotationY and
        self.common.rotationZ
    ) then
      if (
          self.common.rotationX or
          self.common.rotationY or
          self.common.rotationZ
      ) then
        utils:logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> doesn't have all the <rotationX/Y/Z> tokens declared \z
          (but declare currently at least one)."
        )
      end
    end

    -- verify that if $rotation is declared no rotationX/Y/Z is also declared
    if self.common.rotation and (
        self.common.rotationX or
        self.common.rotationY or
        self.common.rotationZ
    ) then
      logger:warning(
          "[PointCloudData][_validate] Source <", self.location,
          "> declare a rotation token but also one of the $rotationX/Y/Z.\z
           In that case $rotation take the priority."
      )
    end

    -- verify grouping values
    if self.common.rotation then
      if self.common.rotation.grouping ~= 3 then
        utils:logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $rotation token only accepts 3 as grouping, not ",
          self.common.rotation.grouping
        )
      end
    end
    if self.common.matrix then
      if self.common.matrix.grouping ~= 16 then
        utils:logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $matrix token only accepts 16 as grouping, not ",
          self.common.matrix.grouping
        )
      end
    end
    if self.common.translation then
      if self.common.translation.grouping ~= 3 then
        utils:logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $translation token only accepts 3 as grouping, not ",
          self.common.translation.grouping
        )
      end
    end

    -- check per-point tokens have the good "shape"
    -- TODO update this
    local attrlength
    for attrname, attrdata in pairs(self.common) do
      -- attrdata can be <false> if not built so skip if so, I wish lua has a
      -- "continue" keyword like in python !
      -- also skip if the token is skip (doesn't have per-point value)
      if attrdata and attrname ~= "skip" then
        --we check first that the <grouping> and <points> attribute seems valid
        attrlength = #(attrdata.values) / attrdata.grouping
        if attrlength ~= self.point_count then
          utils:logerror(
          "[PointCloudData][_validate] Common attribute <", attrname,
          "> as an odd number of values : ", tostring(#(attrdata.values)),
          " / ", tostring(attrdata.grouping), " = ", attrlength,
          " while point_count=", self.point_count
          )
        end
        -- end if attrdata is not false/nil
      end
      -- end for attrname, attrdata
    end

    -- end for _validate()
  end

  function attrs:build()

    -- query data on source to build self
    self:_build_settings()
    self:_build_points()

    self:_build_common()
    self:_build_arbitrary()

    -- check that the data queried above is valid
    self:_validate()

  end

  function attrs:get_common_by_name(name)
  end

  function attrs:get_commons()
  end

  function attrs:get_arbitrary()
  end

  logger:debug(
      "[PointCloudData][new] Finished for location <",
      location,
      ">"
  )

  return attrs

end

PointCloudData["logger"] = logger -- for external modif
PointCloudData["set_logger_level"] = set_logger_level -- for external modif

return PointCloudData