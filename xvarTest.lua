
local xvar = require("util.xvar")

local xvarTest = {}

local function testAssert(a, testName)
    testName = "xvar " .. testName
    assert(a, testName .. " faield")
    print(testName .. " passed")
end

function xvarTest.testAll()
    print("xvar test starts")
    xvarTest.testFn()
    xvarTest.testOperator_Add()
    xvarTest.testOperator_Sub()
    xvarTest.testOperator_Mul()
    xvarTest.testOperator_Div()
    xvarTest.testOperator_Mod()
    xvarTest.testOperator_Power()
    xvarTest.testOperator_Idiv()
    xvarTest.testOperator_And()
    xvarTest.testOperator_Or()
    xvarTest.testOperator_Xor()
    xvarTest.testOperator_Not()
    xvarTest.testOperator_Concat()
    xvarTest.testOperator_Eq()
    xvarTest.testOperator_Lt()
    xvarTest.testOperator_Gt()
    xvarTest.testOperator_Lsh()
    xvarTest.testOperator_Rsh()
    xvarTest.testOperator_Len()
    xvarTest.testOperator_Unm()
    xvarTest.testOperator_index()
    xvarTest.testExp_Simple()
    xvarTest.testExp_xIndex()
    xvarTest.testDirty()
    xvarTest.testExp_Logical()
    xvarTest.testxTable()
    xvarTest.testAorB()
    xvarTest.testMinAndMax()
    xvarTest.testHighOrder()
    xvarTest.testSafeSum()
    xvarTest.testErrorCallback()
    xvarTest.testX_form()
    print("xvar test passes")
end

function xvarTest.testFn()
    local x = xvar.f0(9)
    local y = xvar.f1(function(x)
        return x*x
    end, x)
    print("y:", y())
    testAssert(y() == 81, "fn test 1.1")

    xvar.setValue(x, 2)
    print("y:", y())
    testAssert(y() == 4, "fn test 1.2")

    local x = xvar.f0(3)
    local y = xvar.f0(4)
    local z = xvar.f2(function(x, y)
        return x*x + y*y
    end, x, y)

    print("z", z())
    testAssert(z() == 25, "fn test 2.1")

    xvar.setValue(x, 5)
    xvar.setValue(y, 7)

    print("z:", z())
    testAssert(z() == 74, "fn test 2.2")

    local fn = xvar.fn
    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    local x3 = xvar.f0(3)
    local x4 = xvar.f0(4)
    local x5 = xvar.f0(5)
    local x6 = xvar.f0(6)
    local x7 = xvar.f0(7)

    local y = fn(function(x1, x2, x3, x4, x5, x6, x7)
        -- testAssert(x1 == 1, "fn test 1.1")
        -- testAssert(x2 == 2, "fn test 1.2")
        -- testAssert(x3 == 3, "fn test 1.3")
        -- testAssert(x4 == 4, "fn test 1.4")
        -- testAssert(x5 == 5, "fn test 1.5")
        -- testAssert(x6 == 6, "fn test 1.6")
        -- testAssert(x7 == 7, "fn test 1.7")
        return x1 + x2 + x3 + x4 + x5 + x6 + x7
    end, x1, x2, x3, x4, x5, x6, x7)

    testAssert(y() == 28, "fn test 3.1.1")

    xvar.setValue(x7, 10)
    testAssert(y() == 31, "fn test 3.1.2")

    local fn = xvar.fn
    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    -- local x3 = xvar.f0(3)
    local x4 = xvar.f0(4)
    local x5 = xvar.f0(5)
    local x6 = xvar.f0(6)
    local x7 = xvar.f0(7)

    local y = fn(function(x1, x2, x3, x4, x5, x6, x7)
        testAssert(x1 == 1, "fn test 3.2.1")
        testAssert(x2 == 2, "fn test 3.2.2")
        testAssert(x3 == nil, "fn test 2.3")
        testAssert(x4 == 4, "fn test 3.2.4")
        testAssert(x5 == 5, "fn test 3.2.5")
        testAssert(x6 == 6, "fn test 3.2.6")
        -- testAssert(x7 == 7, "fn test 3.7")
        return x1 + x2 + 0 + x4 + x5 + x6 + x7
    end, x1, x2, nil, x4, x5, x6, x7)
    testAssert(y() == 25, "fn test 3.3")

    xvar.setValue(x7, 10)
    testAssert(y() == 28, "fn test 3.4")
end

