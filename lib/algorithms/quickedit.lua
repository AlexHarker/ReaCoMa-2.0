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

    local temp_folder = utils.dir_parent(os.tmpname())

    local exe = reacoma.utils.wrap_quotes("/usr/local/bin/quickedit")

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local avg_ms = parameters[1].value
    local peak_ms = parameters[2].value
    local type = parameters[3].value
    local log_flag = parameters[4].value
    local reduce = parameters[5].value
    local search_ms = parameters[6].value
    local hold_ms = parameters[7].value
    local threshold = parameters[8].value
    local ratio = parameters[9].value
    local min_length = parameters[10].value

    local recalc = cache_basic_test(parameters)

    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    for i=1, num_selected_items do
        reacoma.container.get_data(i, data)

        -- Remove any existing take markers
        for j=1, data.take_markers[i] do
            reaper.DeleteTakeMarker(
                data.take[i],
                data.take_markers[i] - j
            )
        end

        local types = { "rms", "rms_hann", "mean", "mean_hann" }

        local type_string = types[type + 1]

        local file = reacoma.utils.wrap_quotes(data.full_path[i])
        local cached = paths.expandtilde(temp_folder .. utils.name(data.full_path[i]))
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
        " --min_length " .. min_length

        local retval = reaper.ExecProcess(cmd, 0)

        local results = split_results(retval, " ")
        local result_length = (#results - 1) // 2

        --table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        --reacoma.slicing.process(i, data, true)
        for j=1, result_length do
            local slice_pos1 = tonumber(results[j * 2])
            local slice_secs1 = utils.sampstos(slice_pos1, data.sr[i])
            local slice_pos2 = tonumber(results[j * 2 + 1])
            local slice_secs2 = utils.sampstos(slice_pos2, data.sr[i])

            reaper.SetTakeMarker(
                data.take[i],
                -1, '',
                slice_secs1,
                reaper.ColorToNative(255, 0, 0) | 0x1000000
            )

            reaper.SetTakeMarker(
                data.take[i],
                -1, '',
                slice_secs2,
                reaper.ColorToNative(160, 0, 160) | 0x1000000
            )
        end
    end

    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
    return data
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
            value = 25,
            type = 'sliderdouble',
            desc = 'The window time for averaging.'
        },
        {
            name = 'peak_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 400,
            value = 50,
            type = 'sliderdouble',
            desc = 'The window time for peak finding.'
        },
        {
            name = 'type',
            widget = reaper.ImGui_Combo,
            value = 1,
            items = 'rms\31rms_hann\31mean\31mean_hann\31',
            type = 'combo',
            desc = 'The average type.'
        },
        {
            name = 'log',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'off\31on\31',
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
            value = 30,
            type = 'sliderdouble',
            desc = 'The window time for searching.'
        },
        {
            name = 'hold_ms',
            widget = reaper.ImGui_SliderDouble,
            min = 1,
            max = 1000,
            value = 30,
            type = 'sliderdouble',
            desc = 'The window time for holding.'
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 50,
            value = 10,
            type = 'sliderdouble',
            desc = 'The threshold in dB relative to the minimum average.'
        },
        {
            name = 'ratio',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 1,
            value = 0.35,
            type = 'sliderdouble',
            desc = 'The ratio of samples that would need to be above the threshold.'
        },
        {
            name = 'min_length',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 2000,
            value = 5,
            type = 'sliderdouble',
            desc = 'The minimum detection length.'
        },
    },
    perform_update = segment
}

return quickedit
