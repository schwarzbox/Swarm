#!/usr/bin/env lua
-- FCT
-- 4.6
-- Functional Tools (lua)
-- fct.lua

-- MIT License
-- Copyright (c) 2018 Alexander Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- 5.0
-- separate combo/random library
-- clear tests

-- Tool Box
-- len, count, keys, vals, items, iskey, isval, flip, range, rep,
-- split, invert, isort, slice, sep, copy, iter,
-- equal, join, union, same, diff,
-- each, map, mapr, filter, any, all, zip, reduce, partial, compose
-- chain, cache,
-- accumulate, permutation, combination, randkey, randval, shuff, shuffknuth
-- weighted

-- No metatables when return arr
-- keys, vals, items, flip, range, repl, split, sep, iter, union, same, diff, map, filter, zip, accumulate, permutation, combination, shuffknuth (faster)

-- Support
-- gkv

if arg[0] then io.write('4.6 FCT Functional Tools (lua)', arg[0],'\n') end
if arg[1] then io.write('4.6 FCT Functional Tools (lua)', arg[1],'\n') end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

math.randomseed(os.time())

-- Local function to check arguments and raise errors
local function numfarg(name)
    local k,_
    for i=1,16 do k,_ = debug.getlocal(3,i) if k==name then return i end end
end

local function nofarg(farg,name,...)
    local expected = {}
    for _,v in pairs({...}) do
        expected[v]=v
    end
    if not expected[type(farg)] then
        local t1,t2,num,fin
        num = numfarg(name)
        t1=string.format('%s: %s: bad argument #%d to', arg[-1], arg[0],num)
        t2=string.format('(expected %s, got %s)', expected, type(farg))
        fin=string.format('%s \'%s\' %s', t1, debug.getinfo(2)['name'], t2)
        print(debug.traceback(fin,2))
        os.exit(1)
    end
end

local FCT={}

-- Tool Box
function FCT.len(item)
    nofarg(item,'item','table')
    local len = 0
    for _ in pairs(item) do len = len + 1 end
    return len
end

function FCT.count(val,item)
    nofarg(item,'item','table')
    local res = 0
    for _,v in pairs(item) do
        if v==val then
            res = res + 1
        end
    end
    return res
end

