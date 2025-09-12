if settings.startup["squeak-through-enabled"].value then
  require("features.squeak-through.data-final-fixes")
end

if settings.startup["stack-size-enabled"].value then
  require("features.stack-size.data-final-fixes")
end