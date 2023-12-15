local RunService = game:GetService("RunService")

export type RuntimeSettings = {
	ProductionDebugging: boolean,
	StudioDebugging: boolean,

	Version: string,
}

local Runtime = {
	["RuntimeContext"] = table.freeze({
		Server = RunService:IsServer(),
		Client = RunService:IsClient(),

		Studio = RunService:IsStudio(),
		Playtest = RunService:IsStudio() and RunService:IsRunning(),
	}),

	["RuntimeSettings"] = {
		["ProductionDebugging"] = false,
		["StudioDebugging"] = true,
		["Version"] = "...",
	},

	["RuntimeObjects"] = {
		["Packets"] = {},
	},
}

function Runtime:SetSettings(newSettings: { RuntimeSettings })
	self["RuntimeSettings"] = newSettings
end

function Runtime:GetSettings(): RuntimeSettings
	return self["RuntimeSettings"]
end

return table.freeze(Runtime)
