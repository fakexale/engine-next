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

export type Module<T...> = {
	__tostring: (self: Signal<T...>) -> "CustomSignal",
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Once: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> (),
}
export type Signal<T...> = typeof(setmetatable({} :: { [(T...) -> ()]: boolean }, {} :: Module<T...>))

--[=[
	@class Signal

	A simple custom implementation for [RBXScriptSignals](https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal).

	Unlike most Signal implementions, does not have a Disconnect method.
]=]--
local Signal = {}
Signal.__index = Signal

function Signal:__tostring(): "CustomSignal"
	return "CustomSignal"
end

--[=[
	Returns a new Signal object.

	```lua
	local MySignal = Signal.new()
	```

	@return Signal
]=]--
function Signal.new<T...>(): Signal<T...>
	return setmetatable({}, Signal)
end

--[=[
	Fires the Signal with the given parameters.

	```lua
	local MySignal = Signal.new()

	-- // Signal gets fired with parameters "Hello, world!"
	MySignal:Fire("Hello, world!")
	```
]=]--
function Signal:Fire(...: any)
	for callback in self do
		if not usableThread then
			usableThread = coroutine.create(yield)
			coroutine.resume(usableThread)
		end

		task.spawn(usableThread :: thread, callback, ...)
	end
end

--[=[
	Connects a function to the given Signal.

	Returns a function which disconnects the connection.
	
	```lua
	local Connection = MySignal:Connect(...)

	-- // Disconnects the Signal
	Connection()
	```
]=]--
function Signal:Connect<T...>(callback: (T...) -> ()): Disconnect
	assert(typeof(callback) == "function", "Callback is not a function!")
	assert(self[callback] ~= nil, "Callback already connected to Signal!")

	self[callback] = true

	return function()
		self[callback] = nil
	end
end

--[=[
	Connects the Signal to the function specified, but gets disconnected after it has been fired once.

	```lua
	-- // Gets disconnected after it has been connected once.
	local Connection = MySignal:Once(...)
	```
]=]--
function Signal:Once<T...>(callback: (T...) -> ())
	assert(typeof(callback) == "function", "Callback is not a function!")

	local connection

	connection = self:Connect(function(...)
		connection()
		callback(...)
	end)

	return connection
end

--[=[
	Yields until the Signal gets fired.

	```lua
	MySignal:Wait()

	-- // Prints only after the Signal has fired.
	print("Hello, world!")
	```
]=]--
function Signal:Wait()
	local running = coroutine.running()

	self:Once(function(...)
		task.spawn(running, ...)
	end)

	return coroutine.yield()
end

--[=[
	Disconnects all the connections that a Signal has.

	```lua
	local Connection1 = MySingal:Connect(...)
	local Connection2 = MySignal:Connect(...)

	-- // Disconnects both Connection1 and Connection2.
	MySignal:DisconnectAll()
	```
]=]--
function Signal:DisconnectAll()
	table.clear(self)
end

return table.freeze({
	new = Signal.new,
})
