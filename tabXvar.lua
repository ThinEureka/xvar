
--author cs
--email 04nycs@gmail.com
--
--https://github.com/ThinEureka/xvar
--created on Apri 10, 2024
--

local tabXvar = {}
local xvar = require("util.xvar")
local tabMachine = require("tabMachine.tabMachine")
local volatile = {}

tabXvar.xBind = _{
    s1 = function(c, xvarToViewList, setXvarName, needSort)
        c.xvarToViewList = xvarToViewList
        if setXvarName == nil then
            setXvarName = true
        end
        c.setXvarName = setXvarName
        c.needSort = needSort
        c.dirtyCallback = function(x)
            if c:isQuitting() then
                return
            end
            local callBackKey = c.xvarMap[x]
            if callBackKey then
                c.dirtyMap[callBackKey] = callBackKey
            end
            if c.init and c:getSub("u1") == nil then
                c:start("u1")
            else
                c.updateCount = 5
            end
        end
    end,
    s2 = function(c)
        c.init = false
        c:stopAllSubs("tabUnLinkXvar")
        c.unLinkMap = {}
        c.lastValue = {}
        c.dirtyMap = {}
        c.callBackKeys = {}
        c.xvarMap = {}
        for index, xvarToView in pairs(c.xvarToViewList) do
            if c:isQuitting() then
                return
            end
            local x = xvarToView[1]
            if c.setXvarName then
                if xvar.getName(x) == nil then
                    xvar.setName(x, c:getPath() .. "->xbind.".. index)
                end
            end
            local callBackKey = xvar.addDirtyCallback(x, c.dirtyCallback)
            if c:isQuitting() then
                xvar.removeDirtyCallback(x, callBackKey)
                return
            end
            if c.xvarMap[x] then
                printError("tabXvar.xBind: xvar is already binded to another view", c:getPath())
            end
            c.xvarMap[x] = callBackKey
            c.dirtyMap[callBackKey] = callBackKey
            c.callBackKeys[callBackKey] = xvarToView
            c.lastValue[callBackKey] = volatile
        end
        c.init = true
        if c:getSub("u1") == nil then
            c:start("u1")
        else
            c.updateCount = 5
        end
    end,
    u1 = function(c)
        c.updateCount = 5
        if (updateFunctionIsInLateUpdate()) then
            c:u1_update(0)
        end
    end,
    u1_update = function(c)
        if (c.needSort) then
            local dirtyList = {}
            for callBackKey, state in pairs(c.dirtyMap) do
                if (state) then
                    table.insert(dirtyList, callBackKey)
                end
            end
            table.sort(dirtyList, function(a, b)
                return a < b
            end)
            for _, callBackKey in pairs(dirtyList) do
                c.dirtyMap[callBackKey] = nil
                local xvarToView = c.callBackKeys[callBackKey]
                local view = xvarToView[2]
                if (view) then
                    local x = xvarToView[1]
                    local isVolatile = xvarToView[3]
                    c:updateView(x, view, isVolatile, callBackKey)
                end
            end
        else
            for callBackKey, state in pairs(c.dirtyMap) do
                if (state) then
                    c.dirtyMap[callBackKey] = nil
                    local xvarToView = c.callBackKeys[callBackKey]
                    local view = xvarToView[2]
                    if (view) then
                        local x = xvarToView[1]
                        local isVolatile = xvarToView[3]
                        c:updateView(x, view, isVolatile, callBackKey)
                    end
                end
            end
        end
        c.updateCount = c.updateCount - 1
        if (c.updateCount < 0) then
            c:stop("u1")
        end
    end,
    u1_updateInterval = nil,
    u1_updateTimerMgr = g_t.updateTimerMgr_late,
    inner = {
        xvarTab = function(c)
            return c
        end,
    },
    final = function(c)
        c:removeAllCallBack()
    end,
    removeAllCallBack = function(c)
        for x, callBackKey in pairs(c.xvarMap) do
            xvar.removeDirtyCallback(x, callBackKey)
        end
    end,
    updateView = function(c, x, view, isVolatile, key)
        local unlinkCount = c.unLinkMap[x]
        if (unlinkCount and unlinkCount > 0) then
            return
        end
        local value = x()
        if isVolatile or type(value) == "table" or value ~= c.lastValue[key] or xvar.isVolatile(x) then
            c.lastValue[key] = value
            c:updateViewByValue(x, value, view)
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
    removeXvar = function(c, x)
        local callBackKey = c.xvarMap[x]
        if callBackKey ~= nil then
            xvar.removeDirtyCallback(x, callBackKey)
            c.callBackKeys[callBackKey] = nil
            c.dirtyMap[callBackKey] = nil
            c.xvarMap[x] = nil
        end
    end,
    addXvar = function(c, x, view, isVolatile)
        local callBackKey = c.xvarMap[x]
        if (not callBackKey) then
            callBackKey = xvar.addDirtyCallback(x, c.dirtyCallback)
            if c:isQuitting() then
                xvar.removeDirtyCallback(x, callBackKey)
                return
            end
            if c.setXvarName then
                if xvar.getName(x) == nil then
                    xvar.setName(x, c:getPath() .. "->newlyAdded")
                end
            end
            c.xvarMap[x] = callBackKey
            c.callBackKeys[callBackKey] = {x, view, isVolatile}
        else
            local xvarToView = c.callBackKeys[callBackKey]
            local oldView = xvarToView[2]
            if (oldView ~= view) then
                printError("tabxvar 不能对想同xvar添加不同监听")
                return
            end
        end
        --不能放dirty里面修改，因为有可能就是dirymap里面触发的，导致直接被还原
        if (updateFunctionIsInLateUpdate()) then
            c:updateView(x, view, isVolatile, callBackKey)
        else
            c.dirtyMap[callBackKey] = callBackKey
            if c:getSub("u1") == nil then
                c:start("u1")
            else
                c.updateCount = 5
            end
        end
    end,
    refreshXvars = function(c, xvarToViewList)
        c:removeAllCallBack()
        c:stop("u1")
        c.xvarToViewList = xvarToViewList
        c:start("s2")
    end,
    tabUnLinkXvar = _{
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

            if (xvarTab:isQuitting()) then
                return
            end
            local callBackKey = xvarTab.xvarMap[c.x]
            if (callBackKey) then
                local xvarToView = xvarTab.callBackKeys[callBackKey]
                if (xvarToView) then
                    local view = xvarToView[2]
                    if (unlinkCount <= 0) then
                        if (updateFunctionIsInLateUpdate()) then
                            local isVolatile = xvarToView[3]
                            xvarTab:updateView(c.x, view, isVolatile, callBackKey)
                        else
                            xvarTab.dirtyMap[callBackKey] = callBackKey
                            if xvarTab:getSub("u1") == nil then
                                xvarTab:start("u1")
                            end
                        end
                    elseif (c.value) then
                        xvarTab:updateViewByValue(c.x, c.value, view)
                    end
                end
            end
        end,
        event = g_t.empty_event,
    },

    unLinkXvar = function(c, x, value)
        return c:call(c.tabUnLinkXvar(x, value), "tabUnLinkXvar"):tabProxy(nil, true)
    end,

    event = g_t.empty_event,
}

