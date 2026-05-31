-- Michal swisa 326002813, Ruth Ulman 325442259

------------------------------------------------------------
-- Global lists
------------------------------------------------------------

local listOfKeywords = {
    ["class"] = true,
    ["constructor"] = true,
    ["function"] = true,
    ["method"] = true,
    ["field"] = true,
    ["static"] = true,
    ["var"] = true,
    ["int"] = true,
    ["char"] = true,
    ["boolean"] = true,
    ["void"] = true,
    ["true"] = true,
    ["false"] = true,
    ["null"] = true,
    ["this"] = true,
    ["let"] = true,
    ["do"] = true,
    ["if"] = true,
    ["else"] = true,
    ["while"] = true,
    ["return"] = true
}

local listOfSymbols = {
    ["{"] = true,
    ["}"] = true,
    ["("] = true,
    [")"] = true,
    ["["] = true,
    ["]"] = true,
    ["."] = true,
    [","] = true,
    [";"] = true,
    ["+"] = true,
    ["-"] = true,
    ["*"] = true,
    ["/"] = true,
    ["&"] = true,
    ["|"] = true,
    ["<"] = true,
    [">"] = true,
    ["="] = true,
    ["~"] = true
}

local operators = {
    ["+"] = true,
    ["-"] = true,
    ["*"] = true,
    ["/"] = true,
    ["&"] = true,
    ["|"] = true,
    ["<"] = true,
    [">"] = true,
    ["="] = true
}

local unaryOperators = {
    ["-"] = true,
    ["~"] = true
}

local keywordConstants = {
    ["true"] = true,
    ["false"] = true,
    ["null"] = true,
    ["this"] = true
}

------------------------------------------------------------
-- Utility functions
------------------------------------------------------------

local function trim_trailing_slash(path)
    return string.gsub(path, "[/\\]+$", "")
end

local function escape_xml(value)
    value = string.gsub(value, "&", "&amp;")
    value = string.gsub(value, "<", "&lt;")
    value = string.gsub(value, ">", "&gt;")
    return value
end

local function is_digit(ch)
    return ch ~= nil and ch:match("%d") ~= nil
end

local function is_letter_or_underscore(ch)
    return ch ~= nil and ch:match("[%a_]") ~= nil
end

local function is_identifier_char(ch)
    return ch ~= nil and ch:match("[%w_]") ~= nil
end

local function token_to_xml_line(token)
    return "<" .. token.type .. "> " .. escape_xml(token.value) .. " </" .. token.type .. ">"
end

local function find_input_files(folder)
    local files = {}

    local command = 'dir /b "' .. folder .. '"'
    local handle = io.popen(command)

    if handle == nil then
        return files
    end

    for file in handle:lines() do
        if file:match("%.jack$") then
            table.insert(files, file)
        end
    end

    handle:close()
    return files
end

local function read_all_text(path)
    local file = io.open(path, "r")
    if file == nil then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function write_line(output_file, line)
    output_file:write(line .. "\n")
end

------------------------------------------------------------
-- Part 1: Tokenizing
------------------------------------------------------------

local function classify_word(word)
    if listOfKeywords[word] then
        return "keyword"
    elseif word:match("^%d+$") then
        return "integerConstant"
    else
        return "identifier"
    end
end

local function tokenize_content(content)
    local tokens = {}
    local i = 1
    local n = #content

    while i <= n do
        local ch = content:sub(i, i)
        local next_ch = content:sub(i + 1, i + 1)

        -- Skip spaces, tabs and new lines
        if ch:match("%s") then
            i = i + 1

        -- Line comment: //
        elseif ch == "/" and next_ch == "/" then
            i = i + 2
            while i <= n and content:sub(i, i) ~= "\n" do
                i = i + 1
            end

        -- Block comment: /* ... */
        elseif ch == "/" and next_ch == "*" then
            i = i + 2
            while i <= n - 1 do
                if content:sub(i, i) == "*" and content:sub(i + 1, i + 1) == "/" then
                    i = i + 2
                    break
                end
                i = i + 1
            end

        -- String constant
        elseif ch == '"' then
            i = i + 1
            local temp = ""

            while i <= n and content:sub(i, i) ~= '"' do
                temp = temp .. content:sub(i, i)
                i = i + 1
            end

            table.insert(tokens, {
                type = "stringConstant",
                value = temp
            })

            i = i + 1

        -- Symbol
        elseif listOfSymbols[ch] then
            table.insert(tokens, {
                type = "symbol",
                value = ch
            })

            i = i + 1

        -- Integer constant
        elseif is_digit(ch) then
            local temp = ""

            while i <= n and is_digit(content:sub(i, i)) do
                temp = temp .. content:sub(i, i)
                i = i + 1
            end

            table.insert(tokens, {
                type = "integerConstant",
                value = temp
            })

        -- Keyword or identifier
        elseif is_letter_or_underscore(ch) then
            local temp = ""

            while i <= n and is_identifier_char(content:sub(i, i)) do
                temp = temp .. content:sub(i, i)
                i = i + 1
            end

            table.insert(tokens, {
                type = classify_word(temp),
                value = temp
            })

        else
            -- Unknown character, skip it
            i = i + 1
        end
    end

    return tokens
