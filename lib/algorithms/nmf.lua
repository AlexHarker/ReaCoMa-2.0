function decompose(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-nmf"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local components = parameters[1].value
    local iterations = parameters[2].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[3].value, 
        parameters[4].value, 
        parameters[5].value
    )

    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    data.outputs = {
        components = {}
    }

    for i=1, num_selected_items do
        reacoma.container.get_data(i, data)

        table.insert(
            data.outputs.components,
            data.path[i] .. "_nmf_" .. reacoma.utils.uuid(i) .. ".wav"
        )

        table.insert(
            data.cmd, 
            exe .. 
            " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
            " -resynth " .. reacoma.utils.wrap_quotes(data.outputs.components[i]) ..
            " -iterations " .. iterations ..
            " -components " .. components .. 
            " -fftsettings " .. fftsettings ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
        )
        reacoma.utils.cmdline(data.cmd[i])
        reacoma.layers.exist(i, data)
        reaper.SelectAllMediaItems(0, 0)
        reacoma.layers.process(i, data)
        reaper.UpdateArrange()
    end
end

hpss = {
    info = {
        algorithm_name = 'Non-negative matrix factorisation',
        ext_name = 'reacoma.nmf',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'components',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 10,
            value = 2,
            type = 'sliderint',
            desc = 'The number of elements the NMF algorithm will try to divide the spectrogram of the source in.'
        },
        {
            name = 'iterations',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 100,
            type = 'sliderint',
            desc = 'The NMF process is iterative, trying to converge to the smallest error in its factorisation. The number of iterations will decide how many times it tries to adjust its estimates. Higher numbers here will be more CPU expensive, lower numbers will be more unpredictable in quality.'
        },
        {
            name = 'window size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'sliderint',
            desc = 'window size'
        },
        {
            name = 'hop size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 512,
            type = 'sliderint',
            desc = 'hop size'
        },
        {
            name = 'fft size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'sliderint',
            desc = 'fft size' 
        }
    },
    perform_update = decompose
}

return hpss