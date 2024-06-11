local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteSignal = require(script.Parent.RemoteSignal)
local RemoteFunction = require(script.Parent.RemoteFunction)

local Shared = {}

local remoteSignals = require(script.Parent.RemoteSignals)

local remoteFunctions = {}

function Shared.CreateRemoteSignal(name: string)
	local remoteSignal = remoteSignals[name]
	if remoteSignal then
		warn("A remote signal with the name", name, "already exists!")
		return
	end
	remoteSignal = RemoteSignal.new(name)
	remoteSignals[name] = remoteSignal
	return remoteSignal
end

function Shared.GetRemoteSignal(name: string)
	local remoteSignal = remoteSignals[name]
	if not remoteSignal then
		warn("Remote signal with", name, "does not exist!")
		return
	end
	return remoteSignal
end

function Shared.DestroyRemoteSignal(name: string)
	if not remoteSignals[name] then
		warn("This remote signal does not exist!")
		return
	end
	remoteSignals[name] = nil
end

function Shared.CreateRemoteFunction(name: string, timeoutDuration: number?)
	if remoteSignals[name] then
		warn("A remote signal with the name", name, "already exists!")
		return
	end
	local remoteSignal = RemoteSignal.new(name)
	remoteSignals[name] = remoteSignal
	local remoteFunction = RemoteFunction.new(name, remoteSignal, timeoutDuration)
	return remoteFunction
end

return Shared