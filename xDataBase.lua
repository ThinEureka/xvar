local tableConcat = table.concat
local tableInsert = table.insert
local tableRemove = table.remove
local stringFind = string.find

local xvar = require("util.xvar")

local meta_mt_modev = {__mode = "v"}
local meta_mt_modek = {__mode = "k"}

local xDataBase = _{
    s1 = function(c, data)
        c.rootName = "$"
        c.dataMap = {}
        c.pathMap = {}
        c.nilXvar = xvar.f0(nil)
        c.queryXvarPathMap = setmetatable({}, meta_mt_modev)
        c.queryAllXvarPathMap = setmetatable({}, meta_mt_modev)
        c.queryFilterXvarPathMap = setmetatable({}, meta_mt_modev)
        c.queryFilterXvarFilterMap = setmetatable({}, meta_mt_modek)

        c.root = data
        c.dataMap[c.rootName] = data
    end,
    event = g_t.empty_event,
}

local _catch_err = function(err)
    printError("xDataBase xpcall error", err)
end

function xDataBase:refresh_x(data)
    local oldData = self.root
    self.root = data
    self.dataMap[self.rootName] = data
    if (oldData) then
        for key, value in pairs(oldData) do
            local node = data[key]
            if (node == nil) then
                local nodeKey = tostring(key)
                local pathMap = self.pathMap[nodeKey]
                self.dataMap[nodeKey] = nil
                if (pathMap) then
                    self:_clearPathMap(pathMap)
                end
            end
        end
    end
    for key, node in pairs(data) do
        local nodeKey = tostring(key)
        self.dataMap[nodeKey] = node
        local pathMap = self.pathMap[nodeKey]
        if (pathMap) then
            self:_checkPathExist(node, pathMap)
        end
    end
    for path, data_x in pairs(self.queryXvarPathMap) do
        xvar.setValue(data_x, self.dataMap[path])
    end
    for path, data_x in pairs(self.queryAllXvarPathMap) do
        xvar.setValue(data_x, self.dataMap[path])
        xvar.setDirty(data_x)
    end
    for path, data_x in pairs(self.queryFilterXvarPathMap) do
        local filter = self.queryFilterXvarFilterMap[data_x]
        self:fillDataByFilter(path, filter)
    end
end

function xDataBase:query(...)
    local path = self:_analysisArgs(0, false, ...)
    if (path) then
        return self.dataMap[path]
    end
    return nil
end

function xDataBase:query_x(...)
    return self:_query_x(self.queryXvarPathMap, ...)
end

function xDataBase:queryAll_x(...)
    return self:_query_x(self.queryAllXvarPathMap, ...)
end

function xDataBase:fillDataByFilter(path, filter)
    local result_x = self.queryFilterXvarPathMap[path]
    local temp
    if (not result_x) then
        temp = {}
        result_x = xvar.f0(temp)
        self.queryFilterXvarPathMap[path] = result_x
        self.queryFilterXvarFilterMap[result_x] = filter
    else
        temp = result_x()
        for key, value in pairs(temp) do
            temp[key] = nil
        end
    end
    local dataList = self.dataMap[path]
    if (not dataList or type(dataList) ~= "table") then
        if (type(dataList) ~= "table") then
            assert(false, "queryFilter data type isnot table")
        end
        xvar.setDirty(result_x)
        return result_x
    end
    for key, value in pairs(dataList) do
        local isOk, result = xpcall(filter, _catch_err, value)
        if (isOk and result) then
            temp[key] = value
        end
    end
    xvar.setDirty(result_x)
    return result_x
end

function xDataBase:queryFilter_x(...)
    local argNum = select("#", ...)
    if (argNum < 2) then
        assert(false, "path or filter is nil")
    end
    local filter = select(argNum, ...)
    local path, haveXvarArg = self:_analysisArgs(1, false, ...)
    if (haveXvarArg) then
        local xvarArgResult_x = xvar.fn(function(...)
            local path = self:_analysisArgs(0, false, ...)
            if (path) then
                local result_x = self.queryFilterXvarPathMap[path]
                if (not result_x) then
                    result_x = self:fillDataByFilter(path, filter)
                end
                return result_x
            else
                return self.nilXvar
            end
        end, ...) {"()"}
        return xvarArgResult_x
    elseif (path) then
        local result_x = self.queryFilterXvarPathMap[path]
        if (not result_x) then
            result_x = self:fillDataByFilter(path, filter)
        end
        return result_x
    end
