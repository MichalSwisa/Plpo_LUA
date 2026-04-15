-- Ruth Ulman 325442259, Michal swisa 326002813 
-- Group number: 150060.11.5786.41
-- No .exe file is included in the submission, as LUA works with the interpreter.


local function find_input_files(folder)
    local files = {}

    local handle = io.popen('dir "' .. folder .. '\\*.vm" /b')

    for file in handle:lines() do
        table.insert(files, file)
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
    D=0 //push 0 (false)
    @SP
    A=M-1
    A=A-1
    M=D
    @IF_FALSE%d 
    0;JMP
    (IF_TRUE%d) 
    D=-1 //push -1 (true)
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
    D=0 //push 0 (false)
    @SP
    A=M-1
    A=A-1
    M=D
    @IF_FALSE%d 
    0;JMP
    (IF_TRUE%d) 
    D=-1 //push -1 (true)
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
        %s
        M=D
        @SP
        M=M-1

        ]], segment, index, type, loop))
    end
    
end


-- process input file

local function read_file(file_name, folder_path)
    counter = 0
    CURRENT_FILE_NAME = string.gsub(file_name, "%.vm$", "")
    local file = io.open(folder_path .. "\\" .. file_name, "r")

    for line in file:lines() do
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
        end
    end
    
    file:close()
end




local function main()
    output_file = nil
    -- Get the input folder from command line arguments
    local folder_path = arg[1]
    if folder_path == nil then
        print("Usage: lua5.1 main.lua <input folder>")
        return
    end

    -- Find all .vm file's paths in the input folder
    local files = find_input_files(folder_path)
    if files == nil or #files == 0 then
        print("No .vm files found in the specified folder.")
        return
    end

    -- Extract the folder name from the input path to create the output file name
    local folder_name = string.match(folder_path, "([^\\]+)$")
    local output_file_name = folder_name.. ".asm"
    local output_file_path = folder_path .. "\\" .. output_file_name

    -- Create the output file
    output_file = io.open(output_file_path, "w")
    if output_file == nil then
        print("Failed to create output file: " .. output_file_path)
        return
    end

    -- Process each .vm file
    for _, file_name in ipairs(files) do
        read_file(file_name, folder_path)
        print("End of input file:" ..file_name)
    end

    -- Close the output file
    print("Output file is ready:" ..output_file_name)
    output_file:close()

end

CURRENT_FILE_NAME = nil
main()
