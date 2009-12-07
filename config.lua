local L = LetItSnowLocals
local Config = {}
local AceDialog, AceRegistry, options

LetItSnowLocals = setmetatable(LetItSnowLocals, {
	__index = function(tbl, value)
		rawset(tbl, value, value)
		return value
	end,
})

local function set(info, value)
	LetItSnow.db[info[#(info)]] = value
	LetItSnow:WatchEvents()
	LetItSnow:CheckStatus()
end

local function sliderSet(info, value)
	LetItSnow.db[info[#(info)]] = value
end

local function get(info)
	return LetItSnow.db[info[#(info)]]
end

local function loadGeneralOptions()
	options.args.general = {
		order = 1,
		type = "group",
		name = L["General"],
		set = set,
		get = get,
		args = {
			general = {
				order = 0,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					onHandfulSnowflakes = {
						order = 1,
						type = "toggle",
						name = L["Snowfall when snowflaked"],
						desc = L["Automatically snowfalls you when somebody uses Handful of Snowflakes on yourself."],
						width = "full",
					},
					inCombat = {
						order = 2,
						type = "toggle",
						name = L["Enable in combat"],
						desc = L["Enables snowfalls in combat, otherwise disables all snowfalls in combat and will automatically hide any actively falling snow when you enter combat."],
					},
					whileGrouped = {
						order = 3,
						type = "toggle",
						name = L["Enable while grouped"],
						desc = L["Enables snowfall while grouped, otherwise disables it while in any party or raid."],
					},
					snowMelt = {
						order = 4,
						type = "toggle",
						name = L["Enable snow buildup"],
						desc = L["Instead of falling off the screen, snow will build up on the bottom and gradually fade out."],
						hidden = true,
					},
				},
			},
			snowFall = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Snowfall"],
				args = {
					snowType = {
						order = 1,
						type = "select",
						name = L["Snowfall density"],
						desc = L["How heavy it should snow whenever an interval snowfall comes up."],
						values = {["light"] = L["Light"], ["heavy"] = L["Heavy"]},
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					minFallInterval = {
						order = 3,
						type = "range",
						name = L["Minimum seconds between falls"],
						desc = L["The minimum number of seconds the mod will wait between each snowfall."],
						min = 30, max = 600, step = 10,
						set = setSlider,
					},
					fallRandomizer = {
						order = 4,
						type = "range",
						name = L["Fall randomizer"],
						desc = L["Applies a randomized number of seconds that is added to the minimum seconds between each snowfall."],
						min = 0, max = 300, step = 10,
						set = setSlider,
					},
				},
			},
			flake = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Snowflakes"],
				args = {
					flakeAlpha = {
						order = 1,
						type = "range",
						name = L["Flake alpha"],
						desc = L["Transparency of each snowflake."],
						min = 0.50, max = 1, step = 0.05, isPercent = true,
						set = setSlider,
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					flakeSize = {
						order = 3,
						type = "range",
						name = L["Flake size"],
						desc = L["How big each snowflake should be."],
						min = 5, max = 20, step = 1,
						set = setSlider,
					},
					sizeRandomizer = {
						order = 4,
						type = "range",
						name = L["Size randomizer"],
						desc = L["Applies a randomized number to the flake size. For example if you set this to 5 and flake size to 15, the addon will big flakes that are anywhere from 10 to 20."],
						min = 0, max = 10, step = 1,
					},
				},
			},
		},	
	}
end

local function loadExtraOptions()
	options.args.extra = {
		order = 2,
		type = "group",
		name = L["Extras"],
		set = set,
		get = get,
		args = {
			info = {
				order = 0,
				type = "group",
				inline = true,
				name = L["Info"],
				args = {
					info = {
						order = 0,
						type = "description",
						name = L["If you are crazy, or perhaps bored you can refine how the snowflakes will fall here. You do not have to thought as it will fall fine without you tweaking these."],
					},
				},
			},
			fall = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Falling"],
				set = setSlider,
				args = {
					startSide = {
						order = 1,
						type = "select",
						name = L["Start from"],
						desc = L["Side of the screen to start snowing from, both will randomly choose."],
						values = {["both"] = L["Both sides"], ["left"] = L["Left side"], ["right"] = L["Right side"]},
						set = set,
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					fallDuration = {
						order = 3,
						type = "range",
						name = L["Fall duration"],
						desc = L["How long it should take before a snowflake hits the bottom of the screen."],
						min = 10, max = 60, step = 1,
					},
					fallDurRandomizer = {
						order = 4,
						type = "range",
						name = L["Fall randomizer"],
						desc = L["Another randomizer for fall duration. For example, if you set this to 10 and fall duration to 30 then snowflakes can take anywhere from 20 to 40 seconds to fall."],
					},
				},
			},
			drift = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Drifting"],
				set = setSlider,
				args = {
					driftScreen = {
						order = 1,
						type = "range",
						min = 0.10, max = 1, step = 0.10, isPercent = true,
						name = L["Available drift space"],
						desc = L["How much of the screen snowflakes can drift, 50% will have them drift using half of the screen."],
					},
					driftRandomizer = {
						order = 2,
						type = "range",
						min = 0, max = 1, step = 0.05, isPercent = true,
						name = L["Drift space randomizer"],
						desc = L["Randomizer for drift space. For example, if you set this to 20% and drift space to 30% it can use between 10% and 50% of the screen."],
					},
					driftDuration = {
						order = 3,
						type = "range",
						min = 10, max = 60, step = 5,
						name = L["Drift interval"],
						desc = L["How long it should take a snowflake to complete one drift in seconds."],
					},
					driftDurRandomizer = {
						order = 4,
						type = "range",
						min = 0, max = 60, step = 5,
						name = L["Drift interval randomizer"],
						desc = L["Works the same as all the other randomizers! Except this one is for the drift interval."],
					},
				},
			},
		},
	}
end

local function loadOptions()
	options = {
		type = "group",	
		name = "Let It Snow!",
		childGroups = "tab",
		args = {},
	}
	
	loadGeneralOptions()
	loadExtraOptions()
end

local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Let It Snow|r: " .. msg)
end


SLASH_LETITSNOW1 = "/letitsnow"
SLASH_LETITSNOW2 = "/lis"
SlashCmdList["LETITSNOW"] = function(msg)
	if( not AceDialog and not AceRegistry ) then
		loadOptions()
		
		AceDialog = LibStub("AceConfigDialog-3.0")
		AceRegistry = LibStub("AceConfigRegistry-3.0")
		LibStub("AceConfig-3.0"):RegisterOptionsTable("LetItSnow", options)
		AceDialog:SetDefaultSize("LetItSnow", 500, 450)
	end
		
	AceDialog:Open("LetItSnow")
end

SLASH_SNOW1 = "/snow"
SlashCmdList["SNOW"] = function(msg)
	msg = string.trim(string.lower(msg or ""))
	
	if( msg == "heavy" ) then
		print("Forecasts call for heavy snow!")
		for i=1, 100 do
			LetItSnow:ScheduleTimer("GenerateFlake", math.random(0, LetItSnow.db.fallDuration))
		end
		
	elseif( msg == "light" ) then
		print("Forecasts call for light snow!")
		for i=1, 50 do
			LetItSnow:ScheduleTimer("GenerateFlake", math.random(0, LetItSnow.db.fallDuration))
		end
	elseif( msg == "stop" ) then
		print("Forecasts predict it will clear up :(")
		LetItSnow:CancelTimer("GenerateFlake", true)
		LetItSnow:GradualStop()
	else
		print("Type either /snow light for simulating light snow, /snow heavy for heavy snow or /snow stop to stop all snow.")
	end
end
