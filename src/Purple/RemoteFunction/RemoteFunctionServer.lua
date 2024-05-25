local Players = game:GetService("Players")

local Promise = require(script.Parent.Parent.Promise)
local RemoteSignal = require(script.Parent.Parent.RemoteSignal.RemoteSignalServer)

type Promise = Promise.Promise
type func = (...any) -> (...any)

export type RemoteSignal = RemoteSignal.RemoteSignal
export type RemoteFunction = {
	RemoteSignal: RemoteSignal,
	OnInvoke: func?,
	TimeoutDuration: number?,
	Invoke: (self: RemoteFunction, player: Player, ...any) -> Promise,
	Destroy: (self: RemoteFunction) -> ()
}

local identifiers: {[Player]: number} = {}
local promises: {[Player]: {[number]: Promise}} = {}

local function onPlayerRemoving(player: Player)
	identifiers[player] = nil
	promises[player] = nil
end

local function onPlayerAdded(player: Player)
	identifiers[player] = 0
	promises[player] = {}
end

local function getNextId(player: Player)
	local identifier = identifiers[player]
	if not identifier then
		return nil
	end
	identifiers[player] += 1
	return identifiers[player]
end

local function new(name: string, remoteSignal: RemoteSignal, timeoutDuration: number?): RemoteFunction
	local self: RemoteFunction = {
		RemoteSignal = remoteSignal,
		TimeoutDuration = timeoutDuration or 30,
		OnInvoke = nil,
		Invoke = function(self, player: Player, ...: any): Promise
			local id = getNextId(player)
			if not id then
				error(player.Name .. " does not exist!")
			end
			self.RemoteSignal:Fire(player, id, ...)
			local promise = Promise.new(function(resolve: func, reject: func, onCancel: func)
				local connection = player:GetPropertyChangedSignal("Parent"):Connect(function()
					reject(player.Name .. " has left the game!")
				end)
				local timeoutThread
				local timeoutDuration = self.TimeoutDuration
				if timeoutDuration then
					timeoutThread = task.delay(timeoutDuration, function()
						reject(player.Name .. "'s request has timed out!")
					end)
				end
				onCancel(function()
					connection:Disconnect()
					if timeoutThread then
						task.cancel(timeoutThread)
					end
				end)
			end)
			local playerPromises = promises[player]
			playerPromises[id] = promise
			return promise
		end,
		Destroy = function(self)
			self.RemoteSignal:Destroy()
		end
	}

	self.RemoteSignal:Connect(function(player: Player, id: number, ...: any)
		local onInvoke = self.OnInvoke
		if onInvoke then
			self.RemoteSignal:Fire(player, id, pcall(onInvoke, player, ...))
			return
		end
		local playerPromises = promises[player]
		if not playerPromises then
			return
		end
		local promise = playerPromises[id]
		if not promise then
			return
		end
		local args = {...}
		local success = table.remove(args, 1)
		if promise:GetStatus() == "Pending" then
			promise:_forceResolve(success, table.unpack(args))
		end
		playerPromises[id] = nil
	end)

	return self
end

Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return {
	new = new
}
