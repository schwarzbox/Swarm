-- Thu Aug 30 13:59:57 2018
-- (c) Alexander Veledzimovich
-- obj SWARM

local Tmr = require('lib/tmr')
local fc = require('lib/fct')
local cls = require('lib/cls')
local cmp = require('lib/lovcmp')
local imd = require('lib/lovimd')
local b2d = require('lib/lovb2d')
local ctrl = require('lib/lovctrl')
local set = require('game/set')

local Proto = cls.Class({tag='proto',node=nil, x=nil, y=nil, dx=0, dy=0,
                        angle=0, da=0, scale=set.SCALE})
-- const
Proto.imgdata = imd.fromMatrix({{1}}, set.GRAY, 1)
-- cmp
Proto.setObject = cmp.setObject
Proto.setSprite = cmp.setSprite
Proto.animateSprite = cmp.animateSprite

Proto.rotate = cmp.rotate
Proto.linearDamping = cmp.linearDamping
Proto.border = cmp.outScreen
Proto.circleView = cmp.circleView
Proto.target = cmp.target
Proto.getDirection = cmp.getDirection
-- particle
Proto.destroyParticle = cmp.destroyParticle
Proto.objectParticle = cmp.objectParticle
Proto.boom = cmp.nodeParticle

function Proto:new(o)
    self:setObject()
    self.tmr = Tmr:new()
    self.node:spawn(self)
end

function Proto:__tostring() return self.tag end

function Proto:draw()
    love.graphics.draw(self.image,self.quad, self.x, self.y, self.angle,
                            self.scale, self.scale, self.pivx, self.pivy)
    for particle in pairs(self.particles) do love.graphics.draw(particle) end
end

function Proto:update(dt)
    self:linearDamping(dt)
    self:updateXY(dt)
    self:updateAngle(dt)
    self:updateRect()
end

function Proto:see_swarm()
    local swarms = self.node:get_avatar():get_swarm()
    local run = 1
    for i=1,#swarms do
        if self:circleView(swarms[i].x,swarms[i].y) then
            local x,_=self.getDirection(self.x,self.y,
                                         swarms[i].x,swarms[i].y)
            if math.floor(self.dy+0.5)==0 then
                if x>0 then
                    self.dir=-1
                else
                    self.dir=1
                end
            end
            return run*2
        end
    end
    return run
end

function Proto:turn() self.dir=-self.dir end

function Proto:splash(wid,color,time,accel)
    time=time or {0.2,0.5}
    accel=accel or 500
    self:boom(self.x, self.y, 96, {wid},{set.WHITEF,color,set.GRAYF},
                                        'circle',time, {0.2,1}, accel)
end

local O={}
O.Ground = cls.Class(Proto,{tag='ground', body='static',collider='rectangle'})
O.Ground.imgdata = imd.fromMatrix({{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                                   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}},
                                   set.EMPTY, 100)
function O.Ground:new(o)
    self.Super.new(self,o)
    b2d.setBody(self, self.node:getWorld())
end

O.Spider = cls.Class(Proto,{tag='spider',collider='circle'})
O.Spider.imgdata = set.IMG['spider']
O.Spider.speed = 16
O.Spider.viewrange = 100
function O.Spider:new(o)
    self.Super.new(self,o)
    self.initx = self.x
    self.inity = self.y
    self.dir = 1
    self.tmr:every(3,function() self.dir = love.math.random(-1,1) end)
end

function O.Spider:draw()
    love.graphics.setColor(set.BLACK)
    love.graphics.line(self.initx,self.inity,self.x,self.y)
    local fade = self.node:get_fade()
    love.graphics.setColor({fade,fade,fade,1})
    self.Super.draw(self)
end

function O.Spider:update(dt)
    self.Super.update(self,dt)
    if self.y>=self.inity+70 or self.y<self.inity then
        self:turn()
    end
    self:setDY(self.dir*self.speed)
end

