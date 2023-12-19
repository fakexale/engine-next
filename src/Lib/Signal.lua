--!nonstrict

local usableThread: thread?

local function pass(fn: (...unknown) -> (), ...): ()
	local acquiredThread = usableThread
	usableThread = nil
	fn(...)
	usableThread = acquiredThread
end

local function yield(): ()
	while true do
		pass(coroutine.yield())
	end
end

type Disconnect = () -> ()

export type Signal<T...> = {
	__tostring: (self: Signal<T...>) -> "CustomSignal",
	__call: (self: Signal<T...>, T...) -> (),
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Once: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> ()
}

local Signal = {}
Signal.__index = Signal

function Signal:__tostring(): "CustomSignal"
	return "CustomSignal"
end

function Signal:__call(signal, ...)
	return signal:Fire(...)
end

function Signal.new()
	return setmetatable({}, Signal)
end

function Signal:Fire(...: any | { any })
	for callback in self do
		if not usableThread then
			usableThread = coroutine.create(yield)
			coroutine.resume(usableThread)
		end

		task.spawn(usableThread :: thread, callback, ...)
	end
end

function Signal:Connect(callback)
	assert(typeof(callback) == "function", `Callback is not a function!`)
	assert(self[callback] ~= nil, "Callback already connected to Signal!")

	self[callback] = true

	return function()
		self[callback] = nil
	end
end

function Signal:Once(callback)
	assert(typeof(callback) == "function", `Callback is not a function!`)

	local connection

	connection = self:Connect(function(...)
		connection()
		callback(...)
	end)

	return connection
end

function Signal:Wait()
	local running = coroutine.running()

	self:Once(function(...)
		task.spawn(running, ...)
	end)

	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self)
end

return table.freeze(Signal)
