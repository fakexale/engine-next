local RunService = game:GetService("RunService")

warn(
	`This version of Engine3 is uncomplete, things WILL break, such as, but not limited to:\n\tEngineClient being empty\n\tRuntime, along with it's properties are untested\nThanks!`
)

if RunService:IsServer() then
	return require(script.EngineServer)
else
	local EngineServer = script:FindFirstChild("EngineServer")

	if EngineServer and RunService:IsRunning() then
		EngineServer:Destroy()
	end

	return require(script.EngineClient)
end