--setXvarName default is true
tabXvar.xWait = _{
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
        local key = xvar.addDirtyCallback(x, function(x)
            if c:isQuitting() then
                return
            end
            local v = x()
            if v then
                c:output(v)
                c:stop()
            end
        end)
        if c:isQuitting() then
            xvar.removeDirtyCallback(c.x, key)
            return
        end
        c.key = key
    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
}

--setXvarName default is true
tabXvar.xIsChanged = function(x)
    return tabXvar.xWait(x {"~=", x()})
end

tabXvar.xWatchModification = _{
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
                xvar.setName(x, c:getPath() .. "->xWatchModification")
            end
        end
        c.v = x()
        c.x = x
        local key = xvar.addDirtyCallback(c.x, function(x)
            c:updateView(x, callBack)
        end)
        if c:isQuitting() then
            xvar.removeDirtyCallback(c.x, key)
            return
        end
        c.key = key
    end,
    
    updateView = function(c, x, callBack)
        if c:isQuitting() then
            return
        end
        local v = x()
        if type(v) == "table" or c.v ~= v or xvar.isVolatile(x) then
            c.v = v
            xvar.pcall(callBack, x, v, x)
        end
    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
}

tabXvar.xWatch = _{
    s1 = function(c, x, callBack, isVolatile, setXvarName)
        c.isVolatile = isVolatile
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
                xvar.setName(x, c:getPath() .. "->xWatch")
            end
        end

        c.x = x
        c:updateView(x, callBack, true)

        if c:isQuitting() then
            return
        end

        local key = xvar.addDirtyCallback(x, function(x)
            c:updateView(x, callBack, false)
        end)
        if c:isQuitting() then
            xvar.removeDirtyCallback(c.x, key)
            return
        end
        c.key = key
    end,
    updateView = function(c, x, callBack, firstSetVal)
        if c:isQuitting() then
            return
        end
        local v = x()
        if firstSetVal or c.isVolatile or type(v) == "table" or c.v ~= v or xvar.isVolatile(x) then
            c.v = v
            xvar.pcall(callBack, x, v, x)
        end
    end,

    event = g_t.empty_event,

    final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c.x, c.key)
        end
    end,
}


