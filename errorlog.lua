-- errorlog.lua: registro de errores del mod better-battles.
-- Escribe a un archivo (better-battles.log en el save dir) y al Logger del
-- juego, de forma que un error de dibujo no cierre la partida sin avisar.
-- main.lua lo carga una sola vez y lo pasa a cada feature.
return function()
    local FILE = "better-battles.log"

    local function now()
        return os and os.date and os.date("%Y-%m-%d %H:%M:%S") or "?"
    end

    -- append seguro: love.filesystem escribe en el save dir
    local function writeFile(line)
        if not (love and love.filesystem and love.filesystem.write) then return end
        pcall(function()
            local prev = ""
            local ok, old = pcall(love.filesystem.read, FILE)
            if ok and old then prev = old end
            love.filesystem.write(FILE, prev .. line .. "\n")
        end)
    end

    local function record(level, fmt, ...)
        local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
        local line = string.format("[%s] [better-battles] [%s] %s",
                                   now(), level, msg)
        pcall(print, line)
        writeFile(line)
        return msg
    end

    -- xpcall con traceback: envuelve una función de dibujo para que un error
    -- se loguee y la partida siga corriendo en vez de cerrarse en silencio.
    local function guard(name, fn)
        return function(...)
            local ok, res = xpcall(fn, debug.traceback, ...)
            if not ok then
                record("ERROR", "%s:\n%s", name, tostring(res))
            end
            return res
        end
    end

    return {
        info = function(...) return record("INFO", ...) end,
        warn = function(...) return record("WARN", ...) end,
        error = function(...) return record("ERROR", ...) end,
        guard = guard,
        file = FILE,
    }
end
