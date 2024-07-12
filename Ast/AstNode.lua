local Enumerate = require("Common.Enumerate")

local AstNode = {}
AstNode.__index = AstNode

AstNode.kind = Enumerate("AstNode.kind", {
    "True", "False", "Null",
    "Iden", "String", "Number",

    "Len", "Negative", "Not",

    "Add", "Sub", "Mul", "Div", "Mod", "Pow", "Concat",
    "CompareEqualTo", "CompareNotEqual", "CompareLessThan", "CompareLessEqual", "CompareGreaterThan", "CompareGreaterEqual",
    "And", "Or",

    "Break", "Return",

    "IndexName", "IndexExpr", "SelfIndexName", "TableConstructor", "FunctionCall",

    "IfStatement", "FunctionStatement", "CompoundAssignStatement", "AssignStatement",

    "NormalBlock", "WhileLoop", "ForLoop", "EachLoop", "LetFn", "Let", "Block",

    "EndOfFile"
})

function AstNode.fromArray(nodeKind, children, value)
    local self = {}

    self.nodeKind = nodeKind
    self.children = children
    self.value = value

    return setmetatable(self, AstNode)
end

function AstNode.new(nodeKind, ...)
    return AstNode.fromArray(nodeKind, nil, table.pack(...))
end

function AstNode.fromValue(nodeKind, value, ...)
    return AstNode.fromArray(nodeKind, table.pack(...), value)
end

function AstNode.is(object)
    return type(object) == "table" and getmetatable(object) == AstNode
end

return AstNode