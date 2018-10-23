-- Thu Aug 30 13:59:57 2018
-- (c) Alexander Veledzimovich
-- scr SWARM

local Tmr = require('lib/tmr')
local cls = require('lib/cls')

local ctrl = require('lib/lovctrl')
local ui = require('lib/lovui')
local cmp = require('lib/lovcmp')
local b2d = require('lib/lovb2d')
local fl = require('lib/lovfl')

local obj = require('game/obj')
local set = require('game/set')

local Proto=cls.Class({tag='proto',objects={},garbage={},particles={},
                        avatar=nil,fade=0,pause=false})
-- static cmp
Proto.getRandOffsetXY = cmp.getRandOffsetXY
-- particle
Proto.objectParticle = cmp.objectParticle
function Proto:__tostring() return self.tag end
function Proto:spawn(object)  self.objects[object] = object end
function Proto:trash(object) self.garbage[object]=object end
function Proto:destroy(object) self.objects[object] = nil end
function Proto:get_objects() return self.objects end
function Proto:get_particles() return self.particles end
function Proto:get_avatar() return self.avatar end
function Proto:get_fade() return self.fade end

function Proto:update(dt) ui.Manager.update(dt) end
function Proto:draw() love.graphics.draw(self.bg) ui.Manager.draw() end

function Proto:set_pause(pause)
    self.pause = pause or not self.pause
    self:set_label('PAUSE',self.pause)
end

function Proto:set_label(text,bool)
    if self.label then self.label:remove() end
    if bool then
        self.label = ui.Label{x=set.MIDWID,y=set.MIDHEI, text=text,
                            fnt=set.MENUFNT, fntclr=set.DARKRED, anchor='s'}
    end
end

function Proto:set_cursor()
    love.mouse.setVisible(false)
    self.cursor = self:objectParticle(4, {set.GRAY,set.WHITEHHHF,
                            set.WHITEF},'circle',{0.1,4},{1,0.1})
end

function Proto:cursor_upd()
    local x,y=ctrl:position()
    self.cursor.particle:setPosition(x,y)
    self.cursor.particle:emit(30)
end

function Proto:clear()
    self.avatar=nil
    -- clean corpses
    -- for object in pairs(self.garbage) do self.garbage[object]=nil end
    -- self.garbage={}
    for object in pairs(self.objects) do self:destroy(object) end
    self.objects={}
    for particle in pairs(self.particles) do particle:reset() end
    self.particles={}
    if self.world then self.world:destroy() end
end


local SCR = {}
SCR.Menu=cls.Class(Proto,{tag='menu',fade=1})
SCR.Menu.bg=love.graphics.newImage(set.IMG['uibg'])
function SCR.Menu:new(o)
    ui.Manager.clear()
    self.tmr = Tmr:new()
    cmp.GRAVITY = {x=0,y=10}

    b2d.setWorld(self,10,cmp.GRAVITY.x,cmp.GRAVITY.y)

    local deadhand=obj.DeadHand{screen=self,x=390,y=460,
                            scale=0.4,angle=math.rad(70),active=true}
    deadhand:turn()

    local x,y=ctrl:position()
    self.avatar=self.avatar or obj.Avatar{screen=self,x=x,y=y}

    ui.Label{x=set.MIDWID,y=set.MIDHEI-20,text=set.GAMENAME:upper(),
                                        fntclr=set.GRAY,
                                        fnt=set.TITLEFNT}

    local oldscore = fl.loadLove(set.SAVE) or {42}
    ui.Label{text=oldscore[1],x=556,y=427,
            fntclr=set.GRAY,fnt=set.GAMEFNT,angle=10}

    self:set_cursor()

    set.AUD['swamp']:setVolume(0.3)
    set.AUD['swamp']:setLooping(true)
    set.AUD['swamp']:play()

    self.set_pause = function() end
end

function SCR.Menu.beginContact(obj1, obj2, coll)
    local ud1=obj1:getUserData()
    local ud2=obj2:getUserData()
    if ud1.tag=='swarm' and ud2.tag=='deadhand' then
        ud1,ud2 = ud2,ud1
    end
    if ud1.tag=='deadhand' and ud2.tag=='swarm' then
        ud2:catch()
        SCR.Menu.fade = SCR.Menu.fade-0.01
    end
end

function SCR.Menu:update(dt)
    -- ui
    ui.Manager.update(dt)

    self:cursor_upd()
    for particle in pairs(self.particles) do
        particle:update(dt)
        if particle:getCount()==0 then
            particle:reset()
            self.particles[particle]=nil
        end
    end
    -- objects
    for object in pairs(self.objects) do
        if object.update then object:update(dt) end
    end
    -- box2d to avoid problem with destroy
    if not self.world:isDestroyed() then self.world:update(dt) end

    if self.fade<=0.1 then SCR.Menu.fade=1 love.audio.stop() love:game() end
end

function SCR.Menu:draw()
    love.graphics.setColor({self.fade,self.fade,self.fade,1})
    love.graphics.draw(self.bg)
    -- items
    for item in pairs(self.objects) do if item.draw then item:draw() end end
    -- particle
    for particle in pairs(self.particles) do love.graphics.draw(particle) end
    ui.Manager.draw()
end


