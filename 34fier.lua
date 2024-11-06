local PartCreator = {}

local Function = {}


local DarkerColorPercentage = 17.75
local Darker2ColorPercentage = 32.75


--physics
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Spring

if not game:GetService("RunService"):IsStudio() then
	local function requireStuff(object,name)
		local ls = loadstring(game:HttpGet(object))
		local origEnv = getfenv(ls)
		getfenv(ls).script = name
		getfenv(ls).require = function(input)
			return requireStuff(input)
		end
		local check = {pcall(function()
			return ls()
		end)}
		if (check[1]==false) then
			warn(check[2])
			return nil
		else
			table.remove(check,1)
			return unpack(check)
		end
	end



	Spring = requireStuff("https://raw.githubusercontent.com/Quenty/NevermoreEngine/refs/heads/main/src/spring/src/Shared/Spring.lua","Spring")
else
	Spring = require(script.Spring)
end
local Config = {
	Physics = {
		Enabled = true,
		Distance = 50,
		VelocityThreshold = 0.01,
		PhysicParts = {
			["BR"] = {
				Target = Vector3.new(7.5, 7.5, 7.5),
				Speed = 8.5,
				Damper = 0.1,
				ClothedConfig = {
					OnlyWhenClothed = true,
				},
				Axis = {"Y","X","Z"}
			},
			["Right Chicken"] = {
				Target = Vector3.new(7.5, 7.5, 7.5),
				Speed = 8.5,
				Damper = 0.02,
				ClothedConfig = {
					OnlyWhenClothed = false,
				},
			},
			["Left Chicken"] = {
				Target = Vector3.new(7.5, 7.5, 7.5),
				Speed = 8.5,
				Damper = 0.02,
				ClothedConfig = {
					OnlyWhenClothed = false,
				},
			},
			["RB"] = {
				Target = Vector3.new(10, 10, 10),
				Speed = 11,
				Damper = 0.02,
				ClothedConfig = {
					ClothedModifier = 1.5,
				},
			},
			["LB"] = {
				Target = Vector3.new(10, 10, 10),
				Speed = 11,
				Damper = 0.02,
				ClothedConfig = {
					ClothedModifier = 1.5,
				},
			},	
			ER = {
				Target = Vector3.new(10, 10, 10),
				Speed = 10,
				Damper = 0.1,
				ClothedConfig = {
					OnlyWhenClothed = false,
				},
			},
		},
		Debug = false,
	}
}

local PhysicsList = {}

local function applyPhysics(Character)
	local Player = Players:FindFirstChild(Character.Name)
	if Config.Physics.Enabled then
		if Config.Physics.Debug then
			warn("PHYSICS START",Character.Name)
		end
		table.insert(PhysicsList, { 
			Player = Player and Player or "NPC",
			Character = Character
		})
	end
end
local physicsRender = function(dt)
	for Index, Data in next, PhysicsList do

		local Player = Data.Player
		local Character = Data.Character
		local Torso = Character:FindFirstChild("Torso")
		if not Torso then continue end
		local Morph = Torso:FindFirstChildOfClass("Model")

		if not Character then table.remove(PhysicsList, Index) continue end
		if not Morph then continue end

		local PhysicParts = Config.Physics.PhysicParts
		local Distance = (Camera.CFrame.Position - Torso.Position).Magnitude
		local _, withinScreenBounds = Camera:WorldToScreenPoint(Torso.Position)

		if Distance > Config.Physics.Distance or not withinScreenBounds then continue end



		local Information = Data.Information or {}

		if not Data.Information then
			for name, part in pairs(PhysicParts) do
				local PartInstance = Morph:FindFirstChild(name,true)
				if PartInstance == nil then continue end
				local Joint = nil
				for _, item in pairs(PartInstance:GetJoints()) do
					if (item:IsA("Weld") or item:IsA("Motor6D")) and item.Part1 == PartInstance then
						Joint = item
						break
					end
				end
				if Joint == nil then continue end
				if part.Axis == nil then part.Axis = {"Z","X","Y"} end
				Information[name] = {
					Last 											= tick(),
					LastPosition									= Torso.Position,
					LastRotation									= Torso.RotVelocity,
					Spring											= Spring.new(Vector3.new(0, 0, 0)),
					Joint = Joint,
					OriginalC0 = nil,
					Axis 											= part.Axis,
				}
				Information[name].Spring.Target = part.Target
				Information[name].Spring.Speed = part.Speed
				Information[name].Spring.Damper = part.Damper

				if Information[name].OriginalC0 == nil then
					Information[name].OriginalC0 = Joint.C0
				end
				local clothedVar = Character:FindFirstChild("Clothed")
				if clothedVar and part.ClothedConfig then

					if clothedVar.Value and part.ClothedConfig.ClothedModifier then
						Information[name].Spring.Damper *= part.ClothedConfig.ClothedModifier
					end
					if part.ClothedConfig.OnlyWhenClothed ~= nil then
						if clothedVar.Value ~= part.ClothedConfig.OnlyWhenClothed then
							Information[name].Joint = nil
						end
					end
				end
			end
		end

		if not Data.Information then Data.Information = Information end	
		if not Player then table.remove(PhysicsList, Index) continue end
		if not Information then table.remove(PhysicsList, Index) continue end

		for Index, Part in pairs(Information) do
			if  (Part.Joint) and (Torso) then
				Part.Last = tick()


				Part.Spring:TimeSkip(dt * 1.5)
				Part.Spring:Impulse(
					(Part.LastPosition - Torso.Position) + Vector3.new((Part.LastRotation - Torso.RotVelocity).Y / 4),
					0,
					0
				)
				Part.Joint.C0 =
					(Part.OriginalC0 * CFrame.new(0, (0.02 * -Part.Spring.Velocity[Part.Axis[3]]), 0)) *
					CFrame.Angles(
						math.rad(Random.new():NextNumber(10, 10.5) * Part.Spring.Velocity[Part.Axis[1]]), 
						math.rad(Random.new():NextNumber(4, 4.5) * Part.Spring.Velocity[Part.Axis[2]]),
						math.rad((Random.new():NextNumber(5, 5.5) * -Part.Spring.Velocity[Part.Axis[3]]))
					)
				Part.LastPosition = Torso.Position
				Part.LastRotation = Torso.RotVelocity
			end
		end

		Data.Information = Information
	end

end




RunService.RenderStepped:Connect(physicsRender)

-- start


