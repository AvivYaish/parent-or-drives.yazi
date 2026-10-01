local current = ya.sync(function()
    local c = cx.active.current
    return c.cwd, c.hovered and c.hovered.name
end)

local function check(ok, err)
    if not ok then
        ya.notify {
            title = "Drive list",
            content = tostring(err),
            level = "error",
            timeout = 5,
        }
    end
    return ok
end

return {
    entry = function(_, job)
        if ya.target_family() ~= "windows" then return end
        local cwd, name = current()
        local config = os.getenv("YAZI_CONFIG_HOME")
            or (os.getenv("APPDATA") .. "\\yazi\\config")
        local hub = Url(config .. "\\Drives")
        local action = job.args[1] or "leave"

        if cwd == hub then
            if action ~= "leave" and name and name:match("^[A-Z]$") then
                ya.emit("cd", { name .. ":\\" })
            end
        elseif action ~= "leave" or not tostring(cwd):match("^[A-Za-z]:[/\\]?$") then
            ya.emit(action, {})
        else
            if not check(fs.create("dir_all", hub)) then return end
            for n = 65, 90 do
                local letter = string.char(n)
                local entry = hub:join(letter)
                local cha = fs.cha(Url(letter .. ":\\"), true)
                if cha and cha.is_dir then
                    check(fs.create("dir_all", entry))
                elseif fs.cha(entry) then
                    check(fs.remove("dir", entry)) -- Empty placeholders only.
                end
            end
            ya.emit("cd", { hub })
        end
    end,
}