function xvarTest.testOperator_Add()
    local x = xvar.f0(3)
    local y = xvar.f0(3)
    local z = x + y

    print("z:", z())
    testAssert(z() == 6, "add test 1")

    xvar.setValue(x, 9)
    print("z:", z())
    testAssert(z() == 12, "add test 2")
    print("add test2 passed")

    local x = xvar.f0(3)
    local y = 5
    local z = x + y
    print("z:", z())
    testAssert(z() == 8, "add test 3")
    print("add test3 passed")

    xvar.setValue(x, 9)
    print("z:", z())
    testAssert(z() == 14, "add test 4")

    local x = 3
    local y = xvar.f0(5)
    local z = x + y
    print("z:", z())
    testAssert(z() == 8, "add test 5")

    xvar.setValue(y, 9)
    print("z:", z())
    testAssert(z() == 12, "add test 6")

    xvar.setValue(y, nil)
    print("z:", z())
    testAssert(xvar.rawValue(z) == xvar.err_nil, "add test 7.1")
    testAssert(z() == nil, "add test 7.2")
end

function xvarTest.testOperator_Sub()
    local x = xvar.f0(3)
    local y = xvar.f0(3)
    local z = x - y
    print("z:", z())
    testAssert(z() == 0, "sub test 1")

    xvar.setValue(x, 9)
    print("z:", z())
    testAssert(z() == 6, "sub test 2")
end

function xvarTest.testOperator_Mul()
    local x = xvar.f0(3)
    local y = xvar.f0(4)
    local z = x * y
    print("z:", z())
    testAssert(z() == 12, "mul test 1")
end

function xvarTest.testOperator_Div()
    local x = xvar.f0(1)
    local y = xvar.f0(2)
    local z = x / y
    print("z:", z())
    testAssert(z() == 0.5, "div test 1")
end

function xvarTest.testOperator_Mod()
    local x = xvar.f0(7)
    local y = xvar.f0(3)
    local z = x % y
    print("z:", z())
    testAssert(z() == 1, "mod test 1")
end

function xvarTest.testOperator_Power()
    local x = xvar.f0(2)
    local y = xvar.f0(3)
    local z = x ^ y
    print("z:", z())
    testAssert(z() == 8, "pow test 1.1")

    xvar.setValue(x, 3)
    print("z:", z())
    testAssert(z() == 27, "pow test 1.2")
end

function xvarTest.testOperator_Idiv()
    local x = xvar.f0(3)
    local y = xvar.f0(2)
    local z = x // y
    print("z:", z())
    testAssert(z() == 1, "idiv test 1")
end

-- logical and operator instead of bitwise operator
function xvarTest.testOperator_And()
    local x = xvar.f0(3)
    local y = xvar.f0(2)
    local z = x & y
    print("z:", z())
    testAssert(z() == 2, "and test 1.1")

    xvar.setValue(x, nil)
    print("z:", z())
    testAssert(z() == nil, "and test 1.2")
end

-- logical and operator instead of bitwise operator
function xvarTest.testOperator_Or()
    local x = xvar.f0(3)
    local y = xvar.f0(2)
    local z = x | y
    print("z:", z())
    testAssert(z() == 3, "or test 1.1")

    xvar.setValue(x, nil)
    print("z:", z())
    testAssert(z() == 2, "or test 1.2")
end

-- logical and operator instead of bitwise operator
function xvarTest.testOperator_Xor()
    local x = xvar.f0(3)
    local y = xvar.f0(2)
    local z = x ~ y
    print("z:", z())
    testAssert(z() == false, "xor test 1.1")

    xvar.setValue(x, nil)
    print("z:", z())
    testAssert(z() == true, "xor test 1.2")

    xvar.setValue(y, nil)
    print("z:", z())
    testAssert(z() == false, "xor test 1.3")

    xvar.setValue(x, 3)
    print("z:", z())
    testAssert(z() == true, "xor test 1.4")
end

-- logical and operator instead of bitwise operator
function xvarTest.testOperator_Not()
    local x = xvar.f0(true)
    local y = ~x
    local z = ~y

    print("y,z: ", y(), z())
    testAssert(y() == false, "not test 1.1.1")
    testAssert(z() == true, "not test 1.1.1")

    xvar.setValue(x, false)
    print("y,z: ", y(), z())
    testAssert(y() == true, "not test 1.2.1")
    testAssert(z() == false, "not test 1.2.2")
end

function xvarTest.testOperator_Concat()
    local x = xvar.f0("3333")
    local y = xvar.f0("2222")
    local z = x .. y
    print("z:", z())
    testAssert(z() == "33332222", "concat test 1.1")

    xvar.setValue(x, "4444")
    print("z:", z())
    testAssert(z() == "44442222", "concat test 1.2")
end

