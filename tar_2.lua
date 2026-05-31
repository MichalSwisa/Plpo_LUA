-- Ruth Ulman 325442259, Michal swisa 326002813 
-- Group number: 150060.11.5786.41
-- No .exe file is included in the submission, as LUA works with the interpreter.

local function find_input_files(folder)
    local files = {}

    -- Windows command: list only file names in the given folder
    local command = 'dir /b "' .. folder .. '"'
    local handle = io.popen(command)

    if handle == nil then
        return files
    end

    for file in handle:lines() do
        if file:match("%.vm$") then
            table.insert(files, file)
        end
    end

    handle:close()

    return files
end

-- handlers

local function handleAdd()
    output_file:write(
    [[// add
@SP
A=M-1
D=M
A=A-1
M=D+M
@SP
M=M-1

]])
end

local function handleSub()
    output_file:write(
    [[// sub
@SP
A=M-1
D=M
A=A-1
M=M-D
@SP
M=M-1

]])
end

local function handlNeg()
    output_file:write(
    [[// neg
@SP
A=M-1
D=M
M=-D

]])
end

local function handleEq()
    counter = counter + 1
    output_file:write(string.format(
    [[// eq
@SP
A=M-1
D=M
A=A-1
D=D-M
@IF_TRUE%d
D;JEQ
D=0
@SP
A=M-1
A=A-1
M=D
@IF_FALSE%d
0;JMP
(IF_TRUE%d)
D=-1
@SP
A=M-1
A=A-1
M=D
(IF_FALSE%d)
@SP
M=M-1

]], counter, counter, counter, counter))
end

local function handleGt()
    counter = counter + 1
    output_file:write(string.format(
    [[// gt
@SP
A=M-1
D=M
A=A-1
D=D-M
@IF_TRUE%d
D;JLT
D=0
@SP
A=M-1
A=A-1
M=D
@IF_FALSE%d
0;JMP
(IF_TRUE%d)
D=-1
@SP
A=M-1
A=A-1
M=D
(IF_FALSE%d)
@SP
M=M-1

]], counter, counter, counter, counter))
end

local function handleLt()
    counter = counter + 1
    output_file:write(string.format(
    [[// lt
@SP
A=M-1
D=M
A=A-1
D=D-M
@IF_TRUE%d
D;JGT
D=0
@SP
A=M-1
A=A-1
M=D
@IF_FALSE%d
0;JMP
(IF_TRUE%d)
D=-1
@SP
A=M-1
A=A-1
M=D
(IF_FALSE%d)
@SP
M=M-1

]], counter, counter, counter, counter))
end

local function handleAnd()
    output_file:write(
    [[// and
@SP
A=M-1
D=M
A=A-1
M=M&D
@SP
M=M-1

]])
end

local function handleOr()
    output_file:write(
    [[// or
@SP
A=M-1
D=M
A=A-1
M=D|M
@SP
M=M-1

]])
end

local function handleNot()
    output_file:write(
    [[// not
@SP
A=M-1
M=!M

]])
end

local function handlePush(segment, index)
    local intIndex = tonumber(index)
    local type = ""

    if segment == "constant" then
        output_file:write(string.format(
        [[// push constant %s
@%s
D=A
@SP
A=M
M=D
@SP
M=M+1

]], index, index))

    elseif segment == "temp" then
        intIndex = intIndex + 5
        output_file:write(string.format(
        [[// push temp %s
@%d
D=M
@SP
A=M
M=D
@SP
M=M+1

]], index, intIndex))

    elseif segment == "pointer" then
        if index == "0" then
            type = "THIS"
        else
            type = "THAT"
        end

        output_file:write(string.format(
        [[// push pointer %s
@%s
D=M
@SP
A=M
M=D
@SP
M=M+1

]], index, type))

    elseif segment == "static" then
        output_file:write(string.format(
        [[// push static %s
@%s.%s
D=M
@SP
A=M
M=D
@SP
M=M+1

]], index, CURRENT_FILE_NAME, index))

    elseif segment == "local" then
        type = "LCL"

    elseif segment == "argument" then
        type = "ARG"

    elseif segment == "this" then
        type = "THIS"

    elseif segment == "that" then
        type = "THAT"
    end

    if segment ~= "constant" and segment ~= "temp" and segment ~= "pointer" and segment ~= "static" then
        output_file:write(string.format(
        [[// push %s %s
@%s
D=A
@%s
A=M+D
D=M
@SP
A=M
M=D
@SP
M=M+1

]], segment, index, index, type))
    end
