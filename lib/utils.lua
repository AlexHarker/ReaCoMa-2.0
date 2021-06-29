utils = {}

utils.bool_to_number = { [true]=1, [false]=0 }

utils.DEBUG = function(string)
    -- Handy function for quickly debugging strings
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
end

utils.deep_copy = function(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[utils.deep_copy(k, s)] = utils.deep_copy(v, s) end
  return res
end

utils.arrange = function(undo_msg)
    reaper.Undo_BeginBlock()
    reaper.UpdateArrange()
    reaper.Undo_EndBlock(undo_msg, 0)
end

utils.spairs = function(t, order)
    -- This function orders a table given a function as <order>
    -- If no function is passed then it used the default sort function

    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

utils.reverse_table = function(t)
    -- Reverse a table in place
	local i, j = 1, #t
	while i < j do
		t[i], t[j] = t[j], t[i]
		i = i + 1
		j = j - 1
	end
end

utils.next_pow_str = function(value, return_type)
    -- Finds the next power of <x> and returns it as return_type
    local return_type = return_type or 'string'
    local snap = math.floor(2^math.ceil(math.log(value)/math.log(2)))

    if return_type == 'string' then
        return tostring(snap)
    end
    if return_type == 'number' then
        return tonumber(snap)
    end
end

utils.get_max_fft_size = function(fft_string)
    -- Given the three fftsettings values find the maximum fft size
    -- We have to do this because you can pass 1 as a valid argument
    local split_settings = utils.split_space(fft_string)
    local window = split_settings[1] 
    local fft = split_settings[3]
    local adjusted_fft = ""

    if fft == "1" then 
        adjusted_fft = utils.next_pow_str(tonumber(window), 'string') 
        return adjusted_fft
    else
        return fft
    end
end

utils.form_fft_string = function(window, hop, fft)
    return string.format('%d %d %d', window, hop, fft)
end

utils.uuid = function(idx)
    -- Generates a universally unique identifier string
    -- Increases uniqueness by appending a number <idx>
    -- <idx> is generally taken as a loop value
    return tostring(reaper.time_precise()):gsub("%.+", "") .. idx
end

utils.cmdline = function(invocation)
    -- Calls the <command> at the system's shell
    -- The implementation slightly differs for each operating system
    -- 06/08/2020 23:26:07 Seems ExecProcess works equally well everywhere
    -- local opsys = reaper.GetOS()
    -- if opsys == "Win64" then retval = reaper.ExecProcess(command, 0) end
    -- if opsys == "OSX64" or opsys == "Other" then  retval = reaper.ExecProcess(command, 0) end
    local retval = reaper.ExecProcess(invocation, 0)
    
    if not retval then
        utils.DEBUG("There was an error executing the command: "..command)
        utils.DEBUG("See the return value and error below:\n")
        utils.DEBUG(tostring(retval))
        utils.assert(false)
    end
end

utils.assert = function(test)
    -- A template for asserting and dumping the stack
    -- You should embed this into a function and check against some value
    -- Avoid putting it at the top level and make the asserts granular
    if not test then
        reacoma.utils.DEBUG(debug.traceback())
    end
    assert(test, "Fatal ReaCoMa error! An assertion has failed. Refer to the console for more information. If you provide a bug report it is useful to include the output of this window and the console.")
end

utils.open_browser = function(url)
    local opsys = reaper.GetOS()
    local retval = ""
    if opsys == "Win64" then
        utils.cmdline("explorer " .. url)
    else
        retval = os.execute("open " .. url)
        utils.assert(retval)
    end
end

utils.sampstos = function(samples, samplerate)
    -- Return the number of <samples> given a time in seconds and a <samplerate>
    return samples / samplerate
end

utils.stosamps = function(seconds, samplerate) 
    -- Return the number of <seconds> given a time in samples and a <samplerate>
    return math.floor((seconds * samplerate) + 0.5)
end

utils.dir_parent = function(path, separator)
    -- Returns the base directory of a <path>
    -- for example /foo/bar/script.lua >>> /foo/bar/
    -- Optionally provide a <separator>
    local separator = separator or'/'
    return path:match("(.*"..separator..")")
end

utils.dir_exists = function(path)
    local cross_platform_string = path.."/"
    local ok, err, code = os.rename(path, path)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

utils.basename = function(path)
    -- Returns the basename of a <path>
    -- for example /foo/bar/script.lua >>> /foo/bar/script
    return path:match("(.+)%..+")
end

utils.name = function(path)
    -- Returns the name from a path
    -- /foo/bar/script.lua >> script.lua
    return path:match("^.+/(.+)$")
end

utils.stem = function(path)
    -- Returns the stem of a path
    -- /foo/bar/script.lua >> script
    local _, file, _ = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    return file
end

utils.form_path = function(path)
    -- Forms a path given the reacoma.output settings
    local opsys = reaper.GetOS()
    if reacoma.output == "source" then
        return utils.basename(path)
    elseif reacoma.output == "media" then
        local stem = utils.stem(path)
        return reacoma.paths.expandtilde("~/Documents/REAPER Media/") .. stem
    else
        local stem = utils.stem(path)
        return reacoma.output.."/".. stem
    end
end

utils.table_contains = function(tab, val)
    for i=1, #tab do
        if tab[i] == val then return true end
    end
    return false
end

utils.check_extension = function(path)
    local _, name, ext = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    local valid_ext = {'wav', 'aif', 'aiff', 'WAV', 'AIF', 'AIFF'}
    local valid = utils.table_contains(valid_ext, ext)
    if not valid then
        utils.DEBUG(name.." is not in WAV or AIFF format. ReaCoMa currently only works on WAV or AIFF files.")
        utils.assert(false)
    end
end

utils.rm_trailing_slash = function(input_string)
    -- Remove trailing slash from an <input_string>. 
    -- Will not remove slash if it is the only character.
    return input_string:gsub('(.)%/$', '%1')
end

utils.cleanup = function(path_table)
    -- Given a table of strings (<path_table>) that are paths call os.remove() on them
    for i=1, #path_table do
        os.remove(path_table[i])
    end
end

utils.capture = function(cmd, raw)
    -- Captures and returns the output of a command line call
    -- <cmd> is the command and <raw> is flag determining raw or sanitised return
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

utils.readfile = function(file)
    -- Returns the contents of a <file> a string
    if not reacoma.paths.file_exists(file) then 
        utils.DEBUG(file.." could not be read because it does not exist.") 
        utils.assert(false)
    end
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

utils.split_comma = function(input_string)
    -- Splits an <input_string> seperated by "," into a table
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

utils.split_line = function(input_string)
    -- Splits an <input_string> seperated by line endings into a table
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

utils.split_space = function(input_string)
    -- Splits an <input_string> seperated by spaces into a table
    local t = {}
    for word in input_string:gmatch("%w+") do table.insert(t, word) end
    return t
end

utils.lace_tables = function(table1, table2)
    -- Lace the contents of <table1> and <table2> together
    -- 1, 2, 3  and foo, bar, baz become..gfx.a
    -- 1, foo, 2, bar, 3, baz
    local laced = {}
    for i=1, #table1 do
        table.insert(laced, table1[i])
        table.insert(laced, table2[i])
    end
    return laced
end

utils.rmdelim = function(input_string)
    -- Removes delimiters from an <input_string>
    local nodots = input_string.gsub(input_string, "%.", "")
    local nospace = nodots.gsub(nodots, "%s", "")
    return nospace
end

utils.wrap_quotes = function(input_string)
    -- Surrounds an <input_string> with quotation marks
    -- This is almost always required for passing things to the command line
    return '"'..input_string..'"'
end


utils.dataquery = function(idx, data)
    -- Takes in some 'data' and makes a nice print out
    reaper.ShowConsoleMsg("Item Length Samples: " .. data.item_len_samples[idx] .. "\n")
    if data.slice_points_string then
        reaper.ShowConsoleMsg("Slice Points: " .. data.slice_points_string[idx] .. "\n")
    end
end

utils.get_item_info = function(item_index)
    local info = {}
    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    local take = reaper.GetActiveTake(item)
    local take_markers = reaper.GetNumTakeMarkers(take)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_parent = reaper.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil
    local reverse = nil
    
    if src_parent ~= nil then
        sr = reaper.GetMediaSourceSampleRate(src_parent)
        full_path = reaper.GetMediaSourceFileName(src_parent, "")
        reverse = true
    else
        sr = reaper.GetMediaSourceSampleRate(src)
        full_path = reaper.GetMediaSourceFileName(src, "")
        reverse = false
    end
    
    -- Now check the full path works
    reacoma.utils.check_extension(full_path)

    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local playtype  = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")

    if reverse then
        take_ofs = abs(src_len - (item_len + take_ofs))
    end
    
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = ((src_len-take_ofs) * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = floor(utils.stosamps(item_len, sr))

    -- Yeah this is verbose but it makes it cleaner
    info.item = item
    info.take = take
    info.take_markers = take_markers
    info.sr = sr
    info.full_path = full_path
    info.take_ofs = take_ofs
    info.take_ofs_samples = take_ofs_samples
    info.item_len = item_len
    info.item_len_samples = item_len_samples
    info.item_pos = item_pos
    info.item_pos_samples = item_pos_samples
    info.playrate = playrate
    info.reverse = reverse
    -- Layers specific stuff
    info.playtype = playtype
    info.path = reacoma.utils.form_path(full_path)
    -- Slicing specific stuff
    info.tmp = full_path .. utils.uuid(item_index) .. "fs.csv"

    return info
end
---------- Custom operators ----------
-- These are used in the experimental functions that perform comparisons
matchers = {
    ['>'] = function (x, y) return x > y end,
    ['<'] = function (x, y) return x < y end,
    ['>='] = function (x, y) return x >= y end,
    ['<='] = function (x, y) return x <= y end
}

return utils