local OpCode = require("src.opcode")

local Compiler = {}

function Compiler.new(tokens)
    local self = setmetatable({}, {__index=Compiler})
    self.tokens = tokens
    return self
end

function Compiler:compile()
    local bytecode = {}
    local lstack = {}

    local ip = 1
    while ip <= #self.tokens do
        local token = self.tokens[ip]
        local c = 1

        -- Only compress operators that make sense to compress
        if token.type == "inc_ptr" or token.type == "dec_ptr" or 
           token.type == "inc_value" or token.type == "dec_value" then
            while ip < #self.tokens and self.tokens[ip + 1].type == token.type do
                c = c + 1
                ip = ip + 1
            end
        end

        if token.type == "inc_ptr" then
            table.insert(bytecode, {opcode = OpCode.INC_PTR, value = c})
        elseif token.type == "dec_ptr" then
            table.insert(bytecode, {opcode = OpCode.DEC_PTR, value = c})
        elseif token.type == "inc_value" then
            table.insert(bytecode, {opcode = OpCode.INC_VAL, value = c})
        elseif token.type == "dec_value" then
            table.insert(bytecode, {opcode = OpCode.DEC_VAL, value = c})
        elseif token.type == "put_char" then
            table.insert(bytecode, {opcode = OpCode.PUT, value = 1})
        elseif token.type == "get_char" then
            table.insert(bytecode, {opcode = OpCode.GET, value = 1})
        elseif token.type == "while_not_loop" then
            table.insert(bytecode, {opcode = OpCode.LSTART, value = 0})
            table.insert(lstack, #bytecode)
        elseif token.type == "if_block_jump" then
            local loop_start = table.remove(lstack)
            if not loop_start then
                error("Unmatched loop end")
            end
            table.insert(bytecode, {opcode = OpCode.LEND, value = loop_start})
            bytecode[loop_start].value = #bytecode
        end

        ip = ip + 1
    end

    if #lstack > 0 then
        error("Unmatched loop start")
    end

    return bytecode
end

return Compiler