-- PurpleServer.luau
--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)
local Shared = require(script.Parent.Shared)
local RemoteSignal = require(script.Parent.RemoteSignal.RemoteSignalServer)
local RemoteFunction = require(script.Parent.RemoteFunction.RemoteFunctionServer)

type Promise = Promise.Promise
type RemoteSignal = RemoteSignal.RemoteSignal
type RemoteFunction = RemoteFunction.RemoteFunction

type dispatchTo = "All" | "AllExcept" | "Players"
type frames = number
type callback = (Player, ...any) -> ...any

local maxPacketsCycle = 1000

local remoteSignals = require(script.Parent:WaitForChild("RemoteSignals"))

local Remote: RemoteEvent

local playerPackets = require(script:WaitForChild("PlayerPackets"))

local RateLimitHit = Signal.new()

local function onPlayerAdded(player: Player)
	playerPackets[player] = {
		Names = {},
		Data = {},
		Size = 0,
	}
end

local function onPlayerRemoving(player: Player)
	playerPackets[player] = nil
end

local function runCallbacks(callbacks: { callback }, player: Player, ...: any)
	for _, callback in callbacks do
		task.spawn(callback, player, ...)
	end
end

local function onIncomingReplication(player: Player, packet: playerPackets.playerPacket)
	local data = packet.Data
	local names = packet.Names
	local numberOfPackets = 0

	for i, name in names do
		numberOfPackets += 1
		if numberOfPackets > maxPacketsCycle then
			warn(player, "has been rate limited, number of packets sent:", numberOfPackets)
			RateLimitHit:Fire(player, numberOfPackets)
			return
		end

		local remoteSignal = remoteSignals[name]
		if remoteSignal then
			runCallbacks(remoteSignal.Callbacks, player, table.unpack(data[i]))
		end
	end
end

local function dispatchPackets()
	for _, player in Players:GetPlayers() do
		local packet = playerPackets[player]
		if packet and #packet.Names > 0 then
			Remote:FireClient(player, packet)
			table.clear(packet.Names)
			table.clear(packet.Data)
			packet.Size = 0
		end
	end
end

type PurpleServer = {
	CreateRemoteSignal: (name: string) -> RemoteSignal?,
	GetRemoteSignal: (name: string) -> RemoteSignal?,
	DestroyRemoteSignal: (name: string) -> nil,
	CreateRemoteFunction: (name: string, timeoutDuration: number?) -> RemoteFunction?,
	PrintAllPackets: () -> (),
	SetGlobalRateLimit: (callsPerFrame: number) -> (),
	RateLimitHit: any,
}

local function createServer(): PurpleServer
	local self: PurpleServer = {} :: PurpleServer

	function self.CreateRemoteSignal(name: string): RemoteSignal?
		return Shared.CreateRemoteSignal(name)
	end

	function self.GetRemoteSignal(name: string): RemoteSignal?
		return Shared.GetRemoteSignal(name)
	end

	function self.DestroyRemoteSignal(name: string): nil
		return Shared.DestroyRemoteSignal(name)
	end

	function self.CreateRemoteFunction(name: string, timeoutDuration: number?): RemoteFunction?
		return Shared.CreateRemoteFunction(name, timeoutDuration)
	end

	function self.PrintAllPackets()
		print(playerPackets)
	end

	Remote = Instance.new("RemoteEvent")
	Remote.Parent = ReplicatedStorage
	Remote.Name = "Remote"

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RunService.Heartbeat:Connect(dispatchPackets)
	Remote.OnServerEvent:Connect(onIncomingReplication)

	function self:SetGlobalRateLimit(callsPerFrame: number)
		maxPacketsCycle = callsPerFrame
	end

	self.RateLimitHit = RateLimitHit

	return self
end

return createServer()
