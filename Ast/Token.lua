local Enumerate = require("Common.Enumerate")

local Token = {}
Token.__index = Token

Token.kind = Enumerate("Token.kind", {
    "var", "fn", "if", "elseif", "else", "for", "while", "each", "in", "void", "true", "false", "break", "return",

    "plus", "minus", "star", "slash", "modulo", "hashtag", "caret", "semiColon", "colon", "comma", "dot", "dot2", "dot3",
    "questionMark", "exclamationMark", "ampersand", "pipe",

    "equal", "notEqual", "equalTo", "lessThan", "lessEqual", "greaterThan", "greaterEqual",
    "leftParen", "rightParen", "leftBrace", "rightBrace", "leftBracket", "rightBracket",
    "plusEqual", "minusEqual", "starEqual", "slashEqual", "moduloEqual", "caretEqual", "dot2Equal", "questionMarkEqual",

    "comment", "multilineComment", "incompleteMultilineComment",

    "iden", "string", "incompleteString", "multilineString", "incompleteMultilineString",
    
    "number", "binaryNumber", "hexadecimalNumber", "octalNumber",
    
    "unknown", "eof"
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