end

local function handlePop(segment, index)
    local intIndex = tonumber(index)
    local loop = ""
    local type = ""

    for i = 1, intIndex do
        loop = loop .. "A=A+1\n"
    end

    if segment == "temp" then
        intIndex = intIndex + 5
        output_file:write(string.format(
        [[// pop temp %s
@SP
A=M-1
D=M
@%d
M=D
@SP
M=M-1

]], index, intIndex))

    elseif segment == "pointer" then
        if index == "0" then
            type = "THIS"
        else
            type = "THAT"
        end

        output_file:write(string.format(
        [[// pop pointer %s
@SP
A=M-1
D=M
@%s
M=D
@SP
M=M-1

]], index, type))

    elseif segment == "static" then
        output_file:write(string.format(
        [[// pop static %s
@SP
M=M-1
A=M
D=M
@%s.%s
M=D

]], index, CURRENT_FILE_NAME, index))

    elseif segment == "local" then
        type = "LCL"

    elseif segment == "argument" then
        type = "ARG"

    elseif segment == "this" then
        type = "THIS"

    elseif segment == "that" then
        type = "THAT"
    end

    if segment ~= "temp" and segment ~= "pointer" and segment ~= "static" then
        output_file:write(string.format(
        [[// pop %s %s
@SP
A=M-1
D=M
@%s
A=M
%sM=D
@SP
M=M-1

]], segment, index, type, loop))
    end
end

local function handleLabel(label)
    -- Creates a label that can be used as a jump target.
    local prefix = CURRENT_FUNCTION ~= "" and CURRENT_FUNCTION or CURRENT_FILE_NAME

    output_file:write(string.format(
    [[// label %s
(%s$%s)

]], label, prefix, label))
end

local function handleGoto(label)
    -- Performs an unconditional jump to a label.
    local prefix = CURRENT_FUNCTION ~= "" and CURRENT_FUNCTION or CURRENT_FILE_NAME

    output_file:write(string.format(
    [[// goto %s
@%s$%s
0;JMP

]], label, prefix, label))
end

local function handleIfGoto(label)
    -- Performs a conditional jump based on the top value of the stack.
    local prefix = CURRENT_FUNCTION ~= "" and CURRENT_FUNCTION or CURRENT_FILE_NAME

    output_file:write(string.format(
    [[// if-goto %s
@SP
M=M-1
A=M
D=M
@%s$%s
D;JNE

]], label, prefix, label))
end

local function handleFunction(name, k)
    -- Declares a function and initializes its local variables.
    CURRENT_FUNCTION = name

    output_file:write(string.format(
    [[// function %s %s
(%s)
]], name, k, name))

    k = tonumber(k)

    for i = 1, k do
        handlePush("constant", "0")
    end
end

local function handleCall(name, n)
    -- Calls a function:
    -- Saves the caller state, sets up the new frame, and jumps to the function.
    call_counter = call_counter + 1
    local return_label = name .. "$ret." .. call_counter

    -- push return address
    output_file:write(string.format(
    [[// call %s %s
@%s
D=A
@SP
A=M
M=D
@SP
M=M+1
]], name, n, return_label))

    -- push LCL
    output_file:write(
    [[@LCL
D=M
@SP
A=M
M=D
@SP
M=M+1
]])

    -- push ARG
    output_file:write(
    [[@ARG
D=M
@SP
A=M
M=D
@SP
M=M+1
]])

    -- push THIS
    output_file:write(
    [[@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
]])

    -- push THAT
    output_file:write(
    [[@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
]])

    -- ARG = SP - n - 5
    output_file:write(string.format(
    [[@SP
D=M
@%d
D=D-A
@5
D=D-A
@ARG
M=D
]], tonumber(n)))

    -- LCL = SP
    output_file:write(
    [[@SP
D=M
@LCL
M=D
]])

    -- goto function
    output_file:write(string.format(
    [[@%s
0;JMP
(%s)

]], name, return_label))
end