function xvarTest.testOperator_Eq()
    local x = xvar.f0("33333")
    local y = xvar.f0("22222")

    local z1 = xvar.x_eq(x, y)
    local z2 = x {"==", y}

    local w1 = xvar.x_noteq(x, y)
    local w2 = x {"~=", y}

    print("z1 z2:", z1(), z2())
    testAssert(z1() == false, "eq test 1.1.1")
    testAssert(z2() == false, "eq test 1.1.2")

    print("w1 w2:", w1(), w2())
    testAssert(w1() == true, "eq test 1.1.3")
    testAssert(w2() == true, "eq test 1.1.4")

    xvar.setValue(x, "22222")

    print("z1 z2:", z1(), z2())
    testAssert(z1() == true, "eq test 1.2.1")
    testAssert(z2() == true, "eq test 1.2.2")

    print("w1 w2:", w1(), w2())
    testAssert(w1() == false, "eq test 1.2.3")
    testAssert(w2() == false, "eq test 1.2.4")
end

function xvarTest.testOperator_Lt()
    local x = xvar.f0(3333)
    local y = xvar.f0(2222)
    local z1 = xvar.x_lt(x, y)
    local z2 = x{"<", y}

    print("z1, z2:", z1(), z2())
    testAssert(z1() == false, "lt test 1.1.1")
    testAssert(z2() == false, "lt test 1.1.2")

    xvar.setValue(x, 1111)
    print("z1, z2:", z1(), z2())
    testAssert(z1() == true, "lt test 1.2.1")
    testAssert(z2() == true, "lt test 1.2.2")
end

function xvarTest.testOperator_Gt()
    local x = xvar.f0(3333)
    local y = xvar.f0(2222)
    local z1 = xvar.x_gt(x, y)
    local z2 = x{">", y}

    print("z1, z2:", z1(), z2())
    testAssert(z1() == true, "gt test 1.1.1")
    testAssert(z2() == true, "gt test 1.1.2")

    xvar.setValue(x, 1111)
    print("z1, z2:", z1(), z2())
    testAssert(z1() == false, "gt test 1.2.1")
    testAssert(z2() == false, "gt test 1.2.2")
end

-- bitwise operator <<
function xvarTest.testOperator_Lsh()
    local x = xvar.f0(3333)
    local y = xvar.f0(2)
    local z = x << y
    print("z:", z())
    testAssert(z() == 3333 << 2, "lsh test 1.1")
    print("lsh test1 passed")

    xvar.setValue(x, 22222)
    print("z:", z())
    testAssert(z() == 22222 << 2, "lsh test 1.2")

    xvar.setValue(y, 3)
    print("z:", z())
    testAssert(z() == 22222 << 3, "lsh test 1.3")
end

-- bitwise operator >>
function xvarTest.testOperator_Rsh()
    local x = xvar.f0(3333)
    local y = xvar.f0(2)
    local z = x >> y
    print("z:", z())
    testAssert(z() == 3333 >> 2, "rsh test 1.1")

    xvar.setValue(x, 22222)
    print("z:", z())
    testAssert(z() == 22222 >> 2, "rsh test 1.2")

    xvar.setValue(y, 3)
    print("z:", z())
    testAssert(z() == 22222 >> 3, "rsh test 1.3")
end

function xvarTest.testOperator_Len()
    local x = xvar.f0({1, 2, 3})
    z = #x

    print("z:", z())
    testAssert(z() == 3, "len test 1.1")

    xvar.table_insert(x, 4)

    print("z:", z())
    testAssert(z() == 4, "len test 1.2")
end

function xvarTest.testOperator_Unm()
    local x = xvar.f0(9)
    z = -x

    print("z:", z())
    testAssert(z() == -9, "unm test 1.1")

    xvar.setValue(x, 11)

    print("z:", z())
    testAssert(z() == -11, "unm test 1.2")
end

function xvarTest.testOperator_index()
    local t = xvar.f0({})
    t.x = 9
    local p = t:x_index("x")
    print("p:", p())
    testAssert(p() == 9, "index test 1.1")

    t.x = 33
    print("p:", p())
    testAssert(p() == 33, "index test 1.2")

    local itemList = xvar.f0({})
    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
    }
    local itemCount = itemList:x_index(1003):x_index("count")
    print("itemCount:", itemCount())
    testAssert(itemCount() == 9, "index test 2.1")

    itemList[1003] = {
        id = 1003,
        count = 10,
        time = 3344,
    }

    print("itemCount:", itemCount())
    testAssert(itemCount() == 10, "index test 2.2")
end

function xvarTest.testExp_Simple()
    local x = xvar.f0(4)
    local y = xvar.f0(2)
    local z = xvar.f0(3)
    local w = x*y + z
    print("w:", w())
    testAssert(w() == 11, "exp test 1.1")

    xvar.setValue(y, 9)
    print("w:", w())
    testAssert(w() == 39, "exp test 1.2")
end

