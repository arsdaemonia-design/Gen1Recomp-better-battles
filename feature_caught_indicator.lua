return function(mod, services)
    local PaletteFX = require("src.render.PaletteFX")
    
    local POKEBALL_PIXELS = {
        " 0000 ",
        "011110",
        "011110",
        "000000",
        "020020",
        "022220",
        " 0000 "
    }

    local POKEBALL_VARIANTS = {
        classic = {
            ["0"] = {0, 0, 0, 1},       -- Borde negro
            ["1"] = {0.8, 0.2, 0.2, 1}, -- Rojo
            ["2"] = {1, 1, 1, 1},       -- Blanco
        },
        monochrome = {
            ["0"] = {0, 0, 0, 1},       -- Borde negro
            ["1"] = {0.4, 0.4, 0.4, 1}, -- Gris oscuro
            ["2"] = {1, 1, 1, 1},       -- Blanco/Gris claro
        }
    }
    local function getVariant(game)
        if not game or not game.save or not game.save.modData then return "classic" end
        local modData = game.save.modData["better-battles"]
        if not modData then return "classic" end
        return modData["caught_color"] or "classic"
    end

    local function drawPokedexIcon(game, x, y, scale, isTrueColor)
        local colors = POKEBALL_VARIANTS[getVariant(game)]
        for row = 1, #POKEBALL_PIXELS do
            local line = POKEBALL_PIXELS[row]
            for col = 1, #line do
                local char = line:sub(col, col)
                if colors[char] then
                    love.graphics.setColor(unpack(colors[char]))
                    local px = x + (col - 1) * scale
                    local py = y + (row - 1) * scale
                    love.graphics.rectangle("fill", px, py, scale, scale)
                    if isTrueColor then
                        PaletteFX.markTrueColor(px, py, scale, scale)
                    end
                end
            end
        end
    end

    local function isFeatureEnabled(game)
        if not game or not game.save or not game.save.modData then return true end
        local modData = game.save.modData["better-battles"]
        if not modData then return true end
        if modData["caught_indicator"] == nil then return true end
        return modData["caught_indicator"]
    end

    local BattleState = require("src.battle.BattleState")
    local original_draw = BattleState.draw
    
    function BattleState:draw(...)
        original_draw(self, ...)
        
        if not isFeatureEnabled(self.game) then return end
        
        -- Solo aplica para batallas salvajes
        if self.kind ~= "wild" then return end
        
        local dex = self.game and self.game.save and self.game.save.pokedex
        local caught = dex and dex.owned and dex.owned[self.enemy.mon and self.enemy.mon.species] or false
        
        if not caught then return end
        
        -- Si el HUD enemigo está oculto, no dibujar
        if self.enemySendingOut or self.introBalls or (self.enemy and self.enemy.fainted) then return end
        local slide = (self.introSlide or 0) * 4
        if slide ~= 0 then return end
        
        local pcanvas = love.graphics.getCanvas()
        local pr, pg, pb, pa = love.graphics.getColor()
        local pshader = love.graphics.getShader()
        local pblendMode, pblendAlpha = love.graphics.getBlendMode()
        
        local x, y, scale
        local isTrueColor = true
        
        local function getEnemyNameX()
            local len = string.len(self.enemy and self.enemy.name or "")
            return 8 + (len <= 2 and 16 or len <= 4 and 8 or 0)
        end
        
        local shot = self.dramaticShapeShot
        local isVoxel = shot and shot.canvas and shot.scale
        
        local fx = self.fx
        local sx = fx and fx.shakeX or 0
        local sy = fx and fx.shakeY or 0
        
        if isVoxel then
            scale = shot.scale
            x = (getEnemyNameX() - 8) * scale
            y = shot.ly + 8 * scale
            love.graphics.setCanvas(shot.canvas)
            isTrueColor = false
        elseif self:wideLayout() then
            scale = 1
            x = 112 + sx + 1
            y = 7 + sy + 1
        else
            scale = 1
            local hudShake = fx and fx.hudShakeX or 0
            x = 7 + sx + hudShake + 1
            y = 7 + sy + 1
        end
        
        love.graphics.setShader()
        love.graphics.setBlendMode("alpha", "alphamultiply")
        drawPokedexIcon(self.game, x, y, scale, isTrueColor)
        
        love.graphics.setBlendMode(pblendMode, pblendAlpha)
        love.graphics.setShader(pshader)
        love.graphics.setColor(pr, pg, pb, pa)
        love.graphics.setCanvas(pcanvas)
    end
end
