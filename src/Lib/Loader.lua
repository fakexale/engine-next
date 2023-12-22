local Loader = {}

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

function Loader.MatchName(match: string): (module: ModuleScript) -> boolean
	return function(moduleScript: ModuleScript): boolean
		return string.match(moduleScript.Name, match) ~= nil
	end
end

return Loader