end

local function create_tokens_xml(tokens, output_path)
    local output_file = io.open(output_path, "w")

    if output_file == nil then
        print("Failed to create tokens file: " .. output_path)
        return
    end

    write_line(output_file, "<tokens>")

    for _, token in ipairs(tokens) do
        write_line(output_file, token_to_xml_line(token))
    end

    write_line(output_file, "</tokens>")
    output_file:close()
end

------------------------------------------------------------
-- Part 2: Parsing
------------------------------------------------------------

local Parser = {}
Parser.__index = Parser

function Parser:new(tokens, output_path)
    local obj = {}
    setmetatable(obj, Parser)

    obj.tokens = tokens
    obj.index = 1
    obj.output_file = io.open(output_path, "w")
    obj.indent = 0

    return obj
end

function Parser:close()
    if self.output_file ~= nil then
        self.output_file:close()
    end
end

function Parser:indent_string()
    return string.rep("  ", self.indent)
end

function Parser:write(line)
    self.output_file:write(self:indent_string() .. line .. "\n")
end

function Parser:open_tag(tag)
    self:write("<" .. tag .. ">")
    self.indent = self.indent + 1
end

function Parser:close_tag(tag)
    self.indent = self.indent - 1
    self:write("</" .. tag .. ">")
end

function Parser:current()
    return self.tokens[self.index]
end

function Parser:next_token()
    return self.tokens[self.index + 1]
end

function Parser:current_value()
    local token = self:current()
    if token == nil then
        return nil
    end
    return token.value
end

function Parser:current_type()
    local token = self:current()
    if token == nil then
        return nil
    end
    return token.type
end

function Parser:write_current_and_advance()
    local token = self:current()

    if token == nil then
        return
    end

    self:write(token_to_xml_line(token))
    self.index = self.index + 1
end

function Parser:compileClass()
    self:open_tag("class")

    -- class className {
    self:write_current_and_advance()
    self:write_current_and_advance()
    self:write_current_and_advance()

    while self:current_value() == "static" or self:current_value() == "field" do
        self:compileClassVarDec()
    end

    while self:current_value() == "constructor" or self:current_value() == "function" or self:current_value() == "method" do
        self:compileSubroutine()
    end

    -- }
    self:write_current_and_advance()

    self:close_tag("class")
end

function Parser:compileClassVarDec()
    self:open_tag("classVarDec")

    -- static/field type varName
    self:write_current_and_advance()
    self:write_current_and_advance()
    self:write_current_and_advance()

    while self:current_value() == "," do
        self:write_current_and_advance()
        self:write_current_and_advance()
    end

    -- ;
    self:write_current_and_advance()

    self:close_tag("classVarDec")
end

function Parser:compileSubroutine()
    self:open_tag("subroutineDec")

    -- constructor/function/method void/type name (
    self:write_current_and_advance()
    self:write_current_and_advance()
    self:write_current_and_advance()
    self:write_current_and_advance()

    self:compileParameterList()

    -- )
    self:write_current_and_advance()

    self:compileSubroutineBody()

    self:close_tag("subroutineDec")
end

function Parser:compileParameterList()
    self:open_tag("parameterList")

    if self:current_value() ~= ")" then
        -- type varName
        self:write_current_and_advance()
        self:write_current_and_advance()

        while self:current_value() == "," do
            self:write_current_and_advance()
            self:write_current_and_advance()
            self:write_current_and_advance()
        end
    end

    self:close_tag("parameterList")
end

function Parser:compileSubroutineBody()
    self:open_tag("subroutineBody")

    -- {
    self:write_current_and_advance()

    while self:current_value() == "var" do
        self:compileVarDec()
    end

    self:compileStatements()

    -- }
    self:write_current_and_advance()

    self:close_tag("subroutineBody")
end

function Parser:compileVarDec()
    self:open_tag("varDec")

    -- var type varName
    self:write_current_and_advance()
    self:write_current_and_advance()
    self:write_current_and_advance()

    while self:current_value() == "," do
        self:write_current_and_advance()
        self:write_current_and_advance()
    end

    -- ;
    self:write_current_and_advance()

    self:close_tag("varDec")
end

function Parser:compileStatements()
    self:open_tag("statements")

    while true do
        local value = self:current_value()

        if value == "let" then
            self:compileLet()
        elseif value == "if" then
            self:compileIf()
        elseif value == "while" then
            self:compileWhile()
        elseif value == "do" then
            self:compileDo()
        elseif value == "return" then
            self:compileReturn()
        else
            break
        end
    end

    self:close_tag("statements")
end

function Parser:compileLet()
    self:open_tag("letStatement")

    -- let varName
    self:write_current_and_advance()
    self:write_current_and_advance()

    -- optional: [ expression ]
    if self:current_value() == "[" then
        self:write_current_and_advance()
        self:compileExpression()
        self:write_current_and_advance()
    end

    -- =
    self:write_current_and_advance()

    self:compileExpression()

    -- ;
    self:write_current_and_advance()

    self:close_tag("letStatement")