function xvarTest.testExp_xIndex()
    local itemList = xvar.f0({})
    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
        info = {
            k = {1, 2, 3}
        }
    }
    local k = itemList:x_index(1003):x_index("info"):x_index("k"):x_index(2)
    local z = k * 9
    print("k, z", k(), z())
    testAssert(k() == 2, "exp xIndex test 1.1.1")
    testAssert(z() == 18, "exp xIndex test 1.1.2")

    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
        info = {
            k = {1, 4, 3}
        }
    }
    print(k())
    print("k, z", k(), z())
    testAssert(k() == 4, "exp xIndex test 1.2.1")
    testAssert(z() == 36, "exp xIndex test 1.2.2")

    local itemList = xvar.f0({})
    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
        info = {
            k = {1, 2, 3}
        }
    }

    local k = itemList:x_index(1003):x_index("info"):x_index("k")
    local i = xvar.f0(2)
    local k2 = k:x_index(i)
    print("k2", k2)
    testAssert(k2() == 2, "exp xIndex test 2.1.1")

    xvar.setValue(i, 3)
    testAssert(k2() == 3, "exp xIndex test 2.1.2")

    local itemList = xvar.f0({})
    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
        info = xvar.f0({
            k = xvar.f0({3, 2, 1})
        })
    }

    testAssert(itemList[1003].id == 1003, "exp xIndex test3.1.1")

    local x = itemList:x_index(1003):x_index("info"):x_index("k"):x_index(2)
    print("x:", x())
    testAssert(x() == 2, "exp xIndex test 3.1.2")

    itemList[1003].info.k[2] = 9
    print("itemList[1003].info.k[2]:", itemList[1003].info.k[2])
    print("x:", x())
    testAssert(x() == 9, "exp xIndex test 3.1.3")

    local len = #itemList:x_index(1003):x_index("info"):x_index("k") 
    print("len:", len())
    testAssert(len() == 3, "exp xIndex test 3.1.4")

    xvar.table_insert(itemList[1003].info.k, 99)
    print("len:", len())
    testAssert(len() == 4, "exp xIndex test 3.1.5")

    local itemList = xvar.f0({})
    itemList[1003] = {
        id = 1003,
        count = 9,
        time = 3344,
        info = xvar.f0({
            k = xvar.f0({3, 2, 1})
        })
    }

    local g = itemList:x_index(1003):x_index("info"):x_index("k"):x_index(3)
    print("g:", g())
    testAssert(g() == 1, "exp xIndex test 3.1.6")

    xvar.table_sort(itemList[1003].info.k)
    print("g:", g())
    testAssert(g() == 3, "exp xIndex test 3.1.7")

    -- xvar.dispose(g)
    -- print("xvar dispose test1 passed")

    local h = itemList:x_index(1002):x_index("info"):x_index("k"):x_index(3)
    h()
    testAssert(xvar.rawValue(h) == xvar.err_nil, "exp xIndex test 3.1.8 (err nil test)")

    local k = itemList[1003].info.k
    for key,value in ipairs(k) do
        print("key, value ", key, value)
    end


    local itemList = xvar.f0({
        [1003] = xvar.f0({ id = 1003, type = 9, count = 9, time = 3344}),
        [1002] = xvar.f0({ id = 1002, type = 8, count = 9, time = 3344}),
        [1009] = xvar.f0({ id = 1009, type = 7, count = 9, time = 3344}),
        [1014] = xvar.f0({ id = 1014, type = 8, count = 9, time = 3344}),
        [1008] = xvar.f0({ id = 1008, type = 7, count = 9, time = 3344}),
        [1051] = xvar.f0({ id = 1051, type = 8, count = 9, time = 3344}),
        [1017] = xvar.f0({ id = 1017, type = 7, count = 9, time = 3344}),
        [1015] = xvar.f0({ id = 1015, type = 8, count = 9, time = 3344}),
        [1023] = xvar.f0({ id = 1023, type = 7, count = 9, time = 3344}),
        [1011] = xvar.f0({ id = 1011, type = 8, count = 9, time = 3344}),
        [1020] = xvar.f0({ id = 1020, type = 8, count = 9, time = 3344}),
    })

    local newList = xvar.f1(function(op1)
        local t = {}
        for k, v in pairs(op1) do
            if v.type == 8 then
                local ex = {}
                ex.maxCount = 99
                -- ex.time = 88
                local newV = xvar.x_extend(v, ex)
                table.insert(t, newV)
            end
        end
        table.sort(t, function(a, b)
            return a.id < b.id
        end)
        return t
    end, itemList)

    local t = newList()
    for k, v in pairs(t) do
        print("xvar list  key ", k)
        dump(v(), "xvar value")
    end

    local item = newList:x_index(1)
    dump(item(), "kkkkk 1111")

    itemList[1002].time = 11
    dump(item(), "kkkkk 22222")
    testAssert(item().time == 11, "exp xIndex test 3.1.9")

    xvar.addDirtyCallback(item, function()
        print("ggggg")
    end)

    itemList[1002].time = 13
    dump(item(), "kkkkk 22222")
    testAssert(item().time == 13, "exp xIndex test 3.1.10")

    itemList[1002].time = 14
    dump(item(), "kkkkk 22222")
    testAssert(item().time == 14, "exp xIndex test 3.1.11")

    itemList[1002].time = 15
    dump(item(), "kkkkk 22222")
    testAssert(item().time == 15, "exp xIndex test 3.1.12")
