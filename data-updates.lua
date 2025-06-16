if settings.startup["exteros-pl-enabled"].value == true then
    local new_limit = settings.startup["exteros-pl-maximum"].value

    for _,r in pairs(data.raw.recipe) do
	    r.maximum_productivity = new_limit / 100
    end
end