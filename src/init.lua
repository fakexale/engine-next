local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script.EngineServer)
else
	local EngineServer = script:FindFirstChild("EngineServer")

	if EngineServer and RunService:IsRunning() then
		EngineServer:Destroy()
	end

	return require(script.EngineClient)
end
