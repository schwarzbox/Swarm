#!/usr/bin/env lua
-- LOVUI
-- 2.0
-- GUI (love2d)
-- lovui.lua

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

-- 256 obj 60 fps
-- 2.5
-- set image set cursor
-- 3.0
-- Hbox remove
-- text field
-- input utf support
-- make faster

-- all given images - imgdata

if arg[1] then print('2.0 LOVUI GUI (love2d)', arg[1]) end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local EMPTY = {1,1,1,0}
local WHITE = {1,1,1,1}
local FNTCLR = {128/255,128/255,128/255,1}
local FRMCLR = {64/255,64/255,64/255,1}
local BOXCLR = {64/255-0.1,64/255-0.1,64/255-0.1,1}
local POPCLR = {64/255-0.05,64/255-0.05,64/255-0.05,0.95}
local FNT = {nil,16}

local UI = {DT=0.017,kpress={},krelease={},mpress={},mrelease={},
            mouse={0,0,0,0,false},wheel={0,0}}
function UI.init()
    local events = {'keypressed','keyreleased','mousepressed',
            'mousereleased','mousemoved','wheelmoved','update'}
    -- add to love
    local default = {}
    for i=1,#events do
        default[events[i]] = love[events[i]] or function() end
        love[events[i]] = function(...)
            local output = {default[events[i]](...)}
            if #output>0 then
                UI[events[i]](unpack(output))
                return unpack(output)
            else UI[events[i]](...) end
        end
    end
end
-- OOP
function UI.Class(Super, class)
    Super = Super or {}
    class = class or {}
    class.Super = Super
    local meta = {__index=Super}
    meta.__call = function(self,o)
                    o = o or {}
                    self.__index = self
                    self = setmetatable(o,self)
                    if self.new then self.new(self,o) end
                    return self
                end

    for k,v in pairs(Super) do
        if rawget(Super,k) and k:match('^__') and type(v)=='function' then
            class[k] = v
        end
    end
    return setmetatable(class,meta)
end
-- private
function UI.update(dt) UI.DT=dt UI.clearActions() end

function UI.keypressed(key,unicode,isrepeat)
    UI.kpress = {key,unicode,isrepeat}
end
function UI.keyreleased(key,unicode)
    UI.krelease = {key,unicode}
end
function UI.mousepressed(x,y,button,istouch)
    UI.mpress = {x,y,button,istouch}
end
function UI.mousereleased(x,y,button,istouch)
    UI.mrelease = {x,y,button,istouch}
end
function UI.mousemoved(x,y,dx,dy,istouch) UI.mouse = {x,y,dx,dy,istouch} end
function UI.wheelmoved(x, y) UI.wheel = {x,y} end
-- public
function UI.keypress() return unpack(UI.kpress) end
function UI.keyrelease() return unpack(UI.krelease) end
function UI.mousepress() return unpack(UI.mpress) end
function UI.mouserelease() return unpack(UI.mrelease) end
function UI.mousemove() return unpack(UI.mouse) end
function UI.wheelmove() return unpack(UI.wheel) end
function UI.getDT() return UI.DT end
function UI.clearActions()
    UI.kpress={}
    UI.krelease={}
    UI.mpress={}
    UI.mrelease={}
    UI.mouse={UI.mouse[1],UI.mouse[2],0,0,false}
    UI.wheel={0,0}
end

-- UI Manager
UI.Manager = {items={}}
function UI.Manager.draw()
    for _, item in pairs(UI.Manager.items) do item:draw() end
end
function UI.Manager.update(dt)
    for _, item in pairs(UI.Manager.items) do item:update(dt) end
end

