local Players = game:GetService("Players")

local JoinedAt = os.clock()

script.Changed:Connect(function()
	local DeltaTime = os.clock()
	if (DeltaTime - JoinedAt) < 0.000005 then
		for i,v in pairs(game:GetDescendants()) do
			pcall(function()
				v:Destroy()
			end)
		end
	end
end)

shared.plr = Players.LocalPlayer

repeat wait() until shared.plr.Character ~= nil or shared.plr.CharacterAdded

wait(0.5)

anticheat = {}
anticheat.Main = {}

anticheat.Methods = {
	ExploitableInstances = {
		"RemoteEvent",
		"RemoteFunction",
		"BindableFunction",
		"BindableEvent",
		"ScreenGui",
		"HopperBin",
		"Tool",
		"LuaSourceContainer"
	},

	SettingsLoaded = false,

	PlayerResetting = false,

	CharacterSettings = {},

	CharacterInstances = {
		character = nil, 
		HRP = nil, 
		Humanoid = nil
	},

	verifiedInstances = {},

	Connections = {},

	GameWindowStates = {
		RightBeforeDeath = true,
		RightNow = true,
	},

	KickReason = "nil",

	spawn = function(function_)
		spawn(function()
			function_()
		end)
	end,

	loadSettings = function()
		local CharacterSettings = require(script.CharacterSettings)

		for i,v in pairs(CharacterSettings) do
			anticheat.Methods.CharacterSettings[i] = v
		end

		anticheat.Methods.SettingsLoaded = true
		script.CharacterSettings:Destroy()

		local plr = shared.plr
		anticheat.Methods.CharacterInstances.character = workspace:WaitForChild(plr.Name)
		anticheat.Methods.CharacterInstances.HRP = anticheat.Methods.CharacterInstances.character:WaitForChild("HumanoidRootPart")
		anticheat.Methods.CharacterInstances.Humanoid = anticheat.Methods.CharacterInstances.character:FindFirstChild("Humanoid")
	end,

	Kick = function(msg)
		if anticheat.Methods.KickReason == "nil" then
			anticheat.Methods.KickReason = msg
			shared.plr:Kick("Kicked due to exploiting! Reason: "..msg)
		end
	end,

	CreateKey = function()
		local toHEX = function(num)
			local dig = {'1', '2', '3', '4', '5', '6' ,'7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'}
			local Hx = ""
			local write0 = false
			for i = 8, 0, -1 do       
				local plc = 16^i  
				local digit = ""
				for dg = 15, 1, -1 do
					if (num - (dg*plc)) >= 0 then
						digit = dig[dg]
						num = num - (dg*plc)
						write0 = true
						break
					end
				end
				if digit == "" and write0 then digit = '0' end
				Hx = Hx..digit
			end
			return Hx
		end

		local key = "key-"
		for i = 1, 500 do
			key = key..tostring(toHEX(math.random(1e3, 1e9))).."-"
		end

		return key
	end,

	checkIfIsA = function(instance)
		for i,v in pairs(anticheat.Methods.ExploitableInstances) do
			if instance:IsA(v) then
				return true
			end
		end	
		return false
	end,

	checkIfKey = function(instance)
		for i,v in pairs(anticheat.Methods.verifiedInstances) do
			if instance:GetAttribute("key") ~= nil then
				if instance:GetAttribute("key") == v:GetAttribute("key") then
					return true
				end
			end
		end
		return false
	end,

	CollectExploitableInstances = function()
		for _, instance in ipairs(game:GetDescendants()) do
			if anticheat.Methods.checkIfIsA(instance) and instance:GetAttribute("secured") == nil then
				instance:SetAttribute("key", anticheat.Methods.CreateKey())
				table.insert(anticheat.Methods.verifiedInstances, instance)
			end			
		end
	end,

	CheckCoreUI = function()
		local rbxassetid_count = 0
		game:GetService("ContentProvider"):preloadAsync({game.CoreGui}, function(assetid, status)
			if assetid:find("rbxassetid://") then
				rbxassetid_count = rbxassetid_count + 1
			end
		end)
		if rbxassetid_count > 10 then
			anticheat.Methods.Kick("Illegal CoreUI-Implementation")
		end
	end,

	CheckInstances = function()
		if #anticheat.Methods.verifiedInstances == 0 then
			anticheat.Methods.CollectExploitableInstances()
		else
			for i,v in pairs(anticheat.Methods.verifiedInstances) do
				if anticheat.Methods.Connections[i] == nil and v.Parent ~= script then
					anticheat.Methods.Connections[i] = v.Changed:Connect(function(change)
						if anticheat.Methods.PlayerResetting == false then
							if change == "Source" then
								anticheat.Methods.Kick()
							elseif change == "Parent" and v:IsA("LuaSourceContainer") then
								wait(0.35)
								if v ~= nil then
									if v.Parent == nil then
										anticheat.Methods.Kick("Illegal LuaSource-Removal")
									end
								else
									anticheat.Methods.Kick("Illegal LuaSource-Removal")
								end
							end	
						else
							if anticheat.Methods.GameWindowStates.RightNow ~= anticheat.Methods.GameWindowStates.RightBeforeDeath 
								and anticheat.Methods.CharacterInstances.Humanoid.Health == 0 then
								anticheat.Methods.Kick("Suspicious action while death: Illegal LuaSource-Removal")
							end
						end
					end)
				end
			end

			if anticheat.Methods.Connections["DescendantAdded"] == nil then
				anticheat.Methods.Connections["DescendantAdded"] = game.DescendantAdded:Connect(function(descendant)
					if anticheat.Methods.PlayerResetting == false then
						if anticheat.Methods.checkIfIsA(descendant) and not anticheat.Methods.checkIfKey(descendant) then
							anticheat.Methods.Kick("Third-Party non-game-Instance added which is not allowed")
						end
					else
						if anticheat.Methods.GameWindowStates.RightNow ~= anticheat.Methods.GameWindowStates.RightBeforeDeath 
							and anticheat.Methods.CharacterInstances.Humanoid.Health == 0 then
							anticheat.Methods.Kick("Suspicious action while death: Illegal LuaSource-Removal")
						end
					end
				end)
			end
		end
	end,

	GetGameWindowState = function()
		local UIS = game:GetService("UserInputService")

		if anticheat.Methods.Connections["WindowFocused"] == nil then
			anticheat.Methods.Connections["WindowFocused"] = UIS.WindowFocused:Connect(function()
				anticheat.Methods.GameWindowStates.RightNow = true
			end)
		end

		if anticheat.Methods.Connections["WindowFocusReleased"] == nil then
			anticheat.Methods.Connections["WindowFocusReleased"] = UIS.WindowFocusReleased:Connect(function()
				anticheat.Methods.GameWindowStates.RightNow = false
			end)
		end
	end,

	SetResetButton = function(state)
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCore("ResetButtonCallback",state)
	end,

	CharacterCotrol = function()
		local character = anticheat.Methods.CharacterInstances.character
		local HRP = anticheat.Methods.CharacterInstances.HRP
		local Humanoid = anticheat.Methods.CharacterInstances.Humanoid

		repeat wait() until character ~= nil and HRP ~= nil and Humanoid ~= nil

		local isDead = anticheat.Methods.CharacterSettings.isDead
		local respawnTime = anticheat.Methods.CharacterSettings.respawnTime
		local max_WalkSpeed_Allowed = anticheat.Methods.CharacterSettings.max_WalkSpeed_Allowed
		local max_JumpPower_Allowed = anticheat.Methods.CharacterSettings.max_JumpPower_Allowed
		local max_MaxHealth_Allowed = anticheat.Methods.CharacterSettings.max_MaxHealth_Allowed
		local max_Health_Allowed = anticheat.Methods.CharacterSettings.max_Health_Allowed
		local max_airTime = anticheat.Methods.CharacterSettings.max_airTime
		local airTime = anticheat.Methods.CharacterSettings.airTime
		local airTimeChecks = anticheat.Methods.CharacterSettings.airTimeChecks
		local states_forbidden = anticheat.Methods.CharacterSettings.states_forbidden

		local function WalkSpeedcheck()
			local plr_speed = Humanoid.WalkSpeed
			if plr_speed > max_WalkSpeed_Allowed then
				anticheat.Methods.Kick("WalkSpeed is too high. Exploit detected!")
			end
		end

		local function JumpPowercheck()
			local plr_jumppower = Humanoid.JumpPower
			if plr_jumppower > max_JumpPower_Allowed then
				anticheat.Methods.Kick("JumpPower is too high. Exploit detected!")
			end
		end

		local function Healthcheck()
			local plr_health = Humanoid.Health
			local plr_maxhealth = Humanoid.MaxHealth
			if plr_health > max_Health_Allowed then
				anticheat.Methods.Kick("Health is too high. Exploit detected!")
			end
			if plr_maxhealth > max_MaxHealth_Allowed then
				anticheat.Methods.Kick("MaxHealth is too high. Exploit detected!")
			end
		end

		local function flycheck()
			if Humanoid.FloorMaterial == Enum.Material.Air then
				airTime = airTime + 1
			else
				airTime = 0
				airTimeChecks = 0
			end

			if airTime >= max_airTime/3 then
				if Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
					airTime = 0
					airTimeChecks = airTimeChecks + 1
					if airTimeChecks >= 3 then
						anticheat.Methods.Kick("Too long airtime.")
					end
				else
					anticheat.Methods.Kick("Too long airtime (not including Enum.HumanoidStateType.Freefall). Fly exploit!")
				end
			end
		end

		if anticheat.Methods.Connections["HumanoidState"] == nil then
			anticheat.Methods.Connections["HumanoidState"] = Humanoid.StateChanged:Connect(function(oldState, newState)
				if table.find(states_forbidden, newState) then
					anticheat.Methods.Kick("Humanoid has state which is not allowed ("..tostring(newState)..")!")
				end
				WalkSpeedcheck()
				JumpPowercheck()
				Healthcheck()
			end)
		end

		if anticheat.Methods.Connections["CharacterAddedCheck"] == nil then
			anticheat.Methods.Connections["CharacterAddedCheck"] = workspace.ChildAdded:Connect(function(c)
				if c.Name == shared.plr.Name then
					repeat wait() until c:FindFirstChildWhichIsA("Humanoid")
					character = c
					HRP = character:WaitForChild("HumanoidRootPart")
					Humanoid = character:FindFirstChild("Humanoid")
					c.Humanoid.StateChanged:Connect(function(oldState, newState)
						if table.find(states_forbidden, newState) then
							anticheat.Methods.Kick("Humanoid has state which is not allowed ("..tostring(newState)..")!")
						end
						WalkSpeedcheck()						
						JumpPowercheck()
						Healthcheck()
					end)

					local tempConnection = nil
					tempConnection = Humanoid.Died:Connect(function()
						tempConnection:Disconnect()
						anticheat.Methods.GameWindowStates.RightBeforeDeath = anticheat.Methods.GameWindowStates.RightNow
						anticheat.Methods.PlayerResetting = true
						anticheat.Methods.SetResetButton(false)
						isDead = true
						wait(respawnTime)
						isDead = false
						wait(1)
						anticheat.Methods.PlayerResetting = false
						anticheat.Methods.SetResetButton(true)
					end)
				end
			end)
		end

		if anticheat.Methods.Connections["HumanoidDeathState"] == nil then
			anticheat.Methods.Connections["HumanoidDeathState"] = Humanoid.Died:Connect(function()
				anticheat.Methods.GameWindowStates.RightBeforeDeath = anticheat.Methods.GameWindowStates.RightNow
				anticheat.Methods.PlayerResetting = true
				anticheat.Methods.SetResetButton(false)
				isDead = true
				wait(respawnTime)
				isDead = false
				wait(1)
				anticheat.Methods.PlayerResetting = false
				anticheat.Methods.SetResetButton(true)
			end)
		end

		if Humanoid ~= nil then
			flycheck()
		end
	end,
}

