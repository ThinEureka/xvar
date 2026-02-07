--author cs
--04nycs@gmail.com
--
--https://github.com/ThinEureka/xvar
--created on Apri 10, 2024
--
local xvar = {}

local rawget = rawget
local rawset = rawset
local table = table
local table_insert = table.insert
local table_remove = table.remove
local setmetatable = setmetatable
local xpcall = xpcall
local type = type
local pairs = pairs
local ipairs = ipairs
local select = select

local __err_xs = {}
local __numXs = 0
-- g_allXars = {}
local __x_trace = true

-- this function assumes we're using tabMachine context stack
local function on_error(error)
    local strArray = {}
    local x = __err_xs[__numXs]
    table_insert(strArray, error)
    if x ~= nil then
        local desc = xvar.desc(x, true)
        table_insert(strArray, desc)
    end

    table_insert(strArray, "tabStack {")
    for i = 1, g_getCurStackNum() do
        local context = __contextStack[i].context
        if context ~= nil then
            table_insert(strArray, context:getDetailedPath())
        end
    end
    table_insert(strArray, "}")
    table_insert(strArray, debug.traceback("", 1))
    local strError = table.concat(strArray, "\n")
    printError(strError)

    if fabric and fabric.getInstance and fabric:getInstance() then
        fabric:getInstance():reportCustomException(strError)
    end
end

xvar.pcall = function(f, x, ...)
    local x_trace = __x_trace
    local numXs
    if x_trace then
        numXs = __numXs + 1
        if numXs > #__err_xs then
            table_insert(__err_xs, x)
        else
            __err_xs[numXs] = x
        end
        __numXs = numXs
    end

    local stat, result = xpcall(f, on_error, ...)

    if x_trace then
        __err_xs[numXs] = false --place holder
        __numXs = numXs - 1
    end

    return stat,result
end

local xvar_err_nil = { DEBUG_NAME = "xvar_err_nil" }

local meta_err_nil = {
    __index = function(t, key)
        assert(false, "accessing xvar.err_nil")
    end,

    __newindex = function(t, key)
        assert(false, "accessing xvar.err_nil")
    end,
}

setmetatable(xvar_err_nil, meta_err_nil)

local xvar_volatile = 0

local x_operators = nil
local __land = nil
local __lor = nil
local __lxor = nil
local __lnot = nil

if __xCallbacks == nil then
    __xCallbacks = {}
    __xCallbackSize = 0
end

local __xCallbacks = __xCallbacks

local pcall_xvar_validate = nil


local builtin_binary_ops = {
    --builit in binary
    __add = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 + op2
    end,

    __sub = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 - op2
    end,

    __mul = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end

        return op1 * op2
    end,

    __div = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 / op2
    end,

    __mod = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 % op2
    end,

    __pow = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 ^ op2
    end,

    __idiv = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 // op2
    end,


    -- __band = function(op1, op2)
        -- if op1 == xvar_err_nil or op2 == xvar_err_nil then
            -- return xvar_err_nil
        -- end
--
--
        -- return op1 & op2
    -- end,
--
    -- __bor  = function(op1, op2)
        -- if op1 == xvar_err_nil or op2 == xvar_err_nil then
            -- return xvar_err_nil
        -- end
--
        -- return op1 | op2
    -- end,
--
    -- __bxor  = function(op1, op2)
        -- if op1 == xvar_err_nil or op2 == xvar_err_nil then
            -- return xvar_err_nil
        -- end
--
        -- return op1 ~ op2
    -- end,

    __concat = function(op1, op2)
        if op1 == nil or op1 == xvar_err_nil or
            op2 == nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end
        return op1 .. op2
    end,

    -- __eq = function(op1, op2)
        -- return op1 == op2
    -- end,
--
    -- __lt = function(op1, op2)
        -- return op1 < op2
    -- end,
--
    -- __le = function(op1, op2)
        -- return op1 <= op2
    -- end,

    __shl  = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end

        return op1 << op2
    end,

    __shr  = function(op1, op2)
        if op1 == nil or op2 == nil or
            op1 == xvar_err_nil or op2 == xvar_err_nil then
            return xvar_err_nil
        end

        return op1 >> op2
    end,
}

local builtin_unary_ops = {
    --built unary
    __len = function(op1)
        if op1 == nil  or op1 == xvar_err_nil then
            return xvar_err_nil
        end

        if rawget(op1, "__xop") == nil then
            return #op1
        end

        if rawget(op1, "__xdirty") then
            pcall_xvar_validate(op1)
        end

        return #(rawget(op1, "__xvalue"))
    end,

    __unm = function(op1)
        if op1 == nil  or op1 == xvar_err_nil then
            return xvar_err_nil
        end

        return -op1
    end
}

local __index  = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1[op2]
end

local __eq = function(op1, op2)
    if op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1 == op2
end

local __noteq = function(op1, op2)
    if op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1 ~= op2
end

local __lt = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end
    return op1 < op2
end

local __le = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end
    return op1 <= op2
end

local __gt = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1 > op2
end

local __ge = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1 >= op2
end

local __filter = function(op1, op2)
    if op1 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    local t = {}
    for k, v in pairs(op1) do
        if op2 == nil or op2(v) then
            t[k] = v
        end
    end

    return t
end

local __sort = function(op1, op2)
    if op1 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    local t = {}
    for k, v in pairs(op1) do
        t[k] = v
    end
    if op2 ~= nil then
        table.sort(t, op2)
    end

    return t
end

local __extend = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    local t = {}
    for k, v in pairs(op1) do
        t[k] = v
    end

    for k, v in pairs(op2) do
        t[k] = v
    end

    return t
end

