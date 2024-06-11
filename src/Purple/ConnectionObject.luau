type callback = (Player, ...any) -> (...any)

export type ConnectionObject = {
	Callback: callback,
	Callbacks: {callback},
	RemoteSignal: any,
	Disconnect: (self: ConnectionObject) -> ()
}

local function new(callbacks: {callback}, callback: callback): ConnectionObject
	local self: ConnectionObject = {
		Callback = callback,
		Callbacks = callbacks,
		RemoteSignal = nil,
		Disconnect = function(self: ConnectionObject)
			local index = table.find(self.Callbacks, self.Callback)
			if index then
				table.remove(self.Callbacks, index)
				return
			end
			warn("Could not find callback, signal already disconnected!")
		end
	}

	return self
end

return {
	new = new
}
