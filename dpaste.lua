-- dpaste.org utility by maelstrom071

-- MIT License

-- Copyright (c) 2024 maelstrom071

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local DEFAULT_PROVIDER = "https://dpaste.org"
local DEFAULT_EXPIRY = "never"

local usageText = [[
Usages:
dpaste put <filename> [options]
dpaste get <code> [filename]
dpaste run <code> [arguments...]

Options:
provider=<api url>
expires=<seconds> or never or onetime
]]

function usageError()
    local old = term.getTextColor()
    term.setTextColor(colors.red)
    print(usageText)
    term.setTextColor(old)
    error()
end

local provider = settings.get("dpaste.default_provider") or DEFAULT_PROVIDER
local expires = settings.get("dpaste.default_expiry") or DEFAULT_EXPIRY

function parseOptions(...)
    for _, option in ipairs({...}) do
        local key, value = option:match("(%w+)=(.+)")
        if key == nil then usageError() end
        if key == "provider" then
            provider = value
        elseif key == "expires" then
            if not tonumber(value) and value ~= "never" and value ~= "onetime" then
                print("Expires must be one of <seconds> or never or onetime")
                error()
            end
            expires = value
        else
            print("Unkown option "..key)
            error()
        end
    end
end

function validateProvider()
    local schema = provider:match("^([%w.+-]+):")
    if not schema then
        provider = "https://" .. provider
    elseif schema ~= "http" and schema ~= "https" then
        print("Invalid schema for provider: " .. schema)
        error()
    end
end

function parseUrl(code)
    if code:find("/") then
        return code .. '/raw', code:match("/([^/]+)/*$")
    else
        return provider .. '/' .. code .. '/raw', code
    end
end

local args = {...}

if #args < 1 then usageError() end

if args[1] == "put" then
    if #args < 2 then usageError() end

    if not fs.exists(args[2]) then
        print("No such file")
        error()
    end

    if #args >= 3 then
        parseOptions(select(3, ...))
    end

    validateProvider()

    local file = fs.open(args[2], "r")
    local content = file.readAll()
    file.close()

    local contentEncoded = textutils.urlEncode(content)
    print("Uploading to " .. provider .. "...")
    local response, errorMessage, errorResponse = http.post(provider .. '/api/', string.format("format=url&expires=%s&content=", expires) .. contentEncoded)
    if not response then
        print("Failed to upload paste: " .. errorMessage)
        if errorResponse then print(errorResponse.readAll()) errorResponse.close() end
        error()
    end
    local uploadUrl = response.readAll()
    response.close()

    print("Successfully uploaded as " .. uploadUrl)
    if expires ~= "never" and tonumber(expires) then print("Paste will expire in " .. expires .. " seconds.") end
    if expires == "onetime" then print("Paste will expire immediately on get") end
elseif args[1] == "get" then
    if #args < 2 then usageError() end

    local url, filename = parseUrl(args[2])

    if #args >= 3 then
        filename = args[3]
    end

    if fs.exists(filename) then
        print("File already exists. Overwrite? [y/N]")
        local _, key = os.pullEvent("key")
        if key ~= keys.y then
            return
        end
    end

    print("Downloading from " .. url .. "...")
    local response, errorMessage, errorResponse = http.get(url)
    if not response then
        print("Failed to download paste: " .. errorMessage)
        if errorResponse then print(errorResponse.readAll()) errorResponse.close() end
        error()
    end
    local content = response.readAll()
    response.close()

    local file = fs.open(filename, 'w')
    file.write(content)
    file.close()
    print("Saved as " .. filename .. " successfully")
elseif args[1] == "run" then
    if #args < 2 then usageError() end

    local url, filename = parseUrl(args[2])

    if fs.exists(filename) then
        print("File already exists. Overwrite? [y/N]")
        local _, key = os.pullEvent("key")
        if key ~= keys.y then
            return
        end
    end

    print("Downloading from " .. url .. "...")
    local response, errorMessage, errorResponse = http.get(url)
    if not response then
        print("Failed to download paste: " .. errorMessage)
        error()
    end
    local content = response.readAll()
    response.close()

    local file = fs.open(filename, 'w')
    file.write(content)
    file.close()
    print("Saved as " .. filename .. " successfully")
    print("Running...")
    
    shell.execute(filename, select(3, ...))
    fs.delete(filename)
end