local conflicts = require("core.conflicts")

local COLOR_PALETTE_NAMES = {
  "default", "custom", "white", "black", "grey", "red", "orange", "yellow",
  "green", "cyan", "blue", "purple", "pink", "brown"
}

return {
  name = "player-colors",
  conflicts = conflicts.CONFLICTS["player-colors"],
  runtime_global = {
    { name = "enabled", type = "bool", default = false },
  },
  runtime_per_user = {
    { name = "character-color", type = "string", default = "default", allowed = COLOR_PALETTE_NAMES },
    { name = "character-color-hex", type = "string", default = "", allow_blank = true },
    { name = "chat-color", type = "string", default = "default", allowed = COLOR_PALETTE_NAMES },
    { name = "chat-color-hex", type = "string", default = "", allow_blank = true },
  },
}
