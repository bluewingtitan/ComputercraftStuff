-- Server for the CC-Banking System of one of the minecraft-servers I am playing on.
-- Does not trust any outsiders. Makes heavy use of the fact that sender-ids can't be spoofed, in combination with unencrypted pws.
-- (Basically 2-Way-Auth, You need to own a specific pocked computer AND know your pw, one does not do w/o the other)

-- Why do I need this? Well... I will give out a library to merchants to enable them to create their own systems (and to profit off of that of course :D).

require "find"

bank = {
    protocol = "bankingineffingcc"
}


function bank:create(pghost, pgpass)
    local instance = {
        protocol = bank.protocol
    }

    instance._receive = function (self)
        local id, message = rednet.receive(self.protocol)
        return id, message
    end

end