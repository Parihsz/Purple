local RemoteSignalShared = require(script.Parent:WaitForChild("RemoteSignalShared"))

type Callback = (...any) -> (...any)

export type RemoteSignal = RemoteSignalShared.RemoteSignal & {
	Name: string,
	Callbacks: {Callback},
	Fire: (self: RemoteSignal, ...any) -> (),
	Connect: (self: RemoteSignal, callback: Callback) -> (),
	Once: (self: RemoteSignal, callback: Callback) -> (),
	Wait: (self: RemoteSignal) -> (),
	Destroy: (self: RemoteSignal) -> (),
	DisconnectAll: (self: RemoteSignal) -> ()
}

local playerPacket = require(script.Parent.Parent:WaitForChild("Client"):WaitForChild("PlayerPacket"))

local function new(name: string): RemoteSignal
	local self: RemoteSignal = {
		Name = name,
		Callbacks = {},
		Fire = function(self, ...: any)
			playerPacket.Size += 1
			local size = playerPacket.Size
			playerPacket.Names[size] = self.Name
			playerPacket.Data[size] = {...}
		end,
		Connect = RemoteSignalShared.Connect,
		Once = RemoteSignalShared.Once,
		Wait = RemoteSignalShared.Wait,
		Destroy = RemoteSignalShared.Destroy,
		DisconnectAll = RemoteSignalShared.DisconnectAll
	}
	return self
end

return {
	new = new
}
