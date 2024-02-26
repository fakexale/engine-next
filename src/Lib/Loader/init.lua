--[=[
	@class Loader

	A utillity module used for loading ModuleScripts.
]=]--
local Loader = {}

--[=[
	Loads the children of the given Instance

	```lua
	Loader.LoadChildren(modules)

	-- See Loader.MatchName() for how this works.
	Loader.LoadChildren(modules, Loader.MatchName("Service$"))
	```
]=]--
function Loader.LoadChildren(path: Instance, predicate: (module: ModuleScript) -> boolean?): { [string]: any }
	local loaded: { [string]: any } = {}

	for _, module in path:GetChildren() do
		if not module:IsA("ModuleScript") then
			continue
		end

		if predicate and not predicate(module) then
			continue
		end

		local required = require(module)
		loaded[module.Name] = required
	end

	return loaded
end


--[=[
	Loads the descendants of the given Instance

	```lua
	Loader.LoadDescendants(modules)

	-- See Loader.MatchName() for how this works.
	Loader.LoadDescendants(modules, Loader.MatchName("Service$"))
	```
]=]--
function Loader.LoadDescendants(path: Instance, predicate: (module: ModuleScript) -> boolean?): { [string]: any }
	local loaded: { [string]: any } = {}

	for _, module in path:GetDescendants() do
		if not module:IsA("ModuleScript") then
			continue
		end

		if predicate and not predicate(module) then
			continue
		end

		local required = require(module)
		loaded[module.Name] = required
	end

	return loaded
end


--[=[
	Spawn the ``methodName`` of the given ``loadedModules`` returned by ``LoadChildren`` and ``LoadDescendants``.

	Methods are called with ``task.spawn``.

	```lua
	local LoadedModules = Loader.LoadChildren(modules)

	-- If function "Init", if it exists.
	Loader.SpawnAll(LoadedModules, "Init")
	```
]=]--
function Loader.SpawnAll(loadedModules: { [string]: any }, methodName: string)
	for moduleName, module in loadedModules do
		local method = module[methodName]

		if type(method) ~= "function" then
			continue
		end

		task.spawn(function()
			debug.setmemorycategory(moduleName)
			method(module)
		end)
	end
end

--[=[
	A function act as the predicate for ``LoadChildren`` and ``LoadDescendants``.

	```lua
	-- Loads children, if Loader.MatchName() resolves to true.
	Loader.LoadChildren(modules, Loader.MatchName("Service$"))
	```
]=]--
function Loader.MatchName(match: string): (module: ModuleScript) -> boolean
	return function(moduleScript: ModuleScript): boolean
		return string.match(moduleScript.Name, match) ~= nil
	end
end

return Loader
