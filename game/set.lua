-- Thu Aug 30 13:59:57 2018
-- (c) Alexander Veledzimovich
-- set SWARM

local fc = require('lib/fct')
local fl = require('lib/lovfl')

local SET = {
    APPNAME = love.window.getTitle(),
    VER = '1.5',
    SAVE = 'swarmsave.lua',
    FULLSCR = love.window.getFullscreen(),
    WID = love.graphics.getWidth(),
    HEI = love.graphics.getHeight(),
    MIDWID = love.graphics.getWidth() / 2,
    MIDHEI = love.graphics.getHeight() / 2,
    SCALE = 0.3,

    EMPTY = {0,0,0,0},
    WHITE = {1,1,1,1},
    BLACK = {0,0,0,1},
    RED = {1,0,0,1},
    REDF = {1,0,0,0},
    YELLOW = {1,1,0,1},
    GREEN = {0,1,0,1},
    BLUE = {0,0,1,1},

    DARKGRAY = {32/255,32/255,32/255,1},
    DARKGRAYF = {32/255,32/255,32/255,0},
    GRAY = {0.5,0.5,0.5,1},
    GRAYHHF = {0.5,0.5,0.5,32/255},
    GRAYHF = {0.5,0.5,0.5,16/255},
    GRAYF = {0.5,0.5,0.5,0},
    LIGHTGRAY = {192/255,192/255,192/255,1},
    LIGHTGRAYF = {192/255,192/255,192/255,0},

    WHITEHHHF = {1,1,1,64/255},
    WHITEHHF = {1,1,1,32/255},
    WHITEHF = {1,1,1,16/255},
    WHITEF = {1,1,1,0},

    BLACKBLUE = {32/255,32/255,64/255,1},
    DARKRED = {128/255,0,0,1},

    -- Vera Sans
    MAINFNT = 'res/fnt/Trattatello.ttf',

    IMG=fc.map(love.image.newImageData, fl.loadAll('res/img','png','jpg')),
    AUD=fc.map(function(path)
                       if path:match('[^.]+$')=='wav' then
                           return love.audio.newSource(path,'static')
                       else
                           return love.audio.newSource(path,'stream') end
                        end, fl.loadAll('res/aud','wav','mp3'))
}

SET.TITLEFNT = {SET.MAINFNT,88}
SET.MENUFNT = {SET.MAINFNT,32}
SET.GAMEFNT = {SET.MAINFNT,16}
SET.UIFNT = {SET.MAINFNT,8}

SET.BGCLR =  SET.BLACKBLUE
SET.TXTCLR = SET.WHITE
return SET
