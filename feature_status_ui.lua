return function(mod, services)
    local BattleState = require("src.battle.BattleState")
    local WideBattle = require("src.battle.WideBattle")
    local PaletteFX = require("src.render.PaletteFX")
    
    local STATUS_COLORS = {
        PSN = {0.8, 0.2, 0.8},
        BRN = {1.0, 0.3, 0.0},
        PAR = {1.0, 0.8, 0.0},
        FRZ = {0.4, 0.8, 1.0},
        SLP = {0.8, 0.8, 0.8},
    }

    local function isFeatureEnabled(game)
        if not game or not game.save or not game.save.modData then return true end
        local modData = game.save.modData["better-battles"]
        if not modData then return true end
        if modData["status_ui"] == nil then return true end
        return modData["status_ui"]
    end

    -- 1. Texto flotante sobre el Pokémon
    local original_drawBattlerPic = BattleState.drawBattlerPic
    function BattleState:drawBattlerPic(battler, x, y, scale)
        original_drawBattlerPic(self, battler, x, y, scale)
        if not isFeatureEnabled(self.game) then return end
        
        if battler and battler.shownStatus then
            local text = self:statusLabel({ status = battler.shownStatus })
            if text then
                local c = STATUS_COLORS[text] or {1, 1, 1}
                local r, g, b, a = love.graphics.getColor()
                
                local t = love.timer.getTime()
                local bob = math.sin(t * 4) * 4
                
                local img = self:picImage(battler.sprite)
                local w = img:getWidth() * scale
                
                local font = love.graphics.getFont()
                local textW = font:getWidth(text)
                
                local s_factor = 0.6
                
                love.graphics.push()
                love.graphics.translate(x + w/2 - (textW * s_factor)/2, y + 6 + bob)
                
                local isVoxel = self.dramaticShapeShot ~= nil
                if isVoxel and battler == self.player then
                    love.graphics.translate((textW * s_factor) / 2, 0)
                    love.graphics.scale(-1, 1)
                    love.graphics.translate(-(textW * s_factor) / 2, 0)
                end
                
                love.graphics.scale(s_factor, s_factor)
                
                love.graphics.setColor(c[1], c[2], c[3], 1)
                love.graphics.print(text, 1, 0)
                love.graphics.print(text, 0, 1)
                love.graphics.print(text, 1, 1)
                love.graphics.print(text, 0, 0)
                
                love.graphics.pop()
                love.graphics.setColor(r, g, b, a)
            end
        end
    end

    -- 2. Sistema de degradados dinámicos
    local gradientMesh = nil
    local function getGradientMesh()
        if not gradientMesh then
            gradientMesh = love.graphics.newMesh({
                {0, 0, 0, 0, 1, 1, 1, 1},
                {1, 0, 1, 0, 1, 1, 1, 1},
                {1, 1, 1, 1, 1, 1, 1, 1},
                {0, 1, 0, 1, 1, 1, 1, 1},
            }, "fan", "dynamic")
        end
        return gradientMesh
    end

    -- 3. Ocultar el estado en el HUD
    local original_drawHUDs = BattleState.drawHUDs
    function BattleState:drawHUDs(slide)
        if not isFeatureEnabled(self.game) then
            return original_drawHUDs(self, slide)
        end
        
        local real_p = self.player and self.player.shownStatus
        local real_e = self.enemy and self.enemy.shownStatus
        if self.player then self.player.shownStatus = nil end
        if self.enemy then self.enemy.shownStatus = nil end
        local ret = original_drawHUDs(self, slide)
        if self.player then self.player.shownStatus = real_p end
        if self.enemy then self.enemy.shownStatus = real_e end
        return ret
    end

    local original_wideDraw = WideBattle.draw
    function WideBattle.draw(battle)
        if not isFeatureEnabled(battle.game) then
            return original_wideDraw(battle)
        end
        
        local real_p = battle.player and battle.player.shownStatus
        local real_e = battle.enemy and battle.enemy.shownStatus
        if battle.player then battle.player.shownStatus = nil end
        if battle.enemy then battle.enemy.shownStatus = nil end
        local ret = original_wideDraw(battle)
        if battle.player then battle.player.shownStatus = real_p end
        if battle.enemy then battle.enemy.shownStatus = real_e end
        return ret
    end

    -- 4. Dibujar Degradados en la Capa UI
    local original_draw = BattleState.draw
    function BattleState:draw(...)
        original_draw(self, ...)
        if not isFeatureEnabled(self.game) then return end
        
        local e_cond = self.enemy and not self.showEnemyTrainer and not self.enemySendingOut and not self.enemy.fainted
        local p_cond = self.player and not self.safari and not self.demo and not self.showPlayerBack
        local e_status = e_cond and self.enemy.shownStatus or nil
        local p_status = p_cond and self.player.shownStatus or nil
        local slide = (self.introSlide or 0) * 4
        
        if (p_status or e_status) and slide == 0 then
            love.graphics.push()
            
            local pcanvas = love.graphics.getCanvas()
            local pr, pg, pb, pa = love.graphics.getColor()
            local pshader = love.graphics.getShader()
            local pblendMode, pblendAlpha = love.graphics.getBlendMode()
            
            local shot = self.dramaticShapeShot
            local isVoxel = shot and shot.canvas and shot.scale
            
            local mesh = getGradientMesh()
            
            if isVoxel then
                love.graphics.setCanvas(shot.canvas)
                love.graphics.setShader()
                love.graphics.setBlendMode("add", "alphamultiply")
                
                local s = shot.scale
                local ex, ey, ew, eh = 0, shot.ly + 19 * s, 78 * s, 9 * s
                local pw, ph = 76 * s, 9 * s
                local px, py = shot.pw - 86 * s, shot.ly + 83 * s
                local max_opacity = 0.8
                
                if e_status then
                    local text = self:statusLabel({ status = e_status })
                    if text then
                        local c = STATUS_COLORS[text] or {1, 1, 1}
                        mesh:setVertex(1, 0, 0, 0, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(2, 1, 0, 1, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(3, 1, 1, 1, 1, c[1], c[2], c[3], max_opacity)
                        mesh:setVertex(4, 0, 1, 0, 1, c[1], c[2], c[3], max_opacity)
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(mesh, ex, ey, 0, ew, eh)
                    end
                end
                
                if p_status then
                    local text = self:statusLabel({ status = p_status })
                    if text then
                        local c = STATUS_COLORS[text] or {1, 1, 1}
                        mesh:setVertex(1, 0, 0, 0, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(2, 1, 0, 1, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(3, 1, 1, 1, 1, c[1], c[2], c[3], max_opacity)
                        mesh:setVertex(4, 0, 1, 0, 1, c[1], c[2], c[3], max_opacity)
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(mesh, px, py, 0, pw, ph)
                    end
                end
            else
                local OriginalGameBoyCanvas = nil
                local canvases = love.graphics.getCanvas()
                if type(canvases) == "table" and canvases[1] then
                    OriginalGameBoyCanvas = canvases[1]
                end
                love.graphics.setCanvas(OriginalGameBoyCanvas or love.graphics.getCanvas())
                
                love.graphics.setShader()
                love.graphics.setBlendMode("alpha", "alphamultiply")
                
                local ex, ey, ew, eh = 0, 19, 78, 9
                local px, py, pw, ph = 74, 83, 76, 9
                local max_opacity = 0.35
                
                if e_status then
                    local text = self:statusLabel({ status = e_status })
                    if text then
                        local c = STATUS_COLORS[text] or {1, 1, 1}
                        mesh:setVertex(1, 0, 0, 0, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(2, 1, 0, 1, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(3, 1, 1, 1, 1, c[1], c[2], c[3], max_opacity)
                        mesh:setVertex(4, 0, 1, 0, 1, c[1], c[2], c[3], max_opacity)
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(mesh, ex, ey, 0, ew, eh)
                        if PaletteFX and PaletteFX.markTrueColor then
                            PaletteFX.markTrueColor(math.max(0, ex), math.max(0, ey), ew, eh)
                        end
                    end
                end
                
                if p_status then
                    local text = self:statusLabel({ status = p_status })
                    if text then
                        local c = STATUS_COLORS[text] or {1, 1, 1}
                        mesh:setVertex(1, 0, 0, 0, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(2, 1, 0, 1, 0, c[1], c[2], c[3], 0.0)
                        mesh:setVertex(3, 1, 1, 1, 1, c[1], c[2], c[3], max_opacity)
                        mesh:setVertex(4, 0, 1, 0, 1, c[1], c[2], c[3], max_opacity)
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(mesh, px, py, 0, pw, ph)
                        if PaletteFX and PaletteFX.markTrueColor then
                            PaletteFX.markTrueColor(px, py, pw, ph)
                        end
                    end
                end
            end
            
            love.graphics.pop()
            
            love.graphics.setBlendMode(pblendMode, pblendAlpha)
            love.graphics.setShader(pshader)
            love.graphics.setColor(pr, pg, pb, pa)
            love.graphics.setCanvas(pcanvas)
        end
    end
end
