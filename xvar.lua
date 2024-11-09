--author cs
--04nycs@gmail.com
--
--https://github.com/ThinEureka/xvar
--created on Apri 10, 2024 
--
local xvar = {}

local rawget = rawget
local rawset = rawset

local __err_xs = {}
-- g_allXars = {}
local __x_trace = true

-- this function assumes we're using tabMachine context stack
local function on_error(error)
    local strArray = {}
    local x = __err_xs[#__err_xs]
    table.insert(strArray, error)
    if x ~= nil then
        local xvarMap = {}
        local desc = xvar.getXvarDesc(x, xvarMap)
        table.insert(strArray, xvar.descToStr(desc))
    end

    table.insert(strArray, "tabStack {")
    for i = 1, g_getCurStackNum() do
        local context = __contextStack[i].context
        if context ~= nil then
            table.insert(strArray, context:getDetailedPath())
        end
    end
    table.insert(strArray, "}")
    table.insert(strArray, debug.traceback("", 1))
    local strError = table.concat(strArray, "\n")
    printError(strError)

    if fabric and fabric.getInstance and fabric:getInstance() then
        fabric:getInstance():reportCustomException(strError)
    end

end

xvar.pcall = function(f, x, ...)
    local x_trace = __x_trace
    --temporality diabled
    x_trace = false
    if x_trace then 
        table.insert(__err_xs, x)
    end

    local stat, result = xpcall(f, on_error, ...)

    if x_trace then 
        table.remove(__err_xs)
    end

    if stat then
        return result
    end
end

local xvar_err_nil = {}

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

if __xArrayPool == nil then
    __xArrayPool = {}
end

local __xArrayPool = __xArrayPool

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

local __sum = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return xvar_err_nil
    end

    local sum = 0
    for _, v in pairs(op1) do
        sum = sum + v
    end

    return sum
end

local __safe_sum = function(op1)
    if op1 == nil or op1 == xvar_err_nil then
        return 0
    end

    local sum = 0
    for _, v in pairs(op1) do
        if v ~= nil and v ~= xvar_err_nil then
            sum = sum + v
        end
    end

    return sum
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

xvar_op0 = function(c)
    local x = {}
    setmetatable(x, meta_xvar)
    rawset(x, "__xop", 0)
    rawset(x,"__xvalue", c)

    if g_xvarDebug then
        rawset(x, "__xname", debug.traceback("", 1):gsub("\n", "#"))
    end

   -- rawset(x, "__xdirty", true)


    return x
end

xvar_opn = function(f, ...)
    local x = {}
    setmetatable(x, meta_xvar)
    -- table.insert(g_allXars, x)

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
        table.insert(op_xs, op_x)
    end
    rawset(x,"__op_xs", op_xs)

    rawset(x, "__xdirty", true)
    if g_xvarDebug then
        rawset(x, "__xname", debug.traceback("", 1):gsub("\n", "#"))
    end

    return x
end

xvar_op1 = xvar_opn 
xvar_op2 = xvar_opn 

xvar_opx = function(f)
    local x = {}
    rawset(x,"__xop", -1)
    setmetatable(x, meta_xvar)
    -- table.insert(g_allXars, x)

    rawset(x,"__xf", f)

    rawset(x, "__xdirty", true)
    if g_xvarDebug then
        rawset(x, "__xname", debug.traceback("", 1):gsub("\n", "#"))
    end

    return x
end

xvar_ops = function(f, structure, op_xs)
    local x = {}
    setmetatable(x, meta_xvar)
    -- table.insert(g_allXars, x)

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
        rawset(x, "__xname", debug.traceback("", 1):gsub("\n", "#"))
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
        table.insert(msgs, msg)
    end
    local sinks = rawget(x, "__xsinks")
    if sinks ~= nil then
        for sink, _ in pairs(sinks) do
            xvar_collectDebugMsg(sink, msg)
        end
    end
end

xvar_setDirty = function(x, location)
    local xArray = table.remove(__xArrayPool)
    if xArray == nil then
        xArray = {} 
    end

    local callbackArray = table.remove(__xArrayPool)
    if callbackArray == nil then
        callbackArray = {} 
    end

    xvar_collectDirty(x, xArray, callbackArray, location)

    for index = 1, #xArray do
        -- callbackArray[index](xArray[index])
        local x = xArray[index] 
        if g_xvarDebug then
            table.insert(__err_xs, x)
        end
        xpcall(callbackArray[index], on_error, x)
        if g_xvarDebug then
            table.remove(__err_xs)
        end
    end

    while next(xArray) do
        table.remove(xArray)
    end
    table.insert(__xArrayPool, xArray)

    while next(callbackArray) do
        table.remove(callbackArray)
    end
    table.insert(__xArrayPool, callbackArray)
end

xvar_collectDirty = function(x, xArray, callbackArray, location, excludeX)
    if not excludeX then
        rawset(x, "__xdirty", true)
        rawset(x, "__xdirty_location", location)
    end

    local callbacks = rawget(x, "__xdirtycallbacks")
    if callbacks ~= nil then
        for index, callback in pairs(callbacks) do
            table.insert(xArray, x)
            table.insert(callbackArray, callback)
        end
    end

    local sinks = rawget(x, "__xsinks")
    if sinks ~= nil then
        for sink, _ in pairs(sinks) do
            if not rawget(sink, "__xdirty") then
                if location == nil then
                    xvar_collectDirty(sink, xArray, callbackArray, nil)
                else
                    local xSourceLocation = rawget(sink, "__xsourcelocation")
                    if xSourceLocation == nil then
                        xvar_collectDirty(sink, xArray, callbackArray, nil)
                    else
                        local miss = false
                        local isValue = false
                        local op_xs = rawget(sink, "__op_xs")
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
                                xvar_collectDirty(sink, xArray, callbackArray, location, true)
                            else
                                xvar_collectDirty(sink, xArray, callbackArray, nil)
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

xvar_getCollectDebugMsg = function(x)
    return rawget(x, "__xdebugmsgs")
end

pcall_xvar_validate = function(x)
    if g_xvarDebug then
        table.insert(__err_xs, x)
    end
    local stat = xpcall(xvar_validate, on_error, x)
    if g_xvarDebug then
        table.remove(__err_xs)
    end
    if not stat then
        rawset(x, "__xvalue", xvar_err_nil)
        rawset(x, "__xdirty", false)
    end
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
            value = f(table.unpack(ops))
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
        rawset(x, "__xvalue", nil)

        rawset(x,"__xstructue", rawget(v, "__xstructue"))

        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
    end

    if (g_xvarDebug) then
        xvar_collectDebugMsg(x)
    end
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
        if g_xvarDebug then
            table.insert(__err_xs, x)
        end
        xpcall(callback, on_error, x)
        if g_xvarDebug then
            table.remove(__err_xs)
        end
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
        xvar_setDirty(x, k)
        if (g_xvarDebug) then
            xvar_collectDebugMsg(x)
        end
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
    if op1 == nil or op1 == xvar_err_nil then
        if op2 == nil or op2 == xvar_err_nil then
            return 0
        end
        return op2
    else
        if op2 == nil or op2 == xvar_err_nil then
            return op1
        end
        return op1 + op2
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

xvar.x_sum = function(x1)
    return xvar_op1(__sum, x1)
end

xvar.x_safe_sum = function(x1)
    return xvar_op1(__safe_sum, x1)
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

local __min = function(structure, ops)
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

xvar.x_min = function(...)
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
            table.insert(op_xs, x)
        else
            e.constValue = x
        end

        table.insert(structure, e)
    end

    return xvar_ops(__min, structure, op_xs)
end

local __max = function(structure, ops)
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

xvar.x_max = function(...)
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
            table.insert(op_xs, x)
        else
            e.constValue = x
        end

        table.insert(structure, e)
    end

    return xvar_ops(__max, structure, op_xs)
end

local __table = function(structure, ops)
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
           table.insert(op_xs, k)
       else
           e.constKey = k
       end
       
       if xvar.is_xvar(v) then
           e.valueOpIndex = opIndex
           opIndex = opIndex + 1
           table.insert(op_xs, v)
       else
           e.constValue = v
       end
       table.insert(structure, e)
    end

    return xvar_ops(__table, structure, op_xs)
end

xvar.x_len = function(x1)
    return #x1
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

xvar.setName = function(x, name)
    rawset(x, "__xname", name)
end

xvar.getName = function(x, name)
    rawget(x, "__xname")
end

xvar.isDirty = xvar_isDirty
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
        table.insert(xvalue, ...)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x, #xvalue)
        end
        if (g_xvarDebug) then
            xvar_collectDebugMsg(x)
        end
    end
end

xvar.table_remove = function(x, pos)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        table.remove(xvalue, pos)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        if (g_xvarDebug) then
            xvar_collectDebugMsg(x)
        end
    end
end

xvar.table_sort = function(x, comp)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        table.sort(xvalue, comp)
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        if (g_xvarDebug) then
            xvar_collectDebugMsg(x)
        end
    end
end

xvar.table_copy = function(x, t)
    if rawget(x, "__xop") == 0 then
        local xvalue = rawget(x, "__xvalue")
        for k, v in pairs(t) do
            rawset(xvalue, k, v)
        end
        if not rawget(x, "__xdirty") then
            xvar_setDirty(x)
        end
        if (g_xvarDebug) then
            xvar_collectDebugMsg(x)
        end
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
    
    [__filter] = "xvar.filter",
    [__sort] = "xvar.sort",
    [__extend] = "xvar.extend",
    [__find] = "xvar.find",
    [__indexof] = "xvar.indexof",

    [__sum] = "xvar.sum",
    [__safe_sum] = "xvar.safe_sum",
    [__min] = "xvar.min",

    [__safe_add] = "?+",
}

