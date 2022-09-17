--[[
version=3

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
local hier = require("kui.hierarchical")
-- don't print/log anything here, repeated times number of points.
local utils = require("kui.utils")
local logging = require("lllogger")


if Interface.AtRoot() then
  local log_level = utils.get_user_attr("log_level", {"INFO"})[1]
  logging.getLogger("kui.hierarchical"):setLevel(logging.LEVELS[log_level])
  hier.atroot()

else
  -- don't print/log anything here too, repeated times number of points.
  hier.run_not_root()
end