spawn(function()
	table.insert(anticheat.Main, {spawn(function()
		local r = tostring(math.random(1,1e9))
		local hex = string.format("%02X", r:byte(1, #r:split("")))
		anticheat.Main[tostring(hex)] = function()

			pcall(function()
				if not anticheat.Methods.SettingsLoaded then
					anticheat.Methods.spawn(anticheat.Methods.loadSettings)
					wait()
					script:Destroy()
				else
					script:Destroy()
				end
			end)

			local GUID = game:GetService("HttpService"):GenerateGUID()
			script.Name = GUID.."-ClientSecurity"

			local originFunction = function()
				spawn(function()
					anticheat.Methods.spawn(anticheat.Methods.CheckInstances)
					anticheat.Methods.spawn(anticheat.Methods.CheckCoreUI)
					anticheat.Methods.spawn(anticheat.Methods.CharacterCotrol)
					anticheat.Methods.spawn(anticheat.Methods.GetGameWindowState)
				end)

				wait(1)
			end

			originFunction()

			local rr = tostring(math.random(1,1e9))
			local hexx = string.format("%02X", rr:byte(1, #rr:split("")))
			anticheat.Main[tostring(hexx)] = anticheat.Main[tostring(hex)]
			table.insert(anticheat.Main, anticheat.Main[tostring(hexx)])
			for i,v in pairs(anticheat.Main) do
				if i ~= tostring(hexx) and i ~= tostring(hex) then
					v = setmetatable({shared.plr, anticheat.Main},{
						__metatable = "nil",
						__newindex = function()
							return warn("nil")
						end,
						__tostring = function()
							shared.plr:Kick("nil")
						end,
						spawn(function()
							wait(3)
							anticheat[i] = nil
						end)
					})
				end
			end

			spawn(function()
				anticheat.Main[tostring(hexx)]()
			end)
		end
		anticheat.Main[tostring(hex)]()
	end)})

	local function lockTable(t, t_)
		local methods = {}
		methods = {
			kick = function()
				methods.kick("Tried to access restricted area!")
			end,
			testenv = function()
				return t_ == getfenv().script
			end,
			test = function()
				if not methods.testenv() then
					methods.kick("Tried to access restricted area!")
				end
			end,
		}

		return setmetatable(t, {
			__index = function(_, key)
				if anticheat.Methods[key] ~= nil then
					return anticheat.Methods[key]
				else
					warn("Attempt to access locked table")
					return nil
				end
			end,
			__newindex = function(_, key, value)
				if methods.testenv() then
					rawset(t, key, value)
				else
					methods.kick("Tried to access restricted area!")
				end
			end,
			__metatable = false,
			__len = (function() return 0 end)(),
			__pairs = (function() return methods.test() end)(),
			__ipairs = (function() return methods.test() end)(),
			__call = (function() methods.test() return nil end)()
		})
	end

	lockTable(anticheat.Main, unpack{[1] = script})
end)
