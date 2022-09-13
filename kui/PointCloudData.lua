--[[
version=13

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

local logger = logging.getLogger(...)
logger.formatting:set_tbl_display_indexes(true)

-- we make some global functions local as this will improve performances in
-- heavy loops. Note: this is not that useful for PointCloudData
local tostring = tostring
local mathfloor = math.floor


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
    token_supported = utils.conkat("$", token_supported)
    -- if similar retur the arg token without the <$>
    if token_supported == token then
      return token:gsub("%$", "")
    end
  end

  utils.logerror(
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
  Base class for attributes manipulation. Values are usually stored per point
  at each time samples. Basically we could say this converts a scene graph
  location attribute to a Lua standard object for easy manipulation.


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
    values(table):
      unordered table of time samples with their corresponding table of values
  ]]

  local attrs = {
    ["perPoint"] = true,
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

    local data = utils.get_attr_data(
      self.parent.location,
      self.path,
      error,
      self.static
    )  -- table

    self.class = self.class or data.class
    self.tupleSize = self.tupleSize or data.tuple
    self:set_values(data.values)

  end

  function attrs:rescale_points(pcount)
    --[[
    Remove points from the internal value table.

    Args:
      pcount(number): number of point to keep (a point = a tuple)
    ]]

    if not self.perPoint then
      return
    end

    if pcount * self.tupleSize == self.length then
      return
    end

    local values_all = self:__value_get(nil, true, nil)

    -- iterate through samples
    for _, sv in pairs(values_all) do

      for i=#sv, 1, -1 do

        if i == pcount * self.tupleSize then
          break
        end

        sv[i] = nil

      end

      self.length = #sv

    end

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

    -- check the given size is plausible
    if self.length then
      local d = self.length / size
      if mathfloor(d) ~= d then
        utils.logerror("[BaseAttribute][",self.path,"][set_tuple_size] Given \z
        size <", size, "> is not valid. (", self.length, "/size ~=int)")
      end
    end

    self.tupleSize = tonumber(size)

  end

  function attrs:set_values(values)
    --[[
    Args:
      values(table): unordered tables of time samples of values
    ]]
    self.values = values
    for _, v in pairs(values) do
      self.length = #v
      break -- we only need to do that on the first sample found
    end
  end

  function attrs:set_data_class(data_class)
    --[[
    Args:
      data_class(DataAttribute table): DataAttribute NOT instanced
    ]]
    self.class = data_class
  end

  function attrs:__value_get(pid, raw, nearest_sample)
    --[[
    Return the values for this attribute.
    It can be a slice for the given pid, or the entire range of values.
    The returned values are a DataAttribute instance except if raw=true.
    If self.static=true only the time samples 0.0 will be returned.

    !! Must be loop safe. !!

    Args:

      pid(int or nil):
        point index: which point to use. If not specified return
        the whole table. !! starts at 0 !!

      raw(bool or nil):
        If true return the values as their corresponding DataAttribute instance.
        false by default (if nil)

      nearest_sample(number or nil): instead of returning a table of samples,
        return just the time sample values closest to this.

    Returns:
      DataAttribute: if <raw>=false
      table: of time samples with at least 0.0 if not <nearest_sample>
      table: of values if <nearest_sample>
      nil: if <attr_name> is empty (=false).
    ]]

    local buf
    local smplbuf

    if not self.values then
      return nil
    end

    -- we can't get a slice at the given point if the attribute is not perPoint !
    if not self.perPoint then
      pid = nil
    end

    -- no point specified, return all the values
    if pid == nil then

      smplbuf = self.values  -- table of time samples
      if self.static == true then
        smplbuf[0.0] = self.values[0.0]
      end

      if nearest_sample then
        smplbuf = smplbuf[utils:get_nearest_from_samples(smplbuf, nearest_sample)]
      end

    -- else return a slice of the table
    else

      -- first check if we need to process multiple time samples
      -- we can't filter the time samples AFTER as we would loss the performance
      -- improvement. So yeah a bit of duplicated code.
      if self.static == true then

        buf = {}
        -- grouping usually vary between 1 and 16(matrices), so small loop.
        for grpi=1, self.tupleSize do
          buf[#buf + 1] = self.values[0.0][self.tupleSize * pid + grpi]
        end

        if nearest_sample then
          smplbuf = buf
        else
          smplbuf = {}
          smplbuf[0.0] = buf
        end

      -- process time sample(s) for the given pid
      else


        -- process only sample nearest to given one
        if nearest_sample then

          local closest_smpl
          closest_smpl = utils:get_nearest_from_samples(self.values, nearest_sample)

          smplbuf = {}

          buf = self.values[closest_smpl]
          for grpi=1, self.tupleSize do
            smplbuf[#smplbuf + 1] = buf[self.tupleSize * pid + grpi]
          end

        -- process all time samples :
        else

          smplbuf = {}

          for smpl, processedvalue in pairs(self.values) do

            buf = {}
            -- grouping usually vary between 1 and 16(matrices), so small loop.
            for grpi=1, self.tupleSize do
              buf[#buf + 1] = processedvalue[self.tupleSize * pid + grpi]
            end

            smplbuf[smpl] = buf

          end

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

  function attrs:get_value_at(pid, nearest_sample)
    --[[
    Returns a table of value at the given optional point index.
    Time sample 0.0 is at least present or the time sample nearest to the given
    <nearest_sample> is returned.

    Returns:
      table: of time samples with at least 0.0 if not <nearest_sample>
      table: of values if <nearest_sample>
      nil: if <attr_name> is empty (=false).

    ]]
    return self:__value_get(pid, true, nearest_sample)
  end

  function attrs:get_data_at(pid, nearest_sample)
    --[[
    Returns a DataAttribute instance at the given optional point index
    Time sample 0.0 is at least present or the time sample nearest to the given
    <nearest_sample> is returned.

    Returns:
      DataAttribute: of time samples with at least 0.0 if not <nearest_sample>
      DataAttribute: of values if <nearest_sample>
      nil: if <attr_name> is empty (=false).

    ]]
    return self:__value_get(pid, false, nearest_sample)
  end

  return attrs

end

local function ArbitraryAttribute(parent, source_path, is_static)

  local inner = BaseAttribute:new(parent, source_path, is_static)

  -- consider by default as perPoint. The user have to specify the contrary
  -- in the bottom additional attribute.
  inner.perPoint = true

  function inner:set_additional_from_string(add_obj, target_attr_path)
    --[[
    To call before build() !

    Args:
      a_string(string): string representing a valid Lua table.
    ]]

    if not add_obj or add_obj =="" then
      return
    end

    -- 1. convert string to table
    add_obj = utils.logassert(
        loadstring(utils.conkat("return ", add_obj)),
        "[PointCloudData][_build_arbitrary] Error while converting \z
        <instancing.data.arbitrary> additional column to Lua.",
        " Issue in: ",
        add_obj
    )
    add_obj = add_obj()  -- this should be a table
    if not add_obj or type(add_obj) ~= "table" then
      logger:warning(
          "[ArbitraryAttribute][set_additional_from_string] Invalid \z
          additional argument passed: <", add_obj, ">."
      )
      return
    end

    -- 2. process attributes that are meant to be used internally :

    if add_obj.multi_sampled then
      self.static = false
      add_obj.multi_sampled = nil
    end

    if add_obj.not_per_point then
      self.perPoint = false
      add_obj.not_per_point = nil
    end

    -- 3. convert relative attributes path to absolute
    -- split the target path based on the dot
    local source = {}
    for k in target_attr_path:gmatch("([^%.]+)") do
      source[#source + 1] = k
    end

    for ptarget, pdata in pairs(add_obj) do
      add_obj[ptarget] = nil
      add_obj[utils:path_rel_to_abs(ptarget, source)] = pdata
    end

    self.additional = add_obj

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
    if not self.values or new_size == self.tupleSize then
      return
    end

    if new_size > self.tupleSize then
      utils.logerror("[CommonAttribute][resize_tuple] new_size<",new_size,
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

    self:set_values(samples)
    self.tupleSize = new_size

  end

  return inner

end

local function SourcesAttribute(parent, source_path)
  --[[
  List of instances sources locations with their associated index.
  Require the index token to be build on the PointCloudData parent

  beware of the 3 getter method returned values :
    - get_instance_source_data_at() :
        return a table of {"instance source location", "index", ...}
    - get_data_at() ; get_value_at() :
        return a list of `instance source` locations only

  Motion-blur is disabled. (hardcoded)

  Attributes:
    values:
      ordered table of sucessing instance source location, corresponding index
      like {"/root/A", 0, "/root/B", 1, ...}

  Note: Don't use <pid> with <__value_get()> as the values are not per-point.
  ]]

  local inner = CommonAttribute(parent, source_path, true)

  inner.perPoint = false

  function inner:_get_tuple_index_at_index(index)
    --[[
    Return the value table's tuple index for the given instance source index

    Args:
      index(number or string): instance source index
    Returns:
      number or nil:
        nil if bad index given, else values table's tuple index starting at 0
    ]]

    index = tostring(index)

    local sources = self:__value_get(nil, true, 0.0)  -- table of values

    for i=0, self.length / self.tupleSize - 1 do
      -- index is the second item of the tuple
      if index == sources[i*self.tupleSize + 2] then
        return i
      end

    end

    return nil

  end

  function inner:get_source_at(index)
    --[[
    Return the instance source corresponding to the given index
    Args:
      index(number or string):
    Returns:
      string or nil: nil if not found
    ]]

    local k = self:_get_tuple_index_at_index(index)
    if k then
      local v = self:__value_get(nil, true, 0.0)  -- table of values
      return v[k * self.tupleSize + 1]
    end
    return

  end

  function inner:get_instance_source_data_at(pid)
    --[[
    Return the instance source location + index + source attributes
     to use at given point index.

    Args:
      pid(number): starts at 0

    Returns:
      table: {
        "instance source location",
        "index",
        DataAttribute("source attributes"),
        [...]
      }
    ]]
    local v = self:__value_get(nil, true, 0.0)  -- table of values

    -- return a list of instance sources locations with indexes
    if not pid then
      return v
    end

    -- else if pid return the instance source + index for the given point

    local index = self.parent:get_common_by_name("index"):get_value_at(pid, 0.0)
    index = index[1] -- string

    local ti = self:_get_tuple_index_at_index(index)
    if ti then
      return {v[ti * self.tupleSize + 1], index, v[ti * self.tupleSize + 3]}
    end

    -- if the function didn't return yet mean we didn't find an instance source
    utils.logerror("[SourcesAttribute][get_instance_source_data_at] Can't \z
    find an instance source for pid<", pid, "> from index=", index,
        ", tuple_index=", ti)

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
    -- convert the associated instance index to the table index
    for i=0, #sources / self.tupleSize - 1 do
      -- storred index start counting at 0 so offset
      out[tonumber(sources[i * self.tupleSize + 2]) + 1] = sources[i * self.tupleSize + 1]
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

  function inner:set_values(values)
    --[[
    Args:
      values(table): unordered tables of time samples of values
    ]]
    values = values[0.0]

    -- we will add a third index to each tuple which correspond to the local
    -- attribute stored on the source location
    local new = {}
    for i=0,  #values / 2 - 1 do

      new[#new + 1] = values[i * 2 + 1]  -- instance source location
      new[#new + 1] = values[i * 2 + 2]  -- index
      -- add the third index
      new[#new + 1] = Interface.GetAttr("", values[i * 2 + 1])

    end

    self.length = #new
    values = {}
    values[0.0] = new
    self.values = values
    self.tupleSize = 3

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

  function attrs:_build_settings()
    --[[
    Build the <settings> keys.
    ]]

    local setting

    setting = utils.get_attr_value(
        self.location,
        "instancing.settings.convert_degree_to_radian",
        { 0 }
    ) -- type: table
    self.settings.convert_degree_to_radian = setting[1]

    setting = utils.get_attr_value(
        self.location,
        "instancing.settings.convert_trs_to_matrix",
        { 0 }
    ) -- type: table
    self.settings.convert_trs_to_matrix = setting[1]

    setting = utils.get_attr_value(
        self.location,
        "instancing.settings.enable_motion_blur",
        { 0 }
    ) -- type: table
    setting = setting[1]
    if setting == 0.0 then
      self.settings.disable_motion_blur = true
      logger:info("[PointCloudData][_build_settings] motion blur disabled.")
    else
      self.settings.disable_motion_blur = false
    end

  end

  function attrs:_build_points()
    --[[
    Set the self.points.count attribute based on the point token submitted.
    ]]

    local data_points = utils.get_attr_value(
      self.location,
      "instancing.data.points.count",
      error
    ) -- table of 1 value

    if data_points[1] <= 0 then

      data_points = utils.get_attr_value(
          self.location,
          "instancing.data.points.attr",
          error
      ) -- table of 2 values, first is attribute location, second is tupleSize

      local points = utils.get_attr_value(
          self.location,
          data_points[1],
          error
      )

      self.points = {}
      self.points.count = #points / data_points[2]

    else

      self.points = {}
      self.points.count = data_points[1]

    end

    logger:debug(
      "[PointCloudData][_build_points] Finished, found", self.points.count, "points."
    )

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
    idata = utils.get_attr_value(
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
          self.settings.disable_motion_blur or Tokens.list[token].static
      )
      attribute:build()

      if token == "skip" then
        attribute.perPoint = false
      end

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

      attribute:rescale_points(self.points.count)

      self["common"][token] = attribute


    end

    logger:debug(
      "[PointCloudData][_build_common] Finished"
    )
    -- end _build_common
  end

  function attrs:_build_arbitrary()
      --[[
    Build the <arbitrary> attribute.
    ]]
    local idata

    local target
    local path
    local tuplesize
    local additional
    local attribute

    -- get the attribute on the pc
    idata = utils.get_attr_value(
        self.location,
        "instancing.data.arbitrary",
        false
    )

    if not idata then
      return
    end

    for i=0, #idata / AttrGrp.arbitrary - 1 do

      path = idata[AttrGrp.arbitrary*i+1]
      target = idata[AttrGrp.arbitrary*i+2]
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
      attribute:set_additional_from_string(additional, target)

      attribute:build()

      -- -1 mean the tupleSize was not specified so let the one found by build
      if tuplesize ~= -1 then
        attribute:set_tuple_size(tuplesize)
      end

      attribute:rescale_points(self.points.count)

      self["arbitrary"][target] = attribute

    end

    logger:debug(
      "[PointCloudData][_build_arbitrary] Finished"
    )

    -- end _build_common
  end

  function attrs:_convert_degree_radian()
    --[[
    Convert degree to radian or inverse or do nothing ,depending of user
    specified setting.

    To execute after self:_build_processed_key, the <processed> key have to be build.
    ]]
    local convert_func
    if self.settings.convert_degree_to_radian == 1 then
      convert_func = utils.degree_to_radian
    elseif self.settings.convert_degree_to_radian == -1 then
      convert_func = utils.radian_to_degree
    else
      logger:debug(
        "[PointCloudData][_convert_degree_radian] Aborted early with convert=",
        self.settings.convert_degree_to_radian
      )
      return
    end

    local sv
    local attr

    -- convert the rotationX/Y/Z tokens
    for _, token in ipairs({"rotationX", "rotationY", "rotationZ"}) do

      attr = self:get_common_by_name(token)
      sv = attr:get_value_at()

      for sample, values in pairs(sv) do
        for i=0, #values / attr.tupleSize - 1 do
          -- make sure the axis are not processed !
          values[i * attr.tupleSize + 1] = convert_func(
              values[i * attr.tupleSize + 1]
          )
        end
      end

    end

    logger:debug(
      "[PointCloudData][_convert_degree_radian] Converted rotation axis"
    )

    -- convert the rotation token
    sv = self.common.rotation:get_value_at()
    for _, values in pairs(sv) do

      for i=1, #values do
        values[i] = convert_func(values[i])
      end

    end

    logger:debug(
      "[PointCloudData][_convert_degree_radian] Finished with convert=",
      self.settings.convert_degree_to_radian
    )

  end

  function attrs:_convert_rotation_to_axis()
    --[[
    As rotationX/Y/Z should always exists, use the <rotation> one to build them

    Execute after self:_validate
    ! heavy ! Process through all the rotation points
    ]]

    -- check of course if the attribute is built before starting anything
    if not self.common.rotation then
      return
    end

    local rx = {}
    local ry = {}
    local rz = {}

    local rall_data = {
      { rx, {1.0, 0.0, 0.0} }, -- x
      { ry, {0.0, 1.0, 0.0} }, -- y
      { rz, {0.0, 0.0, 1.0} }  -- z
    }
    local rvalues local raxis local rbuffer

    -- /!\ Perfs
    -- iterate trough all rotation values with are assumed to be in x,y,z order
    -- grouping can only be 3

    -- iterate trough each axis x,y,z
    for rindex, rdata in ipairs(rall_data) do

      rvalues, raxis = rdata[1], rdata[2]

      for sample, source_values in pairs(self.common.rotation:get_value_at()) do

        rbuffer = {}

        for i=0, self.common.rotation.length / self.common.rotation.tupleSize - 1 do

          -- rindex=[1,2,3] ; rdata=[{ {}, {1.0, 0.0, 0.0} }, ...]

          rbuffer[#rbuffer + 1] = source_values[i*self.common.rotation.tupleSize + rindex]
          rbuffer[#rbuffer + 1] = raxis[1]
          rbuffer[#rbuffer + 1] = raxis[2]
          rbuffer[#rbuffer + 1] = raxis[3]

        end

        rvalues[sample] = rbuffer

      end


    end

    for i, token in ipairs({"rotationX", "rotationY", "rotationZ"}) do

      self["common"][token] = CommonAttribute(
        self,
        "function _convert_rotation_to_axis",
        false
      )
      self["common"][token]:set_tuple_size(4)
      self["common"][token]:set_data_class(self.common.rotation.class)
      self["common"][token]:set_values(rall_data[i][1])

    end

    logger:debug("[PointCloudData][_convert_rotation_to_axis] Finished.")

  end

  function attrs:_convert_skip_n_hide()
    --[[
    Both token should always be defined or none of them. So if <hide> is
    specified, convert it to <skip>. If only <skip> is specified convert it
    to <hide>.

    So the <hide> token take over the <skip> token if both specified !

    Motion blur is disabled here.

    Execute after the <self:_validate> method.
    ]]

    local pcvalues = {}

    if self.common.hide then

      for i, hidden in ipairs(self.common.hide:get_value_at(nil, 0.0)) do
        if hidden == 1 then
          pcvalues[#pcvalues + 1] = i
        end
      end
      pcvalues = {[0.0]=pcvalues}

      self["common"]["skip"] = CommonAttribute(
        self,
        "function _convert_skip_n_hide",
        true
      )
      self["common"]["skip"]:set_tuple_size(1)
      self["common"]["skip"]:set_data_class(IntAttribute)
      self["common"]["skip"]:set_values(pcvalues)

    elseif self.common.skip then

      -- build a first time the hide table, all points are visible
      for i=1, self.points.count do
        pcvalues[i] = 0
      end
      -- iterate through point to skip and set them on <pcvalues>
      -- !! self.common.skip.values starts at 0 !! hence the + 1
      for _, to_hide in ipairs(self.common.skip:get_value_at(nil, 0.0)) do
        pcvalues[to_hide + 1] = 1
      end

      pcvalues = {[0.0]=pcvalues}

      self["common"]["hide"] = CommonAttribute(
        self,
        "function _convert_skip_n_hide",
        true
      )
      self["common"]["hide"]:set_tuple_size(1)
      self["common"]["hide"]:set_data_class(IntAttribute)
      self["common"]["hide"]:set_values(pcvalues)

    end

    logger:debug("[PointCloudData][_convert_skip_n_hide] Finished.")

  end

  function attrs:_convert_trs_to_matrix()
    --[[
    Convert the translation, rotationX/Y/Z, and scale attributes to the matrix
    attribute (4x4 matrix).
    ]]

    if self.settings.convert_trs_to_matrix == 0 then
      logger:debug(
        "[PointCloudData][_convert_to_matrix] Aborted. Setting not enable."
      )
      return
    end


    -- compute a list of samples base on <translation> or <rotationX> or <scale>
    -- we only want to use the biggest list of samples from the three ones.
    local buf
    local samples_list

    for _, token in ipairs({"translation", "rotationX", "scale"}) do

      buf = self:get_common_by_name(token)

      if buf then
        buf =  buf:get_value_at()
        buf =  utils:get_samples_list_from(buf) -- type: table: {0.0, -0.25, ...}
        if not samples_list or (#buf > #samples_list) then
          samples_list = buf
        end
      end

    end

    logger:debug(
        "[PointCloudData][_convert_trs_to_matrix] Samples found are:",
        samples_list
    )

    local v
    local matrices_smpls = {}
    local matrices
    local sample
    local m44
    local im44d = Imath.M44d
    local iv3d = Imath.V3d

    -- create samples based on the ones found above
    for smplindex=1, #samples_list do

      -- build a new 4x4 matrix for each point
      matrices = {}
      sample = samples_list[smplindex]

      for i=0, self.points.count - 1 do

        -- translation
        m44 = im44d()
        v = self:get_common_by_name("translation")
        if v then
          v = v:get_value_at(i, sample)
          m44:translate(iv3d(v))
        end

        -- rotations
        v = self:get_common_by_name("rotationX")
        if v then
          v = v:get_value_at(i, sample)
          v = {utils.degree_to_radian(v[1])}
          v[2] = utils.degree_to_radian(
              self:get_common_by_name("rotationY"):get_value_at(i, sample)[1]
          )
          v[3] = utils.degree_to_radian(
              self:get_common_by_name("rotationZ"):get_value_at(i, sample)[1]
          )
          m44:rotate(iv3d(v))
        end

        -- scale
        v = self:get_common_by_name("scale")
        if v then
          v = v:get_value_at(i, sample)
          m44:scale(iv3d(v))
        end

        -- combine the created matrix to the matrices table
        for _, mv in ipairs(m44:toTable()) do
          matrices[#matrices + 1] = mv
        end

      end

      matrices_smpls[sample] = matrices

    end

    self.common.matrix = CommonAttribute(
        self,
        "function _convert_trs_to_matrix()",
        false
    )
    self.common.matrix:set_tuple_size(16)
    self.common.matrix:set_data_class(DoubleAttribute)
    self.common.matrix:set_values(matrices_smpls)

    self.common.translation = false
    self.common.rotation = false
    self.common.rotationX = false
    self.common.rotationY = false
    self.common.rotationZ = false
    self.common.scale = false

    logger:debug(
        "[PointCloudData][_convert_trs_to_matrix] Finished. New matrix \z
        attribute of length=", self.common.matrix.length, "created."
    )

  end

  function attrs:_validate()
    --[[
    To call after built operations.
    Verify that self table is properly built.
    Also clean the unusable attributes.
    TODO see if arbitrary is also needed to be validated
    ]]

    logger:debug("[PointCloudData][_validate] Started.")

    -- attr points must always exists
    if not self.points.count then
      utils.logerror(
          "[PointCloudData][_validate] points.count was not found for <",
          self.location,
          ">."
      )
    end

    -- we need at least one instance source
    if not self.common.sources then
      utils.logerror(
          "[PointCloudData][_validate] No instance sources specified \z
           for location <",
          self.location,
          ">."
      )
    end

    -- instance sources index must start at 0
    if self.common.sources:get_source_at("0") == nil then
      utils.logerror(
        "[PointCloudData][_validate] No index 0 found on <common.sources> attribute."
      )
    end

    -- every instance source need the index to be declared
    -- TODO update once SourcesAttribute finished
    --for _, isource_data in ipairs(self.sources) do
    --  if not isource_data["index"] then
    --    utils.logerror(
    --        "[PointCloudData][_validate] No index specified for \z
    --        instance source <",
    --        self.isource_data["path"],
    --        "> for source location <",
    --        self.location,
    --        ">."
    --    )
    --  end
    --end

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
        utils.logerror(
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
      if self.common.rotation.tupleSize ~= 3 then
        utils.logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $rotation token only accepts 3 as grouping, not ",
          self.common.rotation.grouping
        )
      end
    end
    if self.common.matrix then
      if self.common.matrix.tupleSize ~= 16 then
        utils.logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $matrix token only accepts 16 as grouping, not ",
          self.common.matrix.grouping
        )
      end
    end
    if self.common.translation then
      if self.common.translation.tupleSize ~= 3 then
        utils.logerror(
          "[PointCloudData][_validate] Source <", self.location,
          "> $translation token only accepts 3 as grouping, not ",
          self.common.translation.grouping
        )
      end
    end

    logger:debug("[PointCloudData][_validate] Finished.")

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

    -- order matters
    self:_convert_rotation_to_axis()
    self:_convert_skip_n_hide()
    self:_convert_degree_radian()
    self:_convert_trs_to_matrix()

  end

  function attrs:is_point_hidden(pid)
    --[[
    Return false is the point at given index must not be created (hidden).
    This is determined by using the <hide> token.

    /!\ perfs

    Args:
      pid(int): point index: which point to use. !! starts at 0 !!

    Returns:
      bool: true if the point is hidden and thus should not be created
    ]]

    local data = self:get_common_by_name("hide")
    if not data then
      return false
    end
    data = data:get_value_at(pid, 0.0) -- table of 0|1

    if data[1] == 1 then
      return true
    end

    return false

  end

  function attrs:get_common_by_name(name)
    --[[
    Returns:
      BaseAttribute or nil: nil if not found
    ]]
    return self.common[name]
  end

  function attrs:get_commons()
    return self.common
  end

  function attrs:get_arbitrary()
    return self.arbitrary
  end

  logger:debug(
      "[PointCloudData][new] Finished for location <",
      location,
      ">."
  )

  return attrs

end

return PointCloudData