local args = {...}
local host = args[0]
local pass = args[1]
local client = args[2]
local whitelist = nil

if client then
    whitelist = {client}
end

require "pgres"

local instance = pgres.open("bank.db", host, pass, whitelist)
instance:listen()
