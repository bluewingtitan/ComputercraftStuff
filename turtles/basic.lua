local args = {...} -- get args.

local repeats = args[1]
local stripLength = args[2]
local refuelOrStopAt = 100
local refuelAmount = 4


-- define helper functions

-- mines a tunnel that's as long as [length] defines.
-- doDown defines if the block below should be mined
-- or if the tunnel should be a single block in height
function mineTunnel(length, doDown)
    for i=1,length do
        turtle.dig()
        turtle.forward()
        if doDown then
            turtle.digDown()
        end        
    end
end

-- walks the defined length.
function walk(length)
    for i=1,length do
        turtle.forward()
    end
end

-- mines strips of the length [stripLength] in both directions
-- ends ad it's starting position.
function mineStrips()
    turtle.turnLeft()
    mineTunnel(stripLength,false)
    halfTurn()
    walk(stripLength)
    mineTunnel(stripLength,false)
    halfTurn()
    walk(stripLength)
    turtle.turnRight()
end

-- does half a turn.
-- this is only here to make code even a bit more readable :D
function halfTurn()
    turtle.turnLeft()
    turtle.turnLeft()
end

-- checks if fuel level is critical (defined in [refuelOrStopAt])
-- attempts refuel with item in slot 1, if fuel level is critical.
-- if refuel fails, it will exit out of the program.
function manageFuel()
    if turtle.getFuelLevel() < refuelOrStopAt then
        -- try refuel
        turtle.select(1)
        turtle.refuel(refuelAmount)
    end
    if turtle.getFuelLevel() < refuelOrStopAt then
        -- if refuel hasn't worked, stop.
        term.write("Turtle ran out of fuel and stopped.")
        return
    end
end


for n=1,repeats do
    -- 0. check fuel and refuel if needed
    manageFuel()
    -- 1. mine 3 blocks towards front
    mineTunnel(3,true)
    -- 2. mine strips
    mineStrips()
end

term.write("Finished Job.")