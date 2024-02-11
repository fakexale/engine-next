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

--[=[
	@type Disconnect () -> () -> Disconnect
	@within Signal

	Returned by ``Signal.new``, used to Disconnect the function.
]=]
--
type Disconnect = () -> () -> Disconnect

export type Module<T...> = {
	__tostring: (self: Signal<T...>) -> "CustomSignal",
	new: () -> Signal<T...>,
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	ConnectLimited: (self: Signal<T...>, (T...) -> (), Amount: number) -> Disconnect,
	ConnectUntil: (self: Signal<T...>, (T...) -> (), Seconds: number) -> () -> (),
	ConnectStrict: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Once: (self: Signal<T...>, (T...) -> ()) -> Disconnect,
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> (),
}
export type Signal<T...> = typeof(setmetatable({} :: { [(T...) -> ()]: boolean }, {} :: Module<T...>))

--[=[
	@class Signal

	A simple custom implementation for [RBXScriptSignals](https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal).

	Unlike most Signal implementions, does not have a discrete Disconnect method.
]=]
--
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
]=]
--
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
]=]
--
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
]=]
--
function Signal:Connect<T...>(callback: (T...) -> ()): Disconnect
	assert(typeof(callback) == "function", "Callback is not a function!")
	assert(self[callback] ~= nil, "Callback already connected to Signal!")

	self[callback] = true

	return function()
		self[callback] = nil

		return function()
			return self:Connect(callback)
		end
	end
end

--[=[
	Connects the event to the callback, automaticly disconnects after the event was fired an amount of times. 

	```lua
	-- // Will get disconnected after the callback has connect 15 times
	local Connection = Signal:ConnectLimited(myFunc, 15)
	```
]=]
--
function Signal:ConnectLimited<T...>(callback: (T...) -> (), amount: number): Disconnect
	local fired = 0
	local connection

	connection = self:Connect(function(...)
		fired += 1

		if fired == amount then
			connection()
		end

		callback(...)
	end)

	return connection
end

--[=[
	Connects the event to the callback, automatically disconnects after the time specified elapses.

	```lua
	-- // Disconnects after 15 seconds have elapsed after the connection.
	local MyConnection = Signal:ConnectUntil(myFunc, 15)
	```
]=]
--
function Signal:ConnectUntil<T...>(callback: (T...) -> (), seconds: number): () -> ()
	local connection

	connection = self:Connect(callback)

	local delayer = task.delay(seconds, function()
		connection()
	end)

	return function()
		if coroutine.status(delayer) ~= "dead" then
			task.cancel(delayer)
			connection()
		end
	end
end

--[=[
	Connects the event to the callback, if the callback returns true, it will disconnect the event. 

	```lua
	-- Script 1

	-- // Returns whether a number in nums is even
	local function myFunc(nums: { number }): boolean
		for _, v in pairs(nums) do
			if (v % 2 == 0) then
				return true
			else
				return false
			end
		end
	end

	local MyConnection = MySignal:ConnectStrict(myFunc)

	-- Script 2

	-- // Won't trigger a disconnect
	MySignal:Fire({1, 3, 5})

	-- // Will trigger a disconnect
	MySignal:Fire({2, 4, 6})
	```
]=]
--

function Signal:ConnectStrict<T...>(callback: (T...) -> ()): Disconnect
	local connection

	connection = self:Connect(function(...)
		if callback(...) == false then
			connection()
		end
	end)

	return connection
end

--[=[
	Connects the Signal to the function specified, but gets disconnected after it has been fired once.

	```lua
	-- // Gets disconnected after it has been connected once.
	local Connection = MySignal:Once(...)
	```
]=]
--
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
]=]
--
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
]=]
--
function Signal:DisconnectAll()
	table.clear(self)
end

return table.freeze({
	new = Signal.new,
})