--xvar traceback
local __getValueDesc = nil
local __getDesc = nil
local __getXDesc = nil
local __getFDesc = nil

__getFormula = function(desc)
    if type(desc) == "table" and desc.__isXDesc then
        if desc.formula == nil then
            return "*"
        end
        return desc.formula
    end
    return desc 
end

__getXDesc = function (x, xvarMap, upward)
   local desc = xvarMap[x]
   if desc ~= nil then
       return desc
   else
      desc = {}
   end

   xvarMap[x] = desc

   desc.__isXDesc = true

   local name = rawget(x, "__xname") or "nil"
   desc.xname = name

   local xop = rawget(x, "__xop")
   desc.xop = xop

   local xvalue = rawget(x, "__xvalue") 
   local valueDesc = __getDesc(xvalue, xvarMap, false)
   desc.xvalue = valueDesc

   local f = rawget(x, "__xf") 
   desc.xf =  __getFDesc(f)

   local op1 = rawget(x, "__op1") 
   desc.op1 = __getDesc(op1, xvarMap, true)

   local op2 = rawget(x, "__op2") 
   desc.op2 =  __getDesc(op2, xvarMap, true)

   if xop == 0 then
       desc.formula = "f0(" ..__getFormula(valueDesc) ..")"
   elseif xop == 1 then
       desc.formula = desc.xf .. "(" .. __getFormula(desc.op1) .. ")"
   elseif xop == 2 then
       desc.formula = desc.xf .. "(" .. __getFormula(desc.op1)  .. "," .. __getFormula(desc.op2) .. ")"
   elseif xop == -1 then
       desc.formula = desc.xf .. "()"
   else 
       desc.formula = "*"
   end

   if not upward then
       local xskins = rawget(x, "__xsinks")
       if xskins ~= nil then
           desc.xskins = {}

           local count = 0
           for sink, _ in pairs(xskins) do
               count = count + 1
               table.insert(desc.xskins, __getXDesc(sink, xvarMap, false))
           end
       end
   else
       desc.xskins = "#"
   end

   return desc
end

__getDesc = function(value, xvarMap, upward)
   if value ~= nil and type(value) == "table" and rawget(value, "__xop") ~= nil then
       return __getXDesc(value, xvarMap, upward)
   else 
       return  __getValueDesc(value)
   end
end


__getValueDesc = function(v)
    local desc = tostring(v)
    return desc
end

__getFDesc = function(f)
    if type(f) == "nil" then
        return "nil"
    end

    local name = g_xvarOpNames[f]
    if name ~= nil then
        return name
    end

    local info = debug.getinfo(f)
    local file  = info.source
    local line = info.linedefined
    return file .. " " .. line
end

xvar.getXvarDesc = __getXDesc

xvar.descToStr = function(desc)
    local str = ""
    dump(desc, "x", 99, function(s)
        str = str .. s 
    end)
    return str
end

xvar.setTrace = function(x_trace)
    __x_trace = x_trace 
end

return xvar

