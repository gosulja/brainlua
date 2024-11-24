local opcode = require("src.opcode")

local Interpreter = {}

function Interpreter.new()
    local self = setmetatable({}, {__index=Interpreter})
    self.mem = {}
    self.debug = false
    for i = 1, 30000 do self.mem[i] = 0 end
    return self
end

function Interpreter:get_memory(index)
    if index < 1 or index > 30000 then
        error(string.format("Memory pointer out of bounds: %d", index))
    end
    return self.mem[index]
end

function Interpreter:set_memory(index, value)
    if index < 1 or index > 30000 then
        error(string.format("Memory pointer out of bounds: %d", index))
    end
    
    while value < 0 do value = value + 256 end
    self.mem[index] = value % 256
end

function Interpreter:exec(bytecode, debug)
    self.debug = debug
    local stk = {}      -- loop stack
    local ptr = 1
    local pc = 1
    
    if self.debug then
        print("\nStarting execution:")
    end
    
    local ljumps = {}
    for i = 1, #bytecode do
        local inst = bytecode[i]
        if inst.opcode == opcode.LSTART then
            table.insert(stk, i)
        elseif inst.opcode == opcode.LEND then
            local lstart = table.remove(stk)
            if not lstart then
                error(string.format("error [p:%d] Unmatched loop end", i))
            end
            ljumps[lstart] = i  -- forward jmp
            ljumps[i] = lstart  -- back jmp
        end
    end

    if #stk > 0 then
        error(string.format("error [p:%d] Unmatched loop start", stk[1]))
    end
    
    while pc <= #bytecode do
        local inst = bytecode[pc]
        local next_pc = pc + 1
        
        if self.debug then
            print(string.format("PC: %d, Ptr: %d, Op: %d, Value: %d", pc, ptr, inst.opcode, inst.value))
        end
        
        if inst.opcode == opcode.INC_PTR then
            ptr = ptr + inst.value
            if ptr > 30000 then 
                error(string.format("error [pc:%d] Memory pointer out of bounds", pc))
            end
        elseif inst.opcode == opcode.DEC_PTR then
            ptr = ptr - inst.value
            if ptr < 1 then 
                error(string.format("error [pc:%d] Memory pointer out of bounds", pc))
            end
        elseif inst.opcode == opcode.INC_VAL then
            local current = self:get_memory(ptr)
            self:set_memory(ptr, current + inst.value)
        elseif inst.opcode == opcode.DEC_VAL then
            local current = self:get_memory(ptr)
            self:set_memory(ptr, current - inst.value)
        elseif inst.opcode == opcode.PUT then
            local val = self:get_memory(ptr)
            if self.debug then
                print(string.format("Output: %d ('%s')", val, string.char(val)))
            end
            io.write(string.char(val))
            io.flush()
        elseif inst.opcode == opcode.GET then
            local input = io.read(1)
            if input then
                local byte = string.byte(input)
                if byte < 0 or byte > 255 then
                    error(string.format("error [pc:%d] Invalid input ASCII value: %d", pc, byte))
                end
                self:set_memory(ptr, byte)
            else
                self:set_memory(ptr, 0)
            end
        elseif inst.opcode == opcode.LSTART then
            if self:get_memory(ptr) == 0 then
                if not ljumps[pc] then
                    error(string.format("error [pc:%d] No matching jump found for loop start", pc))
                end
                next_pc = ljumps[pc] + 1
            end
        elseif inst.opcode == opcode.LEND then
            if self:get_memory(ptr) ~= 0 then
                if not ljumps[pc] then
                    error(string.format("error [pc:%d] No matching jump found for loop end", pc))
                end
                next_pc = ljumps[pc]
            end
        end
        
        pc = next_pc
    end
end

return Interpreter