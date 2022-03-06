local args = {...}

if not args[1] or not args[2] then
    print("Usage: fax <file-name> <receiver-name>")
    return
end

local protocol = "dfax1"

local file = fs.open(args[1], "r")
local text = ""
if file then
    text = file.readAll()
    file.close()
  else
    print("File doesn't exist. (Usage: fax <file-name> <receiver-name>)")
end


local function findModem()
    for _, side in pairs(rs.getSides()) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" and peripheral.call(side, "isWireless") then return side end
    end
end


-- look up
local side = findModem()

if not side then
    print("Please attach a wireless modem to use this service!")
    return
end

if not rednet.isOpen(side) then
    rednet.open(side)
end

local id = rednet.lookup(protocol, args[2])
local adress =  protocol .. "://" .. args[2]

if id then
    print("Faxing file to '" .. adress .. "'...")
    rednet.send(id, text, protocol)
    local sender, message = rednet.receive(protocol.."_back", 10)

    if message and sender == id then
        print("Great success!")
    else
        print("The receiver might be offline, out of reach or busy.")
    end

else
    print("Wasn't able to find '" .. adress .. "'. (Usage: fax <file-name> <receiver-name>)")
end