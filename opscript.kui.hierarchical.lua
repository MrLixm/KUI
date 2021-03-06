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
local utils = require("kui.utils")
-- don't print/log anything here, repeated times number of points.

if Interface.AtRoot() then
  local log_level = utils:get_user_attr("log_level", "info")[1]
  hier:set_logger_level(log_level)
  hier:run_root()

else
  -- don't print/log anything here too, repeated times number of points.
  hier:run_not_root()
end