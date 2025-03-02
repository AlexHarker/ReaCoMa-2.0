local r = reaper

local params = {}
local exts = "Reacoma preset files (.rcmprst)\0*.rcmprst\0\0"

-- So we don't have to figure out what the index of a table is
-- for any given default parameters. We can encapsulate it into
-- a function that just does it for us.
-- TODO: one day genercise all the functions into a table utilities module...
params.find_index = function(tbl, value)
	for i, v in ipairs(tbl) do
	  if v == value then
		return i
	  end
	end
	return nil
end

params.find_by_name = function(param_tbl, query_name)
    for _, param in ipairs(param_tbl) do
        if param.name == query_name then
            return param.value
        end
    end
    r.ShowConsoleMsg(query_name.. ' not found')
    return nil
end

params.set = function(obj)
    for _, param in pairs(obj.parameters) do
        -- Handle custom parameters
        if reacoma.utils.table_has(reacoma.imgui.widgets, param.widget) then
            r.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.index, true)
        else
            r.SetExtState(reacoma.settings.version..obj.info.ext_name, param.name, param.value, true)
        end
    end
end

params.get = function(obj)
    for _, param in pairs(obj.parameters) do
        if r.HasExtState(reacoma.settings.version..obj.info.ext_name, param.name) then
            -- Test if parameter is a custom widget
            if reacoma.utils.table_has(reacoma.imgui.widgets, param.widget) then
                param.index = r.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            else
                param.value = r.GetExtState(reacoma.settings.version..obj.info.ext_name, param.name)
            end
        end
    end
end

params.store = function(obj)
    idx = 1
    local values = {}
    for parameter, d in pairs(obj.parameters) do
        values[idx] = d.value
        idx = idx + 1
    end
    return values
end

params.restore = function(obj, values)
    idx = 1
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


params.store_preset = function(obj, slot)
    for _, param in pairs(obj.parameters) do
        r.SetExtState(
            obj.info.ext_name,
            create_slot_identifier(param.name, slot),
            param.value,
            true
        )
    end
end

params.get_preset = function(obj, slot)
    for _, param in pairs(obj.parameters) do
        local id = create_slot_identifier(param.name, slot)
        if r.HasExtState(obj.info.ext_name, id) then
            local v = r.GetExtState(obj.info.ext_name, id)
            param.value = v
        end
    end
end

params.save_to_file = function(obj)
    path = reacoma.settings.last_preset_path
    preset = params.store(obj)
    retval, path = reaper.JS_Dialog_BrowseForSaveFile("Save Preset", path, "", exts)
    file = io.open(path,'w')
    if file then
        for i=1, #preset do
            file:write(tostring(preset[i]) .. "\n")
        end
        file:close()
        reacoma.settings.last_preset_path = reacoma.utils.dir_parent(path)
    end
end

params.restore_from_file = function(obj)
    path = reacoma.settings.last_preset_path
    retval, path = reaper.JS_Dialog_BrowseForOpenFiles("Read Preset", path, "", exts, false)
    file = io.open(path,'r')
    if file then
        file:close()
        preset = {}
        for line in io.lines(path) do 
            preset[#preset + 1] = tonumber(line)
        end
        params.restore(obj, preset)
        reacoma.settings.last_preset_path = reacoma.utils.dir_parent(path)
    end
end

return params