local function handleReturn()
    -- Returns from a function:
    -- Restores the caller state and jumps back to the return address.
    output_file:write(
    [[// return

// FRAME = LCL
@LCL
D=M
@R13
M=D

// RET = *(FRAME - 5)
@5
A=D-A
D=M
@R14
M=D

// *ARG = pop()
@SP
M=M-1
A=M
D=M
@ARG
A=M
M=D

// SP = ARG + 1
@ARG
D=M+1
@SP
M=D

// THAT = *(FRAME - 1)
@R13
M=M-1
A=M
D=M
@THAT
M=D

// THIS = *(FRAME - 2)
@R13
M=M-1
A=M
D=M
@THIS
M=D

// ARG = *(FRAME - 3)
@R13
M=M-1
A=M
D=M
@ARG
M=D

// LCL = *(FRAME - 4)
@R13
M=M-1
A=M
D=M
@LCL
M=D

// goto RET
@R14
A=M
0;JMP

]])
end

-- process input file

local function read_file(file_name, folder_path)
    counter = 0
    CURRENT_FILE_NAME = string.gsub(file_name, "%.vm$", "")

    local file = io.open(folder_path .. "/" .. file_name, "r")

    if file == nil then
        print("Failed to open input file: " .. folder_path .. "/" .. file_name)
        return
    end

    for line in file:lines() do
        -- Remove comments from the middle/end of the line
        line = line:gsub("//.*", "")

        -- Skip empty lines
        if not line:match("^%s*$") then
            local words = {}

            for w in string.gmatch(line, "%S+") do
                table.insert(words, w)
            end

            if words[1] == "add" then
                handleAdd()

            elseif words[1] == "sub" then
                handleSub()

            elseif words[1] == "neg" then
                handlNeg()

            elseif words[1] == "eq" then
                handleEq()

            elseif words[1] == "gt" then
                handleGt()

            elseif words[1] == "lt" then
                handleLt()

            elseif words[1] == "and" then
                handleAnd()

            elseif words[1] == "or" then
                handleOr()

            elseif words[1] == "not" then
                handleNot()

            elseif words[1] == "push" then
                handlePush(words[2], words[3])

            elseif words[1] == "pop" then
                handlePop(words[2], words[3])

            elseif words[1] == "label" then
                handleLabel(words[2])

            elseif words[1] == "goto" then
                handleGoto(words[2])

            elseif words[1] == "if-goto" then
                handleIfGoto(words[2])

            elseif words[1] == "function" then
                handleFunction(words[2], words[3])

            elseif words[1] == "call" then
                handleCall(words[2], words[3])

            elseif words[1] == "return" then
                handleReturn()
            end
        end
    end

    file:close()
end

local function main()
    output_file = nil

    -- Get the input folder from command line arguments
    local folder_path = arg[1]

    if folder_path == nil then
        print("Usage: lua5.1 tar_2.lua <input folder>")
        return
    end

    -- Find all .vm files in the input folder
    local files = find_input_files(folder_path)

    if files == nil or #files == 0 then
        print("No .vm files found in the specified folder.")
        return
    end

    -- Extract folder name for output file.
    -- Works with both Windows backslash paths and slash paths.
    local folder_name = string.match(folder_path, "([^\\/]+)$")
    local output_file_name = folder_name .. ".asm"
    local output_file_path = folder_path .. "/" .. output_file_name

    -- Create output file
    output_file = io.open(output_file_path, "w")

    if output_file == nil then
        print("Failed to create output file: " .. output_file_path)
        return
    end

    local has_sys = false

    for _, file_name in ipairs(files) do
        if file_name == "Sys.vm" then
            has_sys = true
        end
    end

    -- Bootstrap code, only if Sys.vm exists
    if has_sys then
        output_file:write(
        [[// bootstrap
@256
D=A
@SP
M=D

]])
        handleCall("Sys.init", 0)
    end

    -- Process each .vm file
    for _, file_name in ipairs(files) do
        read_file(file_name, folder_path)
        print("End of input file: " .. file_name)
    end

    -- Close output file
    print("Output file is ready: " .. output_file_name)
    output_file:close()
end

CURRENT_FILE_NAME = nil
CURRENT_FUNCTION = ""
counter = 0
call_counter = 0

main()