function FCT.keys(item)
    nofarg(item,'item','table')
    local arr = {}
    for k, _ in pairs(item) do
        arr[#arr+1] = k
    end
    return arr
end

function FCT.vals(item)
    nofarg(item,'item','table')
    local arr = {}
    for _, v in pairs(item) do
        arr[#arr+1] = v
    end
    return arr
end

function FCT.items(item)
    nofarg(item,'item','table')
    local arr = {}
    for _,v in pairs(item) do
        arr[v]=v
    end
    return arr
end

function FCT.iskey(key,item)
    nofarg(item,'item','table')
    if key==nil then return false end
    for k, v in pairs(item) do
        if k==key then return {k,v} end
    end
    return false
end

function FCT.isval(val,item)
    nofarg(item,'item','table')
    if val==nil then return false end
    for k, v in pairs(item) do
        if v==val then return {k,v} end
    end
    return false
end

function FCT.flip(item)
    nofarg(item,'item','table')
    local arr = {}
    for k,v in pairs(item) do arr[v]=k end
    return arr
end


function FCT.range(...)
    local vargs = {...}
    local start, fin
    local step = vargs[3] or 1

    local arr = {}
    if #vargs==1 then
        start, fin = 1, vargs[1]
    elseif #vargs>=2 then
        start, fin = vargs[1], vargs[2]
    else
        start, fin = 1, 1
    end

    for i=start, fin, step do arr[#arr+1] = i end
    return arr
end

function FCT.rep(obj,num)
    nofarg(num,'num','number')
    local arr = {}
    for i=1, num do arr[i] = obj end
    return arr
end

function FCT.split(obj,sep)
    if type(obj)=='number' then obj = tostring(obj) end
    nofarg(obj,'obj','string')
    sep = sep or ''
    local arr={}
    if #sep>0 then
        for i in string.gmatch(obj,'[^'..sep..']+') do
            arr[#arr+1]=i
        end
    end
    if #arr==0 then
        for i in string.gmatch(obj,utf8.charpattern) do
            arr[#arr+1]=i
        end
    end
    return arr
end

function FCT.invert(item)
    nofarg(item,'item','table')
    local arr = {}
    local meta = getmetatable(item)
    for k,v in pairs(item) do
        if type(k)=='number' then
            arr[#item-k+1] = v
        else
            arr[k] = v
        end
    end
    setmetatable(arr, meta)
    return arr
end

function FCT.isort(item,val,rev)
    nofarg(item,'item','table')
    local keys = {}
    for k,_ in pairs(item) do keys[#keys+1]=k end

    if val then
        local sort = function(t,a,b) return t[a]<t[b] end
        if rev then
            sort = function(t,a,b) return t[a]>t[b] end
        end

        table.sort(keys,function(a,b) return sort(item,a,b) end)
    else
        table.sort(keys)
        if rev then
            table.sort(keys,function(a,b) return a>b end)
        end
    end

    local i = 0
    local function inner()
        i = i+1
        if keys[i] then return keys[i], item[keys[i]] end
    end
    return inner
end

function FCT.slice(item,start,fin,step)
    nofarg(item,'item','table')
    local arr = {}
    local meta = getmetatable(item)
    local allkeys = FCT.keys(item)
    local lent = #allkeys
    start = start or 1
    if not fin or fin>lent then fin = lent end
    step = step or 1
    local count=0
    for i=start, fin, step do
        count=count+1
        local index = allkeys[i]
        if type(index)=='number' then index = #arr+1 end
        arr[index] = item[allkeys[i]]
    end
    setmetatable(arr, meta)
    return arr,count
end

function FCT.sep(item,num)
    nofarg(item,'item','table')
    num = num or 1
    local arr = {}
    local i=1
    for _ in pairs(item) do
        local tmpitem,count = FCT.slice(item,i,num+i-1)
        if count == num then arr[#arr+1] = tmpitem else break end
        i=i+num
    end
    return arr
end

function FCT.copy(item)
    nofarg(item,'item','table')
    local arr = {}
    local meta = {}
    local oldmeta = getmetatable(item) or {}

    for k, v in pairs(oldmeta) do meta[k] = v end

    for k, v in pairs(item) do
        if type(v) == 'table' then
            arr[k] = FCT.copy(v)
        else
            arr[k] = v
        end
    end
    setmetatable(arr, meta)
    return arr
end

function FCT.iter(item)
    nofarg(item,'item','table')
    local tmpitem = FCT.copy(item)
    local arr = {}
    local meta = {}

    function meta.__index()
        local allkeys = FCT.keys(tmpitem)
        if next(allkeys) then
            local key = allkeys[1]
            local res = tmpitem[key]
            tmpitem[key] = nil
            return res end
    end

    function meta.__len()
    local len = 0
    for _,_ in pairs(tmpitem) do len = len + 1 end
    return len
    end
    setmetatable(arr, meta)
    return arr
end

function FCT.equal(item1,item2)
    nofarg(item1,'item1','table')
    nofarg(item2,'item2','table')
    if #item1~=#item2 then return false end
    for k,v in pairs(item1) do
        if v~=item2[k] then return false end
    end
    return true
end

function FCT.join(item1,item2)
    if type(item1)~='table' then item1 = {item1} end
    item2 = item2 or {}
    if type(item2)~='table' then item2 = {item2} end

    local arr = FCT.copy(item1)
    local meta = getmetatable(arr)
    local oldmeta = getmetatable(item2) or {}

    for k, v in pairs(oldmeta) do meta[k] = v end

    for k, v in pairs(item2) do
        if type(k)=='number' then k = #arr+1 end
        if type(v) == 'table' then arr[k] = FCT.copy(v)
        else arr[k] = v end
    end
    return arr
end

function FCT.union(item1,item2)
    nofarg(item1,'item1','table')
    nofarg(item2,'item2','table')
    local arr = {}

    for k, v in pairs(item1) do
        if not FCT.isval(v,arr)  then
            if type(k)=='number' then k = #arr+1  end
            arr[k] = v
        end
    end
    for k, v in pairs(item2) do
        if not FCT.isval(v,arr) then
            if type(k)=='number' then k = #arr+1 end
            arr[k] = v
        end
    end
    return arr
end

function FCT.same(item1,item2)
    nofarg(item1,'item1','table')
    nofarg(item2,'item2','table')
    local arr = {}

    for k, v in pairs(item1) do
        if FCT.isval(v,item2) and not FCT.isval(v,arr) then
            if type(k)=='number' then k = #arr+1 end
            arr[k] = v
        end
    end
    return arr
end

function FCT.diff(item1,item2)
    nofarg(item1,'item1','table')
    nofarg(item2,'item2','table')
    local arr = {}

    for k, v in pairs(item1) do
        if not FCT.isval(v,item2) and not FCT.isval(v,arr) then
            if type(k)=='number' then k = #arr+1 end
            arr[k] = v
        end
    end
    for k, v in pairs(item2) do
        if not FCT.isval(v,item1) and not FCT.isval(v,arr) then
            if type(k)=='number' then k = #arr+1 end
            arr[k] = v
        end
    end
    return arr
end

function FCT.each(obj,item)
    nofarg(obj,'obj','string','function')
    nofarg(item,'item','table')
    if type(obj) == 'string' then
        for _, v in pairs(item) do
            v[obj]()
        end
    else
        for _, v in pairs(item) do
            obj(v)
        end
    end
end

function FCT.map(func,item)
    nofarg(func,'func','function')
    nofarg(item,'item','table')
    local arr = {}
    for k, v in pairs(item) do
        arr[k] = func(v)
    end
    return arr
end

function FCT.mapr(func,item)
    nofarg(func,'func','function')
    nofarg(item,'item','table')
    local arr = {}
    local meta = getmetatable(item)
    for k, v in pairs(item) do
        if type(v)=='table' then
            arr[k] = FCT.mapr(func, v)
        else
            arr[k] = func(v)
        end
    end
    setmetatable(arr,meta)
    return arr
end

function FCT.filter(func,item)
    nofarg(func,'func','function')
    nofarg(item,'item','table')
    local arr = {}
    for k, v in pairs(item) do
        if func(v) then arr[k] = v end
    end
    return arr
end

function FCT.any(item)
    nofarg(item,'item','table')
    for _,v in pairs(item) do if v then return true end end
    return false
end

function FCT.all(item)
    nofarg(item,'item','table')
    for _,v in pairs(item) do if not v then return false end end
    return true
end

function FCT.zip(...)
    local tmp = {}
    local minlen = false
    local lenarg

    for _, v in pairs({...}) do
        if type(v)=='table' then
            if getmetatable(v) and getmetatable(v).__len then
                lenarg = #v
            else
                lenarg = FCT.len(v)
            end
            if not minlen then minlen = lenarg end
            if lenarg < minlen then minlen = lenarg end
            tmp[#tmp+1]=v
        end
    end

    local arr = {}
    for i=1, minlen do
        arr[i] = FCT.map(function(item) return item[i] end, tmp)
    end
    return arr
end

function FCT.reduce(func,item)
    nofarg(func,'func','function')
    nofarg(item,'item','table')
    local res = nil
    local allkeys = FCT.keys(item)
    local first = item[allkeys[1]]
    local lent = #allkeys
    if lent>1 then
        for i=2, lent do
            res = func(first, item[allkeys[i]])
            first = res
        end
    else
        res = first
    end
    return res
end

function FCT.partial(func,...)
    nofarg(func,'func','function')
    local vargs = {...}

    local function inner(...)
        local innervargs = {...}
        local res = FCT.join(vargs, innervargs)
        return func(unpack(res, 1, #res))
    end
    return inner
end

function FCT.compose(func,wrap)
    nofarg(func,'func','function')
    nofarg(wrap,'wrap','function')
    local function inner(...)
        return FCT.reduce(function(x, y) return  y(x) end, {wrap(...), func})
    end
    return inner
end

function FCT.chain(...)
    local vargs = {...}
    local arr = {}
    for i=1, #vargs do
        local func = vargs[i]
        if type(func)=='function' then arr[func]=func end
    end

    return function(...)
        for f in pairs(arr) do f(...) end
    end
end

function FCT.cache(func)
    nofarg(func,'func','function')
    local cached = {}
    return function(...)
            local key = table.concat({...})
            local res = cached[key]
            if not res then
                res = func(...)
                cached[key]=res
                return res
            end
            return res
        end
end

-- p = n!
-- repeat
-- p = n^n
-- subset
-- p = n!/(n-k)!
function FCT.permutation(item,num,arr)
    nofarg(item,'item','table')
    num = num or #item
    arr = arr or {}

    if num <= 1 then arr[#arr+1] = {unpack(item)}
    else
        for i=1,num do
            item[num], item[i] = item[i], item[num]
            FCT.permutation(item,num-1,arr)
            item[num], item[i] = item[i], item[num]
        end
    end
    return arr
end

-- c = n!/(k!(n-k)!)
function FCT.combination(item,num,arr)
    nofarg(item,'item','table')
    num = num or 1
    arr = arr or {}

    local findcombo
    findcombo = function(it,res)
            res = res or {}
            res[#res+1] = table.remove(it,1)
            if (#res == num) then
                arr[#arr+1] = res
            else
                for j=1,#it do
                    findcombo({unpack(it,j,#it)},{unpack(res)})
                 end
            end
        end

    for _=1, #item do
        findcombo(item)
    end
    return arr
end

function FCT.accumulate(item,func)
    nofarg(item,'item','table')
    func = func or function(a,b) return a+b end
    local arr = {item[1]}
    for i=2,#item do
        arr[#arr+1]=func(arr[#arr],item[i])
    end
    return arr
end

function FCT.randkey(item)
    nofarg(item,'item','table')
    local allkeys = FCT.keys(item)
    local index = math.random(1, #allkeys)
    return allkeys[index]
end

function FCT.randval(item)
    return item[FCT.randkey(item)]
end

function FCT.shuff(item)
    nofarg(item,'item','table')
    local arr = FCT.copy(item)
    local allkeys = FCT.keys(item)
    for i=1, #allkeys do
        local index = allkeys[math.random(i, #allkeys)]
        arr[allkeys[i]],arr[index] = arr[index],arr[allkeys[i]]
    end
    return arr
end


function FCT.shuffknuth(item)
    nofarg(item,'item','table')
    local arr = {unpack(item)}
    for i=1, #arr do
        local index = math.random(i,#arr)
        arr[i], arr[index] = arr[index], arr[i]
    end
    return arr
end

function FCT.weighted(item)
    nofarg(item,'item','table')
    local sum = 0
    for _, v in pairs(item) do
        sum = sum + v
    end
    local rnd = math.random(sum)
    for k, v in pairs(item) do
        if rnd <= v then return k end
        rnd = rnd - v
    end
end

-- Support
function FCT.gkv(...)
    for key, value in pairs(...) do
        if type(value) == 'table' then
            for k, v in pairs(value) do print(k, v, type(v)) end
        else
            print(key, value)
        end
    end
end

return FCT
