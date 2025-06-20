local new_limit = settings.startup["productivity-limit-maximum"].value

for _,r in pairs(data.raw.recipe) do
    r.maximum_productivity = new_limit / 100
end