local __find = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    for k, v in pairs(op1) do
        if op2(v, k) then
            return v
        end
    end
end

local __indexof = function(op1, op2)
    if op1 == nil or op2 == nil or
        op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    for k, v in pairs(op1) do
        if v == op2 then
            return k
        end
    end
end



local __x_index = nil
local meta_xvar = nil

--private:
local xvar_setDirty = nil
local xvar_collectDirty = nil
local xvar_collectDebugMsg = nil
local xvar_addSink = nil
local xvar_removeSink = nil
local xvar_removeFromSources = nil
local xvar_validate = nil
-- local pcall_xvar_validate = nil

--public:
local xvar_isDirty = nil
local xvar_isVolatile = nil
local xvar_setVolatile = nil
local xvar_reset = nil
local xvar_addDirtyCallback = nil
local xvar_removeDirtyCallback = nil
local xvar_removeAllDirtyCallbacks = nil
local xvar_removeDirtyCallbackByKey = nil
local xvar_readonly = nil
local xvar_getCollectDebugMsg = nil

local xvar_op0 = nil
local xvar_op1 = nil
local xvar_op2 = nil
local xvar_opn = nil
local xvar_opx = nil
local xvar_ops = nil
local xvar_fns = nil
local __table = nil

local function setDebugInfo(x, fn, f, loc)
    local opName = nil
    local isBuiltInOp = false
    if f ~= nil then
        opName = g_xvarOpNames[f]
        if opName ~= nil then
            isBuiltInOp = true
        end
    end

    if not isBuiltInOp then
        if fn == nil then
            local xop = rawget(x, "__xop")
            if xop == 0 then
                fn = "f0"
            elseif xop == -1 then
                fn = "fx"
            elseif xop == -2 then
                fn = "fs"
            else
                fn = "fn"
            end
        end
        opName = fn
    end

    local file
    local line

    if loc ~= nil then
        local info = debug.getinfo(1 + loc)
        file = info.short_src
        line = info.currentline
    else
        if f == nil then
            file = "xvar.lua"
            line = 0
        else
            local info = debug.getinfo(f)
            file = info.short_src
            line = info.linedefined
        end
    end

    local xName = opName .. " " .. file .. ":" .. line

    rawset(x, "__xname", xName)
end

xvar_op0 = function(c)
    local x = {}
    setmetatable(x, meta_xvar)
    rawset(x, "__xop", 0)
    rawset(x,"__xvalue", c)

   -- rawset(x, "__xdirty", true)
    if g_xvarDebug then
        setDebugInfo(x, "f0", nil, 2)
    end

    return x
end

xvar_opn = function(f, ...)
    local x = {}
    setmetatable(x, meta_xvar)
    -- table_insert(g_allXars, x)

    local num = select("#", ...)
    rawset(x,"__xop", num)
    rawset(x,"__xf", f)

    local op_xs = {}
    for index = 1, num do
        local p = select(index, ...)
        local op_x
        if type(p) ~= "table" or rawget(p, "__xop") == nil then
            op_x = xvar_op0(p)
        else
            op_x = p
            xvar_addSink(op_x, x)
        end
        table_insert(op_xs, op_x)
    end
    rawset(x,"__op_xs", op_xs)

    rawset(x, "__xdirty", true)
    if g_xvarDebug then
        setDebugInfo(x, "fn", f, 2)
    end

    return x
end

xvar_op1 = xvar_opn
xvar_op2 = xvar_opn

xvar_opx = function(f)
    local x = {}
    rawset(x,"__xop", -1)
    setmetatable(x, meta_xvar)
    -- table_insert(g_allXars, x)

    rawset(x,"__xf", f)

    rawset(x, "__xdirty", true)
    if g_xvarDebug then
        setDebugInfo(x, "fx", f, 2)
    end

    return x
end

xvar_ops = function(f, structure, op_xs)
    local x = {}
    setmetatable(x, meta_xvar)
    -- table_insert(g_allXars, x)

    rawset(x,"__xop", -2)
    rawset(x,"__xf", f)

    local num = #op_xs
    for index = 1, num do
        local op_x = op_xs[index]
        xvar_addSink(op_x, x)
    end
    rawset(x, "__op_xs", op_xs)
    rawset(x,"__xstructue", structure)

    rawset(x, "__xdirty", true)
    if g_xvarDebug then
        setDebugInfo(x, "fs", f, 2)
    end

    return x
end

xvar_readonly = function(x, isReadOnly)
    rawset(x, "__xreadonly", isReadOnly)
end

--private
xvar_collectDebugMsg = function(x, msg)
    if (not msg) then
        msg = debug.traceback("", 1):gsub("\n", "#")
    end
    local callbacks = rawget(x, "__xdirtycallbacks")
    if callbacks ~= nil then
        local msgs = rawget(x, "__xdebugmsgs")
        if (not msgs) then
            msgs = {}
            rawset(x, "__xdebugmsgs", msgs)
        end
        table_insert(msgs, msg)
    end
    local sinks = rawget(x, "__xsinks")
    if sinks ~= nil then
        for sink, _ in pairs(sinks) do
            xvar_collectDebugMsg(sink, msg)
        end
    end
end

