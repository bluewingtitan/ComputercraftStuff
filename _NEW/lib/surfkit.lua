-- a simple library for creating basic servers.

require "find"

surfkit = {}


function surfkit.create_empty_instance(protocol, hostname)
    local instance = {
        protocol = protocol,
        hostname = hostname
    }

    instance._receive = function (self)
        local id, message = rednet.receive(self.protocol)
        return id, message
    end

    instance._handle = function (self, id, message)
        print("PLEASE DEFINE YOUR OWN _handle(self, id, message) FUNCTION!")
    end

    instance.listen = function (self)
        -- open rednet

        if not rednet.isOpen() then
                if self.modem == nil then
                    local side = findside.modem()
                    if side == nil then
                        error("Was not able to find any modem that is up for use.")
                    end
                    self.modem = side
                end
            rednet.open(self.modem)
        end

        self:_beforeListen()
        self.running = true
        rednet.host(self.protocol, self.hostname)

        self._id, self._msg = self:_receive()
        while self.running do
            parallel.waitForAll(
                function ()
                    self.__id, self.__msg = self:_receive()
                end,
                function ()
                    self:_handle(self._id, self._msg)
                end
            )
            self._id = self.__id
            self._msg = self.__msg
        end
        rednet.unhost(self.protocol, self.hostname)
        self:_afterListen()
    end

    instance._beforeListen = function (self)
        print("Please define your own _beforeListen(self)!")
    end
    
    instance._afterListen = function (self)
        print("Please define your own _afterListen(self)!")
    end

    return instance

end