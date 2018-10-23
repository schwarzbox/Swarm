#!/usr/bin/env love
-- SWARM
-- 1.5
-- Game (love2d)
-- main.lua

-- MIT License
-- Copyright (c) 2018 Alexander Veledzimovich veledz@gmail.com

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

io.stdout:setvbuf('no')
-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local fc = require('lib/fct')

local ctrl = require('lib/lovctrl')
local ui = require('lib/lovui')

local scr = require('game/scr')
local set = require('game/set')

function love:startgame()
    if self.screen then self.screen:clear() end
    self:set_screen('Menu')
end
function love:game()
    self.screen:clear()
    self:set_screen('Game')
end

function love:set_screen(screen,...) self.screen = scr[screen](...) end
function love:get_screen() return self.screen end

function love.load()
    if arg[1] then print(set.VER, set.GAMENAME, 'Game (love2d)', arg[1]) end

    love.window.setTitle(string.format('%s %s', set.GAMENAME, set.VER))
    love.window.setFullscreen(set.FULLSCR, 'desktop')
    love.graphics.setBackgroundColor(set.BGCLR)

    -- init
    ui.init()
    ctrl.init()

    ctrl:bind('lgui+p','pause', function() love.screen:set_pause() end)
    ctrl:bind('escape','quit',function() love.quit() love.event.quit() end)
    ctrl:bind('lgui+q','cmdq',function() love.event.quit(1) end)

    love.screen = nil
    love:startgame()
end

-- dt around 0.016618420952
function love.update(dt)
    local title = string.format('%s %s', set.GAMENAME, set.VER,
                                love.timer.getFPS(),
                                fc.len(love.screen:get_objects()))
    love.window.setTitle(title)
    -- ctrl game
    ctrl:press('pause')
    ctrl:press('quit')
    ctrl:press('cmdq')
    -- update
    love.screen:update(dt)
end

function love.draw() love.screen:draw() end

function love.focus(focus)
    if not focus then
        love.screen:set_pause(true)
    else
        love.screen:set_pause(false)
    end
end

function love.keypressed(key,unicode,isrepeat) end
function love.keyreleased(key,unicode) end
function love.mousepressed(x,y,button,istouch) end
function love.mousereleased(x,y,button,istouch) end
function love.mousemoved(x,y,dx,dy,istouch) end
function love.wheelmoved(x, y) end
function love.quit() print(0) end