xvar_setDirty = function(x, location)
    local xCallbacks = __xCallbacks
    local beginSize = __xCallbackSize
    xvar_collectDirty(x, location)
    local endSize = __xCallbackSize

    --TODO:  a global enableSorting option can be added
    for i = beginSize + 2, endSize do
        local xCallback1 = xCallbacks[i]
        local j = i - 1

        while j >= beginSize + 1 and xCallbacks[j].callbackId > xCallback1.callbackId do
            xCallbacks[j + 1] = xCallbacks[j]
            j = j - 1
        end
        xCallbacks[j + 1] = xCallback1
    end

    for index = beginSize + 1, endSize do
        -- callbackArray[index](xArray[index])
        local xCallback = xCallbacks[index]
        local x = xCallback.x
        local callback = xCallback.callback

        xCallback.x = false
        xCallback.callback = false

        --if g_xvarDebug then
        --    --table_insert(__err_xs, x)
        --end
        xpcall(callback, on_error, x)
        --if g_xvarDebug then
        --    --table_remove(__err_xs)
        --end
    end

    __xCallbackSize = beginSize
end

xvar_collectDirty = function(x, location, excludeX)
    if not excludeX then
        rawset(x, "__xdirty", true)
        rawset(x, "__xdirty_location", location)
    end

    local callbacks = rawget(x, "__xdirtycallbacks")
    if callbacks ~= nil then
        for callbackId, callback in pairs(callbacks) do
            local newSize = __xCallbackSize + 1
            __xCallbackSize = newSize
            if newSize > #__xCallbacks then
                table_insert(__xCallbacks, {})
            end
            local xCallback = __xCallbacks[newSize]
            xCallback.x = x
            xCallback.callback = callback
            xCallback.callbackId = callbackId
        end
    end

    local sinks = rawget(x, "__xsinks")
    if sinks ~= nil then
        for sink, _ in pairs(sinks) do
            if not rawget(sink, "__xdirty") then
                if location == nil then
                    xvar_collectDirty(sink, nil)
                else
                    local xSourceLocation = rawget(sink, "__xsourcelocation")
                    if xSourceLocation == nil then
                        xvar_collectDirty(sink, nil)
                    else
                        local miss = false
                        local isValue = false
                        local op_xs = rawget(sink, "__op_xs")
                        local x_i
                        for i, j in pairs(xSourceLocation) do
                            if i == 0 then
                                x_i = rawget(sink, "__xvalue")
                            else
                                x_i = op_xs[i]
                            end
                            local x_j = op_xs[j]
                            if x_i == x then
                                if i == 0 then
                                    isValue = true
                                else
                                    miss = true
                                    if not rawget(x_j, "__xdirty") then
                                        if rawget(x_j, "__xvalue") == location then
                                            miss = false
                                        end
                                    end
                                end
                                break
                            end
                        end

                        if not miss then
                            if isValue then
                                xvar_collectDirty(sink, location, true)
                            else
                                xvar_collectDirty(sink, nil)
                            end
                        end
                    end
                end
            end
        end
    end
end

local meta_sinks = {__mode = "k"}
xvar_addSink = function(x, sink)
    local sinks = rawget(x, "__xsinks")
    if sinks == nil then
        sinks = {}
        setmetatable(sinks, meta_sinks)
        rawset(x, "__xsinks", sinks)
    end
    sinks[sink] = true
end

xvar_removeSink = function(x, sink)
    local sinks = rawget(x, "__xsinks")
    if sinks == nil then
        return
    end

    sinks[sink] = nil
end

xvar_removeFromSources = function(x)
    local value = rawget(x, "__xvalue")
    if type(value) == "table" then
        if rawget(value, "__xop") ~= nil then
            xvar_removeSink(value, x)
        end
    end

    -- local xop = rawget(x, "__xop")
    -- if xop <= 0 then
        -- return
    -- end

    local op_xs = rawget(x, "__op_xs")
    if op_xs ~= nil then
        for _, op_x in ipairs(op_xs) do
            xvar_removeSink(op_x, x)
        end
    end
end

--public:
xvar_isDirty = function(x)
    return rawget(x, "__xdirty")
end

xvar_isVolatile = function(x)
    return rawget(x, "__xvolatile")
end

xvar_setVolatile = function(x)
    return rawset(x, "__xvolatile", true)
end

xvar_getCollectDebugMsg = function(x)
    return rawget(x, "__xdebugmsgs")
end

pcall_xvar_validate = function(x)
    --if g_xvarDebug then
    --    --table_insert(__err_xs, x)
    --end
    --local stat = xpcall(xvar_validate, on_error, x)
    local stat, result = xvar.pcall(xvar_validate, x, x)
    --if g_xvarDebug then
    --    --table_remove(__err_xs)
    --end
    if not stat then
        rawset(x, "__xvalue", xvar_err_nil)
        rawset(x, "__xdirty", false)
    end

    return result
end

