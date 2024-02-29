local hooksFolder = lfs.writedir() .. "Alpen/Hooks/"
log.write("execHooks", log.INFO, "Hooks Folder: " .. hooksFolder)

local function is_dir(path)
    return path:sub(-1) == "/" or lfs.attributes(path, "mode") == "directory"
end

for file in lfs.dir(hooksFolder) do
    if file ~= "." and file ~= ".." and not is_dir(hooksFolder .. file) then
        dofile(hooksFolder .. file)
        log.write("execHooks", log.INFO, "Running hook: " .. file)
    end
end
