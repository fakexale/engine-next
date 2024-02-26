local RunService = game:GetService("RunService")

local Runtime = {
	["Context"] = table.freeze({
		Server = RunService:IsServer(),
		Client = RunService:IsClient(),

		Studio = RunService:IsStudio(),
		Playtest = RunService:IsStudio() and RunService:IsRunning(),
	})
}

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

return Runtime
