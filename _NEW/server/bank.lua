-- Server for the CC-Banking System of one of the minecraft-servers I am playing on.
-- Does not trust any outsiders. Makes heavy use of the fact that sender-ids can't be spoofed, in combination with unencrypted pws.
-- (Basically 2-Way-Auth, You need to own a specific pocked computer AND know your pw, one does not do w/o the other)

-- Why do I need this? Well... I will give out a library to merchants to enable them to create their own systems (and to profit off of that of course :D).

require "find"
require "surfkit"
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

bank = {
    protocol = "bankingineffingcc"
}


function bank:create(pghost, pgpass, hostname)
    expect(1, pghost, "string")
    expect(2, pgpass, "string", "nil")

    if not pgpass then
        -- double, because we don't want someone (me) to miss this.
        warn("You are running a bank system without a database-password. NEVER DO THIS IN PRODUCTION!")
        print("You are running a bank system without a database-password. NEVER DO THIS IN PRODUCTION!")
    end


    local instance = surfkit.create_empty_instance(bank.protocol, hostname)
    instance.pghost = pghost
    instance.pgpass = pgpass

    instance._beforeListen = function (self)
        if not instance.pbclient then
            print("trying to connect to pgres...")
            instance.pgclient = pgres.connect(self.pghost, self.pgpass)

            if not instance.pgclient:test() then
                error("could not connect to pgres.")
            end
        end
    end


    instance._handle = function (self, id, message)
        
    end

end