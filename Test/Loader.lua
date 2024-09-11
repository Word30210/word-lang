local Lexer = require("Ast\\Lexer")

local function Dump(t, i)
	local function getTypeOfTable(_t)
		local isArray = false
		local isDict = false

		for _key, _ in pairs(_t) do
			if type(_key) == "number" then
				isArray = true
			else
				isDict = true
			end
		end

		if isArray and not isDict then
			return "array"
		elseif not isArray and isDict then
			return "dict"
		elseif isArray and isDict then
			return "mixed"
		end
	end

	local function isArray(_t)
		return getTypeOfTable(_t) == "array"
	end

	local function isDict(_t)
		return getTypeOfTable(_t) == "dict"
	end

	local function isMixed(_t)
		return getTypeOfTable(_t) == "mixed"
	end

	local function hasInnerTable(_t)
		for _, _value in pairs(_t) do
			if type(_value) == "table" then
				return true
			end
		end

		return false
	end

	i = i or 0

	if type(t) ~= "table" and i == 0 then
		return tostring(t)
	end

	local result = ""

	if type(t) == "table" then
		if not isDict(t) and #t == 0 then
			return "{};"
		end

		local writeOneline = isArray(t) and not hasInnerTable(t) and #t <= 10
		local prefix = string.rep("\32\32\32\32", i + 1)
		local prevPrefix = string.rep("\32\32\32\32", i)

		result = result .. "{" .. (writeOneline and " " or "\n")

		for _key, _value in pairs(t) do
			if writeOneline then
				result = result .. (type(_value) == "string" and '"' .. _value .. '"' or tostring(_value)) .. (_key >= #t and "\32" or ",\32")
			else
				local keyPart = "[" .. (type(_key) == "string" and '"' .. _key .. '"' or tostring(_key)) .. "]"
				local valuePart = type(_value) == "table" and Dump(_value, i + 1) or type(_value) == "string" and '"' .. _value .. '";' or tostring(_value) .. ";"

				result = result .. prefix .. keyPart .. "\32=\32" .. valuePart .. "\n"
			end
		end

		result = result .. (writeOneline and "" or prevPrefix) .. "};"
	end

	return result
end

local file = io.open("test\\test.word", "r")

if file then
    local source = file:read("*a")

    local newLexer = Lexer.new(source)

    local result = newLexer:scan()
    local dumpedTable = Dump(result)

    for _, data in ipairs(result) do
		print(data.value or data.kind[1], data.kind[1])
	end
    local result_txt = io.open("test\\result.txt", "w")
    if result_txt then
        result_txt:write(dumpedTable)
        result_txt:close()
    end

    file:close()
end