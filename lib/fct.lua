#!/usr/bin/env lua
-- FCT
-- 3.5
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

-- 3.5
-- + increase perfomance (wrong situations when use lent function)
-- + refactor split, sep and shuff
-- + remove ztab, valval, randtab
-- + add flip

-- 4.0
-- clear tests

-- Tool Box
-- gkv, len, count, keys, vals, iskey, isval, flip, range, rep,
-- split, reverse, isort, slice, sep, clone, iter,
-- equal, join, merge, same, uniq,
-- map, mapr, filter, any, all, zip, partial, reduce, compose,
-- permutation, randkey, randval, shuff, shuffknuth

-- No metatables when return arr
-- keys, vals, flip, range, repl, split, sep, iter, merge, same, uniq, map, filter, zip, permutation, shuffknuth

-- Error traceback
-- novarg, numvarg

if arg[0] then print('3.5 FCT Functional Tools (lua)', arg[0]) end
if arg[1] then print('3.5 FCT Functional Tools (lua)', arg[1]) end

-- old lua version
local unpack = table.unpack or unpack
local utf8 = require('utf8')
-- seed
math.randomseed(os.time())
-- errors
local function numvarg(name)
    local k,_
    for i=1,16 do k,_ = debug.getlocal(3,i) if k==name then return i end end
end

local function novarg(farg,name,expected)
    if type(farg)~=expected then
        local t1,t2,num,fin
        num = numvarg(name)
        t1=string.format('%s: %s: bad argument #%d to', arg[-1], arg[0],num)
        t2=string.format('(expected %s, got %s)', expected, type(farg))
        fin=string.format('%s \'%s\' %s', t1, debug.getinfo(2)['name'], t2)
        print(debug.traceback(fin,2))
        os.exit(1)
    end
end

local FCT={}
function FCT.gkv(item)
    novarg(item,'item','table')
    for k, v in pairs(item) do print(k, v, type(v)) end
end

function FCT.len(item)
    novarg(item,'item','table')
    local len = 0
    for _ in pairs(item) do len = len + 1 end
    return len
end

function FCT.count(val,item)
    novarg(item,'item','table')
    local res = 0
    for _,v in pairs(item) do
        if v==val then res = res + 1 end
    end
    return res
end