end

function xDataBase:modify_x(...)
    local argNum = select("#", ...)
    if (argNum < 2) then
        assert(false, "path or value is nil")
    end
    local value = select(argNum, ...)
    local key = select(argNum - 1, ...)
    local path = self:_analysisArgs(1, true, ...)
    self:_modify_x(path, key, value)
end

function xDataBase:remove_x(...)
    local argNum = select("#", ...)
    if (argNum < 1) then
        assert(false, "path is nil")
    end
    local key = select(argNum, ...)
    local path = self:_analysisArgs(0, false, ...)
    self:_modify_x(path, key, nil)
end

--private
function xDataBase:_modify_x(path, key, value)
    local splitIndex = stringFind(path, ".", 1, true)
    local nextSplitIndex = splitIndex
    while (nextSplitIndex) do
        nextSplitIndex = stringFind(path, ".", nextSplitIndex + 1, true)
        if (nextSplitIndex) then
            splitIndex = nextSplitIndex
        end
    end
    if (splitIndex) then
        if (type(key) == "string") then
            key = string.sub(path, splitIndex + 1)
        end
        path = string.sub(path, 1, splitIndex - 1)
    else
        path = nil
    end
    local parentData
    if (path) then
        parentData = self.dataMap[path]
    else
        parentData = self.root
    end
    if (parentData == nil) then
        if (value ~= nil) then
            if (path) then
                assert(false, "modify_x error parent data is nil:"..path)
            else
                assert(false, "modify_x error parent data is nil:"..key)
            end
        end
        return
    end
    local oldValue = parentData[key]
    self:_notifySelf_x(key, value, path)
    parentData[key] = value
    if (value ~= nil and oldValue ~= nil) then
        if (type(value) ~= type(oldValue)) then
            if (path) then
                assert(false, "data type is change:"..path)
            else
                assert(false, "data type is change:"..key)
            end
            return
        end
    end
    local pathMap
    if (path) then
        pathMap = self.pathMap[path]
        if (pathMap) then
            path = pathMap[key]
            if (path) then
                self.dataMap[path] = value
                pathMap = self.pathMap[path]
            else
                pathMap = nil
            end
        else
            path = nil
        end
    else
        local strKey = tostring(key)
        pathMap = self.pathMap[strKey]
        self.dataMap[strKey] = value
        path = strKey
    end
    if (pathMap) then
        if (value ~= nil) then
            self:_checkPathExist(value, pathMap)
        else
            self:_clearPathMap(pathMap)
        end
    end
    if (path) then
        self:_notify_x(path)
    end
    for data_x_path, data_x in pairs(self.queryAllXvarPathMap) do
        if (not path or data_x_path == self.rootName or stringFind(data_x_path, path) or stringFind(path, data_x_path)) then
            local data = self.dataMap[data_x_path]
            xvar.setValue(data_x, data)
            xvar.setDirty(data_x)
        end
    end
    for data_x_path, data_x in pairs(self.queryFilterXvarPathMap) do
        if (not path or data_x_path == self.rootName or stringFind(data_x_path, path) or stringFind(path, data_x_path)) then
            local filter = self.queryFilterXvarFilterMap[data_x]
            self:fillDataByFilter(path, filter)
        end
    end
end

function xDataBase:_fillPathMap(prePath, key, needCreateCache)
    if (not prePath) then
        local strKey = tostring(key)
        if (needCreateCache and not self.pathMap[strKey]) then
            self.pathMap[strKey] = {}
        end
        return strKey
    end
    local pathMap = self.pathMap[prePath]
    if (not pathMap) then
        pathMap = {}
        self.pathMap[prePath] = pathMap
    end
    local path = pathMap[key]
    if (not path) then
        path = self:_getConcatStr(prePath, key, ".")
        pathMap[key] = path
        if (needCreateCache) then
            self.pathMap[path] = {}
        end
    end

    return path
end