tabXvar.xStat = _{
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
}

tabXvar.xSeq = _{
	s1 = function(c, target_x, count)
		c._x = xvar.f0(nil)
		c._target_x = target_x

		c._next = {}
		c._curTargetValue = nil
		c._count = count

		local key = xvar.addDirtyCallback(target_x, function(x)
			if c:isQuitting() then
				return
			end

			local target = x()
			if target ~= c._curTargetValue and target ~= xvar.err_nil and target ~= nil then
				table.insert(c._next, target)
				c._curTargetValue = target
				if #c._next == c._count then
					xvar.setValue(c._x, c._next)
					c._next = {}
				end
			end
		end)

		if not c:isQuitting() then
			c.key = key
		else
			xvar.removeDirtyCallback(c._target_x, key)
		end
	end,

	event = g_t.empty_event,

	final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c._target_x, c.key)
        end
	end,

	x = function(c)
		return c._x
	end
}

tabXvar.xInState = _{
	s1 = function(c, state_x, targetState, duration)
		c._state_x = state_x
		c._targetState = targetState
		c._duration = duration

		if state_x() == targetState then
			if duration == nil then
				c:output(targetState)
				c:stop()
				return
			else
				c:start("t1")
			end
		end

		local key = xvar.addDirtyCallback(state_x, function(x)
			local state = x()
			if c:isQuitting() then
				return
			end

			if state == targetState then
				if duration == nil or duration == 0 then
					c:output(targetState)
					c:stop()
					return
				end

				if not c:hasSub("t2") then
					c:start("t1")
				end
			else
				c:abort("t2")
			end
		end)

		if not c:isQuitting() then
			c.key = key
		else
			xvar.removeDirtyCallback(c._state_x, key)
		end
	end,

	t1 = function(c)
		c:call(g_t.delay(c._duration), "t2")
	end,

	t3 = function(c)
		c:output(c._state_x())
		c:stop()
	end,

	event = g_t.empty_event,

	final = function(c)
        if c.key then
            xvar.removeDirtyCallback(c._state_x, c.key)
        end
	end,

}

tabXvar.xVersion = _{
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
}

tabXvar.xAlive = _{
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
}

tabXvar.xAliveMap = _{
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
}

tabXvar.xInertia = _{
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
}

tabXvar.xMaxUnlocked = _{
    s1 = function(c, getUnlock_x)
        c.getUnlock_x = getUnlock_x
        c.unlock_x = xvar.f0(0)
    end,

    s2 = function(c)
        local index = c.unlock_x() + 1
        local con_x = c.getUnlock_x(index)
        while con_x ~= nil and con_x() do
            index = index + 1
            con_x = c.getUnlock_x(index)
        end
        if con_x ~= nil then
            xvar.setValue(c.unlock_x, index - 1)
            c:call(tabXvar.xWait(con_x), "s1")
        else
            xvar.setValue(c.unlock_x, index)
        end
    end,
    x = function(c)
        return c.unlock_x
    end,
    event = g_t.empty_event,
}

tabXvar.xCheck = _{
    s1 = function(c, callback, interval)
        if type(callback) ~= "function" then
            assert(false, "callBack must be a function")
            c:stop()
            return
        end
        c.callback = callback
        c.value_x = xvar.f0(c.callback())
        c:setDynamics("s2", "updateInterval", interval or 0)
    end,
    s2 = function(c)
        c:s2_update()
    end,
    s2_update = function(c) 
        local value = c.callback()
        if c.value_x() ~= value then
            xvar.setValue(c.value_x, value)
        end
    end,
    s2_updateInterval = 0,
    x = function(c)
        return c.value_x
    end,
    event = g_t.empty_event,
}

