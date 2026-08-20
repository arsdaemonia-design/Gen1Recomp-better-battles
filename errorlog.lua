-- errorlog.lua: registro de errores del mod better-battles.
-- Escribe a un archivo (better-battles.log en el save dir) y al Logger del
-- juego, de forma que un error de dibujo no cierre la partida sin avisar.
-- main.lua lo carga una sola vez y lo pasa a cada feature.
--
-- COMPAT SANDBOX: el port nuevo corre el código de los mods en un entorno
-- restringido (src/mods/Sandbox.lua) que elimina `debug` y bloquea
-- `love.filesystem` a propósito. Aquí se usa un traceback con fallback y se
-- protege el acceso a love.filesystem con pcall para seguir funcionando en
-- ports viejos (globals completos) y nuevos (sandbox).
return function()
    local FILE = "better-battles.log"

    -- debug.traceback no existe en el sandbox del port nuevo; en el port
    -- viejo sí. Fallback: solo el mensaje del error.
    local traceback = (type(debug) == "table" and type(debug.traceback) == "function")
        and debug.traceback
        or function(err) return tostring(err) end

    local function now()
        return os and os.date and os.date("%Y-%m-%d %H:%M:%S") or "?"
    end

    -- append seguro: love.filesystem escribe en el save dir. En el sandbox
    -- nuevo el acceso a love.filesystem lanza un error (facade), así que todo
    -- va en pcall y el archivo se omite sin romper la partida.
    local function writeFile(line)
        pcall(function()
            if not (love and love.filesystem and love.filesystem.write) then return end
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
            local ok, res = xpcall(fn, traceback, ...)
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
