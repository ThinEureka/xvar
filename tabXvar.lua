
--author cs
--email 04nycs@gmail.com
--
--https://github.com/ThinEureka/xvar
--created on Apri 10, 2024
--

local tabXvar = {}
local xvar = require("util.xvar")
local tabMachine = require("tabMachine.tabMachine")

--setXvarName default is true
tabXvar.xBind = _({
    s1 = function(c, xvarToView, setXvarName)
        c.xvarToView = xvarToView
        if setXvarName == nil then
            setXvarName = true
        end
        c.setXvarName = setXvarName
        c.dirtyCallback = function(x)
            if c:isQuitting() then
                return
            end
            c.dirtyMap[x] = true
            if c:getSub("u1") == nil then
                c:start("u1")
            end
        end
        c:start("t1")
    end,

    inner = {
        xvarTab = function(c)
            return c
        end,
    },

    final = function(c)
        c:removeAllCallBack()
    end,

    t1 = function(c)
        c:stopAllSubs("tabUnLinkXvar")
        c.unLinkMap = {}
        c.dirtyMap = {}
        c.callBackKeys = {}
        for index, xvarToView in pairs(c.xvarToView) do
            if not c:isQuitting() then
                local x = xvarToView[1]
                c.dirtyMap[x] = true
                if c.setXvarName then
                    if xvar.getName(x) == nil then
                        xvar.setName(x, c:getPath() .. "->xbind.".. index)
                    end
                end
                local callBackKeys = xvar.addDirtyCallback(x, c.dirtyCallback)
                c.callBackKeys[x] = callBackKeys
                if c:isQuitting() then
                    xvar.removeDirtyCallback(x, callBackKeys)
                    break
                end
            end
        end
        if c:getSub("u1") == nil then
            c:start("u1")
        end
    end,

    u1 = function(c)
        c.updateCount = 5
        if (updateFunctionIsInLateUpdate()) then
            c:u1_update(0)
        end
    end,

    u1_update = function(c)
        for _, xvarToView in pairs(c.xvarToView) do
            local x = xvarToView[1]
            if (c.dirtyMap[x]) then
                local view = xvarToView[2]
                if (view) then
                    c:updateView(x, view)
                end
                c.dirtyMap[x] = nil
            end
        end
        c.updateCount = c.updateCount - 1
        if (c.updateCount < 0) then
            c:stop("u1")
        end
    end,

    --override in s1
    u1_updateInterval = nil,
    u1_updateTimerMgr = g_t.updateTimerMgr_late,

    --private:
    updateView = function(c, x, view)
        local unlinkCount = c.unLinkMap[x]
        if (unlinkCount and unlinkCount > 0) then
            return
        end
        local value = x()
        if type(view) == "function" then
            xvar.pcall(view, x, value, x)

        elseif type(view) == "table" then
            local setData = view.setData
            if setData ~= nil then
                xvar.pcall(setData, x, view, value, x)
            end
        end
    end,

    updateViewByValue = function(c, x, v, view)
        if c:isQuitting() then
            return
        end

        if type(view) == "function" then
            xvar.pcall(view, x, v, x)

        elseif type(view) == "table" then
            local setData = view.setData
            if setData ~= nil then
                xvar.pcall(setData, x, view, v, x)
            end
        end
    end,

    removeAllCallBack = function(c)
        for x, key in pairs(c.callBackKeys) do
            xvar.removeDirtyCallback(x, key)
        end
    end,

    initXvarToViewMap = function(c)
        if (c.xvarToViewMap) then
            return
        end
        c.xvarToViewMap = {}
        for index, xvarToView in ipairs(c.xvarToView) do
            c.xvarToViewMap[xvarToView[1]] = index
        end
    end,

    removeXvar = function(c, x)
        local callBackKey = c.callBackKeys[x]
        if (not callBackKey) then
            return
        end
        c.callBackKeys[x] = nil
        c:initXvarToViewMap()
        local index = c.xvarToViewMap[x]
        if (index) then
            table.remove(c.xvarToView, index)
            c.xvarToViewMap = nil
            c:initXvarToViewMap()
        end
        xvar.removeDirtyCallback(x, callBackKey)
        c.dirtyMap[x] = nil
    end,

    addXvar = function(c, x, view)
        if c.setXvarName then
            if xvar.getName(x) == nil then
                xvar.setName(x, c:getPath() .. "->newlyAdded")
            end
        end

        c:initXvarToViewMap()
        local index = c.xvarToViewMap[x]
        if (index) then
            c.xvarToView[index][2] = view
        else
            local callBackKey = xvar.addDirtyCallback(x, c.dirtyCallback)
            c.callBackKeys[x] = callBackKey
            table.insert(c.xvarToView, {x, view})
            c.xvarToViewMap[x] = #c.xvarToView
        end
        --不能放dirty里面修改，因为有可能就是dirymap里面触发的，导致直接被还原
        if (updateFunctionIsInLateUpdate()) then
            c:updateView(x, view)
        else
            c.dirtyMap[x] = true
            if c:getSub("u1") == nil then
                c:start("u1")
            end
        end
    end,

    refreshXvars = function(c, xvarToView)
        c:removeAllCallBack()
        c:stop("u1")
        c.xvarToView = xvarToView
        c.xvarToViewMap = nil
        c:start("t1")
    end,

    tabUnLinkXvar = _({
        s1 = function(c, x, value)
            c.x = x
            c.value = value
            local xvarTab = c:_("xvarTab")
            local unlinkCount = xvarTab.unLinkMap[x]
            if (unlinkCount) then
                xvarTab.unLinkMap[x] = unlinkCount + 1
            else
                xvarTab.unLinkMap[x] = 1
            end
        end,
        final = function(c)
            local xvarTab = c:_("xvarTab")

            local unlinkCount = xvarTab.unLinkMap[c.x]
            unlinkCount = unlinkCount - 1
            xvarTab.unLinkMap[c.x] = unlinkCount
            if (unlinkCount < 0) then
                printError("unlink error unlinkCount less 0")
            end
            xvarTab:initXvarToViewMap()
            local viewIndex = xvarTab.xvarToViewMap[c.x]
            if (not viewIndex) then
                return
            end
            local xvarToView = xvarTab.xvarToView[viewIndex]
            if (not xvarToView) then
                return
            end
            local view = xvarToView[2]
            if (unlinkCount <= 0) then
                if (updateFunctionIsInLateUpdate()) then
                    xvarTab:updateView(c.x, view)
                else
                    xvarTab.dirtyMap[c.x] = true
                    if xvarTab:getSub("u1") == nil then
                        xvarTab:start("u1")
                    end
                end
            elseif (c.value) then
                xvarTab:updateViewByValue(c.x, c.value, view)
            end
        end,
        event = g_t.empty_event,
    }),

    unLinkXvar = function(c, x, value)
        return c:call(c.tabUnLinkXvar(x, value), "tabUnLinkXvar"):tabProxy(nil, true)
    end,

    event = g_t.empty_event,
})

