floor = math.floor
abs = math.abs

slicing = {}

slicing.rm_dup = function(slice_table)
    -- Removes duplicate entries from a table
    local hash = {}
    local res = {}
    for _,v in ipairs(slice_table) do
        if not hash[v] then
            res[#res+1] = v -- you could print here instead of saving to result table if you wanted
            hash[v] = true
        end 
    end
    return res
end

slicing.convert_to_source_time = function(slice_points, data)
    
    -- Invert the table around the middle point (mirror!)
    if data.reverse == true then
        for i=1, #slice_points do
            slice_points[i] = reacoma.utils.sampstos(data.item_len_samples - slice_points[i], data.sr)   
        end
        reacoma.utils.reverse_table(slice_points)
    else
        for i=1, #slice_points do
            slice_points[i] = reacoma.utils.sampstos(slice_points[i], data.sr)
        end
    end

    return slice_points
end

slicing.do_onsets_and_offsets = function(slice_points, data)
    
    slice_points = slicing.convert_to_source_time(slice_points, data)

    local color_on = reacoma.colors.scheme[1] or { r=255, g=0, b=0 }
    local color_off = reacoma.colors.scheme[19] or { r=160, g=0, b=160 }

    for i=1, #slice_points do
        local slice_pos = slice_points[i]
        
        local scheme = color_off

        if (i % 2 == 1) then 
            scheme = color_on 
        end

        local color = reaper.ColorToNative(scheme.r, scheme.g, scheme.b) | 0x1000000
        reaper.SetTakeMarker(
            data.take, 
            -1, '', 
            slice_pos, 
            color
        )
    end
end

slicing.gateslice = function(data)
    local onsets_and_offsets = reacoma.utils.split_space(data.slice_points_string)

    -- Interleave the onsets/offsets
    local slice_points = reacoma.utils.lace_tables(
        reacoma.utils.split_comma(onsets_and_offsets[1]),
        reacoma.utils.split_comma(onsets_and_offsets[2])
    )

    -- Also test if the slice points are logical, otherwise exit
    if gate_based_slicer and (slice_points[1] == '-1' or slice_points[2] == '-1') then 
        return 
    end

    slicing.do_onsets_and_offsets(slice_points, data)
end

slicing.process = function(data)
    local slice_points = reacoma.utils.split_comma(data.slice_points_string)

    slice_points = slicing.convert_to_source_time(slice_points, data)

    for i=1, #slice_points do
        local slice_pos = slice_points[i]

        local scheme = reacoma.colors.scheme[1] or { r=255, g=0, b=0 }
        local color = reaper.ColorToNative( scheme.r, scheme.g, scheme.b ) | 0x1000000
        reaper.SetTakeMarker(
            data.take, 
            -1, '', 
            slice_pos, 
            color
        )
    end
end

return slicing
