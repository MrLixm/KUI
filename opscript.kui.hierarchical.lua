-- version=2
local hier = require("kui.hierarchical")
local utils = require("kui.utils")
-- don't print/log anything here, repeated times number of points.

if Interface.AtRoot() then
  local log_level = utils:get_user_attr(Interface.GetCurrentTime(), "log_level", "info")[1]
  hier:set_logger_level(log_level)
  hier:run_root()

else
  -- don't print/log anything here too, repeated times number of points.
  hier:run_not_root()
end