SCR.Game=cls.Class(Proto,{tag='game'})
SCR.Game.bg=love.graphics.newImage(set.IMG['bg'])
SCR.Game.fg=love.graphics.newImage(set.IMG['fg'])
function SCR.Game:new(o)
    ui.Manager.clear()
    self.tmr = Tmr:new()

    cmp.GRAVITY = {x=0,y=10}
    b2d.setWorld(self,10,cmp.GRAVITY.x,cmp.GRAVITY.y)

    self:set_objects()
    self:set_cursor()

    self.fog=self:objectParticle(10, {set.WHITEF,set.WHITEHF,set.GRAYF},
                                set.IMG['fog'], {6,12}, {0.1,10}, 1)
    self.fog.particle:setRotation(0.3, 1)
    self.fog.particle:setEmitterLifetime(-1)
    self.fog.particle:emit(1)

    self.cloud = self:objectParticle(1, {set.GRAYHF,set.WHITEHHHF,set.GRAYF},
                                set.IMG['cloud'], {30,40}, {0.8,1.5}, 0.01)
    self.cloud.particle:setSpeed(10,40)
    self.cloud.particle:setPosition(set.MIDWID,0)
    self.cloud.particle:setEmissionArea('uniform', 200, 100, 0.3)
    self.cloud.particle:setRotation(0, 0)
    self.cloud.particle:setSpin(0, 0)
    self.cloud.particle:emit(40)
    self.cloud.particle:setPosition(-set.IMG['cloud']:getWidth(),0)

    self.fade=0
    self.tmr:tween(4, self, {fade=1},'linear',
                    function() self.deadhand:show_score(0) end)
    set.AUD['swamp']:stop()
    set.AUD['wood']:setVolume(0.4)
    set.AUD['wood']:setLooping(true)
    set.AUD['wood']:play()
end

function SCR.Game:set_objects()
    local x,y=ctrl:position()

    obj.Ground{screen=self,x=set.MIDWID,y=set.HEI}
    obj.Spider{screen=self,x=740,y=365}
    obj.Owl{screen=self,x=190,y=226}
    self.deadhand=obj.DeadHand{screen=self,x=405,y=460}

    self.zombie = 12
    for _=1,self.zombie do
        local zx = love.math.random(set.WID)
        local zy = love.math.random(set.HEI-40,set.HEI-20)
        obj.Zombie{screen=self,x=zx,y=zy}
    end

    self.avatar=self.avatar or obj.Avatar{screen=self,x=x,y=y}

    self.score = {val=nil}
    ui.Label{x=392,y=428,var=self.score,
                fntclr=set.GRAY,fnt=set.GAMEFNT,angle=10}
end


function SCR.Game:get_score() return self.score.val end
function SCR.Game:set_score(score) self.score.val = score end

function SCR.Game:destroy(...)
    self.Super.destroy(self,...)
    self.zombie=self.zombie-1
    if self.zombie==0 then
        local scrscore=(fl.loadLove(set.SAVE) or {0})[1]
        self.tmr:after(3,function()
            if self.score.val > scrscore then scrscore = self.score.val end
            fl.saveLove(set.SAVE,'return {'..scrscore..'}')
            love:startgame()
            end)
    end
end

function SCR.Game.beginContact(obj1, obj2, coll)
    local ud1=obj1:getUserData()
    local ud2=obj2:getUserData()
    if ud1.tag=='swarm' and ud2.tag=='ground' then
        ud1,ud2 = ud2,ud1
    end
    if ud1.tag=='ground' and ud2.tag=='swarm' then
        obj.Swarm.set_done(true)
        ud2:splash(ud2.wid,set.BLACK)
        ud2.groundaud:play()
    end
    if ud1.tag=='zombie' and ud2.tag=='swarm' then
        ud1,ud2 = ud2,ud1
    end
    if ud1.tag=='swarm' and ud2.tag=='zombie' then
        ud1:catch(ud2)
    end
    if ud1.tag=='zombie' and ud2.tag=='zombie' then
        ud2:set_dead(false)
        ud1:turn()
        ud2:turn()
    end
    if ud1.tag=='zombie' and ud2.tag=='ground' then
        ud1,ud2 = ud2,ud1
    end
    if ud1.tag=='ground' and ud2.tag=='zombie' then
        if ud2:get_dead() then
            ud2:destroy()
        end
        if (math.abs(ud2.xvel)>50 or math.abs(ud2.yvel)>100) then
            ud2.dust.particle:emit(25)
        end
    end
end

function SCR.Game:update(dt)
    -- ui
    ui.Manager.update(dt)
    self:cursor_upd()

    if self.pause then return end

    -- garbage
    for object in pairs(self.garbage) do
        if object.update then object:update(dt) end
    end
    -- objects
    for object in pairs(self.objects) do
        if object.update then object:update(dt) end
    end

    for particle in pairs(self.particles) do
        particle:update(dt)
        if particle:getCount()==0 then
            particle:reset()
            self.particles[particle]=nil
        end
    end

    local randx,randy=self.getRandOffsetXY(nil, nil, set.WID, set.HEI, 'rand')
    self.fog.particle:setEmissionRate(love.math.random(1,3))
    self.fog.particle:setPosition(randx,randy)

    local cloud_emit=love.math.random(9)
    if cloud_emit==1 then self.cloud.particle:emit(cloud_emit) end

    -- box2d to avoid problem with destroy
    if not self.world:isDestroyed() then self.world:update(dt) end
end

function SCR.Game:draw()
    love.graphics.setColor({self.fade,self.fade,self.fade,1})
    love.graphics.draw(self.bg)
    -- garbage
    for object in pairs(self.garbage) do
        if object.draw then object:draw() end
    end
    -- objects
    for object in pairs(self.objects) do
        if object.draw then object:draw() end
    end
    -- grass
    love.graphics.draw(self.fg,-14,set.HEI-85)
    -- particle
    for particle in pairs(self.particles) do love.graphics.draw(particle) end
    -- ui
    ui.Manager.draw()
end

return SCR