--setXvarName default is true
tabXvar.xWait = _({
    s1 = function(c, x, setXvarName)
        if setXvarName == nil then
            setXvarName = true
        end

        if setXvarName then
            if xvar.getName(x) == nil then
                xvar.setName(x, c:getPath() .. "->xWait")
            end
        end

        local v = x()
        if v then
            c:output(v)
            c:stop()
            return
        end

        c.x = x
        c.key = xvar.addDirtyCallback(x, function(x)
            if c:isQuitting() then
                return
            end
            local v = x()
            if v then
                c:output(v)
                c:stop()
            end
        end)
    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
})

--setXvarName default is true
tabXvar.xIsChanged = _({
    s1 = function(c, x, setXvarName)
        if setXvarName == nil then
            setXvarName = true
        end

        if setXvarName then
            if xvar.getName(x) == nil then
                xvar.setName(x, c:getPath() .. "->xIsChanged")
            end
        end
        c.oldValue = x()
        c.x = x
        c.key = xvar.addDirtyCallback(x, function(x)
            if c:isQuitting() then
                return
            end
            local v = x()
            if v ~= c.oldValue then
                c:output(v)
                c:stop()
            end
        end)

    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
})

tabXvar.xWatch = _({
    s1 = function(c, x, callBack, setXvarName)
        if type(callBack) ~= "function" then
            assert(false, "callBack must be a function")
            c:stop()
            return
        end

        if setXvarName == nil then
            setXvarName = true
        end

        if setXvarName then
            if xvar.getName(x) == nil then
                xvar.setName(x, c:getPath() .. "->xIsChanged")
            end
        end

        c.x = x
        c:updateView(x, callBack)

        if not c:isQuitting() then
            c.key = xvar.addDirtyCallback(x, function(x)
                c:updateView(x, callBack)
            end)
        end
    end,
    updateView = function(c, x, callBack)
        if c:isQuitting() then
            return
        end
        local v = x()
        xvar.pcall(callBack, x, v, x)
    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
})


