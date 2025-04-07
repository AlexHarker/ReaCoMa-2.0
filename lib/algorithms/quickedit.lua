function split_results(s, delimiter)
    result = {};
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

    local output_file = io.open("Users/alexharker/Downloads/results.txt", "w")
    output_file:write(retcleaned .. "\n")
    for index, result in ipairs(results) do
        output_file:write(index .. ": " .. result .. "\n")
    end
    output_file:close()
    
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
        action = 'segment'
    },
    parameters =  {
        {
            name = 'avg_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 400,
            value = 6.25,
            type = 'sliderdouble',
            desc = 'The window time for averaging.'
        },
        {
            name = 'peak_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 400,
            value = 12.5,
            type = 'sliderdouble',
            desc = 'The window time for peak finding.'
        },
        {
            name = 'type',
            widget = reaper.ImGui_Combo,
            value = 1,
            items = 'rms\0rms_hann\0mean\0mean_hann\0',
            type = 'combo',
            desc = 'The average type.'
        },
        {
            name = 'log',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'off\0on\0',
            type = 'combo',
            desc = 'Log Mode.'
        },
        {
            name = 'reduce',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 25,
            value = 4,
            type = 'sliderint',
            desc = 'The integer value to reduce by.'
        },
        {
            name = 'search_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 1000,
            value = 40,
            type = 'sliderdouble',
            desc = 'The window time for searching.'
        },
        {
            name = 'hold_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 1000,
            value = 140,
            type = 'sliderdouble',
            desc = 'The window time for holding.'
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 50,
            value = 20,
            type = 'sliderdouble',
            desc = 'The threshold in dB relative to the minimum average.'
        },
        {
            name = 'percentage',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 100,
            value = 50,
            type = 'sliderdouble',
            desc = 'The percentage of samples that would need to be above the threshold.'
        },
        {
            name = 'min_length',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 2000,
            value = 300,
            type = 'sliderdouble',
            desc = 'The minimum detection length.'
        },
        {
            name = 'min_level',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 100,
            value = 20,
            type = 'sliderdouble',
            desc = 'The minimum detection level for a segment.'
        },
    },
    perform_update = segment
}

return quickedit
