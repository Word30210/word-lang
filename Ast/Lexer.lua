local Token = require("Ast/Token")

local Lexer = {}
Lexer.__index = Lexer

Lexer.alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
Lexer.digits = "0123456789"
Lexer.whitespaces = "\32\t\n\r\f"
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
Lexer.iden = "[%a_][%w_]*"
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

    ["//"] = Token.kind.comment;
    ["/*"] = Token.kind.multilineCommentStart;
    ["*/"] = Token.kind.multilineCommentEnd;
}

function Lexer.new(source)
    local this = {}

    this._source = source
    this._position = 1
    this._tokens = {}

    return setmetatable(this, Lexer)
end

function Lexer.is(object)
    return type(object) == "table" and getmetatable(object) == Lexer
end

function Lexer.sortOperators(operatorTable)
    local tables = {}

    for operator, token in pairs(operatorTable) do
        local length = #operator

        if not tables[length] then
            for i = 1, length do
                tables[i] = tables[i] or {}
            end
        end

        tables[length][operator] = token
    end
end

function Lexer:_error(str, ...)
    error(str:format(...))
end

function Lexer:_peek(count)
    count = count or 0
    local endPosition = count + self._position
    return self._source:sub(self._position, endPosition)
end

function Lexer:_match(toMatch)
    return Lexer:_peek(#toMatch - 1) == toMatch
end

function Lexer:_advance()
    local character = self:_peek()
    self._position = self._position + 1
    return character
end

function Lexer:_accept(toMatch)
    if self:_match(toMatch) then
        self._position = self._position + #toMatch
        return toMatch
    end

    return nil
end

function Lexer:_expect(toMatch)
    local match = self:_accept(toMatch)
    if not match then
        self:_error("Expected %s", toMatch)
    end

    return match
end

function Lexer:_readString()
    local start = self._position
    local quote = self:_accept("'") or self:_accept('"')
    local charArray = {}

    while not self:_accept(quote) do
        local character = self:_advance()

        if character == "\\" then
            local escapeChar = self:_advance()
            local escapeSequence = Lexer.escapeSequences[escapeChar]
            if not escapeSequence then
                self:_error("%s is not a valid escape sequence", escapeChar)
                break
            end

            character = escapeChar
        end

        table.insert(charArray, character)
    end

    local asString = table.concat(charArray)
    return Token.new(Token.kind.string, start, self._position, asString)
end