tabXvar.xStat = _({
    s1 = function(c, list_x, statF, x1, x2, x3)
        local x2k = {}
        c.x2k = x2k
        c.stat_x = xvar.fx(function()
            return statF(list_x and list_x(), x1 and x1(), x2 and x2(), x3 and x3())
        end)
        xvar.setName(c.stat_x, c:getPath() .. "->xStat")

        if x1 ~= nil or x2 ~= nil or x3 ~= nil then
            c.x1 = x1
            c.x2 = x2
            c.x3 = x3

            c.xDirtyCallback = function(x)
                if c:isQuitting() then
                    return
                end
                xvar.setDirty(c.stat_x)
            end

            if x1 ~= nil then 
                x2k[x1] = xvar.addDirtyCallback(x1, c.xDirtyCallback)
            end

            if x2 ~= nil then
                x2k[x2] = xvar.addDirtyCallback(x2, c.xDirtyCallback)
            end

            if x3 ~= nil then
                x2k[x3] = xvar.addDirtyCallback(x3, c.xDirtyCallback)
            end
        end

        if list_x ~= nil then
            c.list_x = list_x
            local item2k = {}
            c.item2k = item2k

            c.listDirtyCallback = function(x)
                if c:isQuitting() then
                    return
                end
                xvar.setDirty(c.stat_x)
                c:updateItemCallbacks(list_x())
            end

            c.itemDirtyCallback = function(x)
                if c:isQuitting() then
                    return
                end
                xvar.setDirty(c.stat_x)
            end

            x2k[list_x] = xvar.addDirtyCallback(list_x, c.listDirtyCallback)
            c:updateItemCallbacks(list_x())
        end
    end,

    event = g_t.empty_event,

    final = function(c)
        for x, k in pairs(c.x2k) do
            xvar.removeDirtyCallback(x, k)
        end

        local item2k = c.item2k
        if item2k ~= nil then
            for x, k in pairs(item2k) do
                xvar.removeDirtyCallback(x, k)
            end
        end
    end,

    --private:
    updateItemCallbacks = function(c, list)
        local item2k = c.item2k
        if (list) then
            for _, item in pairs(list) do
                if xvar.is_xvar(item) then
                    if not item2k[item] then
                        item()
                        item2k[item] = xvar.addDirtyCallback(item, c.itemDirtyCallback)
                    end
                end
            end
        end

        for x, k in pairs(item2k) do
            if not list or not c.contains(list, x) then
                xvar.removeDirtyCallback(x, k)
            end
        end
    end,

    contains = function(list, item)
        for _, value in pairs(list) do
            if value == item then
                return true
            end
        end

        return false
    end,


    --public:
    x = function(c)
        return c.stat_x
    end
})

tabXvar.xVersion = _({
    s1 = function(c, list_x)
        c._curVersionId = nil
        c._version_x = c:call(tabXvar.xStat(list_x, function(list)
            local curVersionId = c._curVersionId
            if curVersionId == nil then
                curVersionId = 1
            else
                local oldList = c._oldList
                if #oldList ~= #list then
                    curVersionId = curVersionId + 1
                else
                    for k, v in ipairs(list) do
                        if oldList[k] ~= v() then
                            curVersionId = curVersionId + 1
                            break
                        end
                    end
                end
            end

            if c._curVersionId ~= curVersionId then
                c._curVersionId = curVersionId
                c._oldList = {}
                for k, v in ipairs(list) do
                    c._oldList[k] = v()
                end
            end
            return curVersionId
        end), "xStat"):x()

        xvar.verifyDirty(c._version_x, true)
    end,

    --public:
    x = function(c)
        return c._version_x
    end
})

tabXvar.xAlive = _({
    s1 = function(c, target)
        c.ref_x = xvar.f0(target)
        if target == nil or target:isQuitting() then
            return
        end
        target.p:registerLifeTimeListener(target.__name, c)
    end,

    event = {
        [tabMachine.event_context_stop] = function(c, p, name, target)
            if c.ref_x() == target then
                xvar.setValue(c.ref_x, nil)
            end
        end,
    },

    --public:
    --******
        -- c.ref_x
    --******
})

tabXvar.xAliveMap = _({
    s1 = function(c)
        c.ref_x = xvar.f0({})
        c.targetToKey = {}
        -- target.p:registerLifeTimeListener(target.__name, c)
    end,


    event = {
        [tabMachine.event_context_stop] = function(c, p, name, target)
            local key = c.targetToKey[target]
            if key == nil then
                return
            end

            c.ref_x[key] = nil
            c.targetToKey[target] = nil
        end,
    },

    --public:
    --******
        -- c.ref_x
    --******
    --

    add = function(c, key, target)
        if target == nil or target:isQuitting() then
            return
        end

        c.ref_x[key] = target
        c.targetToKey[target] = key
        target.p:registerLifeTimeListener(target.__name, c)
    end,
})

tabXvar.xInertia = _({
    s1 = function(c, x, delay)
        c.nextValue = x()
        c.inertiaX = xvar.f0(c.nextValue)
        c:call(tabXvar.xWatch(x, function(v)
            if c.nextValue == v then
                return
            end

            c.nextValue = v
            if delay ~= nil then
                if not c:hasSub("u0") then
                    c:call(g_t.delay(delay), "u0")
                end
            else
                c:start("u1")
            end
        end), "watch")
    end,

    u1 = function(c)
        xvar.setValue(c.inertiaX, c.nextValue)
    end,

    x = function(c)
        return c.inertiaX
    end
})

return tabXvar
