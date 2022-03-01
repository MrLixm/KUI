--[[
version=0.0.8
todo
]]

local logging = require("lllogger")
local logger = logging:get_logger("kui.array")
logger:set_level("debug")
logger.formatting:set_tbl_display_functions(false)

local PointCloudData = require("kui.PointCloudData")
local utils = require("kui.utils")

local function set_logger_level(self, level)
  --[[
  Propagate the level to all modules too
  ]]
  logger:set_level(level)
  PointCloudData:set_logger_level(level)
  utils:set_logger_level(level)
end

--[[ __________________________________________________________________________
  API
]]

-- // Used by InstancingArray
-- key is the token to query and value is the target attribute path
-- if the token doesnt have any value on point_data it will not be added.
-- ! order is important !
local token_target = {
  { ["token"]="sources", ["target"]="geometry.instanceSource" },
  { ["token"]="index", ["target"]="geometry.instanceIndex" },
  { ["token"]="skip", ["target"]="geometry.instanceSkipIndex" },
  { ["token"]="matrix", ["target"]="geometry.instanceMatrix" },
  { ["token"]="translation", ["target"]="geometry.instanceTranslate" },
  { ["token"]="rotationX", ["target"]="geometry.instanceRotateX" },
  { ["token"]="rotationY", ["target"]="geometry.instanceRotateY" },
  { ["token"]="rotationZ", ["target"]="geometry.instanceRotateZ" },
  { ["token"]="scale", ["target"]="geometry.instanceScale" },
}


local InstancingArray = {}
function InstancingArray:new(point_data)
  --[[

  Made the link between PointCloudData and instance creation.

  Args:
    point_data(PointCloudData) : PointCloudData instance that has been built.

  Attributes:
    pdata(PointCloudData): PointCloudData instance

  ]]

  local attrs = {
    pdata = point_data,
  }

  function attrs:add(target, value)
    --[[
    Args:
      target(str):
      value(DataAttribute or nil):
    ]]
    if value == nil then
      return
    end

    Interface.SetAttr(target, value)

  end

  function attrs:build()
    --[[
    Build the array instance from PointCloudData
    ]]

    -- 1. PROCESS COMMON & SOURCES ATTRIBUTES
    for _, tt in ipairs(token_target) do
      self:add(tt["target"], self.pdata:get_attr_value(tt["token"]))
    end

    -- 2. PROCESS ARBITRARY ATTRIBUTES
    for target, arbtr_data in pairs(self.pdata["arbitrary"]) do
      -- 1. first process the additional table
      -- we only use arbtr_data for the <additional> key yet so we can do this
      arbtr_data = arbtr_data["additional"]  -- type: table or NIL
      if arbtr_data then
        for addit_target, addit_value in pairs(arbtr_data) do
          self:add(addit_target, addit_value)
        end
      end
      -- 2. Add the arbitrary attribute value
      self:add(target,  self.pdata:get_attr_value(target))
    end

    self:add("type", StringAttribute("instance array"))

  end

  return attrs

end


-- processes ------------------------------------------------------------------


local function run()
  --[[
  Create the instance
  ]]
  print("\n")
  local stime = os.clock()
  local time = Interface.GetCurrentTime() -- int

  local u_pointcloud_sg = utils:get_user_attr(
      time, "pointcloud_sg", "$error"
  )[1]

  -- process the source pointcloud
  logger:info("[run] Started processing source <", u_pointcloud_sg, ">.")
  local pointdata
  pointdata = PointCloudData:new(u_pointcloud_sg, time)
  pointdata:build()
  logger:info("[run] Finished processing source <", u_pointcloud_sg, ">.",
      pointdata.point_count, " points found.")

  logger:debug("pointdata = \n", pointdata, "\n")
  -- start instancing
  local instance
  instance = InstancingArray:new(pointdata)
  instance:build()

  stime = os.clock() - stime
  logger:info(
      "[run] Finished in ",stime,"s for pointcloud <",u_pointcloud_sg,">."
  )

end


return {
  ["run"] = run,
  ["set_logger_level"] = set_logger_level,
  ["logger"] = logger
}