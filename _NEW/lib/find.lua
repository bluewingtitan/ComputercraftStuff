findside = {
    _active = {}
}



-- "But why? There is peripheral.find mate!"
-- Well... Rednet wants a side to open, for example.
-- this api also enables functionality to lock/unlock peripherals.
function findside.modem()
    return findside.find("modem")
end

function findside.find(type)
    for _, side in pairs(rs.getSides()) do
        if peripheral.isPresent(side) and peripheral.getType(side) == type and findside._active[side] == nil or findside._active[side] == false then return side end
    end
end

function findside.lock(side)
    findside._active[side] = true
end

function findside.unlock(side)
    findside._active[side] = false
end