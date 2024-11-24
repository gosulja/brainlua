local lexer = require("src.lexer")
local compiler = require("src.compiler")
local interpreter = require("src.interpreter")
local tester = require("src.tester")

local run_tests = false
local file_path = nil

for _, argument in ipairs(arg) do
    if argument == "-t" then
        run_tests = true
    elseif argument:sub(-2) == ".b" then
        file_path = argument
    end
end

if run_tests then
    tester.run_all()
end

local source

if file_path then
    local file = io.open(file_path, "r")
    if file then
        source = file:read("*a")
        file:close()
    else
        error("Error: Could not open file " .. file_path)
    end
else
    io.write(">>> ")
    source = io.read()
end

local tokens = lexer.new(source):tokenize()
local bytecode = compiler.new(tokens):compile()

local core = interpreter.new()
core:exec(bytecode)