--private:
xvar_validate = function(x)
    local xop = rawget(x, "__xop")
    if xop == 0 then
        rawset(x, "__xdirty", false)
        return
    end

    local oldValue = rawget(x, "__xvalue")
    local value = nil
    local op_xs = rawget(x, "__op_xs")
    local f = rawget(x, "__xf")

    if xop > 0 then
        for _, op_x in ipairs(op_xs) do
            if rawget(op_x, "__xdirty") then
                pcall_xvar_validate(op_x)
            end
        end

        if xop == 1 then
            value = f(rawget(op_xs[1], "__xvalue"))
        elseif xop == 2 then
            value = f(rawget(op_xs[1], "__xvalue"), rawget(op_xs[2], "__xvalue"))
        elseif xop == 3 then
            value = f(rawget(op_xs[1], "__xvalue"), rawget(op_xs[2], "__xvalue"),
                rawget(op_xs[3], "__xvalue"))
        elseif xop == 4 then
            value = f(rawget(op_xs[1], "__xvalue"), rawget(op_xs[2], "__xvalue"),
                rawget(op_xs[3], "__xvalue"), rawget(op_xs[4], "__xvalue"))
        else
            local ops = {}
            for index, op_x in ipairs(op_xs) do
                local op = rawget(op_x, "__xvalue")
                ops[index] = op
            end
            value = f(table.unpack(ops, 1, #op_xs))
        end
    elseif xop == -1 then
        value = f()
    elseif xop == -2 then
        for _, op_x in ipairs(op_xs) do
            if rawget(op_x, "__xdirty") then
                pcall_xvar_validate(op_x)
            end
        end

        local ops = {}
        for index, op_x in ipairs(op_xs) do
            local op = rawget(op_x, "__xvalue")
            ops[index] = op
        end
        value = f(rawget(x, "__xstructue"), ops)
    end

    if oldValue ~= value then
        if type(oldValue) == "table"then
            if rawget(oldValue, "__xop") ~= nil then
                xvar_removeSink(oldValue, x)
            end
        end

        if type(value) == "table" then
            if rawget(value, "__xop") ~= nil then
                if rawget(value, "__xdirty") then
                    pcall_xvar_validate(value)
                end
                xvar_addSink(value, x)
            end
        end
    end

    rawset(x, "__xvalue", value)
    rawset(x, "__xdirty", false)
    rawset(x, "__xdirty_location", false)

    return
end

xvar_reset = function(x, v)
    if x == v then
        return
    end

    xvar_removeFromSources(x)

    local xop = nil
    local vIsXvar = true
    if type(v) ~= "table" then
        vIsXvar = false
    else
        xop = rawget(v, "__xop")
        if xop == nil then
            vIsXvar = false
        end
    end

    if not vIsXvar then
        -- rawset(x, "__xop", 0)
        rawset(x, "__xvalue", v)
        rawset(x, "__op_xs", nil)
        rawset(x, "__xf", nil)

        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
    else
        rawset(x, "__xop", xop)
        rawset(x, "__xf", rawget(v, "__xf"))
        local op_xs = rawget(v, "__op_xs")
        if op_xs ~= nil then
            for _, op_x in ipairs(op_xs) do
                xvar_addSink(op_x, x)
            end
        end
        rawset(x, "__op_xs", op_xs)
        -- rawset(x, "__xsinks", rawget(v, "__xsinks"))

        rawset(x, "__xvalue", rawget(v, "__xvalue"))

        rawset(x,"__xstructue", rawget(v, "__xstructue"))

        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
    end

    --if (g_xvarDebug) then
    --    --xvar_collectDebugMsg(x)
    --end
end
local xvar_call_back_id = 0
xvar_addDirtyCallback = function(x, callback)
    local callbacks = rawget(x, "__xdirtycallbacks")
    if callbacks == nil then
        callbacks = {}
        rawset(x, "__xdirtycallbacks", callbacks)
    end
    xvar_call_back_id = xvar_call_back_id + 1
    local callbackId =  xvar_call_back_id
    callbacks[callbackId] = callback

    if rawget(x, "__xdirty") then
        --if g_xvarDebug then
        --    --table_insert(__err_xs, x)
        --end
        xpcall(callback, on_error, x)
        --if g_xvarDebug then
        --    --table_remove(__err_xs)
        --end
    end

    return callbackId
end

xvar_removeDirtyCallback = function(x, key)
    local callbacks = rawget(x, "__xdirtycallbacks")
    if callbacks == nil then
        return
    end

    callbacks[key] = nil
end

xvar_removeAllDirtyCallbacks = function(x, callback)
    rawset(x,  "__xdirtycallbacks", nil)
end

-- local xvar_index = {
    -- get = function(x, key)
        -- return xvar_op2(__index, x, key)
    -- end,
-- }
--
local sourceLocationIndex = {[1] = 2, [0] = 2}
__x_index = function(x, key)
    local y = xvar_op2(__index, x, key)
    rawset(y, "__xsourcelocation", sourceLocationIndex)
    return y
end

meta_xvar = {
    __index = function(x, key)
        if key == "x_index" then
            return __x_index
        end

        if rawget(x, "__xdirty") then
            pcall_xvar_validate(x)
        end

        local value = rawget(x, "__xvalue")
        return value[key]
    end,

    --new index
    __newindex = function(x, k, v)
        local xreadonly = rawget(x, "__xreadonly")
        if (xreadonly) then
            assert(false, "donot to modify xvar data direct")
            return
        end

        local xop = rawget(x, "__xop")
        if xop ~= 0 then
            assert(false)
        end

        local xvalue = rawget(x, "__xvalue")
        if (xvalue[k] == v) then
            return
        end
        rawset(xvalue, k, v)
        rawset(x, "__xvolatile", true)
        xvar_setDirty(x, k)
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
    end,

    --get value
    __call = function(x, ...)
        local argNum = select("#", ...)
        if argNum == 0 then
            if rawget(x, "__xdirty") then
                pcall_xvar_validate(x)
            end

            local value =  rawget(x, "__xvalue")
            if value == xvar_err_nil then
                value = nil
            end

            return value
        end

        if argNum == 1 then
            local array = select(1, ...)
            local opStr = array[1]
            local op = x_operators[opStr]
            local len = #array
            if op ~= nil then
                return op(x, array[2])
            elseif len == 1 then
                if opStr:byte(1) == 46 then
                    op = x_operators["."]
                    return op(x, opStr:sub(2))
                end
            end
        end

        if argNum == 2 then
            local p1, p2 = select(1, ...)
            local op = x_operators[p1]
            return op(x, p2)
        end
    end,

    __pairs = function(x)
        if rawget(x, "__xdirty") then
            pcall_xvar_validate(x)
        end
        local value = rawget(x, "__xvalue")
        return next, value, nil
    end,


    -- __eq = function(op1, op2)
        -- error("Lua does not support overload compare operator to return none boolean value")
    -- end,
--
    -- __lt = function(op1, op2)
        -- error("Lua does not support overload compare operator to return none boolean value")
    -- end,
--
    -- __le = function(op1, op2)
        -- error("Lua does not support overload compare operator to return none boolean value")
    -- end,

    __band = function(op1, op2)
        return xvar_op2(__land, op1, op2)
    end,

    __bor  = function(op1, op2)
        return xvar_op2(__lor, op1, op2)
    end,

    __bxor  = function(op1, op2)
        return xvar_op2(__lxor, op1, op2)
    end,

    __bnot  = function(op1)
        return xvar_op1(__lnot, op1)
    end,
}


for key, value in pairs(builtin_binary_ops) do
    meta_xvar[key] = function(x1, x2)
        return xvar_op2(value, x1, x2)
    end
end

for key, value in pairs(builtin_unary_ops) do
    meta_xvar[key] = function(x1)
        return xvar_op1(value, x1)
    end
end


--public:
--constructors
xvar.f0 = xvar_op0

xvar.f1 = xvar_op1

xvar.f2 = xvar_op2

xvar.fn = xvar_opn

xvar.fx = xvar_opx

xvar.fs = xvar_ops

xvar.fns = function(f, ...)
    local structure = {}
    local opIndex = 1
    local op_xs = {}
    local num = select("#", ...)
    for i = 1, num do
        local x = select(i, ...)
        local e = {}
        if xvar.is_xvar(x) then
            e.opIndex = opIndex
            opIndex = opIndex + 1
            table_insert(op_xs, x)
        else
            e.constValue = x
        end

        table_insert(structure, e)
    end

    return xvar_ops(f, structure, op_xs)
end

local meta_ff = {
    __call = function(ff, ...)
        return xvar.fn(ff.__f, ...)
    end
}

xvar.ff = function(f)
    local ff = {}
    ff.__f = f
    setmetatable(ff, meta_ff)
    return ff
end

xvar.readonly_table = function(c)
    local x = xvar_op0(c)
    rawset(x, "__xreadonly", true)
    return x
end

xvar.err_nil = xvar_err_nil

xvar.volatile = function()
    xvar_volatile = xvar_volatile + 1
    return xvar_volatile
end

--type interface
xvar.is_xvar = function(x)
    if (type(x) ~= "table") then
        return false
    end
    return rawget(x, "__xop") ~= nil
end

xvar.is_xtable = function(x)
    if (type(x) ~= "table") then
        return false
    end

    return rawget(x, "__xf") == __table
end


--custom binary
__land = function(op1, op2)
    if op1 == xvar_err_nil or op2 == xvar_err_nil then
        return xvar_err_nil
    end

    return op1 and op2
end

__lor  = function(op1, op2)
    if op1 ~= xvar_err_nil and op1 then
        return op1
    end

    return op2
end

__lxor  = function(op1, op2)
    return (xvar.is_false(op1) and not xvar.is_false(op2)) or
        (not xvar.is_false(op1) and xvar.is_false(op2))
end

__lnot  = function(op1)
    if op1 == xvar_err_nil then
        return xvar_err_nil
    end
    return not op1
end

__call  = function(op1)
    if op1 == xvar_err_nil or op1 == nil then
        return xvar_err_nil
    end
    return op1()
end

--logic operation
xvar.x_and = function(x1, x2)
    return xvar_op2(__land, x1, x2)
end

xvar.x_or = function(x1, x2)
    return xvar_op2(__lor, x1, x2)
end

xvar.x_xor = function(x1, x2)
    return xvar_op2(__lxor, x1, x2)
end

xvar.x_not = function(x1)
    return xvar_op1(__lnot, x1)
end

xvar.x_call = function(x1)
    return xvar_op1(__call, x1)
end

-- ==
xvar.x_eq = function(x1, x2)
    return xvar_op2(__eq, x1, x2)
end

xvar["=="] = xvar.x_eq

-- ~=
xvar.x_noteq = function(x1, x2)
    return xvar_op2(__noteq, x1, x2)
end

xvar["~="] = xvar.x_noteq

-- <
xvar.x_lt = function(x1, x2)
    return xvar_op2(__lt, x1, x2)
end

xvar["<"] = xvar.x_lt

-- <=
xvar.x_le = function(x1, x2)
    return xvar_op2(__le, x1, x2)
end
xvar["<="] = xvar.x_le

-- >
xvar.x_gt = function(x1, x2)
    return xvar_op2(__gt, x1, x2)
end
xvar[">"] = xvar.x_gt

-- >=
xvar.x_ge = function(x1, x2)
    return xvar_op2(__ge, x1, x2)
end
xvar[">="] = xvar.x_ge

local __safe_add = function(op1, op2)
    if op1 == nil or op1 == xvar_err_nil or op1 == false then
        op1 = 0
    end

    if op1 == true then
        op1 = 1
    end

    if op2 == nil or op2 == xvar_err_nil or op2 == false then
        op2 = 0
    end

    if op2 == true then
        op2 = 1
    end

    return op1 + op2
end

xvar.x_safe_add = function (x1, x2)
    return xvar_op2(__safe_add, x1, x2)
end

xvar["?+"] = xvar.x_safe_add


xvar.x_filter = function(x1, x2)
    return xvar_op2(__filter, x1, x2)
end

xvar.x_sort = function(x1, x2)
    return xvar_op2(__sort, x1, x2)
end

xvar.x_extend = function(x1, x2)
    return xvar_op2(__extend, x1, x2)
end

xvar.x_find = function(x1, x2)
    return xvar_op2(__find, x1, x2)
end

xvar.x_index = __x_index

xvar.x_indexof = function(x1, x2)
    return xvar_op2(__indexof, x1, x2)
end

xvar.x_vp = function(f, f_array, ...)
    local num = select("#", ...)

    if num == 1 then
        local x1 = select(1, ...)
        local t = type(x1)
        if t == "table" then
            if rawget(x1, "__xop") ~= nil then
                return xvar_op1(f_array, x1)
            else
                return xvar.fns(f, table.unpack(x1))
            end
        end
    end

    return xvar.fns(f, ...)
end

local __sum = nil
local __sum_array = nil
xvar.x_sum = function(...)
    return xvar.x_vp(__sum, __sum_array, ...)
end

__sum_array = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return xvar_err_nil
    end

    local sum = 0
    for _, v in pairs(op1) do
        sum = sum + v
    end

    return sum
end

__sum = function(structure, ops)
    local sum = 0
    for _, e in ipairs(structure) do
        local v
        local opIndex = e.opIndex
        if opIndex ~= nil then
            v = ops[opIndex]
        else
            v = e.constValue
        end

        sum = sum + v
    end

    return sum
end

local __safe_sum_array = nil
local __safe_sum = nil

xvar.x_safe_sum = function(...)
    return xvar.x_vp(__safe_sum, __safe_sum_array, ...)
end

__safe_sum_array = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return 0
    end

    local sum = 0
    for _, v in pairs(op1) do
        if v == nil or v == xvar_err_nil or v == false then
            v = 0
        end

        if v == true then
            v = 1
        end

        sum = sum + v
    end

    return sum
end

__safe_sum = function(structure, ops)
    local sum = 0
    for _, e in ipairs(structure) do
        local v
        local opIndex = e.opIndex
        if opIndex ~= nil then
            v = ops[opIndex]
        else
            v = e.constValue
        end

        if v == nil or v == xvar_err_nil or v == false then
            v = 0
        end

        if v == true then
            v = 1
        end

        sum = sum + v
    end

    return sum
end

xvar.x_pairs = function(x)
    return next, x, nil
end

local __A_or_B =  function(cond, a, b)
    if cond and cond ~= xvar_err_nil then
        return a
    end

    return b
end

xvar.x_A_or_B = function (cond_x, A, B)
    return xvar_opn(__A_or_B, cond_x, A, B)
end

xvar.x_identity = function(x1)
    return xvar.f1(function(x) return x end, x1)
end

local __count = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return 0
    end
    local count = 0
    for _, v in pairs(op1) do
        count = count + 1
    end
    return count
end

xvar.x_count = function(x)
    return xvar.fn(__count, x)
end

local __isEmpty = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return true
    end

    return next(op1) == nil
end

xvar.x_isEmpty = function(x)
    return xvar.fn(__isEmpty, x)
end

local __min = nil
local __min_array = nil

xvar.x_min = function(...)
    return xvar.x_vp(__min, __min_array, ...)
end

__min = function(structure, ops)
    local min = xvar_err_nil
    for _, e in ipairs(structure) do
        local v
        local opIndex = e.opIndex
        if opIndex ~= nil then
            v = ops[opIndex]
        else
            v = e.constValue
        end

        if v ~= nil and v ~= xvar_err_nil then
            if min == xvar_err_nil then
                min = v
            elseif v < min then
                min = v
            end
        end
    end

    return min
end

__min_array = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return xvar_err_nil
    end

    local min = xvar_err_nil
    for _, v in ipairs(op1) do
        if v ~= nil and v ~= xvar_err_nil then
            if min == xvar_err_nil then
                min = v
            elseif v < min then
                min = v
            end
        end
    end

    return min
end

local __max = nil
local __max_array = nil

xvar.x_max = function(...)
    return xvar.x_vp(__max, __max_array, ...)
end

__max = function(structure, ops)
    local max = xvar_err_nil
    for _, e in ipairs(structure) do
        local v
        local opIndex = e.opIndex
        if opIndex ~= nil then
            v = ops[opIndex]
        else
            v = e.constValue
        end

        if v ~= nil and v ~= xvar_err_nil then
            if max == xvar_err_nil then
                max = v
            elseif v > max then
                max = v
            end
        end
    end

    return max
end

__max_array = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return xvar_err_nil
    end

    local max = xvar_err_nil
    for _, v in ipairs(op1) do
        if v ~= nil and v ~= xvar_err_nil then
            if max == xvar_err_nil then
                max = v
            elseif v > max then
                max = v
            end
        end
    end

    return max
end

__table = function(structure, ops)
    local result = {}
    for index, e in ipairs(structure) do
        local k, v
        local keyOpIndex = e.keyOpIndex
        if keyOpIndex ~= nil then
            k = ops[keyOpIndex]
        else
            k = e.constKey
        end

        local valueOpIndex = e.valueOpIndex
        if valueOpIndex ~= nil then
            v = ops[valueOpIndex]
        else
            v = e.constValue
        end

        if k ~= nil and v ~= nil then
            result[k] = v
        end
    end

    return result
end

xvar.x_table = function(t)
    local structure = {}
    local opIndex = 1
    local op_xs = {}
    for k, v in pairs(t) do
       local e = {}
       if xvar.is_xvar(k) then
           e.keyOpIndex = opIndex
           opIndex = opIndex + 1
           table_insert(op_xs, k)
       else
           e.constKey = k
       end

       if xvar.is_xvar(v) then
           e.valueOpIndex = opIndex
           opIndex = opIndex + 1
           table_insert(op_xs, v)
       else
           e.constValue = v
       end
       table_insert(structure, e)
    end

    return xvar_ops(__table, structure, op_xs)
end

xvar.x_len = function(x1)
    return #x1
end

local function __select(...)
    local num = select("#", ...)
    for i = 1, num do
        local v = select(i, ...)
        if v and v ~= xvar_err_nil  then
            return i
        end
    end
    return num + 1
end

xvar.x_select = function(...)
    return xvar.fn(__select, ...)
end

local function __index(index, ...)
    if index == true then
        index = 1
    elseif index == false or index == nil then
        index = 2
    end
    return select(index, ...)
end

xvar.x_index = function(index_x, ...)
    return xvar.fn(__index, index_x, ...)
end

local function __indexof(t,item)
    if t == xvar_err_nil or t == nil then
        return nil
    end

    if item == xvar_err_nil or item == nil then
        return nil
    end

    for index, v in ipairs(t) do
        if v == item then
            return index
        end
    end
end

xvar.x_indexof = function(t_x, item_x)
    return xvar.fn(__indexof, t_x, item_x)
end

x_operators = {
    ["+"] = meta_xvar["__add"],
    ["-"] = meta_xvar["__sub"],
    ["*"] = meta_xvar["__mul"],
    ["/"] = meta_xvar["__div"],

    ["%"] = meta_xvar["__mod"],
    ["^"] = meta_xvar["__pow"],

    ["//"] = meta_xvar["__idiv"],

    -- used as conditional operators
    ["&"] = xvar.x_and,
    ["|"] = xvar.x_or,
    ["~"] = xvar.x_xor,

    [".."] = meta_xvar["__concat"],

    ["<<"] = meta_xvar["__shl"],
    [">>"] = meta_xvar["__shr"],

    ["=="] = xvar.x_eq,
    ["~="] = xvar.x_noteq,

    ["<"] = xvar.x_lt,
    ["<="] = xvar.x_le,

    [">"] = xvar.x_gt,
    [">="] = xvar.x_ge,

    ["or"] = xvar.x_or,
    ["and"] = xvar.x_and,
    ["xor"] = xvar.x_xor,

    ["."] = __x_index,
    ["()"] = xvar.x_call,
    ["not"] = __lnot,
    ["#"] = xvar.x_len,

    ["?+"] = xvar.x_safe_add
    -- ["-"] = meta_xvar["__sub"],
    -- ["*"] = meta_xvar["__mul"],
    -- ["/"] = meta_xvar["__div"],

}

xvar.x_op = function(op1, operator, op2)
    local xop = x_operators[operator]
    return xop(op1, op2)
end

xvar.setNickName = function(x, name)
    rawset(x, "__xNickName", name)
end

xvar.getNickName = function(x, name)
    rawget(x, "__xNickName")
end

xvar.isDirty = xvar_isDirty
xvar.isVolatile = xvar_isVolatile
xvar.setVolatile = xvar_setVolatile
-- don't use this function unless you're developing fundamental code for xvar.
xvar.setDirty = xvar_setDirty
xvar.reset = xvar_reset
xvar.addDirtyCallback = xvar_addDirtyCallback
xvar.readonly = xvar_readonly
xvar.removeDirtyCallback = xvar_removeDirtyCallback
xvar.removeAllDirtyCallbacks = xvar_removeAllDirtyCallbacks
xvar.getCollectDebugMsg = xvar_getCollectDebugMsg


xvar.rawValue = function(x)
    return rawget(x, "__xvalue")
end

xvar.verifyDirty = function(x, verifyDirty)
    rawset(x, "__xverifydirty", verifyDirty)
end

xvar.setValue = function(x, value)
    local xop = rawget(x, "__xop")
    if xop ~= 0 then
        assert(false)
    end
    local xvalue = rawget(x, "__xvalue")
    if (value == xvalue) then
        return
    end
    rawset(x, "__xvalue", value)
    if not rawget(x, "__xdirty") then
        xvar_setDirty(x)
    end
end

xvar.is_nil = function(v)
    return v == nil or v == xvar_err_nil
end

xvar.is_false = function(v)
    return v == nil or v == xvar_err_nil or v == false
end

xvar.table_insert = function(x, ...)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        table_insert(xvalue, ...)
        rawset(x, "__xvolatile", true)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x, #xvalue)
        end
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
    end
end

xvar.table_remove = function(x, pos)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        rawset(x, "__xvolatile", true)
        local v = table_remove(xvalue, pos)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
        return v
    end
end

xvar.table_clear = function(x)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        rawset(x, "__xvolatile", true)
        for k in pairs(xvalue) do
            xvalue[k] = nil
        end
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
    end
end

xvar.table_sort = function(x, comp)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        rawset(x, "__xvolatile", true)
        table.sort(xvalue, comp)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
    end
end

xvar.table_copy = function(x, t)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        rawset(x, "__xvolatile", true)
        for k, v in pairs(t) do
            rawset(xvalue, k, v)
        end
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        --if (g_xvarDebug) then
        --    --xvar_collectDebugMsg(x)
        --end
    end
end

local meta_xform = {
    __shr = function(form, f)
        return xvar.fn(f, table.unpack(form))
    end,
}

xvar.on_error = on_error

xvar.x_form = function(...)
    local form = {...}
    setmetatable(form, meta_xform)
    return form
end

g_xvarOpNames = {
    [builtin_binary_ops.__add] = "+",
    [builtin_binary_ops.__sub] = "-",
    [builtin_binary_ops.__mul] = "*",
    [builtin_binary_ops.__div] = "/",
    [builtin_binary_ops.__mod] = "%",
    [builtin_binary_ops.__pow] = "^",
    [builtin_binary_ops.__idiv] = "//",

    [builtin_binary_ops.__concat] = "..",
    [builtin_binary_ops.__shl] = "<<",
    [builtin_binary_ops.__shr] = ">>",

    [builtin_unary_ops.__len] = "#",
    [builtin_unary_ops.__unm] = "-",

    [__index] = "[]",

    [__eq] = "==",
    [__noteq] = "~=",

    [__lt] = "<",
    [__le] = "<=",

    [__gt] = ">",
    [__ge] = ">=",

    [__land] = "&",
    [__lor] = "|",
    [__lxor] = "~(xor)",
    [__lnot] = "~(not)",

    [__call] = "()",

    [__filter] = "filter",
    [__sort] = "sort",
    [__extend] = "extend",
    [__find] = "find",
    [__indexof] = "indexof",
    [__count] = "count",

    [__sum] = "sum",
    [__safe_sum] = "safe_sum",
    [__min] = "min",
    [__max] = "max",
    [__table] = "x_table",

    [__safe_add] = "?+",
    [__select] = "select",

    [__A_or_B] = "A_or_B",
}

g_buildInBinaryOps = {}
for k, v in pairs(builtin_binary_ops) do
    local name = g_xvarOpNames[v]
    g_buildInBinaryOps[name] = true
end

g_buildInBinaryOps["?+"] = true
g_buildInBinaryOps["~"] = true
g_buildInBinaryOps["<"] = true
g_buildInBinaryOps["<="] = true
g_buildInBinaryOps[">"] = true
g_buildInBinaryOps[">="] = true
g_buildInBinaryOps["&"] = true
g_buildInBinaryOps["|"] = true

xvar.desc = function(x, shortPath, fs, rs)
    if rs == nil then
        rs = "\n"
    end

    if fs == nil then
        fs = ""
    end

    local varNameGenerator = xvar.createVarNameGenerator()
    local rootName = varNameGenerator(x)
    local visitMap = {}
    local node = xvar.desc_node(x, varNameGenerator, shortPath, visitMap)
    local desc =  xvar.depthFirstDesc(node, fs, rs, "", "")
    return desc
end

xvar.analyzeXname = function (input, shortPath)
    -- Split on first space
    local spacePos = input:find(" ")
    local opName = input:sub(1, spacePos - 1)
    local rest = input:sub(spacePos + 1)

    -- Split on colon
    local colonPos = rest:find(":")
    local path = rest:sub(1, colonPos - 1)
    local line = rest:sub(colonPos + 1)

    -- Get base name (last part after / or \)
    local baseName = path

    if shortPath then
        -- Find last directory separator
        local lastSlash = path:find("/[^/]*$") or 0
        local lastBackslash = path:find("\\[^\\]*$") or 0
        local lastSep = math.max(lastSlash, lastBackslash)

        if lastSep > 0 then
            baseName = path:sub(lastSep + 1)
        end
    end

    -- Remove .lua extension
    if baseName:sub(-4) == ".lua" then
        baseName = baseName:sub(1, -5)
    end

    return opName , baseName .. ":" .. line
end

xvar.desc_node = function(x, varNameGenerator, shortPath, visitMap)
    local node = {}
    visitMap[x] = true
    node.value = rawget(x, "__xvalue")
    local desc = varNameGenerator(x) .. " = "
    local xname = rawget(x, "__xname")
    local opName, location
    if xname == nil then
        setDebugInfo(x, nil, rawget(x, "__xf"))
        xname = rawget(x, "__xname")
    end
    opName, location = xvar.analyzeXname(xname, shortPath)
    local xop = rawget(x, "__xop")
    local ops = rawget(x, "__op_xs")
    local ops_count = ops and #ops or 0.
    local subNames  = {}
    if xop == 2 and g_buildInBinaryOps[opName] then
        local ops = rawget(x, "__op_xs")
        desc = desc .. varNameGenerator(ops[1]) .. " " .. opName .. " " .. varNameGenerator(ops[2])
    else
        desc = desc .. " " .. opName .. "("
        if ops_count > 0 then
            for i = 1, ops_count do
                desc = desc .. varNameGenerator(ops[i])
                if i < #ops then
                    desc = desc .. ","
                end
            end
        end
        desc = desc .. ")"
    end

    desc = desc ..  " = " .. tostring(node.value) .. "\t@" ..location
    node.desc = desc

    if ops_count > 0 then
        node.children = {}
        for i = 1, ops_count do
            local op = ops[i]
            if not visitMap[op] then
                table_insert(node.children, xvar.desc_node(op,  varNameGenerator , shortPath, visitMap))
            end
        end
    end
    return node
end

xvar.depthFirstDesc = function(node, fs, rs, desc, indent)
    desc = indent .. node.desc
    if node.children == nil then
        return desc
    end

    indent = indent .. fs
    for _, child in ipairs(node.children) do
        local childDesc = xvar.depthFirstDesc(child, fs, rs, desc, indent)
        desc = desc .. rs .. childDesc
    end
    return desc
end

xvar.createVarNameGenerator = function()
    local counter = 0
    local map = {}

    -- Function to convert a number to column-style letters (a, b, ..., z, aa, ab, ...)
    local function to_column_letters(n)
        local result = ""
        while n > 0 do
            local remainder = (n - 1) % 26
            result = string.char(97 + remainder) .. result  -- 97 is ASCII for 'a'
            n = math.floor((n - 1) / 26)
        end
        return result
    end
    return function(x)
        local name = map[x]
        if name then
            return name
        end
        counter = counter + 1
        name = to_column_letters(counter)
        map[x] = name
        return name
    end
end

xvar.setTrace = function(x_trace)
    __x_trace = x_trace
end

return xvar

