local interpreter = require("src.interpreter")
local lexer = require("src.lexer")
local compiler = require("src.compiler")
local opcode = require("src.opcode")

local Tester = {}

function Tester.print_bytecode(bytecode)
    local opnames = {}
    for name, code in pairs(opcode) do
        opnames[code] = name
    end
    
    print("\nBytecode:")
    for i, inst in ipairs(bytecode) do
        print(string.format("%3d: %s %d", i, opnames[inst.opcode], inst.value))
    end
end

Tester.tests = {
    -- Basic ASCII output test
    test_hello_world = {
        code = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.",
        input = "",
        expected = "Hello World!\n",
        debug = false
    },
    
    -- ASCII value wrapping test
    test_wrap = {
        code = "+++++++++++[>++++++++<-]>.",  -- 11 * 8 = 88 ('X')
        input = "",
        expected = "X",
        debug = false
    },

    -- Test for several obscure problems
    test_obscure = {
        code = "[]++++++++++[>>+>+>++++++[<<+<+++>>>-]<<<<-]\"A*$\";?@![#>>+<<]>[>>]<<<<[>++<[-]]>.>",
        input = "",
        expected = "H",
        debug = false,
    },

    -- 
    
    -- Input/output echo test
    test_echo = {
        code = ",[.,]",
        input = "test",
        expected = "test",
        debug = false
    },
    
    test_cell_wrap = {
        code = string.rep("+", 256) .. ".",
        input = "",
        expected = "\0",
        debug = false
    },
}

function Tester.capture_output(fn)
    local old_write = io.write
    local output = {}
    io.write = function(str) table.insert(output, str) end
    
    local status, err = pcall(fn)
    
    io.write = old_write
    return status, table.concat(output), err
end

function Tester.with_input(input, fn)
    local old_read = io.read
    local input_idx = 1
    io.read = function(n)
        if input_idx > #input then return nil end
        local char = input:sub(input_idx, input_idx)
        input_idx = input_idx + 1
        return char
    end
    
    local status, output, err = Tester.capture_output(fn)
    
    io.read = old_read
    return status, output, err
end

function Tester.run_all()
    local passed = 0
    local failed = 0
    
    for name, test in pairs(Tester.tests) do
        io.write(string.format("Running %s... ", name))
        
        local interp = interpreter.new()
        local tokens = lexer.new(test.code):tokenize()
        local bytecode = compiler.new(tokens):compile()
        
        if test.debug then
            Tester.print_bytecode(bytecode)
        end
        
        local run_test = function()
            interp:exec(bytecode)
        end
        
        local status, output, err
        if test.input and #test.input > 0 then
            status, output, err = Tester.with_input(test.input, run_test)
        else
            status, output, err = Tester.capture_output(run_test)
        end
        
        local test_passed = false
        if test.expected_error then
            test_passed = not status
        else
            test_passed = status and output == test.expected
        end
        
        if test_passed then
            print("PASSED")
            passed = passed + 1
        else
            print("FAILED")
            print("  Expected: " .. (test.expected_error and "error" or string.format("%q", test.expected)))
            print("  Got: " .. (status and string.format("%q", output) or tostring(err)))
            if test.debug then
                if output then
                    print("  Output char codes:", table.concat({string.byte(output, 1, #output)}, ", "))
                end
                print("  Expected char codes:", table.concat({string.byte(test.expected, 1, #test.expected)}, ", "))
            end
        end
    end
    
    print(string.format("\nTest Summary: %d passed, %d failed", passed, failed))
    return passed, failed
end

function Tester.add_test(name, code, expected, input)
    Tester.tests[name] = {
        code = code,
        expected = expected,
        input = input or "",
        debug = false
    }
end

return Tester