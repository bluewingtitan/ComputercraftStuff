-- pgres/pre-gres, a simple key/value store for computercraft with client/server-architecture

-------------------------
-- fake imported libs: --
---------------------------------------------------------------------------
-- replace these with the requires that are commented out in production. --
---------------------------------------------------------------------------
findside = {
    _active = {}
}

function findside.modem()
    return findside.find("modem")
end

function findside.find(type)
    for _, side in pairs(rs.getSides()) do
        if peripheral.isPresent(side) and peripheral.getType(side) == type and findside._active[side] == nil or findside._active[side] == false then return side end
    end
end


-- require "util.find"
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

pgres = {
    protocol = "pgres1",
    version = 1
}

function pgres.open(path, hostname, password, modem)
    expect(1, path, "string")
    expect(2, hostname, "string")
    expect(3, password, "string", "nil")
    expect(4, modem, "string", "nil")

    local instance = {
        running = false,
        path = path,
        hostname = hostname,
        sessions = {},
        password = password,
        version = pgres.version,
        protocol = pgres.protocol
    }

    if modem ~= nil then
        instance.modem = modem
    end

    instance._getTime = function ()
        return os.date()
    end

    instance._createEntry = function (self, data, isReadOnly)
        local r = {
            d = data,
            c = self:_getTime() -- save entry creation time.
    }
        if isReadOnly then r.readonly = true end
        return r
    end


    instance._load = function (self)
        local file, content
        if not fs.exists(self.path) then
            file = fs.open(self.path,"w")
            file.write(textutils.serialiseJSON({
                _INIT_VERSION = self:_createEntry(self.version, true),
                _LATEST_VERSION = self:_createEntry(self.version, true)
            }))
            file.close()
        end
        file = fs.open(self.path,"r")
        content = file.readAll()
        self.data = textutils.unserialiseJSON(content)
        file.close()
    end

    instance._save = function (self)
        local file
        file = fs.open(self.path,"w")
        file.write(textutils.serialiseJSON(self.data))
        file.close()
    end

    instance._receive = function (self)
        local id, message = rednet.receive(self.protocol)
        return id, message
    end

    instance._handle = function (self, id, message)
        local key = message["key"]
        local method = message["method"]
        if not key or not method then
            rednet.send(id, self:_getAnswerPacket(key, 400), self.protocol)
            return
        end
        print("["..id.."]: "..method.." "..key)

        if self.password then
            local pw = message["password"]
            if not pw then
                rednet.send(id, self:_getAnswerPacket(key, 401), self.protocol)
                return
            end
            if pw ~= self.password then
                rednet.send(id, self:_getAnswerPacket(key, 403), self.protocol)
                return
            end
        end

        local version = message["version"]
        if version and version ~= self.version then
            print("VERSION DIFFERENCE! Distant: "..version..", local: "..self.version..")")
        end

        if method == "get" then
            local tuple = self.data[key]
            if not tuple then
                rednet.send(id, self:_getAnswerPacket(key, 404), self.protocol)
                return
            end
            rednet.send(id, self:_getAnswerPacket(key, 200, tuple["d"]), self.protocol)
            return
        end

        if method == "set" then
            local data = message["data"]
            if not data then
                rednet.send(id, self:_getAnswerPacket(key, 400), self.protocol)
                return
            end

            local tuple = self.data[key]

            if tuple and tuple.readonly then
                rednet.send(id, self:_getAnswerPacket(key, 403), self.protocol)
                return
            end

            self.data[key] = self:_createEntry(data)
            self:_save()
            rednet.send(id, self:_getAnswerPacket(key, 200), self.protocol)
            return
        end

        rednet.send(id, self:_getAnswerPacket(key, 400), self.protocol)
    end

    instance._getAnswerPacket = function (self, key, stateCode, data)
        return {
            key = key,
            code = stateCode,
            data = data
        }
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


        self:_load()

        if self.data["_LATEST_VERSION"].d ~= self.version then
            -- UPGRADES OF DATA DUE TO BIGGER VERSION CHANGES WILL GO IN HERE.
            print("upgrade db-version from "..self.data["_LATEST_VERSION"].d.." to "..self.version)
            self.data["_LATEST_VERSION"] = self:_createEntry(self.version, true)
            self:_save()
        end


        self.running = true
        rednet.host(self.protocol, self.hostname)

        print("pgres-server by bluewingtitan started.")
        print("version: "..self.protocol)
        print("hostname: "..self.hostname)
        print("file: "..self.path)

        if self.password ~= nil then
            print("Service is password protected!")
        end

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
        print("pgres-server by bluewingtitan stopped.")
    end

    instance.stop = function (self)
        self.running = false
    end


    return instance
end


function pgres.connect(hostname, password)
    local instance = {
        timeout = 10,
        retries = 2,
        hostname = hostname,
        password = password,
        version = pgres.version,
        protocol = pgres.protocol,
        hostid = nil
    }

    instance._resolve = function (self)
        local hostId = rednet.lookup(self.protocol, self.hostname)
        if not hostId then
            error("Wasn't able to resolve hostname: "..self.hostname)
        end
        self.hostid = hostId
    end

    instance.get = function (self, key, retryNumber)
        if not self.hostid then
            self:_resolve()
        end

        local retry = retryNumber
        if not retryNumber then
            retry = 0
        end

        local request = {
            method = "get",
            key = key
        }
        if self.password then
            request.password = self.password
        end

        rednet.send(self.hostid, request, self.protocol)

        local id, result = rednet.receive(self.protocol, self.timeout)

        if not result then
            print("Connection with server timed out")
            if retry < self.retries then
                print("Retrying get request...")
                return self:get(key, retry)
            end

            return nil
        end

        if not result.data or result.code ~= 200 then
            print("Request failed: HttpErrorCode#"..result.code)
        end

        return result
    end


    instance.set = function (self, key, data, retryNumber)
        if not self.hostid then
            self:_resolve()
        end

        local retry = retryNumber
        if not retryNumber then
            retry = 0
        end

        local request = {
            method = "set",
            key = key,
            data = data
        }
        if self.password then
            request.password = self.password
        end

        rednet.send(self.hostid, request, self.protocol)

        local id, result = rednet.receive(self.protocol, self.timeout)

        if not result then
            print("Connection with server timed out")
            if retry < self.retries then
                print("Retrying get request...")
                return self:set(key, data, retry)
            end

            return nil
        end

        if result.code ~= 200 then
            print("Request failed: HttpErrorCode#"..result.code)
        end

        return result
    end


    -- check connection
    local result = instance:get("_LATEST_VERSION")

    if not result or not result.data then
        print("Connection test failed.")
    end

    return instance
end