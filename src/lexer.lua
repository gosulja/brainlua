local Lexer = {}

function Lexer.new(source)
    local self = setmetatable({}, {__index=Lexer})
    self.source = source
    self.position = 1
    self.current = source:sub(self.position, self.position)
    return self
end

function Lexer:not_at_end()
    return self.position < #self.source + 1
end

function Lexer:advance()
    if not self:not_at_end() then return end

    self.position = self.position + 1
    self.current = self.source:sub(self.position, self.position)
end

function Lexer:tokenize()
    local tokens = {}

    while self:not_at_end() do
        if self.current == ">" then
            tokens[#tokens + 1] = {type = "inc_ptr"}
            self:advance()
        elseif self.current == "<" then
            tokens[#tokens + 1] = {type = "dec_ptr"}
            self:advance()
        elseif self.current == "+" then
            tokens[#tokens + 1] = {type = "inc_value"}
            self:advance()
        elseif self.current == "-" then
            tokens[#tokens + 1] = {type = "dec_value"}
            self:advance()
        elseif self.current == "[" then
            tokens[#tokens + 1] = {type = "while_not_loop"}
            self:advance()
        elseif self.current == "]" then
            tokens[#tokens + 1] = {type = "if_block_jump"}
            self:advance()
        elseif self.current == "," then
            tokens[#tokens + 1] = {type = "get_char" }
            self:advance()
        elseif self.current == "." then
            tokens[#tokens + 1] = {type = "put_char"}
            self:advance()
        else
            self:advance()
        end
    end

    return tokens
end

return Lexer