if settings.startup["squeak-through-enabled"].value then
  require("features.squeak-through.data")
end

if settings.startup["far-reach-enabled"].value then
  require("features.far-reach.data")
end