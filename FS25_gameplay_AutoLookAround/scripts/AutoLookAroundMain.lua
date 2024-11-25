
AutoLookAroundMain = {}

local AutoLookAroundMain_mt = Class(AutoLookAroundMain)

function AutoLookAroundMain:new(modDirectory, modName)
	local self = {}
	setmetatable(self, AutoLookAroundMain_mt)

	self.modDirectory = modDirectory
	self.modName = modName

	return self
end

function AutoLookAroundMain:onMissionLoaded(mission)
	self.mission = mission
end

function AutoLookAroundMain.installSpecializations(vehicleTypeManager, specializationManager, modDirectory, modName)
	specializationManager:addSpecialization("autoLookAround", "AutoLookAround", Utils.getFilename("scripts/vehicles/specializations/AutoLookAround.lua", modDirectory), nil)

	if specializationManager:getSpecializationByName("autoLookAround") == nil then
		Logging.error("[ALA] getSpecializationByName(\"autoLookAround\") == nil")
	else
		for vehicleName, vehicleType in pairs(vehicleTypeManager.types) do
			
			if vehicleType ~= nil and vehicleName ~= "locomotive" and vehicleName ~= "trainTrailer" and vehicleName ~= "trainTimberTrailer" and vehicleName ~= "conveyorBelt" and vehicleName ~= "pickupConveyorBelt" 
			then
				if SpecializationUtil.hasSpecialization(Drivable, vehicleType.specializations) and
					SpecializationUtil.hasSpecialization(Enterable, vehicleType.specializations) and
					SpecializationUtil.hasSpecialization(Motorized, vehicleType.specializations) then
						vehicleTypeManager:addSpecialization(vehicleName, modName .. ".autoLookAround")
						print("  Register AutoLookAround '" .. vehicleName.."'")
				end
			else
				Logging.info("  No register AutoLookAround '" .. vehicleName.."'")
			end
			
		end
	end
	
end

function AutoLookAroundMain:update()
end

function AutoLookAroundMain:draw()
end

function AutoLookAroundMain:delete()
end

function AutoLookAroundMain:onReadStream(streamId, connection)
	if connection:getIsServer() then
	end
end

function AutoLookAroundMain:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
	end
end