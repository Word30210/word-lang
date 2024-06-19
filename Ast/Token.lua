local Enumerate = require("Common/Enumerate")

local Token = {}
Token.__index = Token

Token.kind = Enumerate("Token.kind", {
    "let", "do", "end", "if", "elif", "else", "for", "while", "fn", "true", "false", "null", "break",

    "plus", "minus", "star", "dash", "modulo", "hashtag", "caret", "semiColon", "colon", "dot", "questionMark", "exclamationMark", "ampersand", "pipe",
    "equal", "notEqual", "equalTo", "lessThan", "lessEqual", "greaterThan", "greaterEqual",
    "leftParen", "rightParen", "leftBrace", "rightBrace", "leftBracket", "rightBracket",
    "plusEqual", "minusEqual", "starEqual", "dashEqual", "moduloEqual", "caretEqual",

    "comment", "multilineComment",

    "iden", "string", "number", "eof"
})

function Token.new(tokenKind, startPosition, endPosition, value)
    local this = {}

    this.kind = tokenKind
    this.startPosition = startPosition
    this.endPosition = endPosition
    this.value = value

    return setmetatable(this, Token)
end

function Token.is(object)
    return type(object) == "table" and getmetatable(object) == Token
end

return Token