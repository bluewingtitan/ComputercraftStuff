-- config stuff
local configPath = "/tree.cfg"
-- get settings
if fs.exists(configPath) then
    -- load.
    settings.load(configPath)
else
    initConfig()
end

-- init config
function initConfig()
    settings.set("length",4*8)
    settings.save(configPath)
end

0. Get Saplings + Fuel.
1. Fuel Check
2. Fly one block above sapling level. If there is a block in front: Tree grew. Kill it.
		2.1 Replant if tree was broken.
3. Fly back to "dock".
4. Empty Inventory
5. Sleep for some time.



