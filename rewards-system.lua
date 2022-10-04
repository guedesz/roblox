-- GUEDES
-- 03/10/22

---------- CLASS SERVER SIDE ----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local networker = require(ReplicatedStorage.Modules.Networker)


local Maid = require(ReplicatedStorage.Modules.Maid)
local Rewards = {}

Rewards.objects = {}

Rewards.__index = Rewards

function Rewards.Init(player)
	local self = setmetatable({}, Rewards)
	self.Owner = player
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "Rewards"
	self.Folder.Parent = player
	self.Tier1 = Instance.new("NumberValue")
	self.Tier1.Name = "Tier1"
	self.Tier1.Value = 10 --300
	
	self.Tier2 = Instance.new("NumberValue")
	self.Tier2.Name = "Tier2"
	self.Tier2.Value = 20 --900
	
	self.Tier3 = Instance.new("NumberValue")
	self.Tier3.Name = "Tier3"
	self.Tier3.Value = 30 --2400
	
	self.Tier1.Parent = self.Folder
	self.Tier2.Parent = self.Folder
	self.Tier3.Parent = self.Folder
	
	self._maid = Maid.new()
	self._maid:GiveTask(self.Folder)

	self._maid.playerRemoving = Players.PlayerRemoving:Connect(function(player) self:Destroy() end)
	
	self.objects[self.Owner.Name] = self
	
	return self
end

function Rewards:RestartValue(tierName)
	
end

function Rewards:Start()
	
	task.spawn(function()
		while true do
			task.wait(1)
      -- get values from folder and decrease per second
			for _, value in pairs(self.Folder:GetChildren()) do
				if not value then break end
				if value.Value >= 1 then
					value.Value -= 1
				end
			end
		end
	end)
end

function Rewards:ApplyReward(reward)
	local rewards = {
		["Tier1"] = {
			["Cash"] = 250,
			["defaultTimer"] = 10,
		},
		["Tier2"] = {
			["Cash"] = 1000,
			["defaultTimer"] = 20,
		},
		["Tier3"] = {
			["Cash"] = 5000,
			["defaultTimer"] = 30,
		},
		
	}
	
	local leaderstats = self.Owner:FindFirstChild("leaderstats")
	if leaderstats == nil then return end
	
	leaderstats.Cash.Value += rewards[reward].Cash
	
	self[reward].Value = rewards[reward].defaultTimer
	
end

function Rewards.GetPlayerObject(player)
	return Rewards.objects[player.Name]
	
end
function Rewards:Destroy()
	self.objects[self.Owner.Name] = nil
	self._maid.playerRemoving = nil
	self._maid.connection = nil
	self._maid:Destroy()
end


return Rewards

---------- CLASS SERVER SIDE ----------------------------

---------- SERVER SIDE ------------------------------------
local function reward(player)
	local reward = Rewards.Init(player)
	reward:Start()
end
for _, player in pairs(Players:GetPlayers()) do
	reward(player)
end

Players.PlayerAdded:Connect(reward)

networker.bind("getGift", function(player, giftTier)
	
	local playerObject = Rewards.GetPlayerObject(player)
	if playerObject then
		if playerObject[giftTier].Value == 0 then
			-- use method from class to give the right reward.
			playerObject:ApplyReward(giftTier)
			return true
		end
	end
	return false
end)

--------------- SERVER SIDE -------------------

--------- CLIENT SIDE -------------------------

for _, frame in (GiftGui.Frame:GetChildren()) do
	if frame:IsA("Frame") then
		frame.TextButton.MouseButton1Click:Connect(function()
			local success = networker.fire("getGift", frame.Name)
			
			if not success then
				CFB.warnPlayer("You tried to claim a gift too early.")
			else
				Globals.Sounds.sparkleArcade:Play()
			end
		end)
	end
end
