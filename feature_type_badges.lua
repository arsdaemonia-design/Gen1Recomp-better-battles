return function(mod)
    local BattleState = require("src.battle.BattleState")
    local PaletteFX = require("src.render.PaletteFX")

    -- Colores MUY diferenciados para cada tipo de Gen 1
    local typeColors = {
        NORMAL   = {168, 168, 120},
        FIRE     = {240,  80,  48},
        WATER    = {56,  120, 240},
        ELECTRIC = {248, 208,   0},
        GRASS    = {56,  200,  56},
        ICE      = {100, 216, 240},
        FIGHTING = {160,  48,  40},
        POISON   = {160,  48, 200},
        GROUND   = {200, 160,  56},
        FLYING   = {128, 184, 240},
        PSYCHIC  = {248,  64, 144},
        BUG      = {168, 200,  32},
        ROCK     = {160, 136,  72},
        GHOST    = {88,   64, 136},
        DRAGON   = {96,   56, 232},
    }

    local SQ = 5  -- tamaño base del cuadrito (nativo)

    local function isFeatureEnabled(game)
        if not game or not game.save or not game.save.modData then return true end
        local modData = game.save.modData["better-battles"]
        if not modData then return true end
        if modData["type_badges"] == nil then return true end
        return modData["type_badges"]
    end

    -- Dibuja un cuadrito de color sólido con borde negro (tamaño escalado)
    local function drawSquare(typeName, x, y, sz)
        local color = typeColors[typeName]
        if not color then return 0 end

        local g = love.graphics

        -- Borde negro
        g.setColor(0, 0, 0, 1)
        g.rectangle("fill", x, y, sz + 2, sz + 2)

        -- Relleno de color
        g.setColor(color[1]/255, color[2]/255, color[3]/255, 1)
        g.rectangle("fill", x + 1, y + 1, sz, sz)

        return sz + 2
    end

    -- Hook BattleState:draw (DESPUÉS del render, como status_ui)
    local original_draw = BattleState.draw
    function BattleState:draw(...)
        original_draw(self, ...)
        if not isFeatureEnabled(self.game) then return end

        local slide = (self.introSlide or 0) * 4
        if slide ~= 0 then return end

        local g = love.graphics
        g.push()
        local prevCanvas = g.getCanvas()
        local prevShader = g.getShader()
        local pr, pg, pb, pa = g.getColor()

        local shot = self.dramaticShapeShot
        local isVoxel = shot and shot.canvas and shot.scale

        if isVoxel then
            g.setCanvas(shot.canvas)
        end

        g.setShader()

        -- Escala: en modo normal es 1, en voxel es shot.scale
        local s = isVoxel and shot.scale or 1
        local ly = isVoxel and shot.ly or 0  -- offset Y base para voxel
        local sq = math.floor(SQ * s)  -- tamaño del cuadro escalado

        -- ===== ENEMY =====
        if self.enemy and not self.showEnemyTrainer and not self.enemySendingOut
           and not self:growInScale(self.enemy)
           and not self.introBalls and not self.enemy.fainted then

            local enemyData = self.game.data.pokemon[self.enemy.mon.species]
            if enemyData and enemyData.types then
                local endX
                if self.enemy.shownStatus then
                    local label = self:statusLabel({ status = self.enemy.shownStatus })
                    endX = 40 + #label * 8
                else
                    endX = 40 + #tostring(self.enemy.mon.level) * 8
                end

                local bx = (endX + 2) * s
                local by = ly + 9 * s

                local fx = self.fx
                local hudShake = (fx and fx.hudShakeX or 0) * s

                local offset = 0
                for _, t in ipairs(enemyData.types) do
                    local w = drawSquare(t, bx + offset + hudShake, by, sq)
                    offset = offset + w + 1 * s
                end

                if PaletteFX and PaletteFX.markTrueColor then
                    PaletteFX.markTrueColor(bx + hudShake, by, offset, sq + 2)
                end
            end
        end

        -- ===== PLAYER =====
        local hidePlayer = self.safari or self.demo
        if self.player and not hidePlayer and not self.showPlayerBack then

            local playerData = self.game.data.pokemon[self.player.mon.species]
            if playerData and playerData.types then
                local numTypes = #playerData.types
                local sqTotal = sq + 2
                local totalW = numTypes * sqTotal + (numTypes - 1) * math.floor(1 * s)

                -- A la izquierda del <LV> (x=112 nativo)
                local bx = (112 * s) - totalW - math.floor(1 * s)
                local by = ly + 65 * s

                -- En voxel, el HUD del jugador está al lado derecho
                if isVoxel then
                    -- El HUD del jugador en voxel está posicionado diferente
                    -- Usar shot.pw (player width) como referencia
                    bx = (shot.pw or 160 * s) - (48 * s) - totalW
                end

                local offset = 0
                for _, t in ipairs(playerData.types) do
                    local w = drawSquare(t, bx + offset, by, sq)
                    offset = offset + w + math.floor(1 * s)
                end

                if PaletteFX and PaletteFX.markTrueColor then
                    PaletteFX.markTrueColor(bx, by, offset, sq + 2)
                end
            end
        end

        g.pop()
        g.setShader(prevShader)
        g.setColor(pr, pg, pb, pa)
        g.setCanvas(prevCanvas)
    end
end
