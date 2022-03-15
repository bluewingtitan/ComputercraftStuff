-- pushit v1 by boynamedbrian
-- 6BLn8JJ8

local args = {...}
local side = args[1]
local monitorside = args[2]
local files = {}
local totalFiles = 0
local spaces = "                                            "

-- wrap monitor
local monitor = peripheral.wrap(monitorside)
monitor.clear()

local x, y = monitor.getSize()

-- create windows
-- state (single line)
local state = window.create(monitor, 1, 1, x, 1)
local body = window.create(monitor, 1, 2, x, y-2)
local credits = window.create(monitor, 1, y, x, 1)


term.redirect(body)
term.clear()

credits.setTextColor(colors.orange)
credits.setBackgroundColor(colors.white)
credits.write("bluewingtitan's pushit v1"..spaces)


local function writeState(text, txtC)
  state.clear()
  state.setCursorPos(1,1)
  state.setTextColor(txtC)
  state.setBackgroundColor(colors.white)
  state.write(text..spaces)
end


for i in pairs(args) do
  if i>2 then
    totalFiles = totalFiles + 1
    write("using file " .. args[i] .. "\n")
    files[i-2] = args[i]
  end
end

while true do
  writeState("Looking for disk...", colors.blue)
  if disk.isPresent(side) then
    write("disk detected.".."\n")
    local path = disk.getMountPath(side)
    write("disk mounted:"..path.."\n")

    if path then
      writeState("Writing to disk...", colors.lime)
      for i in pairs(files) do
        write("copy "..i.." of "..totalFiles.."\n")
        local tPath = fs.combine(path, files[i])
        if fs.exists(tPath) then
          fs.delete(tPath)
        end
        fs.copy(files[i], tPath)
      end
    else
      writeState("Unable to write to disk", colors.red)
    end
    write("operation finished, eject disk".."\n")
    disk.eject(side)
  end
  sleep(2)
end