return function(mod)
    local BattleState = require("src.battle.BattleState")
    local PaletteFX = require("src.render.PaletteFX")
    local Font = require("src.render.Font")
    local PartyMenu = require("src.ui.PartyMenu")

    local activeBattle = nil

    mod.events:on("battle.started", function(e) activeBattle = e.battle end)
    mod.events:on("battle.ended", function() activeBattle = nil end)

    local function isFeatureEnabled(game)
        if not game.save.modData then return true end
        if not game.save.modData["better-battles"] then return true end
        local val = game.save.modData["better-battles"]["effective_markers"]
        return val == nil and true or val
    end

    local function effectiveness(moveType, defenderTypes)
        local mult = 10
        for _, dt in ipairs(defenderTypes or {}) do
            local row = mod.content.type_chart:get(moveType .. ">" .. dt)
            if row and row.multiplier then
                mult = math.floor(mult * row.multiplier / 10)
            end
        end
        return mult
    end

    local function hasSTAB(moveType, attackerTypes)
        if not attackerTypes then return false end
        for _, at in ipairs(attackerTypes) do
            if moveType == at then return true end
        end
        return false
    end

    local NO_EFFECT_GLYPH = 0xF1
    local MORE_ARROW = 0xEE

    -- ========================================================================
    -- 1. Efectividad en la Selección de Movimientos (BattleState:draw)
    -- ========================================================================
    local original_draw = BattleState.draw
    function BattleState:draw(...)
        original_draw(self, ...)

        if not isFeatureEnabled(self.game) then return end
        if self.phase ~= "moveSelect" then return end

        local sel = self.player and self.player.curMoves and self.player.curMoves[self.moveIndex]
        if not sel then return end
        if self.player.disabledSlot == self.moveIndex then return end

        local def = mod.content.moves:get(sel.id)
        if not def or not def.power or def.power == 0 then return end

        local defTypes = self.enemy and self.enemy.curTypes
        if not defTypes then return end

        local atkTypes = self.player and self.player.mon and self.player.mon.types

        local mult = effectiveness(def.type, defTypes)
        local stab = hasSTAB(def.type, atkTypes)

        -- Coordenadas: esquina superior derecha del cuadro TIPO/PP
        local x = 78
        local y = 74
        if self:isWideBattleLayout() then
            x = 288
            y = 120
        end

        local g = love.graphics
        g.push()
        local prevShader = g.getShader()

        local shot = self.dramaticShapeShot
        local isVoxel = shot and shot.canvas and shot.scale
        if isVoxel then
            g.setCanvas(shot.canvas)
        end

        g.setShader() -- Disable shader para colores reales

        local s = isVoxel and shot.scale or 1
        local ly = isVoxel and shot.ly or 0
        local cx = (x + 2) * s
        local cy = ly + (y + 2) * s
        local size = 3 * s

        local function drawTriangle(dir, baseColor)
            local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
            if stab then
                g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado STAB
                g.setLineWidth(2 * s)
                if dir == "up" then
                    g.polygon("line", cx, cy - size - 2*s, cx - size - 2*s, cy + size + 2*s, cx + size + 2*s, cy + size + 2*s)
                else
                    g.polygon("line", cx, cy + size + 2*s, cx - size - 2*s, cy - size - 2*s, cx + size + 2*s, cy - size - 2*s)
                end
            end
            g.setColor(baseColor[1] * pulse, baseColor[2] * pulse, baseColor[3] * pulse, 1)
            if dir == "up" then
                g.polygon("fill", cx, cy - size, cx - size, cy + size, cx + size, cy + size)
            else
                g.polygon("fill", cx, cy + size, cx - size, cy - size, cx + size, cy - size)
            end
        end

        -- Dibujar forma vectorizada
        if mult == 0 then
            -- Sin efecto: Círculo gris oscuro con una X
            if stab then
                g.setColor(1, 0.84, 0, 1)
                g.circle("fill", cx, cy, size + 2*s)
            end
            g.setColor(0.4, 0.4, 0.4, 1) -- Gris oscuro
            g.circle("fill", cx, cy, size)
            g.setColor(0, 0, 0, 1)
            g.setLineWidth(1 * s)
            g.line(cx - size/2, cy - size/2, cx + size/2, cy + size/2)
            g.line(cx + size/2, cy - size/2, cx - size/2, cy + size/2)
        elseif mult == 10 then
            -- Neutral: Círculo gris claro con un '-' (igual)
            if stab then
                g.setColor(1, 0.84, 0, 1)
                g.circle("fill", cx, cy, size + 2*s)
            end
            g.setColor(0.75, 0.75, 0.8, 1) -- Gris claro/azulado
            g.circle("fill", cx, cy, size)
            g.setColor(0, 0, 0, 1)
            g.setLineWidth(1.5 * s)
            g.line(cx - size/1.5, cy, cx + size/1.5, cy)
        elseif mult > 10 then
            drawTriangle("up", {0, 0.8, 0, 1}) -- Súper efectivo: Triángulo Verde
        else
            drawTriangle("down", {0.9, 0, 0, 1}) -- Poco efectivo: Triángulo Rojo
        end

        -- Marcar para que la paleta Game Boy no lo aplaste
        if not isVoxel and PaletteFX and PaletteFX.markTrueColor then
            PaletteFX.markTrueColor(x - 2, y - 2, 12, 12)
        end

        g.pop()
        g.setShader(prevShader)
        if isVoxel then
            g.setCanvas(shot and shot.oldCanvas or nil)
        end
    end

    -- ========================================================================
    -- 2. Ventaja en Menú de Equipo (PartyMenu Advantage)
    -- ========================================================================
    local original_party_draw = PartyMenu.draw
    function PartyMenu:draw(...)
        original_party_draw(self, ...)

        if not isFeatureEnabled(self.game) then return end

        -- Localizar el estado de batalla activo en la pila
        local battle = self.opts and self.opts.battle
        if not battle then
            if self.battle then
                battle = self.battle
            elseif self.game and self.game.stack and self.game.stack.states then
                for _, state in ipairs(self.game.stack.states) do
                    if state.enemy and (state.phase or state.player) then
                        battle = state
                        break
                    end
                end
            end
        end

        if not battle or not battle.enemy then return end

        local enemyTypes = battle.enemy.curTypes
        if not enemyTypes then return end

        local party = self.party or (self.game and self.game.save and self.game.save.party)
        if not party then return end

        local g = love.graphics
        g.push("all")
        g.setShader() -- Desactivar shaders para pintar color RGB directo

        for i, mon in ipairs(party) do
            local hasAdvantage = false
            local isSTABAdvantage = false
            
            local pData = self.game.data.pokemon[mon.species]
            local monTypes = mon.types or (pData and pData.types) or {}

            for _, moveInfo in ipairs(mon.moves or {}) do
                local def = mod.content.moves:get(moveInfo.id)
                if def and def.power and def.power > 0 then
                    local mult = effectiveness(def.type, enemyTypes)
                    if mult > 10 then
                        hasAdvantage = true
                        -- Si además el movimiento súper efectivo recibe STAB (es del mismo tipo que el Pokémon)
                        if hasSTAB(def.type, monTypes) then
                            isSTABAdvantage = true
                        end
                    end
                end
            end

            -- Solo dibujamos si el Pokémon TIENE ataques útiles (ignorando su tipo base inútil)
            if hasAdvantage then
                local slotY = PartyMenu.entryY(i)
                
                -- Obtener el nombre para calcular dónde termina exactamente el texto
                local name = mon.nickname or (pData and pData.name) or ""
                local nameWidth = #name * 8
                
                -- Posición X dinámicamente al lado derecho del nombre (24 es el offset inicial de X)
                local cx = 24 + nameWidth + 6
                -- Si el nombre es larguísimo (10 letras), lo topamos para que no encime feo
                if cx > 100 then cx = 100 end

                local cy = slotY + 5
                local size = 3

                local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
                
                if isSTABAdvantage then
                    g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado brillante para STAB Súper Efectivo
                else
                    g.setColor(0, 0.85 * pulse, 0.1, 1) -- Verde para ataque Súper Efectivo normal
                end

                -- Triángulo Verde Hacia Arriba
                g.polygon("fill", cx, cy - size, cx - size, cy + size, cx + size, cy + size)

                if PaletteFX and PaletteFX.markTrueColor then
                    PaletteFX.markTrueColor(cx - 5, cy - 5, 10, 10)
                end
            end
        end

        g.pop()
    end
end