O.Owl = cls.Class(Proto,{tag='owl',collider='circle'})
O.Owl.imgdata = imd.slice(set.IMG['owl'],76,99,1,1)[1]
O.Owl.atldata = set.IMG['owl']
function O.Owl:new(o)
    self.Super.new(self,o)
    self:setSprite(self.atldata,76,99,2,1)
    self.owl_anim = self:animateSprite(1,2,5)
end

function O.Owl:update(dt)
    self.owl_anim.update(dt)
end

O.DeadHand = cls.Class(Proto,{tag='deadhand', body='kinematic',
                     collider={-50,-4,-35,-4,-35,4,-50,4}, active=false})
O.DeadHand.imgdata = set.IMG['deadhand']
O.DeadHand.torque = math.rad(2)
function O.DeadHand:new()
    self.Super.new(self,o)
    if self.active then
        b2d.setBody(self, self.node:getWorld())
        self.body:setGravityScale(0)
    end
    self.dust = self:objectParticle(8, {set.GRAY,set.DARKGRAY,set.DARKGRAYF},
                                  'circle',{0.1,4},{1,0.1},4)
    self.dust.particle:setEmissionArea('uniform', 8, 8, 1)
    self.pivx = self.imgdata:getWidth()-20
    self.pivy = 20
    self.scoretmr = nil
end

function O.DeadHand:update(dt)
    self.Super.update(self,dt)
    self.dust.update(dt,'center',{-self.wid+20,0},-love.math.random(20))
    -- update body
    if self.active then
        self.body:setPosition(self.x,self.y)
        self.body:setAngle(self.angle)
    end
end

function O.DeadHand:turn()
    self.tmr:tween(5,self,{angle=math.pi/2},'linear',
            function() self.tmr:tween(5,self,
                                {angle=math.rad(70)},'linear',
                                function()self:turn()end)end)
end

function O.DeadHand:emitdust()
    if ((math.floor(self.rect.left[1]) == 385 and
        math.floor(self.rect.left[2]) == 441) or
        (math.floor(self.rect.left[1]) == 400 and
        math.floor(self.rect.left[2]) == 433)) then
        self.tmr:during(0.6,function() self.dust.particle:emit(100) end)
    end
end

function O.DeadHand:show_score(score)
    local side = 1
    local scrscore = self.node:get_score() or 0
    if self.angle>math.pi/2 then side=-1 end
    if scrscore<score then scrscore = score end
    if not self.scoretmr then
        self.scoretmr = self.tmr:during(1.5,function()
                        self:rotate(side) self:emitdust() end,
                        function() self:setDA(0)
                                self.node:set_score(math.floor(scrscore))
                                self.tmr:clear()
                                self.scoretmr = nil
                        end)
    end
end

O.Zombie = cls.Class(Proto,{tag='zombie',collider={-13,-23,13,-25,
                                                13,6,-13,6}})
O.Zombie.imgdata = imd.slice(set.IMG['zombie'],128,196,1,1)[1]
O.Zombie.atldata = imd.slice(set.IMG['zombie'],640,196,1,1)[1]
O.Zombie.flip = love.graphics.newImage(imd.rotate(O.Zombie.atldata,
                                                      'HFLIP'))
O.Zombie.flip:setFilter('nearest', 'linear')
O.Zombie.dstdata = imd.splash(O.Zombie.imgdata,40,20,set.RED)
O.Zombie.speed = 32
O.Zombie.viewrange = 128

