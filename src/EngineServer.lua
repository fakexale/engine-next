local _VERSION = "v1.0.0"

export type StartOptions = {
	ProductionDebugging: boolean,
	StudioDebugging: boolean,
}

local EngineLib = script.Parent.Lib

local Runtime = require(EngineLib.Runtime)
local Signal = require(EngineLib.Signal)

local DefaultOptions: StartOptions = {
	ProductionDebugging = false,
	StudioDebugging = true,
}

local EngineServer = {
	Lib = script.Parent.Lib,
}
EngineServer.Started = false
EngineServer.SignalTest = Signal.new()

function EngineServer.Start(options: StartOptions)
	assert(not EngineServer.Started, "unnamed")

	local usedOptions

	if not options then
		usedOptions = DefaultOptions
	else
		assert(typeof(options) == "table", `unnamed`)

		usedOptions = options

		for p, v in DefaultOptions do
			if not usedOptions[p] then
				usedOptions[v] = v
			end
		end
	end

	Runtime:SetSettings(usedOptions)
end

return table.freeze(EngineServer)
