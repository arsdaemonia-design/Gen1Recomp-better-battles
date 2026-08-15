return function(mod)
    local BattleState = require("src.battle.BattleState")
    local PaletteFX = require("src.render.PaletteFX")
    local Assets = require("src.render.Assets")

    -- Iconos de tipo, ya partidos de types.png en assets/type_<tipo>.png.
    -- types.png trae los 18 tipos, pero esta versión es Gen 1 (Red/Blue/
    -- Yellow): solo se usan los 15 tipos que existen ahí. dark / steel /
    -- fairy quedan en assets sin usar.
    local GEN1_TYPES = {
        "NORMAL", "FIRE", "WATER", "ELECTRIC", "GRASS", "ICE",
        "FIGHTING", "POISON", "GROUND", "FLYING", "PSYCHIC",
        "BUG", "ROCK", "GHOST", "DRAGON",
    }

    local typeIcon = {}
    for _, t in ipairs(GEN1_TYPES) do
        local ok, img = pcall(Assets.image, mod.path .. "/assets/type_" .. t:lower() .. ".png")
        if ok and img then
            if img.setFilter then pcall(img.setFilter, img, "nearest", "nearest") end
            typeIcon[t] = img
        end
    end
    local hasIcons = next(typeIcon) ~= nil

    -- Colores MUY diferenciados para cada tipo de Gen 1 (fallback si no
    -- cargan los iconos)
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
    local ICON_H = 6.84  -- alto base del icono de tipo (nativo)

    local function isFeatureEnabled(game)
        if not game or not game.save or not game.save.modData then return true end
        local modData = game.save.modData["better-battles"]
        if not modData then return true end
        if modData["type_badges"] == nil then return true end
        return modData["type_badges"]
    end

    -- Caché de iconos preescalados a un alto dado (píxeles del canvas en el
    -- que se van a dibujar), con filtro nearest: remuestrear 193x73 por frame
    -- sale pixelado y desalineado (ancho fraccionario). En voxel el alto es
    -- ICON_H*shot.scale; en render.hud es ICON_H*Ux (resolución de ventana).
    local iconCache = {}
    local function getScaledIcon(typeName, h)
        local key = typeName .. ":" .. h
        local c = iconCache[key]
        if c then return c end
        local img = typeIcon[typeName]
        if not img then return nil end
        local w = math.max(1, math.floor(h * (img:getWidth() / img:getHeight())))
        local ok, canvas = pcall(love.graphics.newCanvas, w, h)
        if not ok then
            iconCache[key] = { img = img, w = w }
            return iconCache[key]
        end
        local prev = love.graphics.getCanvas()
        love.graphics.setCanvas(canvas)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 0, 0, 0, w / img:getWidth(), h / img:getHeight())
        love.graphics.setCanvas(prev)
        if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
        iconCache[key] = { canvas = canvas, w = w }
        return iconCache[key]
    end

    -- Dibuja un icono (o el cuadrito de color si la imagen no está). Devuelve
    -- el ancho dibujado, para apilar tipos en fila.
    local function drawTypeIcon(g, typeName, x, y, h)
        local img = typeIcon[typeName]
        if img then
            local c = getScaledIcon(typeName, h)
            g.setColor(1, 1, 1, 1)
            if c.canvas then
                g.draw(c.canvas, math.floor(x), math.floor(y))
            else
                g.draw(img, math.floor(x), math.floor(y), 0, c.w / img:getWidth(), h / img:getHeight())
            end
            return c.w
        end

        local color = typeColors[typeName]
        if not color then return 0 end

        local sz = math.max(1, math.floor(h))
        g.setColor(0, 0, 0, 1)
        g.rectangle("fill", math.floor(x), math.floor(y), sz + 2, sz + 2)
        g.setColor(color[1]/255, color[2]/255, color[3]/255, 1)
        g.rectangle("fill", math.floor(x) + 1, math.floor(y) + 1, sz, sz)

        return sz + 2
    end

    -- Mapeo canvas UI 160x144 -> ventana (replica Renderer:endFrame). Se usa
    -- en render.hud para dibujar los iconos a resolución de ventana, igual
    -- que el shot.canvas del modo voxel.
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

    -- Iconos pendientes de este frame para render.hud (solo no-voxel)
    local pendingIcons = nil

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

        -- Escala: en voxel es shot.scale; en normal se dibuja en render.hud
        -- a resolución de ventana, así que aquí solo se recolectan datos.
        local s = isVoxel and shot.scale or 1
        local ly = isVoxel and shot.ly or 0
        local sz = hasIcons and math.floor(ICON_H * s) or math.floor(SQ * s)

        local collected = {}

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
                    local w
                    if isVoxel then
                        w = drawTypeIcon(g, t, bx + offset + hudShake, by, sz)
                    else
                        w = getScaledIcon(t, sz).w
                        collected[#collected + 1] = { t = t, x = bx + offset + hudShake, y = by, h = sz }
                    end
                    offset = offset + w + 1 * s
                end

                if isVoxel and PaletteFX and PaletteFX.markTrueColor then
                    PaletteFX.markTrueColor(bx + hudShake, by, offset, sz)
                end
            end
        end

        -- ===== PLAYER =====
        local hidePlayer = self.safari or self.demo
        if self.player and not hidePlayer and not self.showPlayerBack then

            local playerData = self.game.data.pokemon[self.player.mon.species]
            if playerData and playerData.types then
                local numTypes = #playerData.types

                local totalW = 0
                local widths = {}
                for i, t in ipairs(playerData.types) do
                    local img = typeIcon[t]
                    if img then
                        widths[i] = getScaledIcon(t, sz).w
                    else
                        widths[i] = sz + 2
                    end
                    totalW = totalW + widths[i]
                    if i < numTypes then totalW = totalW + math.floor(1 * s) end
                end

                -- A la izquierda del <LV> (x=112 nativo)
                local bx = (112 * s) - totalW - math.floor(1 * s)
                local by = ly + 65 * s

                -- En voxel, el HUD del jugador está al lado derecho
                if isVoxel then
                    bx = (shot.pw or 160 * s) - (48 * s) - totalW
                end

                local offset = 0
                for i, t in ipairs(playerData.types) do
                    if isVoxel then
                        drawTypeIcon(g, t, bx + offset, by, sz)
                    else
                        collected[#collected + 1] = { t = t, x = bx + offset, y = by, h = sz }
                    end
                    offset = offset + widths[i] + math.floor(1 * s)
                end

                if isVoxel and PaletteFX and PaletteFX.markTrueColor then
                    PaletteFX.markTrueColor(bx, by, totalW, sz)
                end
            end
        end

        if not isVoxel then
            pendingIcons = collected
        end

        g.pop()
        g.setShader(prevShader)
        g.setColor(pr, pg, pb, pa)
        g.setCanvas(prevCanvas)
    end

    -- En no-voxel, dibujar los iconos sobre el frame compuesto a resolución
    -- de ventana (igual que el shot.canvas del voxel), nítidos y a tamaño
    -- real, en vez de dejar que se vean diminutos en el canvas 160x144.
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
        nextFn(game, viewport)
        local data = pendingIcons
        pendingIcons = nil
        if not data or #data == 0 then return end

        local g = love.graphics
        local prevShader = g.getShader()
        g.setShader()
        g.push()
        local uox, uoy, Ux, Uy = uiOriginAndScale()
        for _, e in ipairs(data) do
            local h = math.max(1, math.floor(e.h * Ux))
            drawTypeIcon(g, e.t, uox + e.x * Ux, uoy + e.y * Uy, h)
        end
        g.pop()
        g.setShader(prevShader)
    end)
end