end

function Parser:compileIf()
    self:open_tag("ifStatement")

    -- if ( expression ) { statements }
    self:write_current_and_advance()
    self:write_current_and_advance()

    self:compileExpression()

    self:write_current_and_advance()
    self:write_current_and_advance()

    self:compileStatements()

    self:write_current_and_advance()

    -- optional else
    if self:current_value() == "else" then
        self:write_current_and_advance()
        self:write_current_and_advance()

        self:compileStatements()

        self:write_current_and_advance()
    end

    self:close_tag("ifStatement")
end

function Parser:compileWhile()
    self:open_tag("whileStatement")

    -- while ( expression ) { statements }
    self:write_current_and_advance()
    self:write_current_and_advance()

    self:compileExpression()

    self:write_current_and_advance()
    self:write_current_and_advance()

    self:compileStatements()

    self:write_current_and_advance()

    self:close_tag("whileStatement")
end

function Parser:compileDo()
    self:open_tag("doStatement")

    -- do
    self:write_current_and_advance()

    self:compileSubroutineCall()

    -- ;
    self:write_current_and_advance()

    self:close_tag("doStatement")
end

function Parser:compileReturn()
    self:open_tag("returnStatement")

    -- return
    self:write_current_and_advance()

    if self:current_value() ~= ";" then
        self:compileExpression()
    end

    -- ;
    self:write_current_and_advance()

    self:close_tag("returnStatement")
end

function Parser:compileExpression()
    self:open_tag("expression")

    self:compileTerm()

    while operators[self:current_value()] do
        self:write_current_and_advance()
        self:compileTerm()
    end

    self:close_tag("expression")
end

function Parser:compileTerm()
    self:open_tag("term")

    local token = self:current()
    local value = self:current_value()
    local next_value = nil

    if self:next_token() ~= nil then
        next_value = self:next_token().value
    end

    if token == nil then
        self:close_tag("term")
        return
    end

    -- integerConstant / stringConstant / keywordConstant
    if token.type == "integerConstant" or token.type == "stringConstant" or keywordConstants[value] then
        self:write_current_and_advance()

    -- ( expression )
    elseif value == "(" then
        self:write_current_and_advance()
        self:compileExpression()
        self:write_current_and_advance()

    -- unaryOp term
    elseif unaryOperators[value] then
        self:write_current_and_advance()
        self:compileTerm()

    -- varName [ expression ]
    elseif next_value == "[" then
        self:write_current_and_advance()
        self:write_current_and_advance()
        self:compileExpression()
        self:write_current_and_advance()

    -- subroutineCall
    elseif next_value == "(" or next_value == "." then
        self:compileSubroutineCall()

    -- varName
    else
        self:write_current_and_advance()
    end

    self:close_tag("term")
end

function Parser:compileSubroutineCall()
    -- subroutineName OR className/varName
    self:write_current_and_advance()

    -- optional: . subroutineName
    if self:current_value() == "." then
        self:write_current_and_advance()
        self:write_current_and_advance()
    end

    -- (
    self:write_current_and_advance()

    self:compileExpressionList()

    -- )
    self:write_current_and_advance()
end

function Parser:compileExpressionList()
    self:open_tag("expressionList")

    if self:current_value() ~= ")" then
        self:compileExpression()

        while self:current_value() == "," do
            self:write_current_and_advance()
            self:compileExpression()
        end
    end

    self:close_tag("expressionList")
end

------------------------------------------------------------
-- Analyze one Jack file
------------------------------------------------------------

local function analyze_file(folder_path, file_name)
    local base_name = string.gsub(file_name, "%.jack$", "")

    local input_path = folder_path .. "/" .. file_name
    local tokens_output_path = folder_path .. "/" .. base_name .. "T.xml"
    local parse_output_path = folder_path .. "/" .. base_name .. ".xml"

    local content = read_all_text(input_path)

    if content == nil then
        print("Failed to open input file: " .. input_path)
        return
    end

    -- Part 1: Tokenizing
    local tokens = tokenize_content(content)
    create_tokens_xml(tokens, tokens_output_path)
    print("Created tokens file: " .. base_name .. "T.xml")

    -- Part 2: Parsing
    local parser = Parser:new(tokens, parse_output_path)

    if parser.output_file == nil then
        print("Failed to create parse file: " .. parse_output_path)
        return
    end

    parser:compileClass()
    parser:close()

    print("Created parsed XML file: " .. base_name .. ".xml")
end

------------------------------------------------------------
-- Main
------------------------------------------------------------

local function main()
    local folder_path = arg[1]

    if folder_path == nil then
        print("Usage: lua5.1 tar_4.lua <input folder>")
        return
    end

    folder_path = trim_trailing_slash(folder_path)

    local files = find_input_files(folder_path)

    if files == nil or #files == 0 then
        print("No .jack files found in the specified folder.")
        return
    end

    for _, file_name in ipairs(files) do
        analyze_file(folder_path, file_name)
    end

    print("Done.")
end

main()