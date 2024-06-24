local Enumerate = require("Common.Enumerate")

local Token = {}
Token.__index = Token

Token.kind = Enumerate("Token.kind", {
    "let", "if", "elif", "else", "for", "while", "each", "in", "fn", "true", "false", "null", "break", "return", "goto",

    "plus", "minus", "star", "slash", "modulo", "hashtag", "caret", "semiColon", "colon", "dot", "comma", "tilde", "questionMark", "exclamationMark", "atTheRate", "dollar", "ampersand", "pipe",
    "equal", "notEqual", "equalTo", "lessThan", "lessEqual", "greaterThan", "greaterEqual",
    "leftParen", "rightParen", "leftBrace", "rightBrace", "leftBracket", "rightBracket",
    "plusEqual", "minusEqual", "starEqual", "slashEqual", "moduloEqual", "caretEqual", "tildeEqual",

    "comment", "multilineComment",

    "iden", "string", "incompleteString", "number", "unknown", "eof"
})

function Token.new(tokenKind, startPosition, endPosition, value)
    local self = {}

    self.kind = tokenKind
    self.startPosition = startPosition
    self.endPosition = endPosition
    self.value = value

    return setmetatable(self, Token)
end

function Token.is(object)
    return type(object) == "table" and getmetatable(object) == Token
end

return Token