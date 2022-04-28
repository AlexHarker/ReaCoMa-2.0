
params = {}
reacoma_preset_exts = "Reacoma preset files (.rcmprst)\0*.rcmprst\0\0"

params.set = function(obj)
    for parameter, d in pairs(obj.parameters) do
        reaper.SetExtState(obj.info.ext_name, d.name, d.value, true)
    end
end

params.get = function(obj)
    for parameter, d in pairs(obj.parameters) do
        if reaper.HasExtState(obj.info.ext_name, d.name) then
            d.value = reaper.GetExtState(obj.info.ext_name, d.name)
        end
    end
end

params.store = function(obj)
    local idx = 1
    local values = {}
    for parameter, d in pairs(obj.parameters) do
        values[idx] = d.value
        idx = idx + 1
    end
    return values
end

params.restore = function(obj, values)
    local idx = 1
    for parameter, d in pairs(obj.parameters) do
        d.value = values[idx]
        idx = idx + 1
    end
end

params.store_defaults = function(obj)
    obj.defaults = params.store(obj)
end

params.restore_defaults = function(obj)
    params.restore(obj, obj.defaults)
end

params.save_preset = function(obj)
    local path = reacoma.settings.last_preset_path
    local preset = params.store(obj)
    local retval, path = reaper.JS_Dialog_BrowseForSaveFile("Save Preset", path, "", reacoma_preset_exts)
    local file = io.open(path,'w')
    if file then
        for i=1, #preset do
            file:write(tostring(preset[i]) .. "\n")
        end
        file:close()
        reacoma.settings.last_preset_path = utils.dir_parent(path)
    end
end

params.restore_preset = function(obj)
    local path = reacoma.settings.last_preset_path
    local retval, path = reaper.JS_Dialog_BrowseForOpenFiles("Read Preset", path, "", reacoma_preset_exts, false)
    local file = io.open(path,'r')
    if file then
        file:close()
        local preset = {}
        for line in io.lines(path) do
            preset[#preset + 1] = tonumber(line)
        end
        params.restore(obj, preset)
        reacoma.settings.last_preset_path = utils.dir_parent(path)
    end
end

return params
