args = {...}
-- get args:
-- [1]: position of the disk drive

-- What needs to be done:


-- Get Monitor




function WaitForInsert()
    -- 1. Wait for Something to be inserted
    local diskIsThere = false

    while not diskIsThere do
        sleep(1) -- wait a second
        diskIsThere = disk.isPresent(args[1])
    end
end




