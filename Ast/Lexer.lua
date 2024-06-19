local Token = require("Ast/Token")

local Lexer = {}
Lexer.__index = Lexer

Lexer.alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
Lexer.digit = "0123456789"
Lexer.whitespace = "\32\t\n\r\f"
Lexer.escapeSequences = {
    ["a"] = "\a";
    ["b"] = "\b";
    ["f"] = "\f";
    ["n"] = "\n";
    ["r"] = "\r";
    ["t"] = "\t";
    ["v"] = "\v";
    ["\\"] = "\\";
    ["'"] = "'";
    ['"'] = '"';
}
Lexer.iden = Lexer.alphabet .. Lexer.digit .. "_"
Lexer.number = Lexer.digit .. "."
Lexer.keywords = {
    ["let"] = Token.kind.let;
    ["do"] = Token.kind["do"];
    ["end"] = Token.kind["end"];
    ["if"] = Token.kind["if"];
    ["elif"] = Token.kind.elif;
    ["else"] = Token.kind["else"];
    ["for"] = Token.kind["for"];
    ["while"] = Token.kind["while"];
    ["fn"] = Token.kind.fn;
    ["true"] = Token.kind["true"];
    ["false"] = Token.kind["false"];
    ["null"] = Token.kind.null;
}
Lexer.operators = {
    ["+"] = Token.kind.plus;
    ["-"] = Token.kind.minus;
    ["*"] = Token.kind.star;
    ["/"] = Token.kind.dash;
    ["%"] = Token.kind.modulo;
    ["#"] = Token.kind.hashtag;
    ["^"] = Token.kind.caret;
    [";"] = Token.kind.semiColon;
    [":"] = Token.kind.colon;
    ["."] = Token.kind.dot;
    ["?"] = Token.kind.questionMark;
    ["!"] = Token.kind.exclamationMark;
    ["&"] = Token.kind.ampersand;
    ["|"] = Token.kind.pipe;

    [":="] = Token.kind.equal;
    ["<>"] = Token.kind.notEqual;
    ["="] = Token.kind.equalTo;
    ["<"] = Token.kind.lessThan;
    ["<="] = Token.kind.lessEqual;
    [">"] = Token.kind.greaterThan;
    [">="] = Token.kind.greaterEqual;

    ["("] = Token.kind.leftParen;
    [")"] = Token.kind.rightParen;
    ["{"] = Token.kind.leftBrace;
    ["}"] = Token.kind.rightBrace;
    ["["] = Token.kind.leftBracket;
    ["]"] = Token.kind.rightBracket;

    [":+"] = Token.kind.plusEqual;
    [":-"] = Token.kind.minusEqual;
    [":*"] = Token.kind.starEqual;
    [":/"] = Token.kind.dashEqual;
    [":%"] = Token.kind.moduloEqual;
    [":^"] = Token.kind.caretEqual;
}

function Lexer.new(source)
    local self = {}

    self._source = source
    self._position = 1
    self._tokens = {}

    return setmetatable(self, Lexer)
end

function Lexer.is(object)
    return type(object) == "table" and getmetatable(object) == Lexer
end

function Lexer.sortOperators(operatorTable)
    local tables = {}

    for operator, token in pairs(operatorTable) do
        local length = operator:len()

        if not tables[length] then
            for i = 1, length do
                tables[i] = tables[i] or {}
            end
        end

        tables[length][operator] = token
    end

    return tables
end

function Lexer:error(str, ...)
    error(str:format(...))
end

function Lexer:peek(count)
    count = count or 0
    local endPosition = count + self._position
    return self._source:sub(self._position, endPosition)
end

function Lexer:match(toMatch)
    return self:peek(#toMatch - 1) == toMatch
end

function Lexer:advance()
    local character = self:peek()
    self._position = self._position + 1
    return character
end

function Lexer:accept(toMatch)
    if self:match(toMatch) then
        self._position = self._position + #toMatch
        return toMatch
    end

    return nil
end

function Lexer:expect(toMatch)
    local match = self:accept(toMatch)
    if not match then
        self:error("Expected %s", toMatch)
    end

    return match
end

function Lexer:readString()
    local start = self._position
    local charArray = {}

    local quote = self:accept("'") or self:accept('"')

    while not self:accept(quote) do
        local character = self:advance()

        if character == "\\" then
            local escapeChar = self:advance()
            local escapeSequence = Lexer.escapeSequences[escapeChar]
            if not escapeSequence then
                self:error("%s is not a valid escape sequence", escapeChar)
                break
            end

            character = escapeChar
        end

        table.insert(charArray, character)
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.string, start, self._position, asString)
end

function Lexer:readComment()
    local start = self._position
    local charArray = {}

    self:accept("//")

    while not self:accept("\n") do
        table.insert(charArray, self:advance())
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.comment, start, self._position, asString)
end

function Lexer:readMultlineComment()
    local start = self._position
    local charArray = {}

    self:accept("/*")

    while not self:accept("*/") do
        table.insert(charArray, self:advance())
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.multilineComment, start, self._position, asString)
end

function Lexer:readNumber()
    local start = self._position
    local charArray = {}

    local dotCount = false
    while true do
        local character = self:peek()
        if dotCount and Lexer.digit:find(character, 1, true) then
            table.insert(charArray, self:advance())
        elseif Lexer.number:find(character, 1, true) then
            table.insert(charArray, self:advance())
        else break end

        if character == "." then
            dotCount = true
        end
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.number, start, self._position, asString)
end

function Lexer:readIden()
    local start = self._position
    local charArray = {}

    while Lexer.iden:find(self:peek(), 1, true) do
        table.insert(charArray, self:advance())
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.iden, start, self._position, asString)
end

function Lexer:read()
    local start = self._position

    if self:match("//") then
        return self:readComment()
    end
    if self:match("/*") then
        return self:readMultlineComment()
    end
    if self:match("'") or self:match('"') then
        return self:readString()
    end

    for keyword, tokenType in pairs(Lexer.keywords) do
        if self:accept(keyword) then
            return Token.new(tokenType, start, self._position)
        end
    end

    for operatorLength = #Lexer.operators, 1, -1 do
        local operatorGroup = Lexer.operators[operatorLength]

        for operator, tokenType in pairs(operatorGroup) do
            if self:accept(operator) then
                return Token.new(tokenType, start, self._position)
            end
        end
    end

    local character = self:peek()
    if Lexer.whitespace:find(character, 1, true) then
        self:advance()
        return true
    end
    if Lexer.digit:find(character, 1, true) then
        return self:readNumber()
    end
    if (Lexer.alphabet .. "_"):find(character, 1, true) then
        return self:readIden()
    end
end

function Lexer:scan()
    while self._position <= #self._source do
        local token = self:read()

        if not token then
            break
        end

        if Token.is(token) then
            table.insert(self._tokens, token)
        end
    end

    table.insert(self._tokens, Token.new(Token.kind.eof))
    return self._tokens
end

Lexer.operators = Lexer.sortOperators(Lexer.operators)

return Lexer