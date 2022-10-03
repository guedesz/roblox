-- guedes
-- 05/09/2022

local CrazyDonuts = {}
CrazyDonuts.__index = CrazyDonuts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Modules.Globals)
local Maid = require(ReplicatedStorage.Modules.Maid)

function CrazyDonuts.new(time)
	local self = setmetatable({}, CrazyDonuts)
	self._maid = Maid.new()
	self.IncreaseBooster = 2
	self.Active = false
	self.Timer = Instance.new("IntValue")
	self.Timer.Name = "crazyDonutsTimer"
	self.Timer.Value = time
	self.Timer.Parent = ReplicatedStorage.Server
	self._maid:GiveTask(self.Timer)
	self.Players = {} -- Storing old booster values
	
	return self
end

function CrazyDonuts:Start()
	print("Starting Crazy Donuts Time!")
	if _G.isEventOn == true then 
		print("A Crazy Donuts time is already happening") 
		self:Destroy() 
		return
	end
	_G.isEventOn = true
	
	local function updateBooster(player: Player)
		if not player then return end
		self:_updateScreen(player)
		task.spawn(function() self:CountDown() end)
		
		if not self.Players[player.Name] then

			self.Players[player.Name] = {}
			task.spawn(function()
				local Data = player:FindFirstChild("Data")
				if Data == nil then return end
				self.Players[player.Name] = Data.Booster.Value
				Data.Booster.Value = Data.Booster.Value * self.IncreaseBooster
			end)
		end
		local vipTrail = player.Character.Head:FindFirstChild("VIPTrail")
		if vipTrail then
			vipTrail.Lifetime = 0
		end
		local EventTrail = ServerStorage.Tools.EventTrail:Clone()
		EventTrail.Parent = player.Character.Head
		local attachment0 = Instance.new("Attachment", player.Character.Head)
		attachment0.Name = "T0"
		local attachemnt1 = Instance.new("Attachment", player.Character.HumanoidRootPart)
		attachemnt1.Name = "T1"
		EventTrail.Attachment0 = attachment0
		EventTrail.Attachment1 = attachemnt1
	end
	
	local function onPlayerRemoving(player: Player)
		if not player then return end
		local Data = player:FindFirstChild("Data")
		if Data == nil then return end
		print("Player left the game, restoring old value")
		Data.Booster.Value = tonumber(self.Players[player.Name])
	end
	
	self._maid.Update = updateBooster
	self._maid.Removing = onPlayerRemoving
	
	-- starting and update booster value
	self._maid:GiveTask(Players.PlayerAdded:Connect(updateBooster))
	-- Returning to old value if logout
	self._maid:GiveTask(Players.PlayerRemoving:Connect(onPlayerRemoving))

	for _, player in pairs(game.Players:GetPlayers()) do
		updateBooster(player)
	end

end

function CrazyDonuts:CountDown()
	repeat wait(1) self.Timer.Value -= 1 until self.Timer.Value < 1
	self:Destroy()
end

function CrazyDonuts:_updateScreen(player: Player)
	self._maid.ClientConnection = Globals.Remotes.Events.Client.setCrazyUI:FireClient(player, self.Timer, true, "Message2")
end

function CrazyDonuts:_resetPlayersBoosters()
	for player, value in pairs(self.Players) do
		local realPlayer = Players:FindFirstChild(player)
		if realPlayer then
			local Data = realPlayer:FindFirstChild("Data")
			if Data == nil then return end
			
			Data.Booster.Value = tonumber(value)
		end
	end
end

function CrazyDonuts:Destroy()
	print("Ending Crazy Donuts time!")
	_G.isEventOn = false
	self._maid.ClientConnection = nil
	self:_resetPlayersBoosters()
	
	for player, value in pairs(self.Players) do
		local vipTrail = Players:FindFirstChild(player).Character.Head:FindFirstChild("VIPTrail")
		if vipTrail then
			vipTrail.Lifetime = 1
		end
		local EventTrail = Players:FindFirstChild(player).Character.Head:FindFirstChild("EventTrail")
		if EventTrail then
			EventTrail:Destroy()
		end
	end
	self._maid:DoCleaning()
end

return CrazyDonuts

