-- pgres/pre-gres, a simple key/value store for computercraft with client/server-architecture


require "find"
require "surfkit"
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

pgres = {
    protocol = "pgres1",
    version = 1
}

function pgres.open(path, hostname, password, whitelist)
    expect(1, path, "string")
    expect(2, hostname, "string")
    expect(3, password, "string", "nil")

    local instance = surfkit.create_empty_instance(pgres.protocol, hostname)
    instance.running = false
    instance.path = path
    instance.password = password
    instance.version = pgres.version

    if whitelist then
        instance.whitelist = {}
        for key, value in pairs(whitelist) do
            instance.whitelist[value] = true
        end
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

    instance._handle = function (self, id, message)
        if self.whitelist then
            if not whitelist[id] then
                -- we don't want attackers of closed systems to even know the system would technically be functional => no answer, no log.
                return
            end
        end

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

    instance._beforeListen = function (self)
        print("pgres-server by bluewingtitan started.")
        print("version: "..self.protocol)
        print("hostname: "..self.hostname)
        print("file: "..self.path)

        if self.password ~= nil then
            print("Service is password protected!")
        end
    end

    instance._afterListen = function (self)
        print("pgres-server by bluewingtitan stopped.")
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

    instance.test = function ()
        local result = instance:get("_LATEST_VERSION")

        if not result or not result.data then
            return false
        end

        return true
    end
    return instance
end