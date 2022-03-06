local id = "blue"

print("[dfax] starting server with id <"..id..">")

local function findPrinter()
    for _, side in pairs(rs.getSides()) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "printer" then return side end
    end
end
local pside = findPrinter()
if not pside then
    print("Please attach a wireless modem to use this service!")
    return
end
local printer = peripheral.wrap(pside)
local faxserver = {
    running = false
}


local senderId, message
function faxserver:handle()
    print("[dfax] Handle.")
    return self:pout(message, "Day: ".. os.day() .. " Time: " .. os.time())
end



local protocol = "dfax1"
function faxserver:listen(id)
    rednet.host(protocol, id)
    self.running = true
    print("[dfax] server v1.0 was started")

    while self.running do
        senderId, message  = rednet.receive(protocol)
        rednet.send(senderId, "receival confirmed", protocol.."_back")
        local pages = self:handle()
        print("[dfax] Printed ".. pages.. " page(s). " .. printer.getInkLevel() .. " ink, " .. printer.getPaperLevel() .. " paper left")
    end
end

function faxserver:stop()
    self.running = false
end

-- prepare modem
local function findModem()
    for _, side in pairs(rs.getSides()) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" and peripheral.call(side, "isWireless") then return side end
    end
end

local side = findModem()
if not side then
    print("Please attach a wireless modem to use this service!")
    return
end
if not rednet.isOpen(side) then
    rednet.open(side)
end


function faxserver:pout( sText , faxid )
    if not printer.newPage() then
        return
    end

    local pageNumber = 1
    printer.setPageTitle("Fax <"..faxid.."> #"..pageNumber)

    local w,h = printer.getPageSize()
    local x,y = 0, 0
    local function newLine()
        y = y + 1
        if y > h then
            printer.endPage()
            os.sleep( 0.5 )

            if printer.newPage() then
                pageNumber = pageNumber + 1
                printer.setPageTitle("Fax <"..faxid.."> #"..pageNumber)
                y = 1
            else
                print("[dfax] Ran out of pages, ink or script space. Are you emptying the tray with a hopper?")
                return
            end

        else
            printer.setCursorPos(1,y)
        end
    end

    -- Print the line with proper word wrapping
    while string.len(sText) > 0 do
        local whitespace = string.match( sText, "^[ \t]+" )
        if whitespace then
            -- Print whitespace
            printer.write( whitespace )
            x,y = printer.getCursorPos()
            sText = string.sub( sText, string.len(whitespace) + 1 )
        end

        local newline = string.match( sText, "^\n" )
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub( sText, 2 )
        end

        local text = string.match( sText, "^[^ \t\n]+" )
        if text then
            sText = string.sub( sText, string.len(text) + 1 )
            if string.len(text) > w then
                -- Print a multiline word                
                while string.len( text ) > 0 do
                    if x > w then
                        newLine()
                    end
                    printer.write( text )
                    text = string.sub( text, (w-x) + 2 )
                    x,y = printer.getCursorPos()
                end
            else
                -- Print a word normally
                if x + string.len(text) - 1 > w then
                    newLine()
                end
                printer.write( text )
                x,y = printer.getCursorPos()
            end
        end
    end
    printer.endPage()
    return pageNumber
end

faxserver:listen(id)