tabXvar.xIsExpired = _{
    s1 = function(c, endTime, timeOffset)
        timeOffset = timeOffset or 0
        c.dueTime_x = xvar.f0(false)
        if xvar.is_xvar(endTime) then
            c:call(tabXvar.xWatch(endTime, function(time)
                c:abort("s2")
                if (not time or time == 0) then
                    xvar.setValue(c.dueTime_x, false)
                else
                    xvar.setValue(c.dueTime_x, false)
                    c:call(time_util.tabWaitUntil(time + timeOffset), "s2")
                end
            end), "xWatchTime")
        else
            c:call(time_util.tabWaitUntil(endTime + timeOffset), "s2")
        end
    end,
    s3 = function(c)
        xvar.setValue(c.dueTime_x, true)
    end,
    x = function(c)
        return c.dueTime_x
    end,
}

tabXvar.xStayOnce = _{
    s1 = function(c, enter_x, stay_x)
        c.enter_x = enter_x
        c.stay_x = stay_x
        c.enterStay_x = enter_x & stay_x
        c.out_x = ~enter_x & ~stay_x
        c.takeEffect_x = xvar.f0(false)
    end,
    s2 = function(c)
        c:call(g_t.skipFrames(1), "s2_1")
    end,
    s2_2 = function(c)
        xvar.setValue(c.takeEffect_x, false)
        c:call(tabXvar.xWait(~c.enter_x), "s3")
    end,
    s4 = function(c)
        c:call(tabXvar.xWait(c.enterStay_x), "s5")
    end,
    s6 = function(c)
        xvar.setValue(c.takeEffect_x, true)
        c:call(tabXvar.xWait(c.out_x), "s1")
    end,
    x = function(c)
        return c.takeEffect_x
    end,
}

tabXvar.xStay = _{
    s1 = function(c, enter_x, stay_x)
        c.enter_x = enter_x
        c.stay_x = stay_x
        c.enterStay_x = enter_x & stay_x
        c.takeEffect_x = xvar.f0(false)
    end,
    s2 = function(c)
        c:call(tabXvar.xWait(~c.enter_x), "s3")
    end,
    s4 = function(c)
        xvar.setValue(c.takeEffect_x, false)
        c:call(tabXvar.xWait(c.enterStay_x), "s5")
    end,
    s6 = function(c)
        xvar.setValue(c.takeEffect_x, true)
        c:call(tabXvar.xWait(~c.enterStay_x), "s3")
    end,
    x = function(c)
        return c.takeEffect_x
    end,
}

tabXvar.xSelectTask = _{
    s1 = function(c, index_x, ...)
        local tabsNum = select("#", ...)
        local tabs = {}
        for i = 1, tabsNum do
            local tab = select(i, ...)
            table.insert(tabs, #tab)
        end
        c.index_x = index_x
        c:call(tabXvar.xWatch(index_x, function(index)
            local tab = tabs[index]
            c:stop("tabState")
            c.tabState = c:call(tab, "tabState")
        end), "xWatchStateChange")
    end,
}

tabXvar.xSelectState = _{
    s1 = function(c, initState, ...)
        local tabsNum = select("#", ...)
        local tabs = {}
        for i = 1, tabsNum do
            local tab = select(i, ...)
            table.insert(tabs, tab)
        end
        c.tabs = tabs
        c.initState = initState
        c.state_x = xvar.f0(initState)
        c:suspend("s2")
    end,
    s2 = function(c)
        local state = c.state_x()
        local tab = c.tabs[state]
        c:call(tab(c.p1, c.p2, c.p3, c.p4) >> "state" >> "p1" >> "p2" >> "p3" >> "p4", "s3")
    end,
    s4 = function(c)
        c.state = c.state or c.initState
        xvar.setValue(c.state_x, c.state)
        c:start("s2")
    end,
    enter = function(c, state, ...)
        xvar.setValue(c.state_x, state)
        local numParams = select("#", ...)
        for i = 1, numParams do
            c["p"..i] = select(i, ...)
        end
        c:resume("s2")
    end,
    enterState = function(c, state, ...)
        c:notify("enterState"..state, ...)
    end,
    exitState = function(c, state)
        c:notify("exitState"..state)
    end,
    x = function(c)
        return c.state_x
    end,
    event = g_t.empty_event,
    inner = {
        state_x = function(c)
            return c.state_x
        end,
    },
}


return tabXvar
