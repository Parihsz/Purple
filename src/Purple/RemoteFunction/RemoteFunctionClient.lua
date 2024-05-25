local Promise = require(script.Parent.Parent.Promise)
local RemoteSignal = require(script.Parent.Parent.RemoteSignal.RemoteSignalClient)

type Promise = Promise.Promise
type RemoteSignal = RemoteSignal.RemoteSignal

type func = (...any) -> (...any)

export type RemoteFunction = {
	RemoteSignal: RemoteSignal,
	OnInvoke: func,
	TimeoutDuration: number,
	Invoke: (self: RemoteFunction, ...any) -> Promise,
	Destroy: (self: RemoteFunction) -> ()
}

local id = 0
local promises: { [number]: Promise } = {}

local function getNextId()
	id += 1
	return id
end

local function new(name: string, remoteSignal: RemoteSignal, timeoutDuration: number?): RemoteFunction
	local self = {
		RemoteSignal = remoteSignal,
		TimeoutDuration = timeoutDuration or 30,
		OnInvoke = nil
	}

	self.RemoteSignal:Connect(function(id: number, ...: any)
		local onInvoke = self.OnInvoke
		if onInvoke then
			self.RemoteSignal:Fire(id, pcall(onInvoke, ...))
			return
		end
		local promise = promises[id]
		if not promise then
			return
		end
		local args = {...}
		local success = table.remove(args, 1)
		if promise:GetStatus() == "Pending" then
			promise:_forceResolve(success, table.unpack(args))
		end
		promises[id] = nil
	end)

	function self:Invoke(...: any): Promise
		local id = getNextId()
		self.RemoteSignal:Fire(id, ...)
		local promise = Promise.new(function(resolve: func, reject: func, onCancel: func)
			local timeoutThread
			local timeoutDuration = self.TimeoutDuration
			if timeoutDuration then
				timeoutThread = task.delay(timeoutDuration, function()
					reject("Request has timed out!")
				end)
			end
			onCancel(function()
				if timeoutThread then
					task.cancel(timeoutThread)
				end
			end)
		end)
		promises[id] = promise
		return promise
	end

	function self:Destroy()
		self.RemoteSignal:Destroy()
	end

	return self
end

return {
	new = new
}
