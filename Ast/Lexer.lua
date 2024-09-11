--[[
    TODO LIST

    - Rust의 에러 메시지를 참고해서, Lexer:error() 업데이트 하기

    - 객체지향 문법 설계하기
    - 비동기 문법 설계하기
]]--

local Token = require("Ast.Token")

local Lexer = {}
Lexer.__index = Lexer

Lexer.eof = ""
Lexer.eol = "\n"
Lexer.whitespace = "\32\t\n\r\f"
Lexer.digit = "0123456789"
Lexer.alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
Lexer.hexadecimal = Lexer.digit .. "abcdefABCDEF"
Lexer.octal = "01234567"

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

Lexer.keywords = {
    ["var"] = Token.kind.var;
    ["fn"] = Token.kind.fn;
    ["if"] = Token.kind["if"];
    ["elseif"] = Token.kind["elseif"];
    ["else"] = Token.kind["else"];
    ["for"] = Token.kind["for"];
    ["while"] = Token.kind["while"];
    ["each"] = Token.kind.each;
    ["in"] = Token.kind["in"];
    ["void"] = Token.kind.void;
    ["true"] = Token.kind["true"];
    ["false"] = Token.kind["false"];
    ["break"] = Token.kind["break"];
    ["return"] = Token.kind["return"];
}

Lexer.operators = {
    ["+"] = Token.kind.plus;
    ["-"] = Token.kind.minus;
    ["*"] = Token.kind.star;
    ["/"] = Token.kind.slash;
    ["%"] = Token.kind.modulo;
    ["#"] = Token.kind.hashtag;
    ["^"] = Token.kind.caret;
    [";"] = Token.kind.semiColon;
    [":"] = Token.kind.colon;
    ["."] = Token.kind.dot;
    [","] = Token.kind.comma;
    ["?"] = Token.kind.questionMark;
    ["!"] = Token.kind.exclamationMark;
    ["&"] = Token.kind.ampersand;
    ["|"] = Token.kind.pipe;

    [".."] = Token.kind.dot2;
    ["..."] = Token.kind.dot3;

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
    [":/"] = Token.kind.slashEqual;
    [":%"] = Token.kind.moduloEqual;
    [":^"] = Token.kind.caretEqual;
    [":.."] = Token.kind.dot2Equal;
    [":?"] = Token.kind.questionMarkEqual;
}

Lexer.errorFormat = "\n===============YOUR CODE=================\n%s\n%s\n=========================================\nWordLanguage::Lexer | Syntax Error Occurred! | Reason: %s"

function Lexer.new(source)
    local self = {}

    self._source = source
    self._position = 1
    self._tokens = {}
    self._char_array = {}

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

function Lexer:error(errorKind)
    local code = ""
    local errorArrow = ""
    local eolCount = 0

    while eolCount <= 2 do
        local char = self:peek()

        if self:isEOF(char) then break end

        if self:isEOL(char) then
            eolCount = eolCount + 1
        end

        if eolCount < 1 then
            if self:isWhitespace(char) then
                errorArrow = char .. errorArrow
            else
                errorArrow = "\32" .. errorArrow
            end
        end

        code = char .. code

        self:move(-1)
    end

    error(Lexer.errorFormat:format(code, errorArrow:gsub(".$", ""):gsub(".$", "^"), errorKind))
end

function Lexer:move(count)
    count = count or 1
    self._position = self._position + count
end

function Lexer:peek(count)
    count = count or 0
    local endPosition = count + self._position
    return self._source:sub(self._position, endPosition)
end

function Lexer:next()
    return self._source:sub(self._position + 1, self._position + 1)
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

function Lexer:consume(char)
    table.insert(self._char_array, char)
end

function Lexer:concat(clear)
    local asString = table.concat(self._char_array)

    if clear then
        self:clear()
    end

    return asString
end

function Lexer:clear()
    for k, _ in pairs(self._char_array) do
        self._char_array[k] = nil
    end
end

function Lexer:isEOF(char)
    if char == Lexer.eof then
        return true
    else
        return false
    end
end

function Lexer:isEOL(char)
    if char == Lexer.eol then
        return true
    else
        return false
    end
end

