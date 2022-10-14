-- guedes
-- 08/10/22

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Globals = require(ReplicatedStorage.Modules.Globals)
local Maid = require(ReplicatedStorage.Modules.Maid)
local networker = require(ReplicatedStorage.Modules.Networker)
local AbbreviatingNumbers = require(ReplicatedStorage.Modules.AbbreviatingNumbers)

local Upgraders = {}

Upgraders.PlayerUpgraders = {}

Upgraders.__index = Upgraders

local function GetTaggedOnBoxWithFilter(Box, Tag, FilterTag)

	if not Box then return end
	local result = workspace:GetPartBoundsInBox(Box.CFrame, Box.Size)

	local donuts = {}
	if result then
		for i, j in result do
			local isDonut = CollectionService:HasTag(j, 'Dough')
			if CollectionService:HasTag(j, FilterTag) then
				continue
			end
			if isDonut then
				table.insert(donuts, j)
			end
		end
	end
	return donuts
end

function Upgraders.new(player: Player, name, folder)
	local self = setmetatable({}, Upgraders)
	self.Model = folder[name]
	self.Owner = player
	self.Button = folder.Buy
	self.Booster = Globals.Upgraders[name].Booster
	self.Price = Globals.Upgraders[name].Price or 0
	self._maid = Maid.new()
	
	if self.PlayerUpgraders[self.Owner] == nil then self.PlayerUpgraders[self.Owner] = {} end
	table.insert(self.PlayerUpgraders[self.Owner], self)
	
	return self
end 

function Upgraders:Init()
	for _, part in pairs(self.Model:GetChildren()) do
		if not part:IsA("BasePart") then continue end
		if part.Name == "Touch" then
			part.CanCollide = false
			part.CanTouch = true
		else
			part.CanCollide = true
		end
		part.Transparency = 0
	end
	local touch = self.Model:FindFirstChild("Touch")
	if touch then
		self._maid.Connection = game:GetService('RunService').Heartbeat:Connect(function()
			local donutsInBox = GetTaggedOnBoxWithFilter(touch, 'Dough', tostring(self.Model.Name))
			if donutsInBox == nil then return end
			for i, j in donutsInBox do
				task.spawn(function()
					CollectionService:AddTag(j, tostring(self.Model.Name))
					local booster = j:FindFirstChild("Booster")
					if not booster then
						local boosterValue = Instance.new("NumberValue")
						boosterValue.Parent = j
						boosterValue.Name = "Booster"
					end

					local booster = j:FindFirstChild("Booster")
					booster.Value += self.Booster
				end)
			end
		end)
	end
end

function Upgraders:ActiveButton()
	-- Active button
	
	for _, part in pairs (self.Button:GetChildren()) do
		part.Transparency = 0
		part.CanCollide = true
		part.CanTouch = true
	end
	local name = Globals.Billboards.Flavor
	local price = Globals.Billboards.Price
	
	local text2
	local priceAtt = "$".. AbbreviatingNumbers:Convert(self.Price)
	if self.Booster > 1 then
		text2 = self.Model.Name .. " (" .. tostring(self.Booster) .. "x)"
	elseif self.Booster > 0 and self.Booster < 1 then
		text2 = self.Model.Name .. " (" .. tostring(self.Booster + 1) .. "x)"
	end
	
	if self.Price == 0 then
		local success, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(Globals.Upgraders.NeonUpgrader.Id, Enum.InfoType.Product)
		end)

		if success then
			Globals.Remotes.Events.Client.setBillboard:FireClient(self.Owner, name, "V.I.P UPGRADER (2.5x)", self.Button.Touch)
			Globals.Remotes.Events.Client.setBillboard:FireClient(self.Owner, price, "R$" .. productInfo.PriceInRobux, self.Button.Touch)
		end
	else
		Globals.Remotes.Events.Client.setBillboard:FireClient(self.Owner, name, text2, self.Button.Touch)
		Globals.Remotes.Events.Client.setBillboard:FireClient(self.Owner, price, priceAtt, self.Button.Touch)
	end
	
	self.Button.Touch.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		if player.UserId == self.Owner.UserId then
			-- if price is 0 it's a ID
			if self.Price == 0 then
				-- prompt purchaseId
				MarketplaceService:PromptProductPurchase(player, Globals.Upgraders.NeonUpgrader.Id)
				return
			end
			
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats == nil then return end

			if leaderstats.Cash.Value >= self.Price then
				leaderstats.Cash.Value -= self.Price
				local Upgraders = player:FindFirstChild("Upgraders")
				if Upgraders == nil then return end
				Upgraders[self.Model.Name].Value = true
				self:Init()
				
				Globals.Remotes.Events.Client.setSound:FireClient(self.Owner, Globals.Sounds.purchase)
				Globals.Remotes.Events.Client.setParticleToObject:FireClient(self.Owner, Globals.Particles.Purchase, 1, self.Button.Touch)
				
				self.Button:Destroy()
			else
				networker.fire("notify", player, "You don't have enough cash to purchase it!")
			end
		end
	end)
end

function Upgraders.getUpgrader(player: Player, upgraderName)
	for key, value in pairs(Upgraders.PlayerUpgraders[player]) do
		if value.Model.Name == upgraderName then
			return value
		end
	end
end

function Upgraders:Destroy()
	self.PlayerUpgraders[self.Owner] = nil
	self._maid:Destroy()
end

return Upgraders