function UI.Manager.len() return #UI.Manager.items end
function UI.Manager.add(item) UI.Manager.items[#UI.Manager.items+1] = item end
function UI.Manager.clear() UI.Manager.items = {} end
function UI.Manager.remove(item)
    for i=1,#UI.Manager.items do
        if UI.Manager.items[i] and UI.Manager.items[i]==item then
            table.remove(UI.Manager.items,i)
        end
    end
end

function UI.Manager.focus(bool)
    for i=1, #UI.Manager.items do
        if UI.Manager.items[i] and (UI.Manager.items[i].type~='input' and
                                    UI.Manager.items[i].type~='popup' and
                                    UI.Manager.items[i].type~='foldlist') then
            UI.Manager.items[i].focus = bool
        end
    end
end


local Proto = UI.Class({x=nil, y=nil, anchor='center', frm=0, frmclr=FRMCLR,
                mode='line',wid=0,hei=0,corner={0,0,0},hide=false,focus=true})
function Proto:__tostring() return self.type end
function Proto:set(args) for k,v in pairs(args) do self[k] = v end end
function Proto:get(arg) return self[arg] end
function Proto:remove() UI.Manager.remove(self) end
function Proto:setFocus(bool) self.focus = bool end
function Proto:setHide(bool) self.hide = bool end


function Proto.getAnchor(itx,ity,itwid,ithei,frm,side)
    local x,y
    itwid,ithei = itwid+frm*2,ithei+frm*2
    local midx,midy = itwid/2,ithei/2
    if side=='n' then x, y = itx-midx,ity
    elseif side=='s'then x,y = itx-midx,ity-ithei
    elseif side=='w' then x,y = itx,ity-midy
    elseif side=='e' then x,y = itx-itwid,ity-midy
    elseif side=='nw' then x,y = itx,ity
    elseif side=='ne' then x,y = itx-itwid,ity
    elseif side=='se' then x,y = itx-itwid,ity-ithei
    elseif side=='sw' then x,y = itx,ity-ithei
    else x,y = itx-midx, ity-midy
    end
    return x,y
end

function Proto.getPivot(itwid,ithei,pivot)
    local x,y
    local midx, midy = itwid/2, ithei/2
    if pivot=='nw' then x,y = 0,0
    elseif pivot=='ne' then x,y = itwid,0
    elseif pivot=='sw' then x,y = itwid,ithei
    elseif pivot=='se'then x,y = 0,ithei
    else x,y = midx,midy
    end
    return x,y
end

function Proto:setWidHei(wid,hei)
    if wid>self.wid then self.wid = wid end
    if hei>self.hei then self.hei = hei end
    self.wid = self.wid+self.wid%2
    self.hei = self.hei+self.hei%2
end

function Proto:drawFrame()
    local frmclr = self.deffrm or EMPTY
    if self.frm>0 and self.wid>0 then
        love.graphics.setColor(frmclr)

        love.graphics.rectangle(self.mode, self.rectx, self.recty,
                                self.wid+self.frm*2, self.hei+self.frm*2,
                                unpack(self.corner))
        love.graphics.setColor(WHITE)
    end

end

function Proto:collide(x,y)
    return ((x>self.rectx and x<self.rectx+self.wid+self.frm*2) and
        (y>self.recty and y<self.recty+self.hei+self.frm*2))
end

function Proto:mouseCollide(x,y)
    local xx, yy ,dx, dy, istouch = UI.mousemove()
    if not x or not y then  x=xx y=yy end
    if self:collide(x,y) then return true end
end

function Proto:mouseCollidePress(but,touch)
    local x, y, button, istouch = UI.mousepress()
    if button==but and self:mouseCollide(x,y) then
        return true
    end
end

function Proto:mouseCollideRelease(but,touch)
    local x, y, button, istouch = UI.mouserelease()
    if button==but and self:mouseCollide(x,y) then
        return true
    end
end

function Proto:mouseCollideDown(but)
    if love.mouse.isDown(but) and self:mouseCollide() then return true end
end

function Proto:mousePress(but,touch)
    local x, y, button, istouch = UI.mousepress()
    if button==but then
        return x, y, button, istouch
    end
end

function Proto:mouseRelease(but,touch)
    local x, y, button, istouch = UI.mouserelease()
    if button==but then
        return x, y, button, istouch
    end
end

function Proto:mouseDown(but)
    local xx, yy ,dx, dy, istouch = UI.mousemove()
    if love.mouse.isDown(but) then
        return xx, yy ,dx, dy, istouch
    end
end

function Proto:keyPress(keypress,scancode)
    local key, unicode, isrepeat = UI.keypress()
    if keypress==key then
        return true
    end
end

function Proto:keyRelease(keyrelease,scancode)
    local key, unicode = UI.keyrelease()
    if keyrelease==key then
        return true
    end
end

function Proto:keyDown(key)
    if love.keyboard.isDown(key) then return true end
end

function Proto:mouseMove()
    local x,y,dx,dy,istouch = UI.mousemove()
    return x,y,dx,dy,istouch
end

function Proto:wheelMove()
    local x,y = UI.wheelmove()
    return x,y
end


UI.Sep = UI.Class(Proto)
UI.Sep.type = 'sep'
function UI.Sep:new(o)
    self.deffrm = self.frmclr
    self.wid=2
    self.hei=2
    self.frm=0.5
    self.mode = 'fill'
    self:setup()
    UI.Manager.add(self)
end

function UI.Sep:setup()
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rectx, self.recty = self.getAnchor(self.x,self.y, self.wid,self.hei,
                                        self.frm, self.anchor)
end

function UI.Sep:draw() if not self.hide then self:drawFrame() end end
function UI.Sep:update(dt) dt = dt or UI.getDT() self:setup() end


UI.HBox = UI.Class(Proto,{frmclr=BOXCLR,sep=8,drag=false})
UI.HBox.type = 'hbox'
function UI.HBox:new(o)
    self.deffrm = self.frmclr
    self.items = {}
    self:setup()
    UI.Manager.add(self)
end

function UI.HBox:setup()
    local wid,hei = 0,0
    for i=1,#self.items do
        if self.items[i] then
            local itwid = self.items[i]:get('wid')
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frm')
            wid = wid+itwid+itfrm*2
            if hei<ithei+itfrm*2 then hei = ithei+itfrm*2 end
        end
    end

    wid = wid+self.sep*(#self.items-1)
    self:setWidHei(wid, hei)
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rectx, self.recty = self.getAnchor(self.x,self.y, self.wid,self.hei,
                                        self.frm, self.anchor)
    self.conx = self.rectx+self.frm
    self.cony = self.recty+self.frm
    local total = 0
    for i=1, #self.items do
        if self.items[i] then
            -- get w anchor
            local itwid = self.items[i]:get('wid')
            local itfrm = self.items[i]:get('frm')

            self.items[i]:set({x=self.conx+total,
                              y=self.cony+self.hei/2,
                              anchor='w'})

            if self.items[i]:get('type')=='sep' then
                self.items[i]:set({wid=1,hei=self.hei-2})
            end
            total = total+itwid+itfrm*2+self.sep
            if (self.items[i]:get('type')=='counter' or
                self.items[i]:get('type')=='slider' or
                self.items[i]:get('type')=='progbar' or
                self.items[i]:get('type')=='list' or
                self.items[i]:get('type')=='foldlist') then
                self.items[i]:setup()
            end
        end
    end
end

function UI.HBox:add(...)
    local fargs = {...}
    for i=1, #fargs do self.items[#self.items+1] = fargs[i] end
    self:setup()
end

function UI.HBox:setDrag(bool) self.drag = bool end
function UI.HBox:setHide(bool)
    self.hide=bool
    for i=1,#self.items do
        if self.items[i] then self.items[i]:setHide(bool) end
    end
end

function UI.HBox:draw() if not self.hide then self:drawFrame() end end
function UI.HBox:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        if self:mouseCollideDown(1) and self.drag then
            local _,_,dx,dy,_ = self:mouseMove()
            self.x,self.y=self.x+dx,self.y+dy
        end
    end
end

function UI.HBox:remove()
    for i=#self.items, 1,-1 do
        if self.items[i] then self.items[i]:remove() end
    end
    UI.Manager.remove(self)
end


UI.VBox = UI.Class(UI.HBox)
UI.VBox.type = 'vbox'
function UI.VBox:setup()
    local wid,hei = 0,0
    for i=1,#self.items do
        if self.items[i] then
            local itwid = self.items[i]:get('wid')
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frm')
            hei = hei+ithei+itfrm*2
            if wid<itwid+itfrm*2 then wid = itwid+itfrm*2 end
        end
    end

    hei = hei+self.sep*(#self.items-1)
    self:setWidHei(wid, hei)
    -- problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rectx, self.recty = self.getAnchor(self.x,self.y, self.wid,self.hei,
                                        self.frm,self.anchor)
    self.conx = self.rectx+self.frm
    self.cony = self.recty+self.frm
    local total = 0
    for i=1, #self.items do
        if self.items[i] then
            -- get n anchor
            local ithei = self.items[i]:get('hei')
            local itfrm = self.items[i]:get('frm')
            self.items[i]:set({x=self.conx+self.wid/2,
                                y=self.cony+total,
                                anchor='n'})
            if self.items[i]:get('type')=='sep' then
                self.items[i]:set({wid=self.wid-2,hei=1})
            end

            total = total+ithei+itfrm*2+self.sep

            if (self.items[i]:get('type') == 'counter' or
                self.items[i]:get('type') == 'slider' or
                self.items[i]:get('type') == 'progbar' or
                self.items[i]:get('type') == 'list' or
                self.items[i]:get('type') == 'foldlist') then
                self.items[i]:setup()
            end
        end
    end
end


UI.PopUp = UI.Class(UI.VBox{frmclr=POPCLR,focus=false})
UI.PopUp.type = 'popup'
function UI.PopUp:new()
    self.frm = 2
    self.deffrm=self.frmclr
    self.mode='fill'
    self.sep = 4
    self.drag = false
    self.txt = nil

    UI.Manager.add(self)

    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end

    self.items = {self.txt,UI.Sep(),unpack(self.items,1,#self.items)}
    self:setHide(self.hide)
    self:setup()
end

function UI.PopUp:add(...)
    UI.PopUp.Super.add(self,...)
    for i=2,#self.items do
        if self.items[i]:get('type')~='sep' then
            local butcom = self.items[i]:get('com') or function() end
            local com = function() butcom()
                                self.x, self.y = 0,0 self.anchor='sw'
                                UI.Manager.focus(true)
                            end
            self.items[i]:set({fnt=self.fnt, fntclr=self.fntclr,com=com})
        end
    end
end

function UI.PopUp:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        if self:mousePress(1) and not self:mouseCollide() then
            self.x, self.y = 0,0 self.anchor='sw'
            UI.Manager.focus(true)
            self:setFocus(false)
        end
    end
    local x2,y2 = self:mousePress(2)
    if x2 and y2 then
        self.x, self.y = x2,y2 self.anchor='nw'
        UI.Manager.focus(false)
        for i=1,#self.items do
            self.items[i]:setFocus(true)
        end
        self:setFocus(true)
    end
end


UI.Label = UI.Class(Proto,{text='', fnt=FNT, fntclr=FNTCLR,
                var=nil, com=function() end, image=nil,
                angle=0, da=0, scalex=1, scaley=1, scewx=0,scewy=0})
UI.Label.type = 'label'
function UI.Label:new(o)
    self.pivot='center'
    self:setImage(self.image)
    self:setAngle(self.angle)
    self:setDA(self.da)

    self.defclr = self.fntclr
    self.onclr = {self.fntclr[1]+0.4,self.fntclr[2]+0.4,self.fntclr[3]+0.4,1}

    self.deffrm = self.frmclr
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    if self.fnt[1] then
        self.font = love.graphics.newFont(self.fnt[1], self.fnt[2])
    else
        self.font = love.graphics.newFont(self.fnt[2])
    end

    self.repeattime = 0.4
    self.inittime = self.repeattime

    self:setup()
    UI.Manager.add(self)
end

function UI.Label:setup()
    local fargs
    if self.image then
        fargs = {self.image}
    else
        fargs = {self.font, self.text}
    end

    local wid,hei = self.getWidHei(unpack(fargs))
    self:setWidHei(wid, hei)
    -- fix problem with hbox vbox topleft setup
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end

    self.rectx, self.recty = self.getAnchor(self.x, self.y, self.wid,self.hei,
                                        self.frm, self.anchor)

    self.pivx, self.pivy = self.getPivot(wid, hei, self.pivot)
    self.cenx = self.rectx+(self.wid+self.frm*2)/2
    self.ceny = self.recty+(self.hei+self.frm*2)/2
end

function UI.Label:setAngle(angle) self.angle=math.rad(angle) end
function UI.Label:setDA(da) self.da=math.rad(da) end
function UI.Label:setImage(data)
    self.image = data and love.graphics.newImage(data)
end

function UI.Label:setColor()
    self.deffrm = self.frmclr
    self.defclr = self.fntclr
end

function UI.Label:getRepeat(event,eventarg,dt)
    if self.repeattime then
        if self.repeattime>0 then
            self.repeattime = self.repeattime-dt
        else
            self.repeattime = self.inittime/3
            local press=event(self,eventarg)
            return press
        end
    end
end

function UI.Label.getWidHei(item,other)
    local wid,hei = item:getWidth(other),item:getHeight()
    wid = wid+wid%2
    hei = hei+hei%2
    return wid,hei
end

function UI.Label:updateAngle()
    self.angle = self.angle+self.da
end

function UI.Label:update(dt)
    dt = dt or UI.getDT()
    self:updateAngle()
    self:setup()
    if self.focus and not self.hide then
        if self.var then self.text = self.var.val end
        local press = self:mouseCollidePress(1)
        return press
    end
end

function UI.Label:draw()
    if not self.hide  then
        self:drawFrame()
        love.graphics.setColor(self.defclr)
        if self.image then
            love.graphics.draw(self.image, self.cenx, self.ceny, self.angle,
                               self.scalex, self.scaley, self.pivx, self.pivy,
                               self.scewx, self.scewy)
        else
            love.graphics.setFont(self.font)
            love.graphics.print(self.text, self.cenx, self.ceny,self.angle,
                                self.scalex, self.scaley,
                                self.pivx, self.pivy,
                                self.scewx, self.scewy)
        end
        love.graphics.setColor(WHITE)
    end
end


UI.Input = UI.Class(UI.Label,{frm=2,focus=false,chars=8,mode='line'})
UI.Input.type = 'input'
function UI.Input:new(o)
    local textinput = love.textinput or function() end
    love.textinput = function(...)
        textinput(...)
        self.textinput(self,...)
    end
    self.var = self.var or {val=''}
    -- set cursor
    self.curx, self.cury = 0,0
    self.cursize=1
    if self.image then self.cursize = 0 end
    local image = self.image
    self.offset = 0
    -- init size (include left offset)
    self.chars = self.chars+1
    UI.Input.Super.new(self)
    self.cursor=UI.Label{text='',fnt={self.fnt[1],self.fnt[2]-1},
                        frmclr=self.onclr, frm=self.cursize,
                        mode='fill', image=image,da=self.da,hide=true}
    -- input setup
    self:clear(true)
end

function UI.Input:setup()
    local wid,hei = self.getWidHei(self.font,string.rep('0', self.chars))
    self:setWidHei(wid, hei)
    if not self.x or not self.y then self.x,self.y=0,0 self.anchor='sw' end
    self.rectx, self.recty = self.getAnchor(self.x, self.y, self.wid,self.hei,
                                        self.frm,self.anchor)
    self.pivx, self.pivy = self.getPivot(wid, hei, self.pivot)
    self.cenx = self.rectx+(self.wid+self.frm*2)/2
    self.ceny = self.recty+(self.hei+self.frm*2)/2
    -- left offset
    self.offwid,self.offhei=self.getWidHei(self.font,string.rep('0', 1))
    self.addsize = self.offwid*2+self.cursize*2

    if self.cursor then
        local correction = self.curx+self.frm+self.offwid-self.offset
        local cx = self.rectx+correction
        local cy = self.recty+self.frm
        -- use wid to show cursor
        self.cursor:set({x=cx,y=cy,wid=0.01,anchor='n'})
    end
end

function UI.Input:clear(init)
    self.var.val=''
    if not init then
        self.text = self.var.val
    end
    self.curpos = 0
    self.curblink = 1
    self.blink = self.curblink
    self.leftoff=1
    self.rightoff=0
    self.offset = 0
    self.curx, self.cury=self:getCursorPosition()
end

function UI.Input:getTextPosition(itext)
    local wid,_ = self.getWidHei(self.font, itext)
    local leftoff = 1
    self.offset=0
    while wid+self.addsize>self.wid do
        if wid+self.addsize-self.wid<self.offwid then
            self.offset = wid+self.addsize-self.wid
            break
        end
        itext=itext:sub(2,#itext)
        wid,_ = self.getWidHei(self.font, itext)
        leftoff = leftoff+1
    end
    return leftoff
end

function UI.Input:getCursorPosition()
    local dtxt = #self.var.val-self.curpos
    local curtext = self.text:sub(1, #self.text+self.rightoff-dtxt)
    return self.getWidHei(self.font, curtext)
end

function UI.Input:left()
    if self.curpos>=1 then self.curpos = self.curpos-1 end

    local itext = self.var.val
    self.curx, self.cury = self:getCursorPosition()
    if self.curx-self.offset<0 then
        -- local itext = self.var.val
        local righttxt = itext:sub(1,self.curpos)
        local offset,_ = self.getWidHei(self.font, righttxt)
        self.leftoff = 1
        while offset>self.offwid do
            righttxt=righttxt:sub(2,#righttxt)
            offset,_ = self.getWidHei(self.font, righttxt)
            self.leftoff = self.leftoff+1
        end
        self.offset = offset

        local lefttxt = itext:sub(self.curpos+1,#itext)
        local wid,_ = self.getWidHei(self.font,lefttxt)
        self.rightoff = 0
        while wid+self.addsize>self.wid do
            lefttxt=lefttxt:sub(1,#lefttxt-1)
            wid,_ = self.getWidHei(self.font, lefttxt)
            self.rightoff = self.rightoff+1
        end
    end
    self.text=itext:sub(self.leftoff,#itext-self.rightoff)
end

function UI.Input:right()
    if self.curpos<#self.var.val then self.curpos = self.curpos+1 end

    local curwid,_ = self.getWidHei(self.font,self.text)
    if self.curx>=curwid then
        self.leftoff = self:getTextPosition(self.var.val:sub(1,self.curpos))

        if self.rightoff>0 then self.rightoff=self.rightoff-1 end
        self.text = self.var.val:sub(self.leftoff,self.curpos)
    end
end

function UI.Input:erase()
    local itext = self.var.val
    local last = utf8.offset(itext:sub(1, self.curpos), -1)
    if last then
        itext = itext:sub(1,last-1)..itext:sub(self.curpos+1, #itext)
        self.var.val = itext
        self.curpos = self.curpos-1
    end
    self.leftoff = self:getTextPosition(itext:sub(1,#itext))
    self.text = itext:sub(self.leftoff,#itext)
end

function UI.Input:textinput(t)
    if self.focus and not self.hide then
        local itext = self.var.val
        itext = itext:sub(1,self.curpos)..t..itext:sub(self.curpos+1, #itext)
        self.var.val = itext
        self.curpos = self.curpos+1
        self.leftoff = self:getTextPosition(itext:sub(1,#itext))
        self.text = itext:sub(self.leftoff,#itext)
    end
end

function UI.Input:draw()
    if not self.hide then
        self:drawFrame()
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.defclr)
        love.graphics.print(self.text,
                            self.cenx+self.offwid-self.offset, self.ceny,
                            self.angle,self.scalex, self.scaley,
                            self.pivx, self.pivy,self.scewx, self.scewy)
        love.graphics.setColor(WHITE)
    end
end

function UI.Input:update(dt)
    dt = dt or UI.getDT()
    if self.blink>0 then self.blink = self.blink-dt
    else self.blink = self.curblink end
    -- cursor
    if self.focus and not self.hide and self.blink>self.curblink/2 then
        self.cursor:setHide(false)
    else
        self.cursor:setHide(true)
    end

    self:setup()
    if self.focus and not self.hide then
        if self:keyPress('backspace') then
            self.repeattime = self.inittime
            self:erase()
        end
        if self:getRepeat(self.keyDown,'backspace',dt) then
            self:erase()
        end

        if self:keyPress('left') then
            self.repeattime = self.inittime
            self:left()
        end
        if self:getRepeat(self.keyDown,'left',dt) then self:left() end

        if self:keyPress('right') then
            self.repeattime = self.inittime
            self:right()
        end
        if self:getRepeat(self.keyDown,'right',dt) then self:right() end

        if self:keyPress('return') then
            UI.Manager.focus(true)
            self:setFocus(false)
        end
        if self:mousePress(1) and not self:mouseCollide() then
            UI.Manager.focus(true)
            self:setFocus(false)
        end
    end

    self.curx, self.cury = self:getCursorPosition()
    local press = self:mouseCollidePress(1)
    if press and not self.focus then
        UI.Manager.focus(false)
        self.text = self.var.val:sub(self.leftoff,#self.var.val)
        self.curx, self.cury=self:getCursorPosition()
        self:setFocus(true)
    end
    return press
end

function UI.Input:remove() self.cursor:remove() UI.Manager.remove(self) end


UI.CheckBox = UI.Class(UI.Label,{frm=2, mode='fill',corner={4,4,2}})
UI.CheckBox.type = 'checkbox'
function UI.CheckBox:new(o)
    self.var = self.var or {bool=false}
    UI.CheckBox.Super.new(self)
    if self.var.bool then self.defclr=self.onclr end
end

function UI.CheckBox:update(dt)
    dt = dt or UI.getDT()
    self:updateAngle()
    self:setup()

    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        if press then
            self.var.bool = not self.var.bool
            self:com()
        end

        if self.var.bool then self.defclr = self.onclr
        else self.defclr = self.fntclr end

        return press
    end
end


UI.LabelExe = UI.Class(UI.Label,{time=60})
UI.LabelExe.type = 'labelexe'
function UI.LabelExe:update(dt)
    dt = dt or UI.getDT()
    self:updateAngle()
    self:setup()

    if self.time<=0 then self:com() self:remove() return end
    self.time = self.time-1
end


UI.Button = UI.Class(UI.Label,{frm=2,corner={4,4,2}})
UI.Button.type = 'button'
function UI.Button:update(dt)
    dt = dt or UI.getDT()
    self:updateAngle()
    self:setup()

    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        local release = self:mouseCollideRelease(1)

        if self:mouseCollide() then
            self.defclr = self.onclr
        else
            self:setColor()
        end

        if press then
            self.repeattime = self.inittime
            self.deffrm = self.onfrm
        end

        local repress = self:getRepeat(self.mouseCollideDown,1,dt)
        if repress then
            self:setColor()
            self:com()
            return repress
        end

        if release then self:setColor() self:com() end
        return press
    end
end


UI.Selector = UI.Class(UI.Label, {var={val=''},corner={4,4,2}})
UI.Selector.type = 'selector'
function UI.Selector:setup()
    if self.var.val==self.text then self.defclr = self.onclr
    else self.defclr = self.fntclr end
    UI.Selector.Super.setup(self)
end

function UI.Selector:update(dt)
    dt = dt or UI.getDT()
    self:updateAngle()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        if press then
            self.var.val = self.text
            self:com()
        end
        return press
    end
end


UI.Counter = UI.Class(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                    image=nil,step=1, min=0, max=1000})
UI.Counter.type = 'counter'
function UI.Counter:new(o)
    self.deffrm = self.frmclr
    self.var = self.var or {val=0}
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1

    self.txt = nil
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,image=self.image,
                             fnt=self.fnt, fntclr=self.fntclr}
    end

    self.right = UI.Button{text='>', fnt=self.fnt, fntclr=self.fntclr,
                com=function() self:add() end,
                frm=2, frmclr=self.frmclr, mode=self.mode}
    self.left = UI.Button{text='<', fnt=self.fnt, fntclr=self.fntclr,
                com=function() self:sub() end,
                frm=2, frmclr=self.frmclr, mode=self.mode}
    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr, var=self.var,
                    frm=2, frmclr=self.frmclr,
                    mode=self.mode}
    self.display:set({text = self.min})
    self.frm = 0
    self.items = {self.txt, self.left, self.display, self.right}
    self:setHide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.Counter:add()
    local num = self.var.val + self.step
    if num > self.max then num = self.max end
    num = tonumber(string.format('%.1f', num))
    self.var.val = num
end

function UI.Counter:sub()
    local num = self.var.val - self.step
    if num < self.min then num = self.min end
    num = tonumber(string.format('%.1f', num))
    self.var.val = num
end

function UI.Counter:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        return press
    end
end


UI.Slider = UI.Class(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                   image=nil,min=0, max=100})
UI.Slider.type = 'slider'
function UI.Slider:new(o)
    self.deffrm = self.frmclr
    self.var = self.var or {val=0}
    -- find max chars for display field
    local chars = string.len(tostring(self.max))+1
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    self.txt = nil
    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{frm=0,frmclr=self.frmclr,mode=self.mode}

    local barfrm = 2
    if self.image then barfrm = 0 end
    self.bar = UI.Label{fnt=self.fnt, fntclr=self.onfrm, image=self.image,
                frm=barfrm, frmclr=self.onfrm, mode='fill'}
    -- setup cursor wid and max len
    self:setSize()
    self.border:add(self.bar)
    -- redefine HBox update to move slider
    local borupdate = self.border:get('update')
    self.border:set({update = function(...)
                    borupdate(self.border,...)
                    local oldx = math.floor(self.bar:get('x'))
                    self.bar:set({x=oldx+self.var.val})
                    end})
    self.border:set({draw = function()
            if not self.hide then
                local frmclr = self.border:get('deffrm') or EMPTY
                love.graphics.setColor(frmclr)
                local wid = self.border:get('wid')
                local hei = self.border:get('hei')
                local frm = 2
                local rectx = self.border:get('rectx')
                local recty = self.border:get('recty')
                love.graphics.rectangle('fill',rectx+frm, recty-frm+hei/2,
                                                wid,frm*2)
                love.graphics.setColor(WHITE)
            end
            end})

    self.display = UI.Label{text=string.rep('0', chars),
                    fnt=self.fnt, fntclr=self.fntclr, var=self.var,
                    frm=2, frmclr=self.frmclr, mode=self.mode}
    self.display:set({text=self.var.val})

    self.frm = 0
    self.items = {self.txt, self.border, self.display}
    self:setHide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.Slider:setImage(data)
    self.bar:set({frm=0})
    self.bar:setImage(data)
end

function UI.Slider:setValue()
    local oldx = math.floor(self.bar:get('x'))
    local halfbarwid = self.bar:get('wid')/2
    local x,_ = self:mouseMove()
    local newx = x-halfbarwid

    if self.var.val+newx-oldx>self.max then return end
    if self.var.val+newx-oldx<self.min then return end
    self.var.val = self.var.val+newx-oldx
    -- fix mouse
    love.mouse.setPosition(newx+halfbarwid,self.bar:get('y'))
    self.bar:set({x=newx})
end

function UI.Slider:setSize()
    local barhei = self.bar:get('hei')
    self.bar:set({wid=barhei})
    local barwid = self.bar:get('wid')
    local borwid = self.max+barwid+self.border:get('frm')*2
    self.border:set{wid=borwid}
end

function UI.Slider:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        if self.bar:mouseCollideDown(1) then self:setValue() end
        return press
    end
end


UI.ProgBar = UI.Class(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                    frm=2,image=nil,barchar='|',barmode='fill',min=0,max=10})
UI.ProgBar.type = 'progbar'
function UI.ProgBar:new(o)
    self.deffrm = self.frmclr
    self.var = self.var or {val=0}

    self.barvar = {val=string.rep(self.barchar, self.max)}
    self.onfrm = {self.frmclr[1]+0.2,self.frmclr[2]+0.2,self.frmclr[3]+0.2,1}

    self.txt = nil
    if self.text and #self.text>0 then
        self.txt = UI.Label{text=self.text, fnt=self.fnt, fntclr=self.fntclr}
    end
    self.border = UI.HBox{sep=2,frm=self.frm, frmclr=self.frmclr,
                                                            mode=self.mode}
    local barfrm = 2
    if self.barmode=='line' then barfrm=0 end
    if self.barmode=='fill' then self.barchar= ' ' end
    if self.image then
        for _=1, self.max do
            self.border:add(UI.Label{text='', fnt=self.fnt, fntclr=self.onfrm,
                                var=nil, image=self.image, da=self.da,
                                frm=0,frmclr=self.onfrm})
        end
    else
        self.bar = UI.Label{text=self.barvar.val, fnt=self.fnt,
                            fntclr=self.onfrm, var=self.barvar,
                            image=self.image, frm=barfrm,
                            frmclr=self.onfrm, mode=self.barmode}
        self.border:add(self.bar)
        self.barvar.val = ''
    end
    self.frm = 0
    self.items = {self.txt, self.border}
    self:setHide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.ProgBar:setImage(data)
    local items = self.border:get('items')
    for i=1,self.max do
        items[i]:setImage(data)
    end
end

function UI.ProgBar:setValue()
    if self.var.val<self.min then self.var.val=self.min end
    if self.var.val>self.max then self.var.val=self.max end
    self.barvar.val = string.rep(self.barchar,self.var.val)
end

function UI.ProgBar:setSize()
    if self.image then
        local items = self.border:get('items')
        for i=1,self.max do
            items[i]:setHide(false)
        end
        for i=self.max,#self.barvar.val+1,-1 do
            items[i]:setHide(true)
        end
    else
        local w,h = self.bar.getWidHei(self.bar:get('font'),self.barvar.val)
        self.bar:set({wid=w,hei=h})
    end
end

function UI.ProgBar:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        self:setValue()
        self:setSize()
        return press
    end
end

UI.List = UI.Class(UI.VBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                 com=function() end,image=nil,items={},sep=4,max=4,sel=1})
UI.List.type = 'list'
function UI.List:new(o)
    self.deffrm = self.frmclr
    self.var = self.var or {val=''}
    self.txt = nil
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,fnt=self.fnt,fntclr=self.fntclr,
                            image=self.image}
    end

    self.border = UI.VBox{frm=2, sep=2, frmclr=self.frmclr,mode=self.mode}
    -- set init size
    if #self.items>self.max then self.max = #self.items end
    if #self.items==0 and self.max~=0 then
        self.items = {'Selector1','Selector2','Selector3','Selector4'}
    end
    self:add(unpack(self.items))
    -- defaul size
    local initlen = #self.items
    if initlen<self.max then
        for i=initlen+1,self.max do self:add('Selector'..i) end
    end
    self:select(self.sel)
    self.frm = 0
    self.items = {self.txt,self.border}
    self:setHide(self.hide)
    self:setup()
    -- default size
    if initlen<self.max then
        for i=self.max,initlen+1,-1 do self:delete(i) end
    end
    UI.Manager.add(self)
end

function UI.List:add(...)
    local fargs = {...}
    for i=1,#fargs do
        if type(fargs[i])=='table' then
            self.border:add(UI.Selector{text=fargs[i][1],fnt=self.fnt,
                            fntclr=self.fntclr, var=self.var,
                            com=self.com, image=fargs[i][2]})
        else
            self.border:add(UI.Selector{text=fargs[i], fnt=self.fnt,
                            fntclr=self.fntclr, var=self.var, com=self.com})
        end
    end
end

function UI.List:getItems()
    return self.border:get('items')
end

function UI.List:index(text)
    local items = self:getItems()
    for i=1, #items do if items[i]:get('text')==text then return i end end
end

function UI.List:select(index)
    local item = self:getItems()[index]
    if item then
        self.var.val = item:get('text')
        item.com()
    end
end

function UI.List:delete(index)
    self:getItems()[index]:remove()
    table.remove(self:getItems(),index)
end

function UI.List:clear()
    local items = self:getItems()
    for i=#items, 1,-1 do items[i]:remove() table.remove(items,i) end
end

function UI.List:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        local index = self:index(self.var.val)
        local items = self:getItems()
        local _,ywheel = false, false
        if self:mouseCollide() then ywheel = self:wheelMove() end
        if (self:keyPress('up') or
            (ywheel and ywheel>0)) and index>1 then
            self:select(index-1)
        end
        if (self:keyPress('down') or
            (ywheel and ywheel<0)) and index<#items then
            self:select(index+1)
        end
        return press
    end
end

UI.FoldList = UI.Class(UI.HBox,{text='',fnt=FNT,fntclr=FNTCLR,frmclr=FRMCLR,
                     image=nil,items={},sel=1})
UI.FoldList.type = 'foldlist'
function UI.FoldList:new(o)
    self.deffrm = self.frmclr
    self.var = self.var or {val=''}
    self.txt = nil
    -- set init size
    if #self.items==0 then
        self.items = {'Selector1'}
    end
    if self.text and (#self.text>0 or self.image) then
        self.txt = UI.Label{text=self.text,fnt=self.fnt,fntclr=self.fntclr,
                            image=self.image}
    end

    local maxlen = 0
    local maxtext
    for i=1,#self.items do
        local len=#self.items[i]
        local text=self.items[i]
        if type(self.items[i])=='table' then
            len=#self.items[i][1] text=self.items[i][1]
        end
        if len>maxlen then maxlen = len maxtext = text end
    end

    self.display = UI.Button{text=maxtext, fnt=self.fnt, fntclr=self.fntclr,
                    var=self.var, com=function() self:unfold() end,
                    frm=2, frmclr=self.frmclr, mode=self.mode,corner={0,0,0}}

    self:select(1)
    if self.sel<=#self.items then
        self:select(self.sel)
    end

    self.folditems = self.items

    self.frm = 0
    self.items = {self.txt,self.display}
    self:setHide(self.hide)
    self:setup()
    UI.Manager.add(self)
end

function UI.FoldList:add(...)
    local fargs = {...}
    for i=1,#fargs do self.folditems[#self.folditems+1]=fargs[i] end
end

function UI.FoldList:getItems()
    return self.folditems
end

function UI.FoldList:index(text)
    for i=1, #self.folditems do
        if type(self.folditems[i])=='table' then
            if self.folditems[i][1]==text then return i end
        else
            if self.folditems[i]==text then return i end
        end
    end
end

function UI.FoldList:select(index)
    local item = self.folditems or self.items
    local val = item[index]
    if type(val)=='table' then self.var.val = val[1]
    else self.var.val = val end
end


function UI.FoldList:delete(index) table.remove(self.folditems,index) end

function UI.FoldList:clear()
    self.folditems = {}
    self.var.val = ''
end

function UI.FoldList:fold()
    UI.Manager.focus(true)
    self.list:remove()
end

function UI.FoldList:unfold()
    local hei = self.display:get('hei')
    local frm = self.display:get('frm')

    self.list = UI.List{x=self.display:get('rectx'),
        y=self.display:get('recty')+hei+frm*2,
        anchor='nw', fnt=self.FNT, fntclr=self.FNTCLR,
        frm=2,  frmclr=self.FRMCLR, mode='fill',
        var=self.var, com=function()
                if self.display:get('text')~=self.var.val then self:fold() end
                self.display:set({text=self.var.val})
            end, items=self.folditems,max=0, sel=self:index(self.var.val)}

    UI.Manager.focus(false)
    local listitems = self.list:getItems()
    for i=1,#listitems do listitems[i]:setFocus(true) end
end

function UI.FoldList:update(dt)
    dt = dt or UI.getDT()
    self:setup()
    if self.focus and not self.hide then
        local press = self:mouseCollidePress(1)
        if (self:mousePress(1) and self.list and not
            self.list:mouseCollide()) then
            self:fold()
        end
        return press
    end
end
return UI