function O.Zombie:new(o)
    self.Super.new(self,o)
    b2d.setBody(self, self.node:getWorld())

    self.rleg = love.physics.newPolygonShape({-11,6,4,6,
                                                4,28,-11,28})
    self.lleg = love.physics.newPolygonShape({-4,6,11,6,
                                                11,28,-4,28})
    self.leg = self.rleg
    self.fixture_leg = love.physics.newFixture(self.body, self.leg,
                                               self.fixture:getDensity())
    self.fixture_leg:setUserData(self)

    self.body:setMass(2)
    self.body:setGravityScale(3)
    self.body:setInertia(50)
    self.fixture:setFriction(0.8)
    self.fixture_leg:setFriction(1)

    local dir = {-1,1}
    self.dir = dir[love.math.random(1,2)]

    self:setSprite(self.atldata,128,196,5,1)
    self.zombie_anim = self:animateSprite(1,5,0.8)


    self.dust = self:objectParticle(1, {set.DARKGRAYF,set.GRAYHF,
                            set.DARKGRAYF},set.IMG['fog'],{1,6},{0.1,1})
    self.walkdust = self:objectParticle(1, {set.DARKGRAYF,set.GRAYHF,
                            set.DARKGRAYF},set.IMG['fog'],{1,4},{0.1,0.2})

    local speak = {set.AUD['monster1']:clone(),set.AUD['monster2']:clone()}
    speak = fc.randval(speak)
    speak:setVolume(0.2)
    self.tmr:every(love.math.random(16,32),function() speak:play() end)

    self.walkaud = set.AUD['gravelwalk']
    self.walkaud:setVolume(0.2)
    self.deadaud = set.AUD['dead']:clone()
    self.deadaud:setVolume(0.6)
    self.flyaud = set.AUD['fly']:clone()
    love.audio.setEffect('effect',{type='distortion',gain=0.8,edge=0.5})
    self.flyaud:setEffect('effect')
    self.flyaud:setVolume(0.5)

end

function O.Zombie:update(dt)
    self.body:applyForce(self.dx, self.dy)
    self.body:applyTorque(self.da)
    self.body:setLinearDamping(0.2)
    self.body:setAngularDamping(1)
    -- update xy & angle
    self.x,self.y = self.body:getPosition()
    self.angle = self.body:getAngle()

    local run = self:see_swarm()
    if math.floor(self.dy+0.5)>=0 then
        self.angle = 0
        self:setDX(self.dir*self.speed*run)
        self.zombie_anim.setSpeed(run)

        if self.dir<0 then
            self.leg = self.lleg
            self.zombie_anim.setAtlas(self.flip)
        else
            self.leg = self.rleg
            self.zombie_anim.setAtlas()
        end
        self.walkdust.particle:emit(1)
        self.walkaud:play()
    end

    if self:border(set.WID,set.HEI) then
        local x = self.x+set.WID
        self.x = (self.x<0) and x or 0
    end

    if self.y<set.MIDWID then
        self.flyaud:play()
        self:set_dead(true)
    end

    self.zombie_anim.update(dt)
    self.dust.update(dt,'center',{0,0},-love.math.random(10))
    self.walkdust.update(dt,'bot',{0,0},love.math.random(10))

    self.Super.update(self,dt)
    -- update body
    self.body:setPosition(self.x,self.y)
    self.body:setAngle(self.angle)
    self.xvel,self.yvel = self.body:getLinearVelocity()
end

function O.Zombie:get_dead() return self.dead end
function O.Zombie:set_dead(bool) self.dead=bool end

function O.Zombie:destroy()
    self.node.deadhand:show_score(self.yvel)
    self.deadaud:play()
    for particle in pairs(self.particles) do particle:reset() end

    O.Corpse{node=self.node,x=self.x,y=self.y,angle=self.angle}
    self:splash(self.wid/4,set.RED,{0.1,1},800)
    self:destroyParticle({6,6},{0.1,2},1000)
    self.body:destroy()
    self.node:destroy(self)
end

O.Corpse =  cls.Class(Proto,{tag='corpse',collider='circle'})
O.Corpse.imgdata = imd.slice(set.IMG['zombie'],128,156,6,1)[6]
function O.Corpse:new(o)
    self:setObject()
    self.tmr = Tmr:new()
    self:setImage(love.graphics.newImage(imd.splash(O.Corpse.imgdata,10,10)))

    self.dust = self:objectParticle(1, {set.DARKGRAYF,set.GRAYHF,
                            set.DARKGRAYF},set.IMG['fog'],{1,4},{0.1,1})
    self.blood = self:objectParticle(1, {set.DARKRED,set.RED,
                            set.REDF},set.IMG['fog'],{0.01,0.2},{0.01,0.08})
    self.blood.particle:setEmissionArea('uniform', 35, 35, 1)
    self.blood.particle:setSpin(1,2)
    self.tmr:during(0.5,function() self.dust.particle:emit(10) end)
    self.tmr:during(0.8,function() self.blood.particle:emit(100) end)
    self.node:trash(self)
