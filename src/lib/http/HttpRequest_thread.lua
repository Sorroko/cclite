local httpRequest       = require("socket.http")
local httpMime          = require("mime")
local ltn12             = require("ltn12")

local cChannel          = nil
local socketTimeout     = 10

local httpResponseBody  = {}
local httpResponseText  = ""
local httpParams        = {}

local requestDebug      = false

function waitForInstructions(channel, debug)
    cChannel = channel
    requestDebug = debug or false

    --set message vars
    local tData = cChannel:demand()

    assert(type(tData) == "table", "No data received.")

    local socketTimeoutMsg = tData[1]
    local httpParamsMsg = tData[2]

    assert(type(socketTimeoutMsg) == "string", "Socket timeout invalid.")
    assert(type(httpParamsMsg) == "string", "Socket timeout invalid.")

    socketTimeout = tonumber(socketTimeoutMsg)
    httpParams = TSerial.unpack(httpParamsMsg)

    if requestDebug == true then
        print("---REQUEST TIMEOUT----")
        print("Timeout: "..socketTimeout)
        print("---REQUEST PARAMS-----")
        for k,v in pairs(httpParams) do
            if k ~= "headers" then
                print(k .. ": " .. tostring(httpParams[k]))
            end
        end
        print(" ")
        print("---REQUEST HEADERS----")
        for k,v in pairs(httpParams) do
            --print(k .. ": " .. tostring(httpParams[k]))
            if k == "headers" then
                for k2,v2 in pairs(httpParams[k]) do
                    print("header: ["..tostring(k2).."] = "..tostring(v2))
                end
            end
        end
        print("     ")
    end

    httpParams.redirects = 0
    sendRequest()
end

-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

function sendRequest()
    httpRequest.TIMEOUT = socketTimeout

    -- send request:
    local result  =
    {
        httpRequest.request
        {
            method      = httpParams.method,
            url         = httpParams.url,
            headers     = httpParams.headers,
            source      = ltn12.source.string(httpParams.body),
            sink        = ltn12.sink.table(httpResponseBody),
            redirect    = true
        }
    }

    if result[2] == 302 or result[2] == 301 and httpParams.redirects < 3 then
        httpResponseBody = {}
        httpParams.url = result[3]["location"]
        httpParams.redirects = httpParams.redirects + 1
        return sendRequest()
    end

    -- compile responseText
    for k,v in ipairs(httpResponseBody) do
        httpResponseText = httpResponseText .. tostring(v)
    end

    -- insert responseText in to result table
    table.insert(result, httpResponseText)

    -- DEBUG CODE
    if requestDebug == true then
        print("---RESPONSE HEADERS---")
        for k, v in pairs(result) do
            if type(result[k]) == "table" then
                for k2, v2 in pairs(result[k]) do
                    local tbl = result[k]
                    print("header: " .. "["..tostring(k2).."] = ".. tbl[k2])
                end
            end
        end
        for k, v in pairs(result) do
            print(v)
        end
        print(" ")
        print("---RESPONSE PARAMS---")
        print("readyState: ".. tostring(result[1]) )
        print("statusCode: ".. tostring(result[2]) )
        print("statusText: ".. tostring(result[4]) )
        print("responseText: " .. httpResponseText )
        print("---------------------")

    end

    -- send results back to handler
    cChannel:push(TSerial.pack(result))
end

-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-- TSerial v1.23, a simple table serializer which turns tables into Lua script
-- by Taehl (SelfMadeSpirit@gmail.com)

-- Usage: table = TSerial.unpack( TSerial.pack(table) )
TSerial = {}
function TSerial.pack(t)
    assert(type(t) == "table", "Can only TSerial.pack tables.")
    local s = "{"
    for k, v in pairs(t) do
        local tk, tv = type(k), type(v)
        if tk == "boolean" then k = k and "[true]" or "[false]"
        elseif tk == "string" then if string.find(k, "[%c%p%s]") then k = '["'..k..'"]' end
        elseif tk == "number" then k = "["..k.."]"
        elseif tk == "table" then k = "["..TSerial.pack(k).."]"
        else error("Attempted to Tserialize a table with an invalid key: "..tostring(k))
        end
        if tv == "boolean" then v = v and "true" or "false"
        elseif tv == "string" then v = string.format("%q", v)
        elseif tv == "number" then  -- no change needed
        elseif tv == "table" then v = TSerial.pack(v)
        else error("Attempted to Tserialize a table with an invalid value: "..tostring(v))
        end
        s = s..k.."="..v..","
    end
    return s.."}"
end

function TSerial.unpack(s)
    assert(type(s) == "string", "Can only TSerial.unpack strings.")
    assert(loadstring("TSerial.table="..s))()
    local t = TSerial.table
    TSerial.table = nil
    return t
end

-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

waitForInstructions(...)
