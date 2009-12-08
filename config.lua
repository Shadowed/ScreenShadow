local L = ScreenShadowLocals
local Config = {}
local AceDialog, AceRegistry, options

local function set(info, value)
	ScreenShadow.db.profile[info[#(info) - 1]][info[#(info)]] = value
	ScreenShadow:WatchEvents()
	ScreenShadow:CheckStatus()
end

local function sliderSet(info, value)
	ScreenShadow.db.profile[info[#(info) - 1]][info[#(info)]] = value
end

local function get(info)
	return ScreenShadow.db.profile[info[#(info) - 1]][info[#(info)]]
end

local flakeSet = {}
local function getFlakeSet()
	table.wipe(flakeSet)
	for type, set in pairs(ScreenShadow.IMAGE_SETS) do flakeSet[type] = set.name end
	
	return flakeSet
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
					set = {
						order = 1,
						type = "select",
						name = L["Flake set"],
						desc = L["Set of images that should be used for fallin!g"],
						values = getFlakeSet,
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					inCombat = {
						order = 3,
						type = "toggle",
						name = L["Enable in combat"],
						desc = L["Enables falling flakes in combat, otherwise disables them in combat and will automatically hide any actively falling flakes when you enter combat."],
					},
					whileGrouped = {
						order = 4,
						type = "toggle",
						name = L["Enable while grouped"],
						desc = L["Enables falling flakes while grouped, otherwise disables it while in any party or raid."],
					},
				},
			},
			fall = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Fall settings"],
				args = {
					type = {
						order = 1,
						type = "select",
						name = L["Density"],
						desc = L["How many flakes should be falling whenever a fall comes up."],
						values = {["drizzle"] = L["Drizzle (25 flakes)"], ["light"] = L["Light (50 flakes)"], ["medium"] = L["Medium (75 flakes)"], ["heavy"] = L["Heavy (100 flakes)"], ["blizzard"] = L["Blizzard (200 flakes)"]},
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					minInterval = {
						order = 3,
						type = "range",
						name = L["Minimum seconds between falls"],
						desc = L["The minimum number of seconds the mod will wait between each snowfall."],
						min = 30, max = 600, step = 10,
						set = setSlider,
					},
					minRandom = {
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
				name = L["Flakes"],
				args = {
					alpha = {
						order = 1,
						type = "range",
						name = L["Flake alpha"],
						desc = L["Transparency of each flake."],
						min = 0.50, max = 1, step = 0.05, isPercent = true,
						set = setSlider,
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					size = {
						order = 3,
						type = "range",
						name = L["Flake size"],
						desc = L["How big each flake should be."],
						min = 5, max = 20, step = 1,
						set = setSlider,
					},
					sizeRandom = {
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
					side = {
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
					seconds = {
						order = 3,
						type = "range",
						name = L["Fall duration"],
						desc = L["How long it should take before a flake hits the bottom of the screen."],
						min = 10, max = 60, step = 1,
					},
					secondsRandom = {
						order = 4,
						type = "range",
						name = L["Fall randomizer"],
						desc = L["Another randomizer for fall duration. For example, if you set this to 10 and fall duration to 30 then flakes can take anywhere from 20 to 40 seconds to fall."],
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
					screenWidth = {
						order = 1,
						type = "range",
						min = 0.10, max = 1, step = 0.10, isPercent = true,
						name = L["Available drift space"],
						desc = L["How much of the screen flakes can drift, 50% will have them drift using half of the screen."],
					},
					screenRandom = {
						order = 2,
						type = "range",
						min = 0, max = 1, step = 0.05, isPercent = true,
						name = L["Drift space randomizer"],
						desc = L["Randomizer for drift space. For example, if you set this to 20% and drift space to 30% it can use between 10% and 50% of the screen."],
					},
					seconds = {
						order = 3,
						type = "range",
						min = 10, max = 60, step = 5,
						name = L["Drift interval"],
						desc = L["How long it should take a flake to complete one drift in seconds."],
					},
					secondsRandom = {
						order = 4,
						type = "range",
						min = 0, max = 60, step = 5,
						name = L["Drift interval randomizer"],
						desc = L["Works the same as all the other randomizers! Except this one is for the drift interval."],
					},
				},
			},
			rotation = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Rotation"],
				set = setSlider,
				args = {
					degrees = {
						order = 1,
						type = "range",
						min = 0, max = 360, step = 10,
						name = L["Degree rotation"],
						desc = L["How many degrees flakes should rotate overall."],
					},
					sep = {
						order = 2,
						type = "description",
						name = "",
					},
					seconds = {
						order = 2,
						type = "range",
						min = 10, max = 30, step = 5,
						name = L["Seconds to rotate"],
						desc = L["How many seconds it should take to rotate the flake."],
					},
					secondsRandom = {
						order = 3,
						type = "range",
						min = 0, max = 30, step = 1,
						name = L["Seconds randomizer"],
						desc = L["Randomizer for rotations."],
					},
				},
			},
		},
	}
end

local function loadOptions()
	options = {
		type = "group",	
		name = "Screen Shadow",
		childGroups = "tab",
		args = {},
	}
	
	loadGeneralOptions()
	loadExtraOptions()
end

local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Screen Shadow|r: " .. msg)
end


SLASH_SCREENSHADOW1 = "/screenshadow"
SLASH_SCREENSHADOW2 = "/screen"
SLASH_SCREENSHADOW3 = "/ss"
SlashCmdList["SCREENSHADOW"] = function(msg)
	if( not AceDialog and not AceRegistry ) then
		loadOptions()
		
		AceDialog = LibStub("AceConfigDialog-3.0")
		AceRegistry = LibStub("AceConfigRegistry-3.0")
		LibStub("AceConfig-3.0"):RegisterOptionsTable("ScreenShadow", options)
		AceDialog:SetDefaultSize("ScreenShadow", 500, 450)
	end
		
	AceDialog:Open("ScreenShadow")
end

SLASH_SNOW1 = "/snow"
SlashCmdList["SNOW"] = function(msg)
	msg = string.trim(string.lower(msg or ""))
	
	local total = msg == "drizzle" and 25 or msg == "light" and 50 or msg == "medium" and 75 or msg == "heavy" and 100 or msg == "blizzard" and 200
	if( total ) then
		print(string.format(L["Generating %s test flakes."], total))
		for i=1, total do
			ScreenShadow:ScheduleTimer("GenerateFlake", math.random(0, ScreenShadow.db.profile.fall.seconds))
		end
	elseif( msg == "stop" ) then
		print(L["Stopping all generated flakes."])
		ScreenShadow:CancelTimer("GenerateFlake", true)
		ScreenShadow:GradualStop()
	else
		print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/snow drizzle/light/medium/heavy - Generates example falls based on the passed density"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/snow stop - Stops all falling flakes"])
	end
end
