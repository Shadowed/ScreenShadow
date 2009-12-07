LetItSnow = CreateFrame("Frame")
local flakes = {"Interface\\AddOns\\LetItSnow\\snowflake1", "Interface\\AddOns\\LetItSnow\\snowflake2", "Interface\\AddOns\\LetItSnow\\snowflake3", "Interface\\AddOns\\LetItSnow\\snowflake4", "Interface\\AddOns\\LetItSnow\\snowflake5", "Interface\\AddOns\\LetItSnow\\snowflake6"}
local FLAKE_SIZE = 16
local FLAKE_DRIFT = 0.10
local DRIFT_VOLITILITY = 5
local TIME_TO_FALL = 60

function LetItSnow:Test()
if( frame ) then frame:Hide() end
if( textures ) then for _, texture in pairs(textures) do texture:Hide() end end

local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()
local FLAKE_SIZE = 16
local FLAKE_DRIFT = 0.10
local DRIFT_VOLITILITY = 5
local TIME_TO_FALL = 20
local FALL_VOLITILITY = 10
local UPDATE_THRESHOLD = 0.02
local PIXELS_PER_UPDATE = (screenHeight / TIME_TO_FALL) * UPDATE_THRESHOLD


textures = {}
for i=1, 10 do
   textures[i] = UIParent:CreateTexture(nil, "ARTWORK")
   textures[i]:SetHeight(FLAKE_SIZE)
   textures[i]:SetWidth(FLAKE_SIZE)
   textures[i]:SetTexture("Interface\\AddOns\\LetItSnow\\snowflake1")
   
   textures[i].xPos = i * 50
   textures[i].yPos = i * 10
   
   textures[i].driftEnd = screenWidth * (FLAKE_DRIFT + math.random(-DRIFT_VOLITILITY, DRIFT_VOLITILITY) / 100)
   textures[i].driftPos = 0
   textures[i].driftType = "right"
   textures[i].driftPixelsPer = (textures[i].driftEnd / math.random(5, 20)) * UPDATE_THRESHOLD
   
   textures[i].fallPixelsPer = screenWidth / (TIME_TO_FALL + math.random(-FALL_VOLITILITY, FALL_VOLITILITY)) * UPDATE_THRESHOLD
end

frame = CreateFrame("Frame")
frame.timeElapsed = 0
frame:SetScript("OnUpdate", function(self, elapsed)
      self.timeElapsed = self.timeElapsed + elapsed
      if( self.timeElapsed < UPDATE_THRESHOLD ) then return end
      self.timeElapsed = self.timeElapsed - UPDATE_THRESHOLD
      
      for _, texture in pairs(textures) do
         texture.yPos = texture.yPos - texture.fallPixelsPer
         if( texture.switchingDrifts ) then
            texture.switchingDrifts = texture.switchingDrifts - UPDATE_THRESHOLD
            if( texture.switchingDrifts <= 0 ) then texture.switchingDrifts = nil end
         elseif( texture.driftType == "right" ) then
            texture.driftPos = texture.driftPos + texture.driftPixelsPer
            if( texture.driftPos >= texture.driftEnd ) then
               texture.driftType = "left" 
               texture.switchingDrifts = math.random(2, 8) / 100
            end
         elseif( texture.driftType == "left" ) then
            texture.driftPos = texture.driftPos - texture.driftPixelsPer
            if( texture.driftPos <= 0 ) then 
               texture.driftType = "right"
               texture.switchingDrifts = math.random(2, 8) / 100
            end
         end
         
         texture:SetPoint("TOPLEFT", UIParent, "TOPLEFT", texture.xPos + texture.driftPos, texture.yPos)
      end
end)
end


function LetItSnow:ADDON_LOADED(event, addon)
	if( addon ~= "LetItSnow" ) then return end
	LetItSnowDB = LetItSnowDB or {}
	self.db = LetItSnowDB
	
	
	
	self:UnregisterEvent(event)
end


LetItSnow:RegisterEvent("ADDON_LOADED")
LetItSnow:SetScript("OnEvent", function(self, event, ...)
	LetItSnow[event](LetItSnow, event, ...)
end)
