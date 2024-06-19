local function strict(name, table)
    return setmetatable(table, {
        __index = function(_, key)
			error(("%q is not a valid member of %q"):format(tostring(key), name))
		end;

		__newindex = function(_, key)
			error(("%q of %q is not assignable"):format(tostring(key), name))
		end;
    })
end

local function enumerate(enumName, enumItems)
    local items = {}

    for _, name in ipairs(enumItems) do
        items[name] = {}
    end

    return strict(enumName, items)
end

return enumerate