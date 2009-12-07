-- Let It Snow! Mayen of Mal'Ganis US
LetItSnow = CreateFrame("Frame")
LibStub("AceTimer-3.0"):Embed(LetItSnow)

local SNOWFLAKES = {"Interface\\AddOns\\LetItSnow\\images\\snowflake1", "Interface\\AddOns\\LetItSnow\\images\\snowflake2", "Interface\\AddOns\\LetItSnow\\images\\snowflake3", "Interface\\AddOns\\LetItSnow\\images\\snowflake4", "Interface\\AddOns\\LetItSnow\\images\\snowflake5", "Interface\\AddOns\\LetItSnow\\images\\snowflake6"}
local SCREEN_WIDTH = GetScreenWidth()
local SCREEN_HEIGHT = GetScreenHeight()

local hasSnowflakesBuff, scheduledFall, isInCombat
local inactiveFlakes, activeFlakes = {}, {}

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
function LetItSnow:GenerateFlake()
	local flakeSize = self.db.flakeSize + math.random(-self.db.sizeRandomizer, self.db.sizeRandomizer)

	local frame = getFlake()
	frame:SetHeight(flakeSize)
	frame:SetWidth(flakeSize)
	frame:SetAlpha(self.db.flakeAlpha)
	frame.flake:SetTexture(SNOWFLAKES[math.random(1, #(SNOWFLAKES))])
	frame:Show()

	-- Figure out what side the flake is going to start on
	local xMod
	if( self.db.startSide == "left" or ( self.db.startSide == "both" and math.random(2) == 1 ) ) then
		xMod = 1
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.random(0, SCREEN_WIDTH - math.random(0, 100)), flakeSize)
	else
		xMod = -1
		frame:ClearAllPoints()
		frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", math.random(-SCREEN_WIDTH + math.random(0, 100), 0), flakeSize)
	end
	
	-- Sets the flakes to actually fall down!
	frame.fallAnim:SetDuration(self.db.fallDuration + math.random(-self.db.fallDurRandomizer, self.db.fallDurRandomizer))
	frame.fallAnim:SetOffset(0, -SCREEN_HEIGHT - flakeSize)
	frame.fallAnim:SetSmoothing("IN")
	frame.fallAnim:Play()
		
	-- Sets the flake to drift so they don't simply fall straight down
	local offsetVolatility = self.db.driftRandomizer * 100
	frame.driftAnim:SetDuration(self.db.driftDuration + math.random(-self.db.driftDurRandomizer, self.db.driftDurRandomizer))
	frame.driftAnim:SetOffset(xMod * (SCREEN_WIDTH * (self.db.driftScreen + math.random(-offsetVolatility, offsetVolatility) / 100)), 0)
	frame.driftAnim:SetSmoothing("OUT")
	frame.driftAnim:SetStartDelay(math.random(10, 30) / 100)
	frame.driftAnim:Play()
	
	-- Sets the flakes to rotation 360 degrees clockwise if they are starting from the left side, counterclockwise if they start on the right
	frame.rotateAnim:SetDuration(math.min(frame.fallAnim:GetDuration(), math.random(10, 30)))
	frame.rotateAnim:SetDegrees(xMod * 360)
	frame.rotateAnim:SetSmoothing("OUT")
	frame.rotateAnim:SetStartDelay(math.random(0, 50) / 100)
	frame.rotateAnim:Play()
end

-- Stopping flakes, either instantly or a gradual fade out
function LetItSnow:QuickStop()
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

function LetItSnow:GradualStop()
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
function LetItSnow:ScheduleFall()
	scheduledFall = nil
	self:CancelTimer("ScheduleLightSnow", true)
	self:CancelTimer("ScheduleHeavySnow", true)
	
	if( self.db.snowType == "light" ) then
		self:ScheduleTimer("ScheduleLightSnow", self.db.minFallInterval + math.random(0, self.db.fallRandomizer))
	else
		self:ScheduleTimer("ScheduleHeavySnow", self.db.minFallInterval + math.random(0, self.db.fallRandomizer))
	end
end

function LetItSnow:ScheduleLightSnow()
	if( not hasSnowflakesBuff ) then
		scheduledFall = true

		for i=1, 50 do
			self:ScheduleTimer("GenerateFlake", math.random(0, self.db.fallDuration))
		end
	end
	
	self:ScheduleFall()
end

function LetItSnow:ScheduleHeavySnow()
	if( not hasSnowflakesBuff ) then
		scheduledFall = true
		
		for i=1, 100 do
			self:ScheduleTimer("GenerateFlake", math.random(0, self.db.fallDuration))
		end
	end
		
	self:ScheduleFall()
end

local SNOWFLAKES_BUFF = GetSpellInfo(44755)
function LetItSnow:UNIT_AURA(event, unit)
	if( unit ~= "player" ) then return end

	local hasSnow = UnitBuff("player", SNOWFLAKES_BUFF)
	if( hasSnow and not hasSnowflakesBuff and not scheduledFall ) then
		for i=1, 200 do
			self:ScheduleTimer("GenerateFlake", i)
		end
	end

	hasSnowflakesBuff = hasSnow
end

-- Mod enabling/disabling
function LetItSnow:Enable()
	if( self.enabled ) then return end
	self.enabled = true
	
	self:ScheduleFall()
	self:UNIT_AURA()
	self:RegisterEvent("UNIT_AURA")
end

function LetItSnow:Disable()
	if( not self.enabled ) then return end
	self.enabled = nil
	
	self:UnregisterEvent("UNIT_AURA")
	self:GradualStop()
end

function LetItSnow:PLAYER_REGEN_DISABLED()
	isInCombat = true
	self:CheckStatus()
end

function LetItSnow:PLAYER_REGEN_ENABLED()
	isInCombat = nil
	self:CheckStatus()
end

function LetItSnow:CheckStatus()
	if( ( not self.db.inCombat and isInCombat ) or ( not self.db.whileGrouped and ( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) ) ) then
		self:Disable()
	else
		self:Enable()
	end
end

function LetItSnow:WatchEvents()
	if( not self.db.inCombat ) then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
			
	if( not self.db.whileGrouped ) then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED")
		self:RegisterEvent("RAID_ROSTER_UPDATE")
	else
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
		self:UnregisterEvent("RAID_ROSTER_UPDATE")
	end
end

function LetItSnow:ADDON_LOADED(event, addon)
	if( addon ~= "LetItSnow" ) then return end
	self:UnregisterEvent(event)

	LetItSnowDB = LetItSnowDB or {
		inCombat = false,
		onHandfulSnowflakes = true,
		whileGrouped = true,
		snowMelt = true,
		snowType = "light",
		minFallInterval = 60,
		fallRandomizer = 60,
		flakeAlpha = 0.70,
		flakeSize = 20,
		sizeRandomizer = 4,
		startSide = "both",
		fallDuration = 25,
		fallDurRandomizer = 5,
		driftScreen = 0.40,
		driftRandomizer = 0.10,
		driftDuration = 30,
		driftDurRandomizer = 10,
	}
	
	self.db = LetItSnowDB
	
	self.PARTY_MEMBERS_CHANGED = self.CheckStatus
	self.RAID_ROSTER_UPDATE = self.CheckStatus

	self:WatchEvents()
	self:CheckStatus()
end


LetItSnow:RegisterEvent("ADDON_LOADED")
LetItSnow:SetScript("OnEvent", function(self, event, ...)
	LetItSnow[event](LetItSnow, event, ...)
end)
