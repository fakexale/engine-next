local Players = game:GetService("Players")

local Packages = script.Parent.Packages
local EngineLib = script.Parent.Lib

local Promise = require(Packages.Promise)

--[=[
	@class EngineClient

	Client-sided portion of the framework, parallel to EngineServer.
	Used to access client-sided scopes, no other differences.
]=]--
local EngineClient = {
	Lib = EngineLib,
	Imported = {},
}

--[=[
	@private 

	Handles common connections such as PlayerAdded, PlayerRemoving and BindToClose.
	You can use [Loader](/api/Loader) to achieve this with a diverse API.
]=]--
function EngineClient:_HandleConnections()
	local function PlayerAdded(player: Player)
		for _, module in self.Imported do
			if type(module.PlayerAdded) ~= "function" then continue end

			task.spawn(module.PlayerAdded, player)
		end
	end

	local function PlayerRemoving(player: Player)
		for _, module in self.Imported do
			if type(module.PlayerRemoving) ~= "function" then continue end

			task.spawn(module.PlayerRemoving, player)
		end
	end

	local function BindToClose()
		for _, module in self.Imported do
			if type(module.BindToClose) ~= "function" then continue end

			task.spawn(module.BindToClose)
		end
	end

	game:BindToClose(BindToClose)
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

--[=[
	Imports the children of ``path`` which are of class ``ModuleScript``.

	Essentially, requires and sets up commonly used connections a script might have.
]=]--
function EngineClient:Import(path: Instance)
	return Promise.new(function(resolve)
		local Inits = {}

		for _, module in path:GetChildren() do
			local requiredModule = require(module)
			self.Imported[module.Name] = requiredModule

  			if type(requiredModule.OnInit) ~= "function" then continue end
			
			debug.setmemorycategory(module.Name)

    		table.insert(Inits,	Promise.new(function(_resolve)
					debug.setmemorycategory(module.Name)
					requiredModule:OnInit()
					_resolve()
				end)
			)
		end

		resolve(Promise.all(Inits))
	end):andThen(function()
		for p, module in self.Imported do
			if type(module.OnStart) ~= "function" then continue end

			task.spawn(function()
				debug.setmemorycategory(p)
				module:OnStart()
			end)
		end
	end):andThen(function()
		EngineClient:_HandleConnections()
	end)
end

return table.freeze(EngineClient)
