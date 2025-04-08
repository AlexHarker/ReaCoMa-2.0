function split_results(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

cache = { -1, -1, -1, -1, -1}

function cache_basic_test(parameters)
    local calc = false
    for i=1, #cache do
        if cache[i] ~= parameters[i].value then
            calc = true
        end
        cache[i] = parameters[i].value
    end
    return calc

end

function in_bounds(value, data)
    v = tonumber(value)
    return v >= data.take_ofs_samples and v <= (data.take_ofs_samples + data.item_len_samples)
end

function constrain_to_item(input, data) 
    results = {}
    
    for i=1, #input / 2 do
        idx = ((i - 1) * 2) + 1
        
        if in_bounds(input[idx], data) and in_bounds(input[idx + 1], data) then
            table.insert(results, input[idx])
            table.insert(results, input[idx + 1])
        end
    end

    return results
end


function segment(parameters)

    local temp_folder = reacoma.utils.dir_parent(os.tmpname())

    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/quickedit"
        )
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local avg_ms = parameters[1].value
    local peak_ms = parameters[2].value
    local type = parameters[3].value
    local log_flag = parameters[4].value
    local reduce = parameters[5].value
    local search_ms = parameters[6].value
    local hold_ms = parameters[7].value
    local threshold = parameters[8].value
    local ratio = parameters[9].value / 100.0
    local min_length = parameters[10].value
    local min_level = parameters[11].value

    local recalc = cache_basic_test(parameters)

    local processed_items = {}

    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        -- Remove any existing take markers
        for j=1, data.take_markers do
            reaper.DeleteTakeMarker(
                data.take,
                data.take_markers - j
            )
        end

        local types = { "rms", "rms_hann", "mean", "mean_hann" }

        local type_string = types[type + 1]

        local file = reacoma.utils.wrap_quotes(data.full_path)
        local cached = paths.expandtilde(temp_folder .. reacoma.utils.name(data.full_path))
        local needs_full_calc = recalc or not paths.file_exists(cached)

        if not needs_full_calc then
            file = cached
            cached = "read"
        end

        local cmd = exe ..
        " --file " .. file ..
        " --avg_ms " .. avg_ms ..
        " --peak_ms "  .. peak_ms ..
        " --type " .. type_string ..
        " --log " .. log_flag ..
        " --reduce " .. reduce ..
        " --search_ms " .. search_ms ..
        " --hold_ms " .. hold_ms ..
        " --threshold " .. threshold ..
        " --ratio " .. ratio ..
        " --cache " .. cached ..
        " --min_length " .. min_length ..
        " --min_level " .. min_level

        local retval = reaper.ExecProcess(cmd, 0)
        local retcleaned = string.gsub(retval, "^.*results ", "")
        retcleaned = string.gsub(retcleaned, " \n$", "")
        results = split_results(retcleaned, " ")
        results = constrain_to_item(results, data) 
        slicing.do_onsets_and_offsets(results, data)

        table.insert(processed_items, data)
    end

    reaper.UpdateArrange()
    return processed_items
end

quickedit = {
    info = {
        algorithm_name = 'Quick Edit',
        ext_name = 'reacoma.quickedit',
        action = 'segment',
        offsets = true
    },
    parameters =  {
        {
            name = 'avg_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 400,
            value = 6.25,
            desc = 'The window time for averaging.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'peak_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 400,
            value = 12.5,
            desc = 'The window time for peak finding.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'type',
            widget = reaper.ImGui_Combo,
            value = 1,
            items = 'rms\0rms_hann\0mean\0mean_hann\0',
            desc = 'The average type.'
        },
        {
            name = 'log',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'off\0on\0',
            desc = 'Log Mode.'
        },
        {
            name = 'reduce',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 25,
            value = 4,
            desc = 'The integer value to reduce by.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'search_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 1000,
            value = 40,
            desc = 'The window time for searching.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'hold_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 1000,
            value = 140,
            desc = 'The window time for holding.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 50,
            value = 20,
            desc = 'The threshold in dB relative to the minimum average.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'percentage',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 100,
            value = 50,
            desc = 'The percentage of samples that would need to be above the threshold.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'min_length',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 2000,
            value = 300,
            desc = 'The minimum detection length.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
        {
            name = 'min_level',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 100,
            value = 20,
            desc = 'The minimum detection level for a segment.',
            flag = reaper.ImGui_SliderFlags_AlwaysClamp()
        },
    },
    perform_update = segment
}

return quickedit
