-- This file contains variables that can change the default behaviour of ReaCoMa

-------------------------------------------------------------------------------------
-- Parameter Description: Location for files generated by ReaCoMa
-- Default: "source"
-- Options: 
    -- media
    -- description: new files will be put in the REAPER media folder
    -- <anything>
    -- description: You can set a custom path. It has to be an absolute path and be valid.
-- Examples:
    -- reacoma.output = "source"
    -- reacoma.output = "media"
    -- reacoma.output = "~/my_custom_output"
reacoma.output = "source"
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- Parameter Description: Bypass command line versoin checks
-- Default: "false"
-- Examples:
    -- reacoma.bypass_version = true (this will ignore the checking of versions)
reacoma.bypass_version = false
-------------------------------------------------------------------------------------