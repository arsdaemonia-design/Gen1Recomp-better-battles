return function(mod, services, log)
    local BattleState = require("src.battle.BattleState")
    local PaletteFX = require("src.render.PaletteFX")
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

    local TypeChart = require("src.battle.TypeChart")

    local function effectiveness(moveType, defenderTypes)
        return TypeChart.effectiveness(moveType, defenderTypes or {})
    end

    local function hasSTAB(moveType, atkTypes)
        for _, at in ipairs(atkTypes or {}) do
            if at == moveType then return true end
        end
        return false
    end

    -- Mapeo canvas UI -> ventana (replica Renderer:endFrame). Se usa en
    -- render.hud para dibujar el overlay a resolución de ventana, igual que
    -- el shot.canvas del modo voxel (los marcadores dejan de verse diminutos
    -- y pixelados en el canvas 160x144).
    local function uiOriginAndScale()
        local Renderer = require("src.render.Renderer")
        local ww, wh = love.graphics.getDimensions()
        local pw, ph = ww, wh
        if love.graphics.getPixelDimensions then pw, ph = love.graphics.getPixelDimensions() end
        local dpiX, dpiY = 1, 1
        if ww > 0 and pw > 0 then dpiX = pw / ww end
        if wh > 0 and ph > 0 then dpiY = ph / wh end
        local uiw, uih = Renderer:uiSize()
        local Up = Renderer:uiScale()
        if Renderer.uiFill then Up = math.min(ph / uih, pw / uiw) end
        local Ux, Uy = Up / dpiX, Up / dpiY
        local uox = math.floor((pw - uiw * Up) / 2) / dpiX
        local uoy = math.floor((ph - uih * Up) / 2) / dpiY
        return uox, uoy, Ux, Uy
    end

    -- ========================================================================
    -- 1. Efectividad en la Selección de Movimientos (BattleState:draw)
    -- ========================================================================

    -- Marcador del frame actual para render.hud (solo no-voxel).
    local pendingMarker = nil

    local original_draw = BattleState.draw
    BattleState.draw = log.guard("effective_markers.draw", function(self, ...)
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

        -- Coordenadas: dentro del cuadro TIPO/PP, en la fila de TYPE/ pero
        -- alejado del borde derecho del recuadro
        local x = 72
        local y = 74
        local wide = self:isWideBattleLayout()
        if wide then
            x = 282
            y = 120
        end

        -- Sugerir el movimiento con mejor daño esperado (efectividad × potencia)
        local bestIdx, bestScore = nil, 0
        for i, mv in ipairs(self.player.curMoves or {}) do
            local md = mod.content.moves:get(mv.id)
            if md and md.power and md.power > 0 then
                local m = effectiveness(md.type, defTypes)
                local score = md.power * m
                if score > bestScore then bestIdx, bestScore = i, score end
            end
        end

        local shot = self.dramaticShapeShot
        local isVoxel = shot and shot.canvas and shot.scale

        local g = love.graphics

        -- En voxel se dibuja en el shot.canvas (resolución de ventana) como
        -- siempre. En normal se recolectan los datos y render.hud los pinta a
        -- resolución de ventana sobre el frame compuesto, para que se vean tan
        -- nítidos como en voxel en lugar de diminutos en el canvas 160x144.
        if isVoxel then
            g.push()
            local prevShader = g.getShader()
            g.setCanvas(shot.canvas)
            g.setShader()

            local s = shot.scale
            local lx = shot.lx or 0
            local ly = shot.ly or 0
            local cx = lx + (x + 2) * s
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
                drawTriangle("up", {0, 0.8, 0, 1}) -- Súper efectivo
            else
                drawTriangle("down", {0.9, 0, 0, 1}) -- Poco efectivo
            end

            -- Sugerir el mejor movimiento: cuadrado dorado pulsante
            if bestIdx then
                local ix, iy
                if wide then
                    local col = (bestIdx - 1) % 2
                    local row = math.floor((bestIdx - 1) / 2)
                    ix, iy = (col == 0 and 108 or 214), 112 + row * 16 + 3
                else
                    ix, iy = 146, 96 + bestIdx * 8 + 3
                end
                local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
                g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado
                g.rectangle("fill", lx + ix * s - 2 * s, ly + iy * s - 2 * s, 4 * s, 4 * s)
            end

            g.pop()
            g.setShader(prevShader)
            g.setCanvas(shot.oldCanvas or nil)
        else
            pendingMarker = {
                x = x, y = y, wide = wide,
                mult = mult, stab = stab,
                bestIdx = bestIdx,
                battle = self,
            }
        end
    end)

    -- En no-voxel, dibujar el overlay del moveSelect sobre el frame compuesto
    -- a resolución de ventana, igual que el shot.canvas del modo voxel.
    mod.hooks:wrap("render.hud", log.guard("effective_markers.render.hud",
        function(nextFn, game, viewport)
        nextFn(game, viewport)
        local d = pendingMarker
        pendingMarker = nil
        if not d then return end
        local battle = d.battle
        if not battle or battle ~= activeBattle or battle.phase ~= "moveSelect" then return end

        local g = love.graphics
        local prevShader = g.getShader()
        g.setShader()
        g.push()

        local uox, uoy, Ux, Uy = uiOriginAndScale()
        local cx = math.floor(uox + (d.x + 2) * Ux)
        local cy = math.floor(uoy + (d.y + 2) * Uy)
        local size = 3 * Ux
        local stab = d.stab
        local mult = d.mult

        local function drawTriangle(dir, baseColor)
            local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
            if stab then
                g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado STAB
                g.setLineWidth(2 * Ux)
                if dir == "up" then
                    g.polygon("line", cx, cy - size - 2*Ux, cx - size - 2*Ux, cy + size + 2*Ux, cx + size + 2*Ux, cy + size + 2*Ux)
                else
                    g.polygon("line", cx, cy + size + 2*Ux, cx - size - 2*Ux, cy - size - 2*Ux, cx + size + 2*Ux, cy - size - 2*Ux)
                end
            end
            g.setColor(baseColor[1] * pulse, baseColor[2] * pulse, baseColor[3] * pulse, 1)
            if dir == "up" then
                g.polygon("fill", cx, cy - size, cx - size, cy + size, cx + size, cy + size)
            else
                g.polygon("fill", cx, cy + size, cx - size, cy - size, cx + size, cy - size)
            end
        end

        if mult == 0 then
            if stab then
                g.setColor(1, 0.84, 0, 1)
                g.circle("fill", cx, cy, size + 2*Ux)
            end
            g.setColor(0.4, 0.4, 0.4, 1)
            g.circle("fill", cx, cy, size)
            g.setColor(0, 0, 0, 1)
            g.setLineWidth(1 * Ux)
            g.line(cx - size/2, cy - size/2, cx + size/2, cy + size/2)
            g.line(cx + size/2, cy - size/2, cx - size/2, cy + size/2)
        elseif mult == 10 then
            if stab then
                g.setColor(1, 0.84, 0, 1)
                g.circle("fill", cx, cy, size + 2*Ux)
            end
            g.setColor(0.75, 0.75, 0.8, 1)
            g.circle("fill", cx, cy, size)
            g.setColor(0, 0, 0, 1)
            g.setLineWidth(1.5 * Ux)
            g.line(cx - size/1.5, cy, cx + size/1.5, cy)
        elseif mult > 10 then
            drawTriangle("up", {0, 0.8, 0, 1})
        else
            drawTriangle("down", {0.9, 0, 0, 1})
        end

        -- Cuadrado dorado del mejor movimiento
        if d.bestIdx then
            local ix, iy
            if d.wide then
                local col = (d.bestIdx - 1) % 2
                local row = math.floor((d.bestIdx - 1) / 2)
                ix, iy = (col == 0 and 108 or 214), 112 + row * 16 + 3
            else
                ix, iy = 146, 96 + d.bestIdx * 8 + 3
            end
            local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8
            g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado
            g.rectangle("fill", math.floor(uox + ix * Ux - 2 * Ux), math.floor(uoy + iy * Uy - 2 * Uy), 4 * Ux, 4 * Uy)
        end

        g.pop()
        g.setShader(prevShader)
    end))

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

                local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.8

                -- Flecha de selección ▶ coloreada (posición fija x=0, al lado del
                -- cursor): el poke actualmente seleccionado muestra su ventaja en
                -- la propia flechita, sin depender del largo del nombre.
                if i == self.index then
                    local cy = slotY + 8
                    g.setColor(1, 1, 1, 1)
                    g.rectangle("fill", 0, cy, 8, 8)
                    if isSTABAdvantage then
                        g.setColor(1 * pulse, 0.84 * pulse, 0, 1) -- Dorado STAB
                    else
                        g.setColor(0, 0.85 * pulse, 0.1, 1) -- Verde
                    end
                    g.polygon("fill", 2, cy + 1, 2, cy + 7, 7, cy + 4)
                    if PaletteFX and PaletteFX.markTrueColor then
                        PaletteFX.markTrueColor(0, cy, 8, 8)
                    end
                end

                -- Triángulo ▲ en posición FIJA en la fila inferior (y+8, la del
                -- HP bar), pegado justo antes de la barra (que empieza en x=40):
                -- ocupa 34-40. Nunca choca con nombres largos ni con el nivel
                -- /status (x=104+).
                local cx = 37
                local cy = slotY + 12
                local size = 3

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
