return function(mod)
    local BattleState = require("src.battle.BattleState")
    local ItemEffects = require("src.inventory.ItemEffects")
    local Font = require("src.render.Font")
    local Strings = require("src.core.Strings")

    local function isFeatureEnabled(game)
        if not game or not game.save or not game.save.modData then return true end
        local modData = game.save.modData["better-battles"]
        if not modData then return true end
        if modData["quick_item"] == nil then return true end
        return modData["quick_item"]
    end

    local function getQuickItems(game)
        local balls = {}
        local potions = {}
        local potPref = { POTION=1, SUPER_POTION=2, HYPER_POTION=3, MAX_POTION=4, FULL_RESTORE=5 }
        
        for id, qty in pairs(game.save.inventory or {}) do
            if ItemEffects.isBall(id) then
                table.insert(balls, { id = id, qty = qty })
            elseif potPref[id] then
                table.insert(potions, { id = id, qty = qty })
            end
        end
        local ballPref = { POKE_BALL=1, GREAT_BALL=2, ULTRA_BALL=3, MASTER_BALL=4 }
        table.sort(balls, function(a, b) return (ballPref[a.id] or 0) < (ballPref[b.id] or 0) end)
        table.sort(potions, function(a, b) return (potPref[a.id] or 0) < (potPref[b.id] or 0) end)
        return balls, potions
    end

    local function useQuickItem(battle, itemDef)
        if not itemDef then return end
        local id = itemDef.id
        local game = battle.game
        
        -- To properly queue the item action in BattleState, we must switch phase to "messages"
        -- exactly like BattleState:openItems does before pushing the BagMenu.
        battle.phase = "messages"
        battle.afterQueue = "menu"
        
        if ItemEffects.needsTarget(id) and not ItemEffects.isBall(id) then
            -- Quick Potions should quickly heal the ACTIVE Pokemon without opening the party menu.
            local target = battle.player.mon
            local result, payload = ItemEffects.use(game.data, game.save, id, target, battle)
            if result == "consumed" then
                game.save.inventory[id] = game.save.inventory[id] - 1
                if game.save.inventory[id] <= 0 then game.save.inventory[id] = nil end
                battle:itemUsed(payload)
            elseif result == "kept" then
                battle:itemUsed(payload)
            else
                if type(payload) == "table" then
                    for _, msg in ipairs(payload) do battle:say(msg) end
                else
                    battle:say(payload or "It won't have any effect.")
                end
            end
        else
            -- Direct use (like Pokeball)
            local result, payload = ItemEffects.use(game.data, game.save, id, nil, battle)
            if result == "ball" then
                game.save.inventory[id] = game.save.inventory[id] - 1
                if game.save.inventory[id] <= 0 then game.save.inventory[id] = nil end
                battle:throwBall(id)
            elseif result == "consumed" then
                game.save.inventory[id] = game.save.inventory[id] - 1
                if game.save.inventory[id] <= 0 then game.save.inventory[id] = nil end
                battle:itemUsed(payload)
            elseif result == "kept" then
                battle:itemUsed(payload)
            else
                -- If failed (e.g. trainer battle), show message
                if type(payload) == "table" then
                    for _, msg in ipairs(payload) do battle:say(msg) end
                else
                    battle:say(payload or "You can't use that here!")
                end
            end
        end
    end

    local original_update = BattleState.update
    function BattleState:update(dt)
        if not isFeatureEnabled(self.game) then 
            return original_update(self, dt)
        end
        
        if self.betterBattlesQuickItemOpen then
            local balls, potions = getQuickItems(self.game)
            local selectable = {}
            
            if not self.bbQuickItemBallIndex or self.bbQuickItemBallIndex > #balls then self.bbQuickItemBallIndex = 1 end
            if not self.bbQuickItemPotionIndex or self.bbQuickItemPotionIndex > #potions then self.bbQuickItemPotionIndex = 1 end
            
            if #balls > 0 then table.insert(selectable, balls[self.bbQuickItemBallIndex]) end
            if #potions > 0 then table.insert(selectable, potions[self.bbQuickItemPotionIndex]) end

            if self.game.input:wasPressed("up") or self.game.input:wasPressed("down") then
                if #selectable > 1 then
                    self.bbQuickItemCursor = self.bbQuickItemCursor == 1 and 2 or 1
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                end
            elseif self.game.input:wasPressed("left") then
                local currentItem = selectable[self.bbQuickItemCursor]
                if currentItem and ItemEffects.isBall(currentItem.id) and #balls > 1 then
                    self.bbQuickItemBallIndex = self.bbQuickItemBallIndex - 1
                    if self.bbQuickItemBallIndex < 1 then self.bbQuickItemBallIndex = #balls end
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                elseif currentItem and #potions > 1 then
                    self.bbQuickItemPotionIndex = self.bbQuickItemPotionIndex - 1
                    if self.bbQuickItemPotionIndex < 1 then self.bbQuickItemPotionIndex = #potions end
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                else
                    self.betterBattlesQuickItemOpen = false
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                end
            elseif self.game.input:wasPressed("right") then
                local currentItem = selectable[self.bbQuickItemCursor]
                if currentItem and ItemEffects.isBall(currentItem.id) and #balls > 1 then
                    self.bbQuickItemBallIndex = self.bbQuickItemBallIndex + 1
                    if self.bbQuickItemBallIndex > #balls then self.bbQuickItemBallIndex = 1 end
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                elseif currentItem and #potions > 1 then
                    self.bbQuickItemPotionIndex = self.bbQuickItemPotionIndex + 1
                    if self.bbQuickItemPotionIndex > #potions then self.bbQuickItemPotionIndex = 1 end
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                end
            elseif self.game.input:wasPressed("b") then
                self.betterBattlesQuickItemOpen = false
                require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
            elseif self.game.input:wasPressed("a") then
                self.betterBattlesQuickItemOpen = false
                require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                
                local selected = selectable[self.bbQuickItemCursor]
                if selected then
                    useQuickItem(self, selected)
                end
            end
            return
        end
        
        if self.phase == "menu" then
            local col = (self.menuIndex - 1) % 2
            if (col == 0 and self.game.input:wasPressed("left")) or self.game.input:wasPressed("select") then
                local balls, potions = getQuickItems(self.game)
                if #balls > 0 or #potions > 0 then
                    self.betterBattlesQuickItemOpen = true
                    self.bbQuickItemCursor = 1
                    self.bbQuickItemBallIndex = 1
                    self.bbQuickItemPotionIndex = 1
                    require("src.core.Sound").play(self.game.data, "SFX_PRESS_AB")
                    return
                end
            end
        end

        original_update(self, dt)
    end

    local original_draw = BattleState.draw
    function BattleState:draw(...)
        original_draw(self, ...)
        if not isFeatureEnabled(self.game) then return end
        
        if self.betterBattlesQuickItemOpen then
            local pcanvas = love.graphics.getCanvas()
            
            local balls, potions = getQuickItems(self.game)
            local lines = {}
            
            if not self.bbQuickItemBallIndex or self.bbQuickItemBallIndex > #balls then self.bbQuickItemBallIndex = 1 end
            if not self.bbQuickItemPotionIndex or self.bbQuickItemPotionIndex > #potions then self.bbQuickItemPotionIndex = 1 end
            
            if #balls > 0 then
                local b = balls[self.bbQuickItemBallIndex]
                local name = self.game.data.items[b.id] and self.game.data.items[b.id].name or b.id
                local arrowText = #balls > 1 and name .. " ▶" or name
                table.insert(lines, arrowText .. " x" .. b.qty)
            end
            if #potions > 0 then
                local p = potions[self.bbQuickItemPotionIndex]
                local name = self.game.data.items[p.id] and self.game.data.items[p.id].name or p.id
                local arrowText = #potions > 1 and name .. " ▶" or name
                table.insert(lines, arrowText .. " x" .. p.qty)
            end
            
            if #lines > 0 then
                local pr, pg, pb, pa = love.graphics.getColor()
                local pshader = love.graphics.getShader()
                local pblendMode, pblendAlpha = love.graphics.getBlendMode()
                
                local shot = self.dramaticShapeShot
                local isVoxel = shot and shot.canvas and shot.scale
                
                if isVoxel then love.graphics.setCanvas(shot.canvas) end
                
                love.graphics.setShader()
                love.graphics.setBlendMode("alpha", "alphamultiply")
                
                if self:wideLayout() then
                    Font.drawBox(0, 13, 38, 5)
                    for i, text in ipairs(lines) do
                        if self.bbQuickItemCursor == i then Font.draw("▶", 16, 104 + 8 + (i-1)*16) end
                        Font.draw(text, 24, 104 + 8 + (i-1)*16)
                    end
                else
                    Font.drawBox(0, 12, 20, 6)
                    for i, text in ipairs(lines) do
                        if self.bbQuickItemCursor == i then Font.draw("▶", 8, 96 + 16 + (i-1)*16) end
                        Font.draw(text, 16, 96 + 16 + (i-1)*16)
                    end
                end
                
                love.graphics.setBlendMode(pblendMode, pblendAlpha)
                love.graphics.setShader(pshader)
                love.graphics.setColor(pr, pg, pb, pa)
            end
            
            love.graphics.setCanvas(pcanvas)
        end
    end
end
