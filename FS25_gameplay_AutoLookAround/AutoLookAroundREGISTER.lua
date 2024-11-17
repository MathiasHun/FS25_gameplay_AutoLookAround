
AutoLookAroundREGISTER = {}

g_specializationManager:addSpecialization('autoLookAround', 'AutoLookAround', Utils.getFilename('AutoLookAround.lua', g_currentModDirectory), nil)

if g_specializationManager:getSpecializationByName("autoLookAround") == nil then
	Logging.error("[ALA] Error: getSpecializationByName(\"autoLookAround\") == nil")
else
	for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
		if SpecializationUtil.hasSpecialization(Drivable, vehicleType.specializations) and
			SpecializationUtil.hasSpecialization(Motorized, vehicleType.specializations) and
			SpecializationUtil.hasSpecialization(Enterable, vehicleType.specializations) then
				g_vehicleTypeManager:addSpecialization(vehicleName, g_currentModName .. '.autoLookAround')
				print("  Register AutoLookAround '" .. vehicleName.."'")
		end
	end
end