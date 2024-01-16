local RunService = game:GetService("RunService")

warn("Engine3 is unfinished, but is still usable excluding EngineClient.")

if RunService:IsServer() then
	return require(script.EngineServer)
else
	local EngineServer = script:FindFirstChild("EngineServer")

	if EngineServer and RunService:IsRunning() then
		EngineServer:Destroy()
	end

	return require(script.EngineClient)
end
