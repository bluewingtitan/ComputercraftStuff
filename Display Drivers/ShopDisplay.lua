term.write("Monitor location: ")
side = io.read()
term.write("Display Text: ")
text = io.read()
term.write("Font Color: ")
textColor = io.read()
term.write("speed: ")
scrollSpeed = io.read()
 
function makeScrollingText(side,text,tc,speed)
    mon = peripheral.wrap(side)
    w,h = mon.getSize()
    x = w
    tc = string.rep(tc,#text)
    mon.setTextScale(5)
    mon.clear()
    while true do
        mon.setCursorPos(x,1)
        mon.blit(text,tc,string.rep("f",#text))
        x = x-1
        if x < (#text - (#text * 2)) then
            x = w
        end
        sleep(speed+0)
        mon.clear()
    end
end
 
makeScrollingText(side,text,textColor,scrollSpeed)