end

function xvarTest.testDirty()
    local itemList = xvar.f0({})
    local item = xvar.f0({id = 1002, count = 15})
    itemList[1002] = item

    local count = itemList:x_index(1002):x_index("count")
    print("count:", count())
    testAssert(count() == 15, "dirty test 0.1")
    testAssert(not xvar.isDirty(count), "dirty test 0.2")

    local dirty = false
    xvar.addDirtyCallback(count, function()
        print("dirty 11111")
        dirty = true
    end)

    item.count = 16
    testAssert(dirty, "dirty test 0.3")
    -- assert(xvar.isDirty(count), "dirty optimization test2 failed")
    --
    testAssert(count() == 16, "dirty test 0.4")

    dirty = false
    item.id = 1003
    testAssert(not dirty, "dirty test 0.5")
    print("dirty optimization test6 passed")

    local A = xvar.f0 {}
    A.B = xvar.f0 {}
    A.B[1001] = xvar.f0{ lv = 9}
    A.B[1002] = xvar.f0{ lv = 11}

    local y = A {".B"} {".", 1001}{".lv"}
    local z = A {".B"} {".", 1002}{".lv"}
    print("y", y())
    print("z", z())

    A.B[1001] = xvar.f0{ lv = 8}
    print("y isDirty 1:", xvar.isDirty(y), xvar.rawValue(y))
    testAssert(xvar.isDirty(y) == true, "dirtytest 1.1")
    testAssert(xvar.rawValue(y) == 9, "dirytest 1.2")
    print("y", y())
    testAssert(xvar.isDirty(y) == false, "dirtytest 1.3")
    testAssert(xvar.rawValue(y) == 8, "dirytest 1.4")

    print("z isDirty 1:", xvar.isDirty(z), xvar.rawValue(z))
    testAssert(xvar.isDirty(z) == false, "dirtytest 1.5")
    testAssert(xvar.rawValue(z) == 11, "dirytest 1.6")
    print("z", z())
    testAssert(xvar.isDirty(z) == false, "dirtytest 1.7")
    testAssert(xvar.rawValue(z) == 11, "dirytest 1.8")

    A.B[1002] = xvar.f0{ lv = 5}
    print("y isDirty 1:", xvar.isDirty(y), xvar.rawValue(y))
    testAssert(xvar.isDirty(y) == false, "dirtytest 2.1")
    testAssert(xvar.rawValue(y) == 8, "dirytest 2.2")
    print("y", y())
    testAssert(xvar.isDirty(y) == false, "dirtytest 2.3")
    testAssert(xvar.rawValue(y) == 8, "dirytest 2.4")

    print("z isDirty 1:", xvar.isDirty(z), xvar.rawValue(z))
    testAssert(xvar.isDirty(z) == true, "dirtytest 2.5")
    testAssert(xvar.rawValue(z) == 11, "dirytest 2.6")
    print("z", z())
    testAssert(xvar.isDirty(z) == false, "dirtytest 2.7")
    testAssert(xvar.rawValue(z) == 5, "dirytest 2.8")

    A.B[1001].lv = 2
    print("y isDirty 1:", xvar.isDirty(y), xvar.rawValue(y))
    testAssert(xvar.isDirty(y) == true, "dirtytest 3.1")
    testAssert(xvar.rawValue(y) == 8, "dirytest 3.2")
    print("y", y())
    testAssert(xvar.isDirty(y) == false, "dirtytest 3.3")
    testAssert(xvar.rawValue(y) == 2, "dirytest 3.4")

    local A = xvar.f0 {}
    A.B = xvar.f0 {}
    A.B[1001] = xvar.f0{ lv = 9}
    A.B[1002] = xvar.f0{ lv = 11}

    local yAB = A {".B"} 
    local yAB_1001 = yAB {".", 1001}
    local yAB_1001_lv = yAB_1001 {".lv"}

    print(string.format("A dirty %s, A.B dirty %s, yAB dirty %s, yAB_100l dirty %s, yAB_1001_lv dirty %s",
    xvar.isDirty(A), xvar.isDirty(A.B), xvar.isDirty(yAB), xvar.isDirty(yAB_1001), xvar.isDirty(yAB_1001_lv)))

    testAssert(not xvar.isDirty(A), "dirtytest 4.1")
    testAssert(xvar.isDirty(A.B) == true, "dirtytest 4.2")
    testAssert(xvar.isDirty(yAB), "dirtytest 4.3")
    testAssert(xvar.isDirty(yAB_1001), "dirtytest 4.4")
    testAssert(xvar.isDirty(yAB_1001_lv), "dirtytest 4.5")

    local lv = yAB_1001_lv()
    print(lv)
    testAssert(lv == 9, "dirty test 4.5.a")

    print(string.format("A dirty %s, A.B dirty %s, yAB dirty %s, yAB_100l dirty %s, yAB_1001_lv dirty %s",
    xvar.isDirty(A), xvar.isDirty(A.B), xvar.isDirty(yAB), xvar.isDirty(yAB_1001), xvar.isDirty(yAB_1001_lv)))

    testAssert(not xvar.isDirty(A), "dirtytest 4.6")
    testAssert(not xvar.isDirty(A.B) == true, "dirtytest 4.7")
    testAssert(not xvar.isDirty(yAB), "dirtytest 4.8")
    testAssert(not xvar.isDirty(yAB_1001), "dirtytest 4.9")
    testAssert(not xvar.isDirty(yAB_1001_lv), "dirtytest 4.10")

    A.B[1001].lv = 44
    -- print(yAB_1001_lv())

    print(string.format("A dirty %s, A.B dirty %s, yAB dirty %s, yAB_100l dirty %s, yAB_1001_lv dirty %s",
    xvar.isDirty(A), xvar.isDirty(A.B), xvar.isDirty(yAB), xvar.isDirty(yAB_1001), xvar.isDirty(yAB_1001_lv)))

    testAssert(not xvar.isDirty(A), "dirtytest 5.1")
    testAssert(not xvar.isDirty(A.B), "dirtytest 5.2")
    testAssert(not xvar.isDirty(yAB), "dirtytest 5.3")
    testAssert(not xvar.isDirty(yAB_1001), "dirtytest 5.4")
    testAssert(xvar.isDirty(yAB_1001_lv), "dirtytest 5.5")

    local lv = yAB_1001_lv()
    print(lv)
    testAssert(lv == 44, "dirty test 5.5.a")

    print(string.format("A dirty %s, A.B dirty %s, yAB dirty %s, yAB_100l dirty %s, yAB_1001_lv dirty %s",
    xvar.isDirty(A), xvar.isDirty(A.B), xvar.isDirty(yAB), xvar.isDirty(yAB_1001), xvar.isDirty(yAB_1001_lv)))

    testAssert(not xvar.isDirty(A), "dirtytest 5.6")
    testAssert(not xvar.isDirty(A.B) == true, "dirtytest 5.7")
    testAssert(not xvar.isDirty(yAB), "dirtytest 5.8")
    testAssert(not xvar.isDirty(yAB_1001), "dirtytest 5.9")
    testAssert(not xvar.isDirty(yAB_1001_lv), "dirtytest 5.10")