function xDataBase:_analysisArgs(skipNum, autoCreat, ...)
    local argNum = select('#', ...)
    if (argNum <= 0) then
        return self.rootName
    end
    local prePath
    local preNode = self.root
    local argIndex = 1
    local arg = select(1, ...)
    local param = arg
    while argIndex <= argNum - skipNum do
        if (not param) then
            return
        end
        if (param == xvar.err_nil) then
            return nil, true
        end
        if (type(param) == "table") then
            return nil, true
        end
        local pathMap = prePath and self.pathMap[prePath] or self.pathMap
        local path
        if (pathMap) then
            path = pathMap[param]
        end
        if (path and not self.dataMap[path]) then
            path = nil
        end
        if (path) then
            preNode = self.dataMap[path]
        else
            local splitIndex
            if (not path and type(param) == "string") then
                splitIndex = stringFind(param, ".", 1, true)
                if (splitIndex) then
                    arg = string.sub(param, splitIndex + 1)
                    param = string.sub(param, 1, splitIndex - 1)
                end
            end
            if (not splitIndex) then
                local needCreateCache = argIndex < argNum - skipNum or param ~= arg
                path = self:_fillPathMap(prePath, param, needCreateCache)
                if (preNode ~= nil) then
                    --自动补全路径
                    if autoCreat and needCreateCache and preNode[param] == nil then
                        preNode[param] = {}
                    end
                    preNode = preNode[param]
                    self.dataMap[path] = preNode
                end
            end
        end
        if (path) then
            prePath = path
            if (param ~= arg) then
                param = arg
            else
                argIndex = argIndex + 1
                if (argIndex <= argNum - skipNum) then
                    arg = select(argIndex, ...)
                    param = arg
                end
            end
        end
    end
    return prePath, false
end

function xDataBase:_clearPathMap(pathMap)
    for key, path in pairs(pathMap) do
        self.dataMap[path] = nil
        local childPathMap = self.pathMap[path]
        if (childPathMap) then
            self:_clearPathMap(childPathMap)
        end
    end
end

function xDataBase:_checkPathExist(parent, pathMap)
    for key, path in pairs(pathMap) do
        local node = parent[key]
        local childPathMap = self.pathMap[path]
        if (node ~= nil) then
            self.dataMap[path] = node
            if childPathMap then
                self:_checkPathExist(node, childPathMap)
            end
        else
            self.dataMap[path] = nil
            if childPathMap then
                self:_clearPathMap(childPathMap)
            end
        end
    end
end

function xDataBase:_notify_x(path)
    local pathMap = self.pathMap[path]
    local strPath = tostring(path)
    local data_x = self.queryXvarPathMap[strPath]
    if (data_x) then
        xvar.setValue(data_x, self.dataMap[strPath])
    end
    if (pathMap) then
        for key, value in pairs(pathMap) do
            local data_x = self.queryXvarPathMap[value]
            if (data_x) then
                xvar.setValue(data_x, self.dataMap[value])
            end
            self:_notify_x(value)
        end
    end
end

function xDataBase:_notifySelf_x(key, value, path)
    if (not path) then
        path = self.rootName
    end
    local data_x = self.queryXvarPathMap[path]
    if (data_x) then
        data_x[key] = value
    end
end

function xDataBase:_query_x(pathMap, ...)
    local path, haveXvarArg = self:_analysisArgs(0, false, ...)
    if (haveXvarArg) then
        local xvarArgResult_x = xvar.fn(function(...)
            local path = self:_analysisArgs(0, false, ...)
            if (path) then
                local result_x = pathMap[path]
                if (not result_x) then
                    local result = self.dataMap[path]
                    result_x = xvar.f0(result)
                    pathMap[path] = result_x
                end
                return result_x
            else
                return self.nilXvar
            end
        end, ...) {"()"}
        return xvarArgResult_x
    elseif (path) then
        local result_x = pathMap[path]
        if (not result_x) then
            local result = self.dataMap[path]
            result_x = xvar.f0(result)
            pathMap[path] = result_x
        end
        return result_x
    end
end

local tempStrTable = {}
function xDataBase:_getConcatStr(str1, str2, split)
    if (not str1 and not str2) then
        return nil
    elseif (not str1) then
        return str2
    elseif (not str2) then
        return str1
    end
    -- tableInsert(tempStrTable, str1)
    -- tableInsert(tempStrTable, str2)
    tempStrTable[1] = str1
    tempStrTable[2] = str2
    local result = tableConcat(tempStrTable, split)
    -- while #tempStrTable > 0 do
    --     tableRemove(tempStrTable)
    -- end
    return result
end

return xDataBase