function FCT.keys(item)
    novarg(item,'item','table')
    local arr = {}
    for k, _ in pairs(item) do
        arr[#arr+1] = k
    end
    return arr
end

function FCT.vals(item)
    novarg(item,'item','table')
    local arr = {}
    for _, v in pairs(item) do
        arr[#arr+1] = v
    end
    return arr
end

function FCT.iskey(key,item)
    novarg(item,'item','table')
    if key==nil then return false end
    for k, v in pairs(item) do
        if k==key then return {k,v} end
    end
    return false
end

function FCT.isval(val,item)
    novarg(item,'item','table')
    if val==nil then return false end
    for k, v in pairs(item) do
        if v==val then return {k,v} end
    end
    return false
end

function FCT.flip(item)
    novarg(item,'item','table')
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
    novarg(num,'num','number')
    local arr = {}
    for i=1, num do arr[i] = obj end
    return arr
end

function FCT.split(obj,sep)
    if type(obj)=='number' then obj = tostring(obj) end
    novarg(obj,'obj','string')
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

function FCT.reverse(item)
    novarg(item,'item','table')
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
    novarg(item,'item','table')
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
    novarg(item,'item','table')
    local arr = {}
    local meta = getmetatable(item)
    local all_keys = FCT.keys(item)
    local lent = #all_keys
    start = start or 1
    if not fin or fin>lent then fin = lent end
    step = step or 1
    local count=0
    for i=start, fin, step do
        count=count+1
        local index = all_keys[i]
        if type(index)=='number' then index = #arr+1 end
        arr[index] = item[all_keys[i]]
    end
    setmetatable(arr, meta)
    return arr,count
end

function FCT.sep(item,num)
    novarg(item,'item','table')
    num = num or 1
    local arr = {}
    local i=1
    for _ in pairs(item) do
        local tmp_item,count = FCT.slice(item,i,num+i-1)
        if count == num then arr[#arr+1] = tmp_item else break end
        i=i+num
    end
    return arr
end

function FCT.clone(item)
    novarg(item,'item','table')
    local arr = {}
    local oldmeta = getmetatable(item) or {}
    local meta = {}
    for k, v in pairs(oldmeta) do meta[k] = v end

    for k, v in pairs(item) do
        if type(v) == 'table' then
            arr[k] = FCT.clone(v)
        else
            arr[k] = v
        end
    end
    setmetatable(arr, meta)
    return arr
end

function FCT.iter(item)
    novarg(item,'item','table')
    local tmp_item = FCT.clone(item)
    local arr = {}
    local meta = {}

    function meta.__index()
        local all_keys = FCT.keys(tmp_item)
        if next(all_keys) then
            local key = all_keys[1]
            local res = tmp_item[key]
            tmp_item[key] = nil
            return res end
    end

    function meta.__len()
    local len = 0
    for _,_ in pairs(tmp_item) do len = len + 1 end
    return len
    end
    setmetatable(arr, meta)
    return arr
end

function FCT.equal(item1,item2)
    novarg(item1,'item1','table')
    novarg(item2,'item2','table')
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

    local arr = FCT.clone(item1)
    local oldmeta = getmetatable(item2) or {}
    for k, v in pairs(oldmeta) do getmetatable(arr)[k] = v end

    for k, v in pairs(item2) do
        if type(k)=='number' then k = #arr+1 end
        if type(v) == 'table' then arr[k] = FCT.clone(v)
        else arr[k] = v end
    end
    return arr
end

function FCT.merge(item1,item2)
    novarg(item1,'item1','table')
    novarg(item2,'item2','table')
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
    novarg(item1,'item1','table')
    novarg(item2,'item2','table')
    local arr = {}

    for k, v in pairs(item1) do
        if FCT.isval(v,item2) and not FCT.isval(v,arr) then
            if type(k)=='number' then k = #arr+1 end
            arr[k] = v
        end
    end
    return arr
end

function FCT.uniq(item1,item2)
    novarg(item1,'item1','table')
    novarg(item2,'item2','table')
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

function FCT.map(func,item)
    novarg(func,'func','function')
    novarg(item,'item','table')
    local arr = {}
    for k, v in pairs(item) do
        arr[k] = func(v)
    end
    return arr
end

function FCT.mapr(func,item)
    novarg(func,'func','function')
    novarg(item,'item','table')
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
    novarg(func,'func','function')
    novarg(item,'item','table')
    local arr = {}
    for _, v in pairs(item) do
        if func(v) then arr[#arr+1] = v end
    end
    return arr
end

function FCT.any(item)
    novarg(item,'item','table')
    for _,v in pairs(item) do if v then return true end end
    return false
end

function FCT.all(item)
    novarg(item,'item','table')
    for _,v in pairs(item) do if not v then return false end end
    return true
end

function FCT.zip(...)
    local vargs = FCT.filter(function(item)
                    if type(item)=='table' then return true end end, {...})
    novarg(vargs[1],'vargs','table')

    local min_len = false
    for _, v in pairs(vargs) do
        local len_arg
        if getmetatable(v) and getmetatable(v).__len then
            len_arg = #v
        else
            len_arg = FCT.len(v)
        end
        if not min_len then min_len = len_arg end
        if len_arg < min_len then min_len = len_arg end
    end

    local arr = {}
    for i=1, min_len do
        arr[i] = FCT.map(function(item) return item[i] end, vargs)
    end
    return arr
end

function FCT.partial(func,...)
    novarg(func,'func','function')
    local vargs = {...}

    local function inner(...)
        local new_vargs = {...}
        local res = FCT.join(vargs, new_vargs)
        return func(unpack(res, 1, #res))
    end
    return inner
end

function FCT.reduce(func,item)
    novarg(func,'func','function')
    novarg(item,'item','table')
    local res = nil
    local all_keys = FCT.keys(item)
    local first = item[all_keys[1]]
    local lent = #all_keys
    if lent>1 then
        for i=2, lent do
            res = func(first, item[all_keys[i]])
            first = res
        end
    else
        res = func(first, first)
    end
    return res
end

function FCT.compose(func,wrap)
    novarg(func,'func','function')
    novarg(wrap,'wrap','function')
    local function inner(...)
        return FCT.reduce(function(x, y) return  y(x) end, {wrap(...), func})
    end
    return inner
end

function FCT.permutation(item,arr)
    novarg(item,'item','table')
    arr = arr or {}
    arr[#arr+1]={unpack(item)}

    local index
    for i=#item,2,-1 do if item[i]>item[i-1] then index = i-1 break end end
    if not index then return arr end

    for i=#item,1,-1 do
        if item[i]>item[index] then
            item[i],item[index] = item[index],item[i]
            local tail = {unpack(item,index+1,#item)}
            item  = {unpack(item,1,index)}
            table.sort(tail,function(a,b) return a<b end)
            for j=1,#tail do item[#item+1]=tail[j] end
            break
        end
    end
    return FCT.permutation(item,arr)
end

function FCT.randkey(item)
    novarg(item,'item','table')
    local all_keys = FCT.keys(item)
    local index = math.random(1, #all_keys)
    return all_keys[index]
end

function FCT.randval(item)
    return item[FCT.randkey(item)]
end

function FCT.shuff(item)
    novarg(item,'item','table')
    local arr = FCT.clone(item)
    local all_keys = FCT.keys(item)
    for i=1, #all_keys do
        local index = all_keys[math.random(i, #all_keys)]
        arr[all_keys[i]],arr[index] = arr[index],arr[all_keys[i]]
    end
    return arr
end

function FCT.shuffknuth(item)
    novarg(item,'item','table')
    local arr = {unpack(item)}
    for i=1, #arr do
        local index = math.random(i,#arr)
        arr[i], arr[index] = arr[index], arr[i]
    end
    return arr
end

return FCT