end

function xvarTest.testExp_Logical()
    --and
    local x = xvar.f0(false)
    local y = xvar.f0(false)
    local z = x & y 
    print("z:", z())
    testAssert(z() == false, "exp logical test 1.1")

    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == false, "exp logical test 1.2")

    xvar.setValue(x, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 1.3")

    xvar.setValue(x, false)
    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == false, "exp logical test 1.4")

    -- or 
    local x = xvar.f0(false)
    local y = xvar.f0(false)
    local z = x | y
    print("z:", z())
    testAssert(z() == false, "exp logical test 2.1")

    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 2.2")

    xvar.setValue(x, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 2.3")

    xvar.setValue(x, false)
    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 2.4")

    --xor
    local x = xvar.f0(false)
    local y = xvar.f0(false)
    local z = x ~ y 
    print("z:", z())
    testAssert(z() == false, "exp logical test 3.1")

    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 3.2")

    xvar.setValue(x, true)
    print("z:", z())
    testAssert(z() == false, "exp logical test 3.3")

    xvar.setValue(x, false)
    xvar.setValue(y, true)
    print("z:", z())
    testAssert(z() == true, "exp logical test 3.4")

    --not
    local x = xvar.f0(false)
    local y = ~x

    print("y:", y())
    testAssert(y() == true, "exp logical test 4.1")

    xvar.setValue(x, true)

    print("y:", y())
    testAssert(y() == false, "exp logical test 4.2")
end

function xvarTest.testExp_Chain()
    local x = xvar.f0(3)
    local y = x {"<", 5}
    testAssert(y() == true, "exp chain test 1.1")

    xvar.setValue(x, 6)
    testAssert(y() == false, "exp chain test 1.2")

    y = xvar.f0(3)
    xvar.setValue(y, 3)
    local z = x {"+", y} {"==", 9} 
    print("z:", z())
    testAssert(z() == true, "exp chain test 2.1")

    xvar.setValue(y, 4)
    testAssert(z() == false, "exp chain test 2.2")

    x = xvar.f0(3)
    y = xvar.f0(4)
    local z = x {"+", y} {"==", 7} & y {"-", x} {"==", 1}
    local z1 = x {"+", y} {"==", 7} | y {"-", x} {"==", 1}
    local z2 = x {"+", y} {"==", 7} ~ y {"-", x} {"==", 1}

    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == true, "exp chain test 3.1.1")
    testAssert(z1() == true, "exp chain test 3.1.2")
    testAssert(z2() == false, "exp chain test 3.1.3")

    xvar.setValue(y, 3)
    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == false, "exp chain test 3.2.1")
    testAssert(z1() == false, "exp chain test 3.2.2")
    testAssert(z2() == false, "exp chain test 3.2.3")

    xvar.setValue(x, 4)
    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == false, "exp chain test 3.3.1")
    testAssert(z1() == true, "exp chain test 3.3.2")
    testAssert(z2() == true, "exp chain test 3.3.3")

    local x = xvar.f0(3)
    local y = xvar.f0(4)
    local z = x ("+", y) ("==", 7) & y ("-", x) ("==", 1)
    local z1 = x ("+", y) ("==", 7) | y ("-", x) ("==", 1)
    local z2 = x ("+", y) ("==", 7) ~ y ("-", x) ("==", 1)

    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == true, "exp chain test 3.4.1")
    testAssert(z1() == true, "exp chain test 3.4.2")
    testAssert(z2() == false, "exp chain test 3.4.3")

    xvar.setValue(y, 3)
    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == false, "exp chain test 3.5.1")
    testAssert(z1() == false, "exp chain test 3.5.2")
    testAssert(z2() == false, "exp chain test 3.5.3")

    xvar.setValue(x, 4)
    print("z:", z())
    print("z1:", z1())
    print("z2:", z2())
    testAssert(z() == false, "exp chain test 3.6.1")
    testAssert(z1() == true, "exp chain test 3.6.2")
    testAssert(z2() == true, "exp chain test 3.6.3")

    local t = xvar.f0 {
        [1002] = xvar.f0 { id = 1002, count = 100}
    }

    local count = t {".", 1002} {".", "count"}
    print("count:", count())
    testAssert(count() == 100, "exp chain test 4.1")
