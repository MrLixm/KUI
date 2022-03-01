-- version=2
local array = require("kui.array")
local utils = require("kui.utils")

local log_level = utils:get_user_attr(Interface.GetCurrentTime(), "log_level", "info")[1]
array:set_logger_level(log_level)
array:run()
