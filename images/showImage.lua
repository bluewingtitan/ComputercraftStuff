local args = {...}

-- get monitor
local monitor = peripheral.wrap(args[1])
monitor.setTextScale(0.5)

-- load image
local img = paintutils.loadImage(args[2])

-- paint image
local old = term.redirect(monitor)
paintutils.drawImage(img,1,1)
term.redirect(term.native())