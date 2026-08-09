return function(mod, services)
    local compile = loadstring or load

    local function loadModule(path)
        local source, readError = mod:read(path)
        if not source then
            error("cannot read " .. path, 0)
        end
        local chunk, compileError = compile(source, "@" .. mod.path .. "/" .. path)
        if not chunk then
            error("cannot compile " .. path, 0)
        end
        return chunk()
    end

    local function getBoolOption(g, key, default)
        if not g.save.modData then g.save.modData = {} end
        if not g.save.modData["better-battles"] then g.save.modData["better-battles"] = {} end
        local val = g.save.modData["better-battles"][key]
        if val == nil then return default end
        return val
    end
    
    local function toggleBoolOption(g, key)
        if not g.save.modData then g.save.modData = {} end
        if not g.save.modData["better-battles"] then g.save.modData["better-battles"] = {} end
        local current = getBoolOption(g, key, true)
        g.save.modData["better-battles"][key] = not current
        return true
    end

    mod.content.screens:register("BetterBattlesOptions", {
        new = function(game)
            local OptionRows = require("src.ui.OptionRows")
            local Font = require("src.render.Font")
            
            local rows = {
                {
                    label = "BETTER STATUS",
                    value = function(g) return getBoolOption(g, "status_ui", true) and "ON" or "OFF" end,
                    step = function(g, dir) return toggleBoolOption(g, "status_ui") end
                },
                {
                    label = "CAUGHT POKEBALL",
                    value = function(g) return getBoolOption(g, "caught_indicator", true) and "ON" or "OFF" end,
                    step = function(g, dir) return toggleBoolOption(g, "caught_indicator") end
                },
                {
                    label = "BALL COLOR",
                    value = function(g)
                        local c = (g.save.modData["better-battles"] and g.save.modData["better-battles"]["caught_color"]) or "classic"
                        return c == "classic" and "RED" or "GREY"
                    end,
                    step = function(g, dir)
                        if not g.save.modData then g.save.modData = {} end
                        if not g.save.modData["better-battles"] then g.save.modData["better-battles"] = {} end
                        local current = g.save.modData["better-battles"]["caught_color"] or "classic"
                        g.save.modData["better-battles"]["caught_color"] = current == "classic" and "monochrome" or "classic"
                        return true
                    end
                },
                {
                    label = "QUICK ITEM BTN",
                    value = function(g) return getBoolOption(g, "quick_item", true) and "ON" or "OFF" end,
                    step = function(g, dir) return toggleBoolOption(g, "quick_item") end
                },
                {
                    label = "TYPE BADGES",
                    value = function(g) return getBoolOption(g, "type_badges", true) and "ON" or "OFF" end,
                    step = function(g, dir) return toggleBoolOption(g, "type_badges") end
                }
            }
            
            local screen = {
                game = game,
                rows = rows,
                index = 1,
                scroll = 0,
                isOpaque = true,
            }
            
            function screen:sgbPalettes(g)
                return require("src.render.PaletteFX").wholeNamed(g.data, "MEWMON")
            end
            
            function screen:update()
                local input = self.game.input
                if input:wasPressed("up") then
                    self.index = (self.index - 2) % #self.rows + 1
                elseif input:wasPressed("down") then
                    self.index = self.index % #self.rows + 1
                elseif input:wasPressed("left") then
                    local row = self.rows[self.index]
                    if row.step then row.step(self.game, -1) end
                elseif input:wasPressed("right") then
                    local row = self.rows[self.index]
                    if row.step then row.step(self.game, 1) end
                elseif input:wasPressed("b") then
                    self.game.stack:pop()
                end
                self.scroll = OptionRows.clampScroll(self.index, self.scroll, #self.rows, nil)
            end
            
            function screen:draw()
                OptionRows.draw(self.game, self.rows, self.index, self.scroll)
                love.graphics.setColor(0, 0, 0, 1)
                Font.draw("B:BACK", 8, 136)
                love.graphics.setColor(1, 1, 1, 1)
            end
            
            return screen
        end
    })

    -- Hook para inyectar opciones en el menú principal (como zone-display)
    mod.hooks:wrap("ui.options.rows", function(next, game, rows)
        local out = next(game, rows)
        if type(out) ~= "table" then return out end

        out[#out + 1] = {
            id = "bb_main_menu",
            label = "BETTER BATTLES",
            value = function(g) return "CONFIGURE" end,
            activate = function(g) mod.ui.push(g, "BetterBattlesOptions") end
        }

        return out
    end)


    -- Cargar los submódulos de características
    local features = {
        loadModule("feature_status_ui.lua"),
        loadModule("feature_caught_indicator.lua"),
        loadModule("feature_quick_item.lua"),
        loadModule("feature_type_badges.lua"),
    }

    -- Ejecutar/Instalar cada característica
    for _, featureInstall in ipairs(features) do
        featureInstall(mod, services)
    end
end