function Function.PartListDefault()
	return {
		["BRMain"] = {
			["Instance"] = "Part",
			["Name"] = "BR",
			["Size"] = Vector3.new(1.88, 0.094, 0.094),
			["CFrame"] = CFrame.new(0,0.9,-0.3)*CFrame.Angles( math.rad(-0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,-0.016,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
			}
		},

		["ChickenTexture"] = {
			["Instance"] = "Mesh",
			["Name"] = "BTexture",
			["MeshId"] = "rbxassetid://7606070501",
			["Size"] = Vector3.new(1.398, 1.128, 1.692),
			["CFrame"] = CFrame.new(0,0.033,0)*CFrame.Angles( math.rad(-0.001),math.rad(-90),math.rad(21.763) ),
			["CFrame1"] = CFrame.new(0.428,0.437,0.009)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0.015) ),
			["Transparency"] = 0.02,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR"
			},
			["Function"] = {},
			["Scale"] = "ChickensScale"

		},

		["ChickenPantsTexture"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://7606070501",
			["Size"] = Vector3.new(1.398, 1.128, 1.692),
			["CFrame"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(-0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR",
				[3] = "BTexture"
			},
			["Function"] = {},
			["Scale"] = "ChickensScale"

		},

		["Left Chicken"] = {
			["Instance"] = "Part",
			["Name"] = "Left Chicken",
			["Size"] = Vector3.new(1.169, 1.224, 1.038),
			["CFrame"] = CFrame.new(0.432, 0.432, 0.127)*CFrame.Angles( math.rad(-0),math.rad(179.999),math.rad(23.746) ),
			["CFrame1"] = CFrame.new(-0.188, 0.564, 0.188)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR",
				[3] = "BTexture"
			},
			["Function"] = {"ChickensMesh", "SpotDecalCreate"},
			["Scale"] = "ChickensScale",
			["AdjustScale"] = {"Size", "CFrame1"}
		},
		["Right Chicken"] = {
			["Instance"] = "Part",
			["Name"] = "Right Chicken",
			["Size"] = Vector3.new(1.169, 1.224, 1.038),
			["CFrame"] = CFrame.new(0.432, 0.432, -0.131)*CFrame.Angles( math.rad(-0.001),math.rad(179.998),math.rad(23.747) ),
			["CFrame1"] = CFrame.new(-0.188, 0.564, -0.188)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0.001) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR",
				[3] = "BTexture"
			},
			["Function"] = {"ChickensMesh", "SpotDecalCreate"},
			["Scale"] = "ChickensScale",
			["AdjustScale"] = {"Size", "CFrame1"}
		},
		["Left Nle"] = {
			["Instance"] = "Mesh",
			["Name"] = "Nle",
			["MeshId"] = "rbxassetid://5270413936",
			["Size"] = Vector3.new(0.091, 0.12, 0.097),
			["CFrame"] = CFrame.new(0.553, -0.213, -0.287)*CFrame.Angles( math.rad(-0 ),math.rad(-0),math.rad(-0.001) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Darker2",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR",
				[3] = "BTexture",
				[4] = "Left Chicken"
			},
			["Function"] = {"DarkPart"},
			["Scale"] = "ChickensScale",	
		},
		["Right Nle"] = {
			["Instance"] = "Mesh",
			["Name"] = "Nle",
			["MeshId"] = "rbxassetid://5270413632",
			["Size"] = Vector3.new(0.091, 0.12, 0.097),
			["CFrame"] = CFrame.new(0.553, -0.213, 0.287)*CFrame.Angles( math.rad(-0 ),math.rad(-0),math.rad(-0.001) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Darker2",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "BR",
				[3] = "BTexture",
				[4] = "Right Chicken"
			},
			["Function"] = {"DarkPart"},
			["Scale"] = "ChickensScale",	
		},
		["Closed"] = {
			["Instance"] = "Part",
			["Name"] = "Closed",
			["MeshId"] = "rbxassetid://6257060708",
			["Size"] = Vector3.new(0.624, 0.6, 0.52),
			["CFrame"] = CFrame.new(-0.003, -1.001, 0.1)*CFrame.Angles( math.rad(0),math.rad(90),math.rad(-0) ),
			["CFrame1"] = CFrame.new(-0.02,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso"
			},
			["Function"] = {"ClosedMeshCreate"},
			["Scale"] = "ChickensScale",	
		},
		["TorsoMesh"] = {
			["Instance"] = "Mesh",
			["Name"] = "TorsoMesh",
			["MeshId"] = "rbxassetid://16220564888",
			["Size"] = Vector3.new(2.053, 1.985, 0.997),
			["CFrame"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(-0 ),math.rad(0.052),math.rad(-0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso"
			},
			["Function"] = {},
		},
		["UVTorso"] = {
			["Instance"] = "Mesh",
			["Name"] = "UVTorso",
			["MeshId"] = "rbxassetid://13755434958",
			["Size"] = Vector3.new(2.078, 1.998, 0.967),
			["CFrame"] = CFrame.new(0,0.052,0)*CFrame.Angles( math.rad(0 ),math.rad(180),math.rad(-0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "TorsoMesh"
			},
			["Function"] = {},
		},
		["UVTorsoPants"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://13755434958",
			["Size"] = Vector3.new(2.1, 2.005, 0.993),
			["CFrame"] = CFrame.new(0.003, 0.01, 0.007)*CFrame.Angles(0,0,0 ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "TorsoMesh",
				[3] = "UVTorso"
			},
			["Function"] = {},
		},
		["UVTorsoShirt"] = {
			["Instance"] = "Mesh",
			["Name"] = "ShirtTexture",
			["MeshId"] = "rbxassetid://13755434958",
			["Size"] = Vector3.new(2.1, 2.005, 0.986),
			["CFrame"] = CFrame.new(-0, 0.001, 0.001)*CFrame.Angles(0,0,0 ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "TorsoMesh",
				[3] = "UVTorso"
			},
			["Function"] = {},
		},
		["Left Meow"] = {
			["Instance"] = "Mesh",
			["Name"] = "LB",
			["MeshId"] = "rbxassetid://6349489786",
			["Size"] = Vector3.new(1.236, 1.367, 1.359),
			["CFrame"] = CFrame.new(-0.481, -0.935, 0.247)*CFrame.Angles( math.rad(-5),math.rad(180),math.rad(20) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"
		},
		["Right Meow"] = {
			["Instance"] = "Mesh",
			["Name"] = "RB",
			["MeshId"] = "rbxassetid://6349489786",
			["Size"] = Vector3.new(1.236, 1.367, 1.359),
			["CFrame"] = CFrame.new(0.485, -0.935, 0.229)*CFrame.Angles( math.rad(-5),math.rad(-180),math.rad(-20) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["Transparency"] = 1,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},
		["Left Meow Texture"] = {
			["Instance"] = "Mesh",
			["Name"] = "BPantsTextureL",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(1.246, 1.415, 1.063),
			["CFrame"] = CFrame.new(-0.025, 0.008, -0.109)*CFrame.Angles( math.rad(19.637),math.rad(176.894),math.rad(4.366) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "LB"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"
		},
		["Right Meow Texture"] = {
			["Instance"] = "Mesh",
			["Name"] = "BPantsTextureR",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(1.246, 1.415, 1.063),
			["CFrame"] = CFrame.new(0.023, 0.01, -0.108)*CFrame.Angles( math.rad(19.636),math.rad(-176.894),math.rad(-4.368)),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.Plastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "RB"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},

		["Left Meow Skin_Clothed"] = {
			["Instance"] = "Mesh",
			["Name"] = "LBSKIN",
			["MeshId"] = "rbxassetid://17106927899",
			["Size"] = Vector3.new(1.236, 1.385, 1.058),
			["CFrame"] = CFrame.new(-0.002, 0.003, 0)*CFrame.Angles( math.rad(0.001),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "LB",
				[3] = "BPantsTextureL"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"
		},
		["Right Meow Skin_Clothed"] = {
			["Instance"] = "Mesh",
			["Name"] = "RBSKIN",
			["MeshId"] = "rbxassetid://17106927899",
			["Size"] = Vector3.new(1.236, 1.385, 1.058),
			["CFrame"] = CFrame.new(0.005,0,0)*CFrame.Angles( math.rad(0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "RB",
				[3] = "BPantsTextureR"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},

		["Core"] = {
			["Instance"] = "Mesh",
			["Name"] = "Core",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(0.97, 0.583, 0.817),
			["CFrame"] = CFrame.new(-0.003, -1.076, 0.11)*CFrame.Angles( math.rad(-0),math.rad(-180),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},
		["CoreLB"] = {
			["Instance"] = "Mesh",
			["Name"] = "LeftBase",
			["MeshId"] = "rbxassetid://17106927899",
			["Size"] = Vector3.new(1.038, 1.025, 1.259),
			["CFrame"] = CFrame.new(0.516, -0.025, -0.067)*CFrame.Angles( math.rad(14.477),math.rad(161.032),math.rad(-15.504) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "Core"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},
		["CoreLBPT"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(1.043, 1.192, 1.264),
			["CFrame"] = CFrame.new(-0.003, 0.019, 0.001)*CFrame.Angles( math.rad(-30.001),math.rad(0),math.rad(0.001) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "Core",
				[3] = "LeftBase"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},

		["CoreRB"] = {
			["Instance"] = "Mesh",
			["Name"] = "RightBase",
			["MeshId"] = "rbxassetid://17106927899",
			["Size"] = Vector3.new(1.039, 1.025, 1.259),
			["CFrame"] = CFrame.new(-0.51, -0.025, -0.059)*CFrame.Angles( math.rad(14.476),math.rad(-161.032),math.rad(15.501) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "Core"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},
		["CoreRBPT"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(1.043, 1.192, 1.264),
			["CFrame"] = CFrame.new(0.002, 0.021, 0.002)*CFrame.Angles( math.rad(-30),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "Core",
				[3] = "RightBase"
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},

		["CorePT"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://9067214532",
			["Size"] = Vector3.new(0.99, 0.643, 0.867),
			["CFrame"] = CFrame.new(0, -0.02, 0.025)*CFrame.Angles( math.rad(-0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Torso",
				[2] = "Core",
			},
			["Function"] = {},
			["Scale"] = "MeowsScale"

		},


		["Left Leg"] = {
			["Instance"] = "Mesh",
			["Name"] = "Left Leg",
			["MeshId"] = "rbxassetid://6870651596",
			["Size"] = Vector3.new(1.088, 2.292, 1.252),
			["CFrame"] = CFrame.new(-0.038, 0.126, 0.01)*CFrame.Angles( math.rad(-0),math.rad(90),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Left Leg",
			},
			["Function"] = {},

		},

		["Right Leg"] = {
			["Instance"] = "Mesh",
			["Name"] = "Right Leg",
			["MeshId"] = "rbxassetid://6870651384",
			["Size"] = Vector3.new(1.088, 2.292, 1.208),
			["CFrame"] = CFrame.new(0.048, 0.125, 0.01)*CFrame.Angles( math.rad(-0),math.rad(90),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Right Leg",
			},
			["Function"] = {},

		},

		["Left Leg Texture"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://6870651596",
			["Size"] = Vector3.new(1.088, 2.292, 1.252),
			["CFrame"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(-0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Left Leg",
				[2] = "Left Leg"
			},
			["Function"] = {},

		},

		["Right Leg Texture"] = {
			["Instance"] = "Mesh",
			["Name"] = "PantsTexture",
			["MeshId"] = "rbxassetid://6870651384",
			["Size"] = Vector3.new(1.088, 2.292, 1.208),
			["CFrame"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(-0),math.rad(0),math.rad(0) ),
			["CFrame1"] = CFrame.new(0,0,0)*CFrame.Angles( math.rad(0),math.rad(-0),math.rad(0) ),
			["Transparency"] = 0.01,
			["Reflectance"] = 0,
			["Material"] = Enum.Material.SmoothPlastic,
			["Shape"] = Enum.PartType.Block,
			["Color"] = {
				["Tone"] = "Base",
				["Color"] = "Parent"
			},
			["Parent"] = {
				[1] = "Right Leg",
				[2] = "Right Leg"
			},
			["Function"] = {},

		},
	}
end


local PartList = Function.PartListDefault()



function Function.PlayerDataDefault()
	return {
		CurrentWear = {},
		CurrentBundle = "nil",
		AutoExecute = true,
		DelayTime = 1,
		Tone = "Base",
		BundleBodyColor = true,
		Face = false,
		MeshSizeLock = false,
		AccessorySizeLock = false,
		MeshBasePartInvisible = false,
		BodyPartPhysics = true,
		CatalogUsername = "",
		CatalogOutfitId = "",
		CatalogWear = {
			Shirt = "",
			Pants = "",
			ShirtGraphic = "",
		},
		CatalogAccessory = {},
		SkinTone = nil,
		ChickensScale = 1,
		MeowsScale = 1,
		ChickensType = 1,

		PartList = Function.PartListDefault(),

		LocalTransparency = {
			["Head"] = false,
			["Right Arm"] = false,
			["Left Arm"] = false,
			["Torso"] = false,
			["Right Leg"] = false,
			["Left Leg"] = false
		},

		CurrentPartList = {
			Trumpets = {},
			Wear = {},
			Accessory = {},
			ParentTransparency = {},
			RealtimeUpdateList = {
				["Mesh"] = {},
				["Accessory"] = {}
			},
			PartParent = {},
			BodyPartPhysics = {},
			SpotDecal = {},
		}
	}
end


local PlayerData = {
	["Player"] = Function.PlayerDataDefault()
}



function Function.ChickensMesh(ObjectInstance, Character, Extra, Data)
	local SpecialMesh = Instance.new("SpecialMesh")

	SpecialMesh.MeshType = Enum.MeshType.FileMesh

	if ObjectInstance.Name == "Left Chicken" then
		SpecialMesh.MeshId = "rbxassetid://5270415437"
	else
		SpecialMesh.MeshId = "rbxassetid://5270413797"
	end

	SpecialMesh.Scale = Vector3.new(0.45, 0.45, 0.45)

	SpecialMesh.Parent = ObjectInstance
end

function Function.ClosedMeshCreate(ObjectInstance, Character, Extra, Data)
	local SpecialMesh = Instance.new("SpecialMesh")

	SpecialMesh.MeshType = Enum.MeshType.FileMesh

	SpecialMesh.MeshId = "rbxassetid://6257060708"

	SpecialMesh.Scale = Vector3.new(0.536, 0.536, 0.541)

	SpecialMesh.Parent = ObjectInstance

	local H,S,V = ObjectInstance.Color:ToHSV()
	local DarkerColorCode = Color3.fromHSV(H,S,V+(-DarkerColorPercentage * V/100))

	local Decal1 = Instance.new("Decal")
	Decal1.Name = "Closed"
	Decal1.Texture = "http://www.roblox.com/asset/?id=9065325204"
	Decal1.Color3 = DarkerColorCode
	Decal1.Parent = ObjectInstance
	Decal1.Face = "Left"

	local Decal2 = Instance.new("Decal")
	Decal2.Name = "Closed"
	Decal2.Texture = "http://www.roblox.com/asset/?id=9065326582"
	Decal2.Color3 = DarkerColorCode
	Decal2.Parent = ObjectInstance
	Decal2.Face = "Left"
end


function Function.SpotDecalCreate(ObjectInstance, Character, Extra, Data)
	for i = 1, 2 do
		local Decal = Instance.new("Decal", ObjectInstance)
		Decal.Color3 = Color3.fromRGB(110, 110, 111)
		Decal.Texture = "http://www.roblox.com/asset/?id=9065282081"
		Decal.Face = "Right"
		Decal.Name = "Spot Decal".." "..tostring(i)
		PlayerData[Data].CurrentPartList.SpotDecal[Decal] = ObjectInstance

		local H,S,V = ObjectInstance.Color:ToHSV()
		local DarkerColorCode = Color3.fromHSV(H,S,V+(-Darker2ColorPercentage * V/100))

		Decal.Color3 = DarkerColorCode
	end
end


function Function.DarkPart(ObjectInstance, Character, Extra, Data)
	if Extra.Tone == "Dark" then
		local H,S,V = ObjectInstance.Parent.Color:ToHSV()
		local DarkerColorCode = Color3.fromHSV(H,S,V+(-DarkerColorPercentage * V/100))

		ObjectInstance.Color = DarkerColorCode
	end
end


function coder(text, shift)
	local result = ""
	shift = shift % 26  

	for i = 1, #text do
		local char = text:sub(i, i)
		local byte = char:byte()


		if byte >= 65 and byte <= 90 then
			byte = ((byte - 65 + shift) % 26) + 65

		elseif byte >= 97 and byte <= 122 then
			byte = ((byte - 97 + shift) % 26) + 97
		end

		result = result .. string.char(byte)
	end

	return result
end

function Function.Weld(MeshDetail, Character, Extra, Data)
	if Character.Parent ~= nil then
		local INSTANCE = MeshDetail["Instance"]
		local NAME = MeshDetail["Name"]

		local SIZE = MeshDetail["Size"]
		local CFRAME = MeshDetail["CFrame"]
		local CFRAME1 = MeshDetail["CFrame1"]
		local TRANSPARENCY = MeshDetail["Transparency"]
		local REFLECTANCE = MeshDetail["Reflectance"]
		local MESHBASEPARTTRANSPARENCY = MeshDetail["MeshBasePartTransparency"]
		local MATERIAL = MeshDetail["Material"]
		local COLOR = MeshDetail["Color"]
		local PARENT = MeshDetail["Parent"]
		local PARENTTRANSPARENCY = MeshDetail["ParentTransparency"]
		local FUNCTION = MeshDetail["Function"]
		local SCALE = MeshDetail["Scale"]
		local ADJUSTSCALE = MeshDetail["AdjustScale"]

		local MESHID = MeshDetail["MeshId"]
		local TEXTUREID = MeshDetail["TextureId"]
		local DOUBLESIDED = MeshDetail["DoubleSided"]

		local SHAPE = MeshDetail["Shape"]

		local BodyPart = Character:FindFirstChild(PARENT[1])

		if BodyPart then
			--local XMultiply, YMultiply, ZMultiply = Function.MultiplyCalculate(BodyPart.Size, BodyPartSize[PARENT[1]])
			local ObjectInstance

			local Parent = Character
			local Scale = 1


			if BodyPart == Character.Torso then
				BodyPart = BodyPart.Feale
				Parent = BodyPart
			end

			if BodyPart == Character["Right Leg"] then
				BodyPart = Character.Torso.Feale
				Parent = BodyPart
			end
			if BodyPart == Character["Left Leg"] then
				BodyPart = Character.Torso.Feale
				Parent = BodyPart
			end



			for Index = 1, #PARENT do
				Parent = Parent:FindFirstChild(PARENT[Index])
			end
			if SCALE then
				Scale = PlayerData[Data][SCALE]
			end



			if PARENTTRANSPARENCY ~= nil then
				PlayerData[Data].CurrentPartList.ParentTransparency[Parent] = {D = Parent.Transparency, T = PARENTTRANSPARENCY}
				Parent.Transparency = PARENTTRANSPARENCY
			end

			if INSTANCE == "Mesh" then
				local IS = game:GetService("InsertService")
				ObjectInstance = IS:CreateMeshPartAsync(MESHID, Enum.CollisionFidelity.Box, Enum.RenderFidelity.Performance)

				if TEXTUREID == nil then TEXTUREID = "" end
				ObjectInstance.TextureID = TEXTUREID
				--ObjectInstance.DoubleSided = DOUBLESIDED
			elseif INSTANCE == "Part" then
				ObjectInstance = Instance.new("Part")
				ObjectInstance.Shape = SHAPE
			end

			local Color

			if COLOR["Color"] == "Parent" then
				Color = Parent.Color
			else
				Color = COLOR["Color"]
			end

			local H,S,V = Color:ToHSV()

			if COLOR["Tone"] == "Darker" then
				Color = Color3.fromHSV(H,S,V+(-DarkerColorPercentage * V/100))
			elseif COLOR["Tone"] == "Darker2" then
				Color = Color3.fromHSV(H,S,V+(-Darker2ColorPercentage * V/100))
			end

			if PlayerData[Data].MeshBasePartInvisible then
				ObjectInstance.Transparency = MESHBASEPARTTRANSPARENCY
			end

			ObjectInstance.Color = Color

			ObjectInstance.CanCollide = false
			ObjectInstance.CanQuery = false
			ObjectInstance.CanTouch = false
			ObjectInstance.Massless = true

			ObjectInstance.Name = NAME
			ObjectInstance.Transparency = TRANSPARENCY
			ObjectInstance.Reflectance = REFLECTANCE
			ObjectInstance.Material = MATERIAL

			local WeldInstance = Instance.new("Weld", ObjectInstance)
			WeldInstance.Name = NAME.." Weld"
			WeldInstance.Part0 = Parent
			WeldInstance.Part1 = ObjectInstance

			ObjectInstance.Size = SIZE

			WeldInstance.C0 = CFRAME

			WeldInstance.C1 = CFRAME1






			ObjectInstance.Parent = Parent

			if FUNCTION ~= "" then
				if typeof(FUNCTION) == "string" then
					Function[FUNCTION](ObjectInstance, Character, Extra, Data)
				elseif typeof(FUNCTION) == "table" then
					for i, v in pairs(FUNCTION) do
						Function[v](ObjectInstance, Character, Extra, Data)
					end
				end
			end



			return ObjectInstance
		end 
	end

end


function PartCreator.ProcessAll(Character,Extra2)



end








local DummyMesh = {
	["Head"] = {
		Size = Vector3.new(2, 1, 1),
		Offset = CFrame.new(0, 1.5, 0)
	},
	["Torso"] = {
		Size = Vector3.new(2, 2, 1),
		Offset = CFrame.new(0,0,0)
	},
	["Right Arm"] = {
		Size = Vector3.new(1, 2, 1),
		Offset = CFrame.new(1.5, 0, 0)
	},
	["Left Arm"] = {
		Size = Vector3.new(1, 2, 1),
		Offset = CFrame.new(-1.5, 0, 0)
	},
	["Right Leg"] = {
		Size = Vector3.new(1, 2, 1),
		Offset = CFrame.new(0.5, -2, 0)
	},
	["Left Leg"] = {
		Size = Vector3.new(1, 2, 1),
		Offset = CFrame.new(-0.5, -2, 0)
	}
}

local EditableProperty = {
	"TextureId",
	"Size",
	"Transparency",
	"MeshBasePartTransparency",
	"Color",
	"Reflectance",
}

local Method2BodyPart = {
	"Torso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
	"Head",
}

local BodyColorPart = {
	["HeadColor3"] = "Head",
	["LeftArmColor3"] = "Left Arm",
	["RightArmColor3"] = "Right Arm",
	["LeftLegColor3"] ="Left Leg",
	["RightLegColor3"] = "Right Leg",
	["TorsoColor3"] = "Torso"
}

local BodyPartSize = {
	["Head"] = Vector3.new(2, 1, 1),
	["HeadMeshFix"] = Vector3.new(1, 1, 1),
	["Torso"] = Vector3.new(2, 2, 1),
	["Left Arm"] = Vector3.new(1, 2, 1),
	["Left Leg"] = Vector3.new(1, 2, 1),
	["Right Arm"] = Vector3.new(1, 2, 1),
	["Right Leg"] = Vector3.new(1, 2, 1),
	["HumanoidRootPart"] = Vector3.new(2, 2, 1),
}

local AttachmentCFrame = {
	["RootAttachment"] = CFrame.new(0,0,0),

	["FaceCenterAttachment"] = CFrame.new(0,0,0),
	["FaceFrontAttachment"] = CFrame.new(0, 0, -0.6),
	["HairAttachment"] = CFrame.new(0,0.6,0),
	["HatAttachment"] = CFrame.new(0,0.6,0),

	["LeftGripAttachment"] = CFrame.new(0, -1, 0),
	["LeftShoulderAttachment"] = CFrame.new(0,1,0),

	["LeftFootAttachment"] = CFrame.new(0, -1, 0),

	["RightGripAttachment"] = CFrame.new(0, -1, 0),
	["RightShoulderAttachment"] = CFrame.new(0,1,0),

	["RightFootAttachment"] = CFrame.new(0, -1, 0),

	["BodyBackAttachment"] = CFrame.new(0, 0, 0.5),
	["BodyFrontAttachment"] = CFrame.new(0, 0, -0.5),
	["LeftCollarAttachment"] = CFrame.new(-1, 1, 0),
	["NeckAttachment"] = CFrame.new(0, 1, 0),
	["RightCollarAttachment"] = CFrame.new(1, 1, 0),
	["WaistBackAttachment"] = CFrame.new(0, -1, 0.5),
	["WaistCenterAttachment"] = CFrame.new(0, -1, 0),
	["WaistFrontAttachment"] = CFrame.new(0, -1, -0.5),
}

local AttachmentParent = {
	["RootAttachment"] = "HumanoidRootPart",

	["FaceCenterAttachment"] = "Head",
	["FaceFrontAttachment"] = "Head",
	["HairAttachment"] = "Head",
	["HatAttachment"] = "Head",

	["LeftGripAttachment"] = "Left Arm",
	["LeftShoulderAttachment"] = "Left Arm",

	["LeftFootAttachment"] = "Left Leg",

	["RightGripAttachment"] = "Right Arm",
	["RightShoulderAttachment"] = "Right Arm",

	["RightFootAttachment"] = "Right Leg",

	["BodyBackAttachment"] = "Torso",
	["BodyFrontAttachment"] = "Torso",
	["LeftCollarAttachment"] = "Torso",
	["NeckAttachment"] = "Torso",
	["RightCollarAttachment"] = "Torso",
	["WaistBackAttachment"] = "Torso",
	["WaistCenterAttachment"] = "Torso",
	["WaistFrontAttachment"] = "Torso",
}

local HumanoidAccessoryName = {
	"HairAccessory",
	"BackAccessory",
	"FaceAccessory",
	"FrontAccessory",
	"HatAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"WaistAccessory",
}

local AccessoryType = {
	[8] = "HatAccessory",
	[41] = "HairAccessory",
	[42] = "FaceAccessory",
	[43] = "NeckAccessory",
	[44] = "ShouldersAccessory",
	[45] = "FrontAccessory",
	[46] = "BackAccessory",
	[47] = "WaistAccessory",
}

local DummyMotor6Ds = {
	["Neck"] = {
		C0 = CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(-90),math.rad(180),math.rad(0)),
		C1 = CFrame.new(0, -0.5, 0)* CFrame.Angles(math.rad(-90),math.rad(180),math.rad(0)),
		Part0 = "Torso",
		Part1 = "Head"
	},
	["Left Shoulder"] = {
		C0 = CFrame.new(-1, 0.5, 0)* CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
		C1 = CFrame.new(0.5, 0.5, 0)* CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
		Part0 = "Torso",
		Part1 = "Left Arm"
	},
	["Left Hip"] = {
		C0 = CFrame.new(-1, -1, 0)* CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
		C1 = CFrame.new(-0.5, 1, 0)* CFrame.Angles(math.rad(0),math.rad(-90),math.rad(0)),
		Part0 = "Torso",
		Part1 = "Left Leg"
	},
	["Right Shoulder"] = {
		C0 = CFrame.new(1, 0.5, 0)* CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
		C1 = CFrame.new(-0.5, 0.5, 0)* CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
		Part0 = "Torso",
		Part1 = "Right Arm"
	},
	["Right Hip"] = {
		C0 = CFrame.new(1, -1, 0)* CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
		C1 = CFrame.new(0.5, 1, 0)* CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
		Part0 = "Torso",
		Part1 = "Right Leg"
	},
	["RootJoint"] = {
		C0 = CFrame.new(0,0,0)* CFrame.Angles(math.rad(-90),math.rad(180),math.rad(0)),
		C1 = CFrame.new(0.5, 1, 0)* CFrame.Angles(math.rad(-90),math.rad(180),math.rad(0)),
		Part0 = "HumanoidRootPart",
		Part1 = "Torso",
		Parent = "HumanoidRootPart"
	},
}

local function transformUICreate()
	local Main = Instance.new("ScreenGui")
	Main.Name = "morphuitransform"
	local Frame = Instance.new("Frame",Main)
	Frame.AnchorPoint = Vector2.new(0.5,0.5)
	Frame.Size = UDim2.fromScale(1,1)
	Frame.Position = UDim2.fromScale(0.5,0.5)
	Frame.BackgroundTransparency = 1
	local tl = Instance.new("TextLabel",Frame)
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.fromScale(1,0.052)
	tl.Position = UDim2.fromScale(0,0)
	tl.Font = Enum.Font.Ubuntu
	tl.TextColor3 = Color3.fromRGB(255,149,227)
	tl.TextScaled = true
	tl.TextStrokeColor3 = Color3.fromRGB(97,84,130)
	tl.TextStrokeTransparency = 0
	return Main
end

local Particles = {
	["Poof"] = {
		["Color"] = Color3.fromRGB(186,71,159),
		["LightEmission"] = 0.5,
		["LightInfluence"] = 1,
		["Size"] = 5,
		["Transparency"] = 1,
		["Texture"] = "rbxassetid://7731347137",
		["ZOffset"] = 10,
		["Lifetime"] = 1,
		["Rate"] = 50,
		["Rotation"] = 300,
		["RotSpeed"] = 10,
		["Speed"] = 10,
		["Shape"] = "Sphere",
		["ShapeInOut"] = "Outward",
		["Acceleration"] = Vector3.new(0,0.1,0),
		["VelocityInheritance"] = 1,
	}
}

local BodyPartTransparencyList = {
	["Torso"] = 1,
	["Left Leg"] = 1,
	["Right Leg"] = 1,
	["Right Arm"] = 0,
	["Left Arm"] = 0,
	["Head"] = 0
}

function Function.AttachmentCreate(Character)
	for Attach, ParentName in pairs(AttachmentParent) do
		local Base = Character:FindFirstChild(ParentName)

		if Base then
			local Attachment = Instance.new("Attachment", Base)
			Attachment.Name = Attach
			Attachment.CFrame = AttachmentCFrame[Attach]
		end
	end
end

function Function.HeadMesh(Part)
	local SpecialMesh = Instance.new("SpecialMesh", Part)
	SpecialMesh.MeshType = Enum.MeshType.Head
	SpecialMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
end

function Function.Dummy(CF)
	local DummyModel = Instance.new("Model")
	local DummyHumanoid = Instance.new("Humanoid", DummyModel)

	local RootPart = Instance.new("Part", DummyModel)
	RootPart.Name = "HumanoidRootPart"
	RootPart.Size = Vector3.new(2,2,1)
	RootPart.Anchored = false
	RootPart.Transparency = 1

	DummyModel.PrimaryPart = RootPart

	for Name, Property in pairs(DummyMesh) do
		local Part = Instance.new("Part", DummyModel)
		Part.Size = Property.Size
		Part.CFrame = RootPart.CFrame * Property.Offset
		Part.Anchored = false
		Part.Name = Name
		Part.CanCollide = true
		if Part.Name == "HumanoidRootPart" then
			Part.CanCollide = false
		end
		if Name == "Head" then
			Function.HeadMesh(Part)
		end
	end

	for Name, MotorData in pairs(DummyMotor6Ds) do
		local Motor = Instance.new("Motor6D", DummyModel.Torso)
		Motor.Name = Name
		Motor.Part0 = DummyModel[MotorData.Part0]
		Motor.Part1 = DummyModel[MotorData.Part1]
		Motor.C0 = MotorData.C0
		Motor.C1 = MotorData.C1
		if MotorData.Parent then
			Motor.Parent = DummyModel[MotorData.Parent]
		end
	end

	local face = Instance.new("Decal",DummyModel.Head)
	face.Texture = "rbxasset://textures/face.png"
	face.Face = "Front"

	Function.AttachmentCreate(DummyModel)

	return DummyModel
end

local function createParticleEmitter(particleData)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(particleData.Color)
	emitter.LightEmission = particleData.LightEmission
	emitter.LightInfluence = particleData.LightInfluence
	emitter.Size = NumberSequence.new(particleData.Size)
	emitter.Texture = particleData.Texture
	emitter.ZOffset = particleData.ZOffset
	emitter.Transparency = NumberSequence.new(particleData.Transparency)
	emitter.Lifetime = NumberRange.new(particleData.Lifetime)
	emitter.Rate = particleData.Rate
	emitter.Rotation = NumberRange.new(particleData.Rotation)
	emitter.RotSpeed = NumberRange.new(particleData.RotSpeed)
	emitter.Speed = NumberRange.new(particleData.Speed)
	emitter.VelocitySpread = 180 

	emitter.Shape = Enum.ParticleEmitterShape[particleData.Shape]
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut[particleData.ShapeInOut]
	emitter.Acceleration = particleData.Acceleration
	emitter.VelocityInheritance = particleData.VelocityInheritance

	return emitter
end


local function R15Method(Character)
	if Character:FindFirstChild("UpperTorso") then
		local FakeLimbs = {}
		local Torso = Instance.new("Part",Character)
		Torso.Transparency = 0
		Torso.Name = "Torso"
		Torso.Size = Vector3.new(2,2,1)
		Torso.CanCollide = false

		local TorsoWeld = Instance.new("Motor6D",Torso)
		TorsoWeld.Part0 = Character.UpperTorso
		TorsoWeld.Part1 = Torso
		TorsoWeld.C0 = CFrame.new(0,-0.2,0) * CFrame.Angles(0,0,0)

		local RightLeg = Instance.new("Part",Character)
		RightLeg.Transparency = 0
		RightLeg.Name = "Right Leg"
		RightLeg.Size = Vector3.new(1, 2, 1)
		RightLeg.CanCollide = false
		local RightLegWeld = Instance.new("Motor6D",RightLeg)
		RightLegWeld.Part0 = Character.RightLowerLeg
		RightLegWeld.Part1 = RightLeg
		RightLegWeld.C0 = CFrame.new(-0.027, 0.05, -0.009) * CFrame.Angles(0,0,0)

		local LeftLeg = Instance.new("Part",Character)
		LeftLeg.Transparency = 0
		LeftLeg.Name = "Left Leg"
		LeftLeg.Size = Vector3.new(1, 2, 1)
		LeftLeg.CanCollide = false
		local LeftLegWeld = Instance.new("Motor6D",LeftLeg)
		LeftLegWeld.Part0 = Character.LeftLowerLeg
		LeftLegWeld.Part1 = LeftLeg
		LeftLegWeld.C0 = CFrame.new(-0.027, 0.05, -0.009) * CFrame.Angles(0,0,0)
		table.insert(Torso,FakeLimbs)
		table.insert(RightLeg,FakeLimbs)
		table.insert(LeftLeg,FakeLimbs)
		for _, Limb in pairs(FakeLimbs) do
			Limb.Color = Character:FindFirstChildOfClass("Motor6D").Part0.Color
		end
		return Torso
	end
end

function PartCreator.ThirtyFourify(Character,Extra2,Misc)

	local Method2CharacterFolder = game.Workspace:FindFirstChild("Method2CharacterFolder")

	if not Method2CharacterFolder then
		Method2CharacterFolder = Instance.new("Folder", game.Workspace)
		Method2CharacterFolder.Name = "Method2CharacterFolder"
	end

	if type(Character) == "string" then
		if game:GetService("Players"):FindFirstChild(Character) then
			Character =  game:GetService("Players"):FindFirstChild(Character).Character
		else
			return
		end
	end

	if Extra2["User Morph"] == true then
		local User = Extra2["User Morph"]
		local userId
		local success, _ = pcall(function()
			userId = Players:GetUserIdFromNameAsync(User)
		end)
		if not success then  warn("Invalid User") return end
		local HumDesc = game.Players:GetHumanoidDescriptionFromUserId(userId)
		Character.Humanoid:ApplyDescription(HumDesc)
		task.wait(0.5)
	end

	if Extra2["ExecutePlayers"] == true then
		for _, i in pairs(game:GetService("Players"):GetPlayers()) do
			coroutine.wrap(function()
				local char = i.Character
				local success, err = pcall(function()
					PartCreator.ThirtyFourify(char, {["Clothed"] = Extra2["Clothed"]})
				end)
				if not success then
					warn(char.Name .. " encountered an error: " .. err)
				end
			end)()
		end
	end

	if not Character:FindFirstChild("Torso") then R15Method(Character) end

	if Character.Torso:FindFirstChild("Feale") then
		Character.Torso.Feale:Destroy()

		for _, i in pairs(Character:GetDescendants()) do
			if i:IsA("Clothing") then
				i.Parent = Character
			end
			if i:IsA("BoolValue") then
				i:Destroy()
			end


		end

		for Name, Value in pairs(BodyPartTransparencyList) do
			local BPInstance = Character:FindFirstChild(Name)
			if BPInstance then
				BPInstance.Transparency = 0
			end
		end

	end

	local Data = Character.Name
	PlayerData[Character.Name] = Function.PlayerDataDefault()
	local DataDetail = PlayerData[Data]

	local Extra = {["TShirt"] = nil, ["Shirt"] = nil, ["Pants"] = nil, ["Tone"] = DataDetail.Tone}

	local PartListData = DataDetail.PartList

	if Extra2["NewRig"] == true then

		local Dummy = Function.Dummy()	
		Dummy.Parent = workspace
		Dummy.HumanoidRootPart.CFrame = Character.HumanoidRootPart.CFrame + Vector3.new(0,2,0)
		if Extra2["RigType"] == "Felinor" then


			local possibleTones = {Color3.fromRGB(50, 47, 45),Color3.fromRGB(202, 157, 148),Color3.fromRGB(234, 236, 195),Color3.fromRGB(194, 199, 151),Color3.fromRGB(133, 134, 111)}

			local randomtone = math.random(1,#possibleTones)
			local tone = possibleTones[randomtone]

			for _, i in pairs(Dummy:GetChildren()) do
				if i:IsA("BasePart") then
					i.Color = tone
				end
			end
			local accTable = {
				["Ears"] = {
					["MeshId"] = "rbxassetid://17175013251",
					["TextureId"] = "rbxassetid://2599831937",
					["VertexColor"] = Vector3.new(0.495, 0.507, 0.385),
					["Weld"] = {
						["C0"] = CFrame.new(-0.011, -0.185, -0.052) * CFrame.Angles(math.rad(0),math.rad(180),math.rad(0)),
						["C1"] = CFrame.new(0,0.583,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
					}
				},
				["Hair2"] = {
					["MeshId"] = "rbxassetid://12798774870",
					["TextureId"] = "rbxassetid://2599831937",
					["VertexColor"] = Vector3.new(0.495, 0.507, 0.385),
					["Weld"] = {
						["C0"] = CFrame.new(-0.087, 1.26, -0.004) * CFrame.Angles(math.rad(0),math.rad(90),math.rad(0)),
						["C1"] = CFrame.new(0,0.583,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
					}
				},
				["Hair3"] = {
					["MeshId"] = "rbxassetid://16246718724",
					["TextureId"] = "rbxassetid://2599831937",
					["VertexColor"] = Vector3.new(0.495, 0.507, 0.385),
					["Weld"] = {
						["C0"] = CFrame.new(-0.006, 1.191, 0.075) * CFrame.Angles(math.rad(0),math.rad(-180),math.rad(0)),
						["C1"] = CFrame.new(0,0.583,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
					},
					["Chance"] = {5,10}
				}
			}

			local felinorfaceset = {
				["Sclera"] = {
					["Texture"] = "http://www.roblox.com/asset/?id=4607991394",
					["Color"] = Color3.fromRGB(255,255,255),
					["ZIndex"] = 0
				},["ShapeA"] = {
					["Texture"] = "http://www.roblox.com/asset/?id=4608017383",
					["Color"] = Color3.fromRGB(255,255,255),
					["ZIndex"] = 1
				},
				["DGFace"] = {
					["Texture"] = "http://www.roblox.com/asset/?id=5613302434",
					["Color"] = Color3.fromRGB(218, 164, 0),
					["ZIndex"] = 3
				}
			}

			Dummy.Head:FindFirstChildOfClass("Decal"):Destroy()
			for Name, i in pairs(felinorfaceset) do
				local decal = Instance.new("Decal",Dummy.Head)
				decal.Texture = i["Texture"]
				decal.Color3 = i["Color"]
				decal.Face = "Front"
				decal.ZIndex = i["ZIndex"]
				decal.Name = Name
			end

			for _, i in pairs(accTable) do
				local acc = Instance.new("Accessory")
				local Handle = Instance.new("Part",acc)
				Handle.Size = Vector3.new(1,1,1)
				Handle.Transparency = 0
				Handle.CanCollide = false
				Handle.Name = "Handle_"
				local spmesh = Instance.new("SpecialMesh",Handle)
				spmesh.MeshType = Enum.MeshType.FileMesh
				spmesh.MeshId = i["MeshId"]
				spmesh.TextureId = i["TextureId"]
				spmesh.VertexColor = i["VertexColor"]

				local accweld = Instance.new("Weld")
				accweld.C0 = i["Weld"]["C0"]
				accweld.C1 = i["Weld"]["C1"]
				accweld.Part0 = Handle
				accweld.Part1 = Dummy.Head
				accweld.Parent = Handle
				acc.Parent = Dummy

				if i["Chance"] then
					local needed = i["Chance"][1]
					local outof = i["Chance"][2]
					local chancecheck = math.random(1,outof)
					if chancecheck < needed then
						acc:Destroy()
					end
				end
			end


			local function darkenColor(originalColor,DarkerColorPercentage)
				local H, S, V = originalColor:ToHSV()

				local DarkerColorCode = Color3.fromHSV(H, S, V - (DarkerColorPercentage * V / 100))

				local r,g,b = math.floor((DarkerColorCode.R*255)+0.5),math.floor((DarkerColorCode.G*255)+0.5),math.floor((DarkerColorCode.B*255)+0.5)
				return r,g,b

			end

			local function c3ToRGB(C3)
				return C3.R*255,C3.G*255,C3.B*255
			end

			local function c3ToVector(C3)
				return Vector3.new(C3.R,C3.G,C3.B)
			end

			for _, i in pairs(Dummy:GetChildren()) do
				if i:IsA("Accessory") then
					if i:FindFirstChild("Handle_") then
						local part = i.Handle_
						local mesh = part:FindFirstChildOfClass("SpecialMesh")
						local hairdark = math.random(30,40)
						local r,g,b = darkenColor(tone,hairdark)
						local vertex = c3ToVector(Color3.fromRGB(r,g,b))
						mesh.VertexColor = vertex
					end
				end
			end

			local EyeDecal = Dummy:FindFirstChild("DGFace",true)
			if EyeDecal then
				local DCP = math.random(20,30)
				local R,G,B = darkenColor(tone,DCP)
				EyeDecal.Color3 = Color3.fromRGB(R,G,B)
			end

			local shirt = Instance.new("Shirt",Dummy)
			local pants = Instance.new("Pants",Dummy)
			shirt.ShirtTemplate = "rbxassetid://11679642015"
			pants.PantsTemplate = "rbxassetid://11679644318"



			Character = Dummy
		end
		Dummy.Name = "Dummy"
		if Extra2["Dummy Name"] == ""  or Extra2["Dummy Name"] == nil then return end
		local User = Extra2["Dummy Name"]
		local userId
		local success, _ = pcall(function()
			userId = Players:GetUserIdFromNameAsync(User)
		end)
		if not success then  warn("Invalid User") return end
		local HumDesc = game.Players:GetHumanoidDescriptionFromUserId(userId)
		Dummy.Humanoid:ApplyDescription(HumDesc)
		Dummy.Name = User.."'s Clone"

	end

	if Extra2["NewRig"] == true then
		if not Extra2["SpawnPos"] then
			Extra2["SpawnPos"] = Character.HumanoidRootPart.CFrame + Vector3.new(2,0,2)
		end
		Character.HumanoidRootPart.CFrame =(Extra2["SpawnPos"] + Vector3.new(0,3,0)) * CFrame.Angles(0,math.rad(-180),0)
	end

	if game:GetService("Players"):GetPlayerFromCharacter(Character) then

		local uicor = coroutine.wrap(function()
			local player = game:GetService("Players"):GetPlayerFromCharacter(Character)
			if player ~= game:GetService("Players").LocalPlayer then return end
			local playerui = player.PlayerGui
			local ui = transformUICreate()
			ui.Parent = playerui
			local possibletexts = {"Voxwlilhg!","34lilhg!","Prghuq Ureorahg!","Uxehqvlp Xqfhuwlilhg!","Hvwurjhq Ryhugrvh.. Mxlfh Zuog Vwboh! "}
			local text = possibletexts[math.random(1,#possibletexts)]
			ui.Frame.TextLabel.Text = coder(text, -3)
			if Misc then
				if Misc["LieTarget"] then
					ui.Frame.TextLabel.Text = coder(text, -3).." Injected by "..Misc["LieTarget"]
				end
			end
			ui.Frame.TextLabel.TextTransparency = 1
			ui.Frame.TextLabel.TextStrokeTransparency = 1
			local ts = game:GetService("TweenService")
			local texttweentransparency = ts:Create(ui.Frame.TextLabel, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{ ["TextTransparency"] = 0, ["TextStrokeTransparency"] = 0})
			local texttweensize = ts:Create(ui.Frame.TextLabel, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.InOut,0,true),{ ["Size"] = UDim2.fromScale(1,0.07) })
			texttweentransparency:Play()
			texttweensize:Play()
			task.wait(1)
			texttweentransparency = ts:Create(ui.Frame.TextLabel, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{ ["TextTransparency"] = 1, ["TextStrokeTransparency"] = 01})
			texttweensize = ts:Create(ui.Frame.TextLabel, TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{ ["Size"] = UDim2.fromScale(1,0.070) })
			texttweentransparency:Play()
			texttweensize:Play()
			task.wait(1)
			ui:Destroy()
		end)()
	end

	local bv = Instance.new("BoolValue",Character)
	bv.Value =false
	bv.Name = "Ready"
	local bv2 = Instance.new("BoolValue",Character)
	bv2.Value =Extra2["Clothed"]
	bv2.Name = "Clothed"

	local poofsmoke = createParticleEmitter(Particles.Poof)
	poofsmoke.Parent = Character.Torso
	poofsmoke.Enabled = true
	local poofsound = Instance.new("Sound",Character.Torso)
	poofsound.SoundId = "rbxassetid://9116406375"
	poofsound.RollOffMode = Enum.RollOffMode.InverseTapered
	poofsound.RollOffMaxDistance = 100
	poofsound:Play()
	poofsound.Ended:Connect(function()
		poofsound:Destroy()
		poofsmoke.Enabled = false
	end)


	for Name, Value in pairs(BodyPartTransparencyList) do
		local BPInstance = Character:FindFirstChild(Name)
		if BPInstance then
			BPInstance.Transparency = Value
		end
	end

	local FMODEL = Instance.new("Model")
	FMODEL.Parent = Character.Torso
	FMODEL.Name = "Feale"




	local TORSOMAIN = Instance.new("Part",FMODEL)
	TORSOMAIN.Transparency =1 
	TORSOMAIN.Size = Vector3.new(2, 2, 1)
	TORSOMAIN.Name = "Torso"
	TORSOMAIN.Color = Character.Torso.Color
	TORSOMAIN.CanCollide = false
	local TORSOMAINWELD = Instance.new("Motor6D",TORSOMAIN)
	TORSOMAINWELD.Part0 = Character.Torso
	TORSOMAINWELD.Part1 = TORSOMAIN

	local RLMAIN = Instance.new("Part",FMODEL)
	RLMAIN.Transparency =1 
	RLMAIN.Size = Vector3.new(1, 2, 1)
	RLMAIN.Name = "Right Leg"
	RLMAIN.Color = Character["Right Leg"].Color
	RLMAIN.CanCollide = false
	local RLMAINWELD = Instance.new("Motor6D",RLMAIN)
	RLMAINWELD.Part0 = Character["Right Leg"]
	RLMAINWELD.Part1 = RLMAIN

	local LLMAIN = Instance.new("Part",FMODEL)
	LLMAIN.Transparency =1 
	LLMAIN.Size = Vector3.new(1, 2, 1)
	LLMAIN.Name = "Left Leg"
	LLMAIN.Color = Character["Left Leg"].Color
	LLMAIN.CanCollide = false
	local LLMAINWELD = Instance.new("Motor6D",LLMAIN)
	LLMAINWELD.Part0 = Character["Left Leg"]
	LLMAINWELD.Part1 = LLMAIN





	local TORSOMESH = Function.Weld(PartListData["TorsoMesh"], Character, Extra, Data)
	local UVTORSO = Function.Weld(PartListData["UVTorso"], Character, Extra, Data)
	local UVTORSOSHIRT = Function.Weld(PartListData["UVTorsoShirt"], Character, Extra, Data)
	local UVTORSOPANTS = Function.Weld(PartListData["UVTorsoPants"], Character, Extra, Data)

	local RIGHTLEG = Function.Weld(PartListData["Right Leg"], Character, Extra, Data)
	local RIGHTLEGT = Function.Weld(PartListData["Right Leg Texture"], Character, Extra, Data)

	local LEFTLEG = Function.Weld(PartListData["Left Leg"], Character, Extra, Data)
	local LEFTLEGT = Function.Weld(PartListData["Left Leg Texture"], Character, Extra, Data)

	local BRMAIN = Function.Weld(PartListData["BRMain"], Character, Extra, Data)
	local BRTexture = Function.Weld(PartListData["ChickenTexture"], Character, Extra, Data)
	local BRPantsTexture = Function.Weld(PartListData["ChickenPantsTexture"], Character, Extra, Data)

	local LEFTMeow = Function.Weld(PartListData["Left Meow"], Character, Extra, Data)
	local RIGHTMeow = Function.Weld(PartListData["Right Meow"], Character, Extra, Data)

	local LEFTMeowTEXTURE = Function.Weld(PartListData["Left Meow Texture"], Character, Extra, Data)
	local RIGHTMeowTEXTURE = Function.Weld(PartListData["Right Meow Texture"], Character, Extra, Data)

	local LEFTMeowSKIN = Function.Weld(PartListData["Left Meow Skin_Clothed"], Character, Extra, Data)
	local RIGHTMeowSKIN = Function.Weld(PartListData["Right Meow Skin_Clothed"], Character, Extra, Data)


	local LEFTChicken = Function.Weld(PartListData["Left Chicken"], Character, Extra, Data)
	local RIGHTChicken = Function.Weld(PartListData["Right Chicken"], Character, Extra, Data)

	local LEFTNle = Function.Weld(PartListData["Left Nle"], Character, Extra, Data)
	local RIGHTNle = Function.Weld(PartListData["Right Nle"], Character, Extra, Data)

	local CLOSED = Function.Weld(PartListData["Closed"], Character, Extra, Data)	

	local CORE = Function.Weld(PartListData["Core"], Character, Extra, Data)	
	local COREPT = Function.Weld(PartListData["CorePT"], Character, Extra, Data)	

	local CORELB = Function.Weld(PartListData["CoreLB"], Character, Extra, Data)	
	local CORELBPT = Function.Weld(PartListData["CoreLBPT"], Character, Extra, Data)

	local CORERB = Function.Weld(PartListData["CoreRB"], Character, Extra, Data)	
	local CORERBPT = Function.Weld(PartListData["CoreRBPT"], Character, Extra, Data)



	PlayerData[Data].CurrentPartList["Trumpets"]["Closed"] = CLOSED

	PlayerData[Data].CurrentPartList["Trumpets"]["Left Nle"] = LEFTNle
	PlayerData[Data].CurrentPartList["Trumpets"]["Right Nle"] = RIGHTNle

	PlayerData[Data].CurrentPartList["Trumpets"]["Left Chicken"] = LEFTChicken
	PlayerData[Data].CurrentPartList["Trumpets"]["Right Chicken"] = RIGHTChicken

	for _, i in pairs(Character.Torso.Feale:GetChildren()) do
		local c = i
		for _, i2 in pairs(c:GetDescendants()) do
			if i2:IsA("BasePart") then
				if string.find(i2.Name,"Texture") then

					if string.find(i2.Name,"Pants") then
						i2.TextureID = Character:FindFirstChildOfClass("Pants").PantsTemplate
					end
					if string.find(i2.Name,"Shirt") or string.find(i2.Name,"BTexture") then
						i2.TextureID = Character:FindFirstChildOfClass("Shirt").ShirtTemplate
					end
				end
			end




		end

	end

	applyPhysics(Character)
	if Extra2["Clothed"] == false then
		Character.Clothed.Value = false
		for _, i in pairs(Character:GetDescendants()) do
			if i:IsA("BasePart") and string.find(i.Name,"Texture") then
				i.Transparency = 1

			end
			if i:IsA("BasePart") and string.find(i.Name,"Base") then
				i.Transparency = 1

			end
			if i:IsA("BasePart") and string.find(i.Name,"SKIN") then
				i.Transparency = 1

			end
			if i:IsA("Decal") and string.find(i.Name,"Texture") then
				i.Transparency = 1
			end
			if i:IsA("Clothing") then
				i.Parent = Character.Torso
			end
			if string.find(i.Name,"Nle") and i:IsA("BasePart") then
				i.Transparency = 0
			end
			if string.find(i.Name,"Closed") and i:IsA("BasePart") then
				i.Transparency = 0
			end
			if i.Name == "LB" or i.Name == "RB" then
				i.Transparency = 0
			end
			Character:FindFirstChild("UVTorso",true).Transparency = 1
			Character:FindFirstChild("TorsoMesh",true).Transparency = 0
		end
	end


	Character:FindFirstChild("Ready").Value = true
	if Misc then
		if Misc["PermaMorph"] == true then
			if game:GetService("Players"):GetPlayerFromCharacter(Character) == nil then return end
			local PermaMorph = coroutine.wrap(function()
				local player = game:GetService("Players"):GetPlayerFromCharacter(Character)
				player.CharacterAdded:Connect(function(NewChar)
					local check = math.random(1,2)
					local c = false
					if check == 2 then c = true end
					task.wait(3)

					PartCreator.ThirtyFourify(NewChar
						,{["Clothed"] = c, ["NewRig"] = false, ["RigType"] = "Felinor"}
					)		
					player.Character.ChildAdded:Connect(function(Child)
						if Child.Name == "HumanoidRootPart" then
							task.wait(1)
							PartCreator.ThirtyFourify(NewChar
								,{["Clothed"] = c, ["NewRig"] = false, ["RigType"] = "Felinor"}
							)	
						end
					end)
				end)

			end)()
		end
	end

end

function PartCreator.SpawnDummy(Character)

	if type(Character) == "string" then
		if game:GetService("Players"):FindFirstChild(Character) then
			Character =  game:GetService("Players"):FindFirstChild(Character).Character
		else
			return
		end
	end

	local Dummy = Function.Dummy()	
	Dummy.Parent = workspace
	Dummy.HumanoidRootPart.CFrame = Character.HumanoidRootPart.CFrame + Vector3.new(0,2,0)
	Dummy.Name = "Dummy"
end



-- LIBRBARY

local executoroptions = {
	["Clothed"] = false,
	["New Rig"] = false,
	["Execute All"] = false,
	["RigType"] = "Dummy",
	["Dummy User"] = "",
	["User Morph"] = "",
	["AutoExecute"] = false
}

local function Execute()
	PartCreator.ThirtyFourify(Players.LocalPlayer.Name
		,{["Clothed"] = executoroptions["Clothed"],
			["NewRig"] = executoroptions["New Rig"],
			["ExecutePlayers"] = executoroptions["Execute All"],
			["RigType"] = executoroptions["RigType"],
			["Dummy User"] = executoroptions["Dummy User"],
			["User Morph"] = executoroptions["User Morph"],
			["AutoExecute"] = false,
		}
	)

end

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/main/BracketV32.lua"))()

local Window = Bracket:Window({Name = "34ifer",Enabled = true,Color = Color3.new(0.654902, 0.396078, 0.882353),Size = UDim2.new(0,496,0,496),Position = UDim2.new(0.5,-248,0.5,-248)}) do



	local Tab = Window:Tab({Name = "Config"}) do

		Tab:Divider({Text = "Morph",Side = "Left"})	

		local Label = Tab:Label({Text = "Settings",Side = "Left"})


		local Execute = Tab:Button({Name = "Execute",Side = "Left",Callback = function()
			Execute()
		end})


		local ClothedToggle = Tab:Toggle({Name = "Clothed",Side = "Left",Value = false,Callback = function(Bool)
			executoroptions["Clothed"] = Bool
		end})

		ClothedToggle:ToolTip("Toggle Clothing")

		local ToggleUI = Tab:Keybind({Name = "ToggleUI",Side = "Left",Key = ";",Mouse = false,Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},Callback = function(Bool,Key)
			if Bool == true then
				Window:Toggle(true)
			else
				Window:Toggle(false)
			end
		end})


		local Section = Tab:Section({Name = "Execute Config",Side = "Right"}) do
			local Label2 = Tab:Label({Text = "Config",Side = "Left"})
			local NewRig = Tab:Toggle({Name = "Spawn Dummy",Side = "Left",Value = false,Callback = function(Bool)
				executoroptions["New Rig"] = Bool
			end})
			local ExecuteAll = Tab:Toggle({Name = "Execute All",Side = "Left",Value = false,Callback = function(Bool)
				executoroptions["Execute All"] = Bool
			end})
			local AutoExecute = Tab:Toggle({Name = "Auto Execute",Side = "Left",Value = false,Callback = function(Bool)
				executoroptions["AutoExecute"] = Bool
			end})
			AutoExecute:ToolTip("Automatically execute new chars")
			ExecuteAll:ToolTip("Execute all players")


			local Def = {"Dummy"}
			local Dropdown = Tab:Dropdown({Name = "Dummy Type",Side = "Left",Default = Def,List = {
				{
					Name = "Dummy",
					Mode = "Toggle",
					Value = false,
					Callback = function(Selected)
						Def = Selected
						executoroptions["RigType"] = Selected
					end
				},
				{
					Name = "Felinor",
					Mode = "Toggle",
					Value = false,
					Callback = function(Selected)
						Def = Selected
						executoroptions["RigType"] = Selected
					end
				},
			}})
			local DummyName = Tab:Textbox({Name = "Dummy Username",Side = "Left",Text = "Text",Placeholder = "Username",NumberOnly = false,Callback = function(String)
				executoroptions["Dummy User"] = String
			end})
			local UserMorph = Tab:Textbox({Name = "Morph Username",Side = "Left",Text = "Text",Placeholder = "Username",NumberOnly = false,Callback = function(String)
				executoroptions["User Morph"] = String
			end})
			DummyName:ToolTip("Dummy Appearance")
			UserMorph:ToolTip("Set your appearance")

		end




	end
end

local CharacterTable = {}



task.spawn(function()



	while true do
		task.wait()
		if executoroptions["AutoExecute"] == true then
			for _, i in pairs(workspace:GetDescendants()) do
				if i:IsA("Humanoid") then
					pcall(function()
						local Char = i.Parent
						task.wait()
						if not table.find(CharacterTable,Char) then
							table.insert(CharacterTable,Char)
						end
					end)

				end
			end
		end
	end
end)


local autoExecute = function(dt)
	if executoroptions["AutoExecute"] == false then return end
	for Index, Data in next, CharacterTable do
		local Character = Data
		if Character == nil then table.remove(CharacterTable, Index)  continue end
		local Torso = Character:FindFirstChild("Torso")
		if not Torso then continue end
		local Morph = Torso:FindFirstChild("Feale")

		if Morph then continue end

		pcall(function()
			PartCreator.ThirtyFourify(Character
				,{["Clothed"] = executoroptions["Clothed"],
					["NewRig"] = executoroptions["New Rig"],
					["ExecutePlayers"] = false,
					["RigType"] = executoroptions["RigType"],
					["Dummy User"] = executoroptions["Dummy User"],
					["User Morph"] = executoroptions["User Morph"],
					["AutoExecute"] = false,
					["Silent"] = true
				}
			)
		end)
	end

end

RunService.Stepped:Connect(autoExecute)


return PartCreator

