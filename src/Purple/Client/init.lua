--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)
local Shared = require(script.Parent.Shared)
local RemoteSignal = require(script.Parent.RemoteSignal.RemoteSignalClient)
local RemoteFunction = require(script.Parent.RemoteFunction.RemoteFunctionClient)

type Promise = Promise.Promise
type RemoteSignal = RemoteSignal.RemoteSignal
type RemoteFunction = RemoteFunction.RemoteFunction

type frames = number
type callback = (...any) -> ...any

type playerPacket = {
	Names: { string },
	Data: { any },
	Size: number,
}

local dispatchCycle = 1
local currentCycle = 1
local compressionFunction

local remoteSignals = require(script.Parent.RemoteSignals)
local remote: RemoteEvent = ReplicatedStorage:WaitForChild("Remote")
local playerPacket = require(script.PlayerPacket)

local function dispatchPackets()
	if playerPacket.Size == 0 then
		return
	end
	remote:FireServer(playerPacket)
	table.clear(playerPacket.Names)
	table.clear(playerPacket.Data)
	playerPacket.Size = 0
end

local function runCallbacks(callbacks: { callback }, ...: any)
	for _, callback in callbacks do
		task.spawn(callback, ...)
	end
end

local function onIncomingReplication(packet: playerPacket)
	local data = packet.Data
	local names = packet.Names
	for i, name in names do
		local remoteSignal = remoteSignals[name]
		if remoteSignal then
			runCallbacks(remoteSignal.Callbacks, table.unpack(data[i]))
		end
	end
end

type PurpleClient = {
	CreateRemoteSignal: (name: string) -> RemoteSignal?,
	GetRemoteSignal: (name: string) -> RemoteSignal?,
	DestroyRemoteSignal: (name: string) -> nil,
	CreateRemoteFunction: (name: string, timeoutDuration: number?) -> RemoteFunction?,
	PrintPacket: () -> (),
}

local function createClient(): PurpleClient
	local self: PurpleClient = {} :: PurpleClient

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

	function self.PrintPacket()
		print(playerPacket)
	end

	RunService.Heartbeat:Connect(dispatchPackets)
	remote.OnClientEvent:Connect(onIncomingReplication)

	return self
end

return createClient()
