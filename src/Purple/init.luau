local RunService = game:GetService("RunService")

local function packString(data: string)
	local length = string.len(data)
	return string.pack("<Hz", length, data)
end

local function unpackString(data: string)
	local unpackedData = {string.unpack("<Hz", data)}
	return unpackedData[2]
end

local function getClient()
	if RunService:IsServer() then
		error("Attempt to require client module on the server")
	else
		return require(script:WaitForChild("Client"))
	end
end

local function getServer()
	if not RunService:IsServer() then
		error("Attempt to require server module on the client")
	else
		return require(script:WaitForChild("Server"))
	end
end

local Module = {
	Client = getClient,
	Server = getServer
}

-- Example usage:
-- local clientModule = Module.Client()
-- local serverModule = Module.Server()

-- TODO:
-- - Add string/table compression
-- - Add rate limit per keys
-- - Convert identifiers to integers

return Module