function Lexer:isWhitespace(char)
    if self:isEOF(char) then return false end

    if self.whitespace:find(char, 1, true) then
        return true
    else
        return false
    end
end

function Lexer:isDigit(char)
    if self:isEOF(char) then return false end

    if self.digit:find(char, 1, true) then
        return true
    else
        return false
    end
end

function Lexer:isAlpha(char)
    if self:isEOF(char) then return false end

    if self.alphabet:find(char, 1, true) then
        return true
    else
        return false
    end
end

function Lexer:isHex(char)
    if self:isEOF(char) then return false end

    if self.hexadecimal:find(char, 1, true) then
        return true
    else
        return false
    end
end

function Lexer:isOctal(char)
    if self:isEOF(char) then return false end

    if self.octal:find(char, 1, true) then
        return true
    else
        return false
    end
end

function Lexer:isOperator(char)
    if Lexer.operators[char] then
        return true
    else
        return false
    end
end

function Lexer:peektk()
    return self._tokens[#self._tokens]
end

function Lexer:pervtk()
    return self._tokens[#self._tokens - 1]
end

function Lexer:readString()
    local start = self._position
    local tokenKind = "string"

    local quote = self:accept("'") or self:accept('"')

    while not self:accept(quote) do
        local char = self:advance()

        if char == "\\" then
            local escapeChar = self:advance()
            local escapeSequences = Lexer.escapeSequences[escapeChar] or escapeChar
            char = escapeSequences
        elseif self:isEOF(self:peek()) or self:isEOL(self:peek()) then
            self:error("incompleteString")
        end

        self:consume(char)
    end

    local asString = self:concat(true)
    return Token.new(Token.kind[tokenKind], start, self._position, asString)
end

function Lexer:readMultilineString()
    local start = self._position
    local tokenKind = "MultilineString"

    local multiQuote = self:accept("`")

    while not self:accept(multiQuote) do
        local char = self:advance()

        if char == "\\" then
            local escapeChar = self:advance()
            local escapeSequences = Lexer.escapeSequences[escapeChar] or escapeChar
            char = escapeSequences
        elseif self:isEOF(char) then
            self:error("incompleteMultilineString")
        end

        self:consume(char)
    end

    local asString = self:concat(true)
    return Token.new(Token.kind[tokenKind], start, self._position, asString)
end

function Lexer:readComment()
    local start = self._position

    self:accept("//")

    while not self:accept(Lexer.eol) do
        self:consume(self:advance())
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.comment, start, self._position, asString)
end

function Lexer:readMultilineComment()
    local start = self._position
    local tokenKind = "multilineComment"

    self:accept("/*")

    while not self:accept("*/") do
        if self:isEOF(self:peek()) then
            self:error("incompleteMultilineComment")
        end

        self:consume(self:advance())
    end

    local asString = self:concat(true)
    return Token.new(Token.kind[tokenKind], start, self._position, asString)
end

function Lexer:readIden()
    local start = self._position

    while self:isAlpha(self:peek()) or self:isDigit(self:peek()) or self:match("_") do
        self:consume(self:advance())
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.iden, start, self._position, asString)
end

function Lexer:readNumber()
    local start = self._position

    local afterDot = false
    local afterE = false

    if self:match("0") then
        if self:next() == "b" or self:next() == "B" then
            return self:readBinaryNumber()
        elseif self:next() == "x" or self:next() == "X" then
            return self:readHexadecimalNumber()
        elseif self:next() == "o" or self:next() == "O" then
            return self:readOctalNumber()
        end
    end

    while self:isDigit(self:peek()) or self:match(".") or self:match("_") do
        if self:match(".") then
            if afterDot then
                self:error("malformedNumber")
            else
                afterDot = true
            end
        end

        self:consume(self:advance())
    end

    if self:match("e") or self:match("E") then
        afterE = true

        self:consume(self:advance())

        if self:match("+") or self:match("-") then
            self:consume(self:advance())
        end
    elseif self:isAlpha(self:peek()) then
        self:error("malformedNumber")
    end

    while self:isAlpha(self:peek()) or self:isDigit(self:peek()) or self:match("_") do
        if self:isAlpha(self:peek()) then
            if self:match("e") or self:match("E") then
                if afterE then
                    self:error("malformedNumber")
                else
                    afterE = true
                end
            else
                self:error("malformedNumber")
            end
        end

        self:consume(self:advance())
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.number, start, self._position, asString)
end

function Lexer:readBinaryNumber()
    local start = self._position

    if not self:accept("0b") then
        self:accept("0B")
    end

    if self:isEOF(self:peek()) or self:isWhitespace(self:peek()) then
        self:error("malformedNumber")
    end

    while not(self:isEOF(self:peek()) or self:isWhitespace(self:peek())) do
        if self:match("0") or self:match("1") then
            self:consume(self:advance())
        else
            self:error("malformedNumber")
        end
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.binaryNumber, start, self._position, asString)
end

function Lexer:readHexadecimalNumber()
    local start = self._position

    if not self:accept("0x") then
        self:accept("0X")
    end

    if self:isEOF(self:peek()) or self:isWhitespace(self:peek()) then
        self:error("malformedNumber")
    end

    while not(self:isEOF(self:peek()) or self:isWhitespace(self:peek())) do
        if self:isHex(self:peek()) then
            self:consume(self:advance())
        else
            self:error("malformedNumber")
        end
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.hexadecimalNumber, start, self._position, asString)
end

function Lexer:readOctalNumber()
    local start = self._position

    if not self:accept("0o") then
        self:accept("0O")
    end

    if self:isEOF(self:peek()) or self:isWhitespace(self:peek()) then
        self:error("malformedNumber")
    end

    while not(self:isEOF(self:peek()) or self:isWhitespace(self:peek())) do
        if self:isOctal(self:peek()) then
            self:consume(self:advance())
        else
            self:error("malformedNumber")
        end
    end

    local asString = self:concat(true)
    return Token.new(Token.kind.octalNumber, start, self._position, asString)
end

function Lexer:readDot()
    local start = self._position

    if self:isDigit(self:next()) then
        return self:readNumber()
    end

    if self:match("...") then
        self:move(3)
        return Token.new(Lexer.operator.dot3, start, self._position)
    elseif self:match("..") then
        self:move(2)
        return Token.new(Lexer.operator.dot2, start, self._position)
    else
        self:move(1)
        return Token.new(Lexer.operator.dot, start, self._position)
    end
end

function Lexer:readUnknown()
    local start = self._position

    while true do
        local char = self:advance()

        if self:isEOF(char)
            or self:isEOL(char)
            or self:isWhitespace(char)
            or self:isDigit(char)
            or self:isAlpha(char)
            or self:isOperator(char)
        then
            self:error("Unknown")
        end
    end
end

function Lexer:read()
    local start = self._position

    if self:match("'") or self:match('"') then
        return self:readString()
    end
    if self:match("`") then
        return self:readMultilineString()
    end
    if self:match("//") then
        return self:readComment()
    end
    if self:match("/*") then
        return self:readMultilineComment()
    end

    for keyword, tokenType in pairs(Lexer.keywords) do
        if self:accept(keyword) then
            return Token.new(tokenType, start, self._position)
        end
    end

    for operatorLength = #Lexer.operators, 1, -1 do
        local operatorGroup = Lexer.operators[operatorLength]

        for operator, tokenType in pairs(operatorGroup) do
            if self:match(operator) then
                if operator == "." then
                    return self:readDot()
                else
                    self:accept(operator)
                    return Token.new(tokenType, start, self._position)
                end
            end
        end
    end

    if self:isWhitespace(self:peek()) then
        self:advance()
        return true
    end
    if self:isDigit(self:peek()) then
        return self:readNumber()
    end
    if self:isAlpha(self:peek()) or self:match("_") then
        return self:readIden()
    end

    return self:readUnknown()
end

function Lexer:scan()
    while self._position <= #self._source do
        local token = self:read()

        if not token then
            break
        end

        if Token.is(token) then
            print(token.kind[1], token.value)

            table.insert(self._tokens, token)
        end
    end

    table.insert(self._tokens, Token.new(Token.kind.eof))
    return self._tokens
end

Lexer.operators = Lexer.sortOperators(Lexer.operators)

return Lexer