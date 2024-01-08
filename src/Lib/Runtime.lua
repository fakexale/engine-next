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

function Runtime:BindHeartbeatEvery(ticks: number, fn: () -> ()): () -> ()
	local currentTick = 0

	local connection = RunService.Heartbeat:Connect(function()
		currentTick += 1

		if currentTick >= ticks then 
			currentTick = 0 
			return
		end

		fn()
	end)

	return function()
		connection:Disconnect()
	end
end

return table.freeze(Runtime)
