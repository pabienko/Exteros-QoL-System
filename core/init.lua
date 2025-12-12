--[[
  CORE/INIT.LUA - Core Module Initialization
  
  This module initializes and exports all core utilities.
  Import this module to get access to all core functionality.
  
  Usage:
    local core = require("core.init")
    core.debug.log("Message")
    core.inventory.transfer(...)
]]

local M = {}

-- Load all core modules
M.debug = require("core.debug")
M.constants = require("core.constants")
M.validation = require("core.validation")
M.inventory = require("core.inventory")
M.math = require("core.math")
M.settings = require("core.settings")

return M
