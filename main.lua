#!/usr/bin/env love
-- SWARM
-- 1.5
-- Game (love2d)
-- main.lua

-- MIT License
-- Copyright (c) 2018 Aliaksandr Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Soft ware.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local fc = require('lib/fct')

local ctrl = require('lib/lovctrl')
local ui = require('lib/lovui')

local nod = require('game/nod')
local set = require('game/set')
io.stdout:setvbuf('no')

function love:startgame()
    if self.node then self.node:clear() end
    self:set_node('Menu')
end
function love:game()
    self.node:clear()
    self:set_node('Game')
end

function love:set_node(node,...) self.node = nod[node](...) end
function love:get_node() return self.node end

function love.load()
    if arg[1] then print(set.VER, set.APPNAME, 'Game (love2d)', arg[1]) end

    love.window.setTitle(string.format('%s %s', set.APPNAME, set.VER))
    love.window.setFullscreen(set.FULLSCR, 'desktop')
    love.graphics.setBackgroundColor(set.BGCLR)

    -- init
    ui.load()
    ctrl.load()

    ctrl:bind('escape','pause', function() love.node:set_pause() end)
    ctrl:bind('lgui+r','cmdr',function() love.event.quit('restart') end)
    ctrl:bind('lgui+q','cmdq', function() love.event.quit(1) end)

    love.node = nil
    love:startgame()
end

-- dt around 0.016618420952
function love.update(dt)
    -- ctrl game
    ctrl:press('pause')
    ctrl:press('cmdr')
    ctrl:press('cmdq')
    -- update
    love.node:update(dt)
end

function love.draw() love.node:draw() end

function love.focus(focus)
    if not focus then
        love.node:set_pause(true)
    else
        love.node:set_pause(false)
    end
end

function love.keypressed(key,unicode,isrepeat) end
function love.keyreleased(key,unicode) end
function love.mousepressed(x,y,button,istouch) end
function love.mousereleased(x,y,button,istouch) end
function love.mousemoved(x,y,dx,dy,istouch) end
function love.wheelmoved(x, y) end
function love.quit() print(0) end