end

function xvarTest.testxTable()
    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    -- local x3 = xvar.f0(3)
    local x4 = xvar.f0(4)
    local x5 = xvar.f0(5)
    local x6 = xvar.f0(6)
    local x7 = xvar.f0(7)

    local y = xvar.x_table{x1, x2, 3, 4, x5, x6, x7}
    local t = y()
    testAssert(t[1] == 1, "x_table test 1.1")
    testAssert(t[2] == 2, "x_table test 1.2")
    testAssert(t[3] == 3, "x_table test 1.3")
    testAssert(t[4] == 4, "x_table test 1.4")
    testAssert(t[5] == 5, "x_table test 1.5")
    testAssert(t[6] == 6, "x_table test 1.6")
    testAssert(t[7] == 7, "x_table test 1.7")

    xvar.reset(x5, nil)
    local t = y()
    dump(t, "tttt")
    testAssert(t[1] == 1, "x_table test 2.1")
    testAssert(t[2] == 2, "x_table test 2.2")
    testAssert(t[3] == 3, "x_table test 2.3")
    testAssert(t[4] == 4, "x_table test 2.4")
    testAssert(t[5] == nil, "x_table test 2.5")
    testAssert(t[6] == 6, "x_table test 2.6")
    testAssert(t[7] == 7, "x_table test 2.7")

    testAssert(#t == 7, "x_table test 2.8")

    local y = xvar.x_table{x1 = x1, x2 = x2, [3] = x3, [4] = x4, x5 = x5, x6 = x6, x7= x7}
    local t = y()
    dump(t, "tttt")
    testAssert(t.x1 == 1, "x_table test 3.1")
    testAssert(t.x2 == 2, "x_table test 3.2")
    testAssert(t[3] == nil, "x_table test 3.3")
    testAssert(t[4] == 4, "x_table test 3.4")
    testAssert(t.x5 == nil, "x_table test 3.5")
    testAssert(t.x6 == 6, "x_table test 3.6")
    testAssert(t.x7 == 7, "x_table test 3.7")


    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    local z = x1 + x2
    local w = x1 * x2

    local y = xvar.x_table{[x1 + x2] = x1, [x1 * x2] = x1 + x2}
    local t = y()
    testAssert(t[3] == 1, "x_table test 4.1")
    testAssert(t[2] == 3, "x_table test 4.2")

    xvar.setValue(x1, 4)
    xvar.setValue(x2, 9)

    local t = y()
    dump(t, "tttt")
    testAssert(t[13] == 4, "x_table test 4.3")
    testAssert(t[36] == 13, "x_table test 4.4")
end

function xvarTest.testAorB()
    local x = xvar.f0(3)
    local y = xvar.f0(2)
    local z = xvar.x_A_or_B(x {">", y}, x, y) 
    print("z:", z())
    testAssert(z() == 3, "A_or_B test 1.1")

    xvar.setValue(x, 1)
    print("z:", z())
    testAssert(z() == 2, "A_Or_B test 1.2")

    local x = xvar.f0(3)
    local y = xvar.f0(nil)
    local z = xvar.f0(1)

    local w = xvar.x_A_or_B(x {">", 0}, y, z) 
    print("w:", w())
    testAssert(w() == nil, "A_Or_B test 2.1")

    local w = x{">", 0} & y | z
    print("w:", w())
    testAssert(w() == 1, "A_Or_B test 2.2")
end

function xvarTest.testMinAndMax()
    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    local x3 = xvar.f0(3)
    local x4 = xvar.f0(4)
    local x5 = xvar.f0(5)
    local x6 = xvar.f0(6)
    local x7 = xvar.f0(7)
    local x8 = xvar.f0(8)

    local y = xvar.x_min(x1, x2, nil, x3, 3.5, x4, xvar.err_nil, x5, 5.6, x6, x7, x8)
    print(y())
    testAssert(y() == 1, "minAndMax test 1.1 (min)")

    xvar.setValue(x5, -1)
    print(y())
    testAssert(y() == -1, "minAndMax test 1.2 (min)")

    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    local x3 = xvar.f0(3)
    local x4 = xvar.f0(4)
    local x5 = xvar.f0(5)
    local x6 = xvar.f0(6)
    local x7 = xvar.f0(7)
    local x8 = xvar.f0(8)

    local y = xvar.x_max(x1, x2, nil, x3, 3.5, x4, xvar.err_nil, x5, 5.6, x6, x7, x8)
    print(y())
    testAssert(y() == 8, "max test 2.1 (max)")

    xvar.setValue(x8, -1)
    print(y())
    testAssert(y() == 7, "max test 2.2 (max)")
end

function xvarTest.testHighOrder()
    local A = xvar.f0{}
    local x = A{".lv"}{"()"}
    print("x:", x())
    testAssert(x() == nil, "high order test 1.1")

    A.lv = xvar.f0(2)
    print("x:", x())
    testAssert(x() == 2, "high order test 1.2")
end

function xvarTest.testSafeSum()
    local x = xvar.f0(nil)
    local y = xvar.f0(nil)

    local z = x {"?+", y}
    print("z:", z())
    testAssert(z() == 0, "safe sum test 1.1")

    xvar.setValue(x, 2)
    print("z:", z())
    testAssert(z() == 2, "safe sum test 1.2")

    xvar.setValue(y, 3)
    print("z:", z())
    testAssert(z() == 5, "safe sum test 1.3")

    local x1 = xvar.f0 (1)
    local x2 = xvar.f0 (nil)
    local x3 = xvar.f0 (3)

    local X = xvar.x_table {x1, x2, x3}

    local y = xvar.x_safe_sum(X)
    print("y:", y())
    testAssert(y() == 4, "safe sum test 2.1")

    xvar.setValue(x2, 2)
    print("y:", y())
    testAssert(y() == 6, "safe sum test 2.2")
end

function xvarTest.testErrorCallback()
    local item = xvar.f0(false)
    xvar.addDirtyCallback(item, function()
        print("11111")
        local a = nil
        local b = a + 3
        print("222222")
    end)
    xvar.reset(item, 9)

    local count = xvar.f1(function(item)
        return item.count
    end, item)
 
    testAssert(count() == nil, "error callback test 1")
end

function xvarTest.testX_form()
    local x1 = xvar.f0(1)
    local x2 = xvar.f0(2)
    local x3 = xvar.f0(3)

    local y = xvar.x_form(x1, x2, x3) >> function(x1, x2, x3)
        return x1 + x2 + x3
    end

    print("y:", y())
    testAssert(y() == 6, "x form test 1.1")

    xvar.reset(x1, 3)
    print("y:", y())
    testAssert(y() == 8, "x form test 1.2")

end

-- function xvarTest.testReset()
-- end

return xvarTest
