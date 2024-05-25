local Players = game:GetService("Players")
local RemoteSignalShared = require(script.Parent:WaitForChild("RemoteSignalShared"))

type Callback = RemoteSignalShared.callback

export type RemoteSignal = {
	Name: string,
	Callbacks: { Callback },
	Connect: (self: RemoteSignal, callback: Callback) -> (),
	Once: (self: RemoteSignal, callback: Callback) -> (),
	Wait: (self: RemoteSignal) -> (),
	Destroy: (self: RemoteSignal) -> (),
	DisconnectAll: (self: RemoteSignal) -> (),
	Fire: (self: RemoteSignal, players: Player | { Player }, ...any) -> (),
	FireAll: (self: RemoteSignal, ...any) -> (),
	FireAllExcept: (self: RemoteSignal, players: Player | { Player }, ...any) -> (),
}

local playerPackets = require(script.Parent.Parent:WaitForChild("Server"):WaitForChild("PlayerPackets"))

local function insertPacket(player: Player, name: string, value: any)
	local packet = playerPackets[player]
	if not packet then
		return
	end
	packet.Size += 1
	local size = packet.Size
	packet.Names[size] = name
	packet.Data[size] = value
end

local function dispatchToAll(name: string, value: { any })
	for player, packet in playerPackets do
		insertPacket(player, name, value)
	end
end

local function dispatchToSelect(name: string, value: { any }, players: Player | { Player })
	if typeof(players) == "table" then
		for _, player in players :: { Player } do
			insertPacket(player, name, value)
		end
	else
		insertPacket(players :: Player, name, value)
	end
end

local function dispatchToAllExcept(name: string, value: { any }, players: Player | { Player })
	local allPlayers = Players:GetPlayers()
	if typeof(players) == "table" then
		for _, player in players do
			local index = table.find(allPlayers, player)
			if index then
				table.remove(allPlayers, index)
			end
		end
	else
		local index = table.find(allPlayers, players)
		if index then
			table.remove(allPlayers, index)
		end
	end
	for _, player in allPlayers do
		insertPacket(player, name, value)
	end
end

local dispatchLookup = {
	All = dispatchToAll,
	Select = dispatchToSelect,
	AllExcept = dispatchToAllExcept,
}

local function new(name: string): RemoteSignal
	local self: RemoteSignal = {
		Name = name,
		Callbacks = {},
		Connect = RemoteSignalShared.Connect,
		Once = RemoteSignalShared.Once,
		Wait = RemoteSignalShared.Wait,
		Destroy = RemoteSignalShared.Destroy,
		DisconnectAll = RemoteSignalShared.DisconnectAll,
		Fire = function(self, players: Player | { Player }, ...: any)
			dispatchLookup.Select(self.Name, { ... }, players)
		end,
		FireAll = function(self, ...: any)
			dispatchLookup.All(self.Name, { ... })
		end,
		FireAllExcept = function(self, players: Player | { Player }, ...: any)
			dispatchLookup.AllExcept(self.Name, { ... }, players)
		end,
	}
	return self
end

return {
	new = new,
}
