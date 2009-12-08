-- Screen Shadow, Mayen of Mal'Ganis US
ScreenShadow = CreateFrame("Frame")
LibStub("AceTimer-3.0"):Embed(ScreenShadow)

local L = ScreenShadowLocals
local IMAGE_SETS = {}
local SCREEN_WIDTH = GetScreenWidth()
local SCREEN_HEIGHT = GetScreenHeight()

local scheduledFall, isInCombat
local inactiveFlakes, activeFlakes = {}, {}

function ScreenShadow:ADDON_LOADED(event, addon)
	if( addon ~= "ScreenShadow" ) then return end
	self:UnregisterEvent(event)

	self.defaults = {
		profile = {
			general = {
				inCombat = false,
				whileGrouped = true,
				set = "snowflakes",
			},
			fall = {
				type = "light",
				minInterval = 60,
				minRandom = 60,
				seconds = 25,
				secondsRandom = 5,
				side = "both",
			},
			flake = {
				alpha = 0.70,
				size = 20,
				sizeRandom = 4,
			},
			drift = {
				screenWidth = 0.40,
				screenRandom = 0.10,
				seconds = 30,
				secondsRandom = 20,
			},
			rotation = {
				degrees = 360,
				seconds = 20,
				secondsRandom = 10,
			},
		},
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("ScreenShadowDB", self.defaults, true)
	
	self.IMAGE_SETS = IMAGE_SETS
	self.PARTY_MEMBERS_CHANGED = self.CheckStatus
	self.RAID_ROSTER_UPDATE = self.CheckStatus

	self:WatchEvents()
	self:CheckStatus()
end

function ScreenShadow:CheckStatus()
	-- Disable
	if( ( not self.db.profile.general.inCombat and isInCombat ) or ( not self.db.profile.general.whileGrouped and ( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) ) ) then
		if( self.enabled ) then
			self.enabled = nil
			self:GradualStop()
		end
	-- Enable
	elseif( not self.enabled ) then
		self.enabled = true
		self:ScheduleFall()
	end
end

function ScreenShadow:WatchEvents()
	if( not self.db.profile.general.inCombat ) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
			
	if( not self.db.profile.general.whileGrouped ) then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED")
		self:RegisterEvent("RAID_ROSTER_UPDATE")
	else
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
	end
end

function ScreenShadow:PLAYER_REGEN_DISABLED()
	isInCombat = true
	self:CheckStatus()
end

function ScreenShadow:PLAYER_REGEN_ENABLED()
	isInCombat = nil
	self:CheckStatus()
end

-- Handle releasing and grabbing new flakes
local function OnFinished(self)
	self.parent.fallAnimGroup:Stop()
	self.parent.fadeAnimGroup:Stop()
	self.parent.driftAnimGroup:Stop()
end

local function OnStop(self)
	if( self.parent.suppress ) then return end
	
	for i=#(activeFlakes), 1, -1 do
		if( activeFlakes[i] == self.parent ) then
			table.insert(inactiveFlakes, table.remove(activeFlakes, i))
			self.parent:Hide()
			break
		end
	end
end

local function getFlake()
	local frame = table.remove(inactiveFlakes, 1)
	if( not frame ) then
		frame = CreateFrame("Frame", nil, UIParent)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetFrameLevel(1)
		
		frame.flake = frame:CreateTexture(nil, "BACKGROUND")
		frame.flake:SetAllPoints(frame)

		frame.fallAnimGroup = frame:CreateAnimationGroup()
		frame.fallAnimGroup:SetLooping("NONE")

		frame.fallAnim = frame.fallAnimGroup:CreateAnimation("Translation")
		frame.fallAnim.parent = frame
		frame.fallAnim:SetScript("OnFinished", OnFinished)
		frame.fallAnim:SetScript("OnStop", OnStop)

		frame.fadeAnimGroup = frame:CreateAnimationGroup()
		frame.fadeAnimGroup:SetLooping("NONE")

		frame.fadeAnim = frame.fadeAnimGroup:CreateAnimation("Alpha")
		frame.fadeAnim:SetScript("OnFinished", OnFinished)
		frame.fadeAnim:SetScript("OnStop", OnStop)
		frame.fadeAnim.parent = frame
		
		frame.driftAnimGroup = frame:CreateAnimationGroup("Translation")
		frame.driftAnimGroup:SetLooping("BOUNCE")
	
		frame.driftAnim = frame.driftAnimGroup:CreateAnimation("Translation")
		frame.rotateAnim = frame.driftAnimGroup:CreateAnimation("Rotation")
	end
	
	table.insert(activeFlakes, frame)
	return frame
end

-- Start a new flake off
function ScreenShadow:GenerateFlake()
	local flakeSize = self.db.profile.flake.size + math.random(-self.db.profile.flake.sizeRandom, self.db.profile.flake.sizeRandom)
	local set = IMAGE_SETS[self.db.profile.general.set] or IMAGE_SETS.snowflakes
	local frame = getFlake()
	frame:SetHeight(flakeSize)
	frame:SetWidth(flakeSize)
	frame:SetAlpha(self.db.profile.flake.alpha)
	frame.flake:SetTexture(set[math.random(1, #(set))])
	frame:Show()
		
	-- Figure out what side the flake is going to start on
	local xMod
	if( self.db.profile.fall.side == "left" or ( self.db.profile.fall.side == "both" and math.random(2) == 1 ) ) then
		xMod = 1
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.random(0, SCREEN_WIDTH - math.random(0, 100)), flakeSize)
	else
		xMod = -1
		frame:ClearAllPoints()
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", math.random(-SCREEN_WIDTH + math.random(0, 100), 0), flakeSize)
	end
	
	-- Sets the flakes to actually fall down!
	frame.fallAnim:SetDuration(self.db.profile.fall.seconds + math.random(-self.db.profile.fall.secondsRandom, self.db.profile.fall.secondsRandom))
	frame.fallAnim:SetOffset(0, -SCREEN_HEIGHT - flakeSize)
	frame.fallAnim:SetSmoothing("IN")
	frame.fallAnim:Play()
		
	-- Sets the flake to drift so they don't simply fall straight down
	local offsetVolatility = self.db.profile.drift.screenRandom * 100
	frame.driftAnim:SetDuration(self.db.profile.drift.seconds + math.random(-self.db.profile.drift.secondsRandom, self.db.profile.drift.secondsRandom))
	frame.driftAnim:SetOffset(xMod * (SCREEN_WIDTH * (self.db.profile.drift.screenWidth + math.random(-offsetVolatility, offsetVolatility) / 100)), 0)
	frame.driftAnim:SetSmoothing("OUT")
	frame.driftAnim:SetStartDelay(math.random(10, 30) / 100)
	frame.driftAnim:Play()
	
	-- Sets the flakes to rotation 360 degrees clockwise if they are starting from the left side, counterclockwise if they start on the right
	local rotateMod = math.random(1, 2) == 1 and 1 or -1
	frame.rotateAnim:SetDuration(self.db.profile.rotation.seconds + math.random(-self.db.profile.rotation.secondsRandom, self.db.profile.rotation.secondsRandom))
	frame.rotateAnim:SetDegrees(rotateMod * self.db.profile.rotation.degrees)
	frame.rotateAnim:SetSmoothing("OUT")
	frame.rotateAnim:SetStartDelay(math.random(0, 50) / 100)
	frame.rotateAnim:Play()
end

-- Stopping flakes, either instantly or a gradual fade out
function ScreenShadow:QuickStop()
	self:CancelAllTimers()

	for _, frame in pairs(activeFlakes) do
		frame.suppress = true
		frame.fallAnimGroup:Stop()
		frame.driftAnimGroup:Stop()
		frame.fadeAnimGroup:Stop()
		frame:Hide()
	end
	
	for i=#(activeFlakes), 1, -1 do
		local frame = table.remove(activeFlakes, i)
		frame.suppress = nil
		table.insert(inactiveFlakes, frame)
	end
end

function ScreenShadow:GradualStop()
	self:CancelAllTimers()

	for _, frame in pairs(activeFlakes) do
		if( not frame.fadeAnim:IsPlaying() ) then
			frame.fadeAnim:SetDuration(0.75)
			frame.fadeAnim:SetChange(-1)
			frame.fadeAnim:SetSmoothing("IN")
			frame.fadeAnim:Play()
		end
	end
end

-- Deals with creating snow, this creates it in 30 second intervals
function ScreenShadow:ScheduleFall()
	scheduledFall = nil
	
	local flakes = self.db.profile.fall.type == "drizzle" and 25 or self.db.profile.fall.type == "light" and 50 or self.db.profile.fall.type == "medium" and 75 or self.db.profile.fall.type == "heavy" and 100 or self.db.profile.fall.type == "blizzard" and 200
	self:CancelTimer("ScheduleFlakeFalling", true)
	self:ScheduleTimer("ScheduleFlakeFalling", self.db.profile.fall.minInterval + math.random(0, self.db.profile.fall.minRandom), flakes)
end

function ScreenShadow:ScheduleFlakeFalling(total)
	for i=1, total do
		self:ScheduleTimer("GenerateFlake", math.random(0, self.db.profile.fall.seconds))
	end

	scheduledFall = true
	self:ScheduleFall()
end

-- If you want to register your own set for use within the addon
function ScreenShadow:RegisterSet(type, name, ...)
	IMAGE_SETS[type] = {name = name, ...}
end

-- Register the default set of course
ScreenShadow:RegisterSet("snowflakes", L["Snowflakes"], "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\1", "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\2", "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\3", "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\4", "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\5", "Interface\\AddOns\\ScreenShadow\\sets\\snowflakes\\6")
ScreenShadow:RegisterSet("petals", L["Petals"], "Interface\\AddOns\\ScreenShadow\\sets\\petals\\1", "Interface\\AddOns\\ScreenShadow\\sets\\petals\\2", "Interface\\AddOns\\ScreenShadow\\sets\\petals\\3", "Interface\\AddOns\\ScreenShadow\\sets\\petals\\4")


ScreenShadow:RegisterEvent("ADDON_LOADED")
ScreenShadow:SetScript("OnEvent", function(self, event, ...)
	ScreenShadow[event](ScreenShadow, event, ...)
end)