end

function O.Corpse:update(dt)
    self.Super.update(self,dt)
    self.dust.update(dt,'center',{0,0},-love.math.random(10))
    self.blood.update(dt,'center',{0,0},-love.math.random(100,300),
                                    math.rad(love.math.random(0,180)))
end

O.Avatar = cls.Class({tag='avatar',node=nil,x=nil,y=nil,dx=0,dy=0,num=96})
function O.Avatar:new(o)
    self.swarm = {}
    self.tmr = Tmr:new()

    local delta=96
    for i=1, self.num do
        local x = love.math.random(self.x-delta,self.x+delta)
        local y = love.math.random(self.y-delta,self.y+delta)
        self.swarm[i] = O.Swarm{node=self.node,x=x,y=y}
    end
    self.node:spawn(self)
    O.Swarm:set_goal(self.x,self.y)

    self.flyaud = set.AUD['idle']:clone()
    for i=1,4 do
        local flyaud = set.AUD['idle']:clone()
        love.audio.setEffect('effect',{type='echo',delay=0.5,spread=0.5})
        flyaud:setEffect('effect')
        self.tmr:every(love.math.random(0,i+4),function()
                                                love.audio.stop(flyaud)
                                                flyaud:play()
                                                end)
    end
end

function O.Avatar:get_swarm() return self.swarm end

function O.Avatar:update(dt)
    local x,y = ctrl:position()
    if O.Swarm.done then
        O.Swarm:set_goal(x,y)
        O.Swarm.set_done(false)
    end
    self.flyaud:play()
end

O.Swarm = cls.Class(Proto, {tag='swarm'})
O.Swarm.imgdata = imd.fromMatrix({{1}}, set.GRAY, 8)
O.Swarm.speed = 96
O.Swarm.torque = math.rad(180)
O.Swarm.maxtorque = math.rad(180)
O.Swarm.goal = {0,0}
function O.Swarm:new(o)
    self.Super.new(self,o)
    b2d.setBody(self, self.node:getWorld())
    self.fixture:setRestitution(1.3)

    self.tail = self:objectParticle(3, {set.DARKGRAY,set.GRAYHHF,
                            set.DARKGRAYF},'circle',{0.1,5},{1,0.1})
    self.hitaud = set.AUD['hit']:clone()
    self.hitaud:setVolume(0.2)
    self.groundaud = set.AUD['ground']:clone()
    self.groundaud:setVolume(0.05)
end

function O.Swarm.set_done(bool) O.Swarm.done=bool end
function O.Swarm:set_goal(x,y) self.goal[1]=x self.goal[2]=y end
function O.Swarm:get_goal()
    if O.Swarm.goal[1]==math.floor(self.x) and
        O.Swarm.goal[2]==math.floor(self.y) then
        O.Swarm.set_done(true)
    end
end

function O.Swarm:update(dt)
    self:get_goal()
    -- new force
    self.body:applyForce(self.dx, self.dy)
    self.body:applyTorque(self.da)
    -- update xy & angle
    self.x,self.y = self.body:getPosition()
    self.angle = self.body:getAngle()

    local side
    self.dx,self.dy,side = self:target(self.goal[1],self.goal[2],true)
    self:rotate(side)
    self.Super.update(self,dt)

    self.tail.update(dt,'left',{0,0},-love.math.random(4))
    self.tail.particle:emit(1)
    -- update body
    self.body:setPosition(self.x,self.y)
    self.body:setAngle(self.angle)
end

function O.Swarm:catch(obj)
    if obj then obj:setDY(-self.speed) end
    self:splash(self.wid,set.RED)
    self.hitaud:play()
end

return O
