#!/usr/bin/env love
-- LOVB2D
-- 0.1
-- Box2D (love2d)
-- b2d.lua

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

if arg[1] then print('0.1 LOVB2D Game Components (love2d)', arg[1]) end

-- lua<5.3
local utf8 = require('utf8')
local unpack = table.unpack or unpack

local B2D = {}

function B2D.setWorld(obj,pxmetr,gravx,gravy,sleep)
    pxmetr = pxmetr or 10
    gravx = gravx or 0
    gravy = gravy or 9.83
    sleep = sleep or true
    --  work well with shape sizes from 0.1 to 10 meters
    love.physics.setMeter(pxmetr)

    obj.world = love.physics.newWorld(gravx*pxmetr,gravy*pxmetr,sleep)
    obj.world:setCallbacks(obj.beginContact, obj.endContact,
                         obj.preSolve, obj.postSolve)

    obj.getWorld = function(self) return self.world end
end

function B2D.setBody(obj,world,collider,body,density)
    collider = collider or (obj.collider or 'circle')
    body = body or (obj.body or 'dynamic')
    density = density or 1

    obj.body = love.physics.newBody(world, (obj.x or 0),(obj.y or 0), body)
    obj.body:setAngle((obj.angle or 0))
    if collider=='circle' then
        obj.shape = love.physics.newCircleShape((obj.radius or 10))
    elseif collider=='rectangle' then
        obj.shape = love.physics.newRectangleShape((obj.wid or 10),
                                                    (obj.hei or 10))
    else
        local vertex
        if type(collider)=='table' and type(collider[1])=='number' then
            vertex = collider
        else
            vertex = {-10,5,0,0,-10,-5}
        end
        obj.shape=love.physics.newPolygonShape(vertex)
    end
    -- density connect with mass reset mass after fixture
    obj.fixture = love.physics.newFixture(obj.body, obj.shape, density)
    obj.fixture:setUserData(obj)

    obj.getBody = function(self) return self.body end
    obj.getShape = function(self) return self.shape end
    obj.getFixture = function(self) return self.body end
end

return B2D
