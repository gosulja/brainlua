# brainlua
A brainfuck implementation written in Lua with LuaJIT.

This implementation currently passes all of the tests internally, if you want to contribute and fix any errors you encounter, please add new test cases and a pull request!

# Requirements
* LuaJIT

# Usage
Make sure you have the requirements installed on your machine before proceeding.

### Clone the repository.
```bash
$ git clone https://github.com/gosulja/brainlua.git
$ cd brainlua
```

### Run internal test cases.
```bash
$ luajit src/main.lua -t
```

This will run the repl along with the test cases.

### Running files
```bash
$ luajit src/main.lua examples/cat.b
```

Files require to have the `.b` file extension.

# Resources
* https://www.brainfuck.org/
* https://www.brainfuck.org/epistle.html
* https://www.brainfuck.org/tests.b
