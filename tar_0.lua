local function find_input_files(folder)
    local files = {}

    local handle = io.popen('dir "' .. folder .. '\\*.vm" /b')

    for file in handle:lines() do
        table.insert(files, file)
    end

    handle:close()

    return files
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
        elseif words[1] == "push" then
            handlePush(words[2], words[3])
        elseif words[1] == "pop" then
            handlePop(words[2], words[3])
        end
    end
    
    file:close()
end
    

local function main()
    OUTPUT_FILE = nil
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
    print("Found " .. #files .. " .vm files in the folder.")

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
