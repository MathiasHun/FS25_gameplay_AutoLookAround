
local directory = g_currentModDirectory
local modName = g_currentModName

g_autoLookAroundModName = modName
g_autoLookAroundDirectory = directory

source(Utils.getFilename("scripts/AutoLookAroundMain.lua", directory))

local autoLookAround

local function isEnabled()
	return autoLookAround ~= nil
end

function init()

	autoLookAround = AutoLookAroundMain:new(directory, modName)
	
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

	Mission00.load = Utils.prependedFunction(Mission00.load, loadMission)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)

	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, autoLookAroundsaveToXMLFile)

	SavegameSettingsEvent.readStream = Utils.appendedFunction(SavegameSettingsEvent.readStream, readStream)
	SavegameSettingsEvent.writeStream = Utils.appendedFunction(SavegameSettingsEvent.writeStream, writeStream)
	
	TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateVehicleTypes)
	
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, registerActionEvents)
	BaseMission.unregisterActionEvents = Utils.appendedFunction(BaseMission.unregisterActionEvents, unregisterActionEvents)
	
end

function loadMission(mission)

	mission.autoLookAround = autoLookAround

	addModEventListener(autoLookAround)

end

function loadedMission(mission, node)

	if not isEnabled() then
		print("Error: autoLookAround is nil, not enabled")
		return
	end

	if mission.cancelLoading then
		return
	end

	autoLookAround:onMissionLoaded(mission)

end

function autoLookAroundsaveToXMLFile(missionInfo)
	if isEnabled() and missionInfo.isValid then
		local savegameFolderPath = missionInfo.savegameDirectory 
		if savegameFolderPath == nil then
			savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), missionInfo.savegameIndex)
		end
	end
end

function validateVehicleTypes(typeManager)
	if typeManager.typeName == "vehicle" then
		AutoLookAroundMain.installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
	end
end

function registerActionEvents()
	autoLookAround:registerActionEvents()
end

function unregisterActionEvents()
	autoLookAround:unregisterActionEvents()
end

function unload()

	if not isEnabled() then
		return
	end

	removeModEventListener(autoLookAround)

	autoLookAround:delete()
	autoLookAround = nil

	if g_currentMission ~= nil then
		g_currentMission.autoLookAround = nil
	end
end

function readStream(e, streamId, connection)
	if not isEnabled() then
		return
	end

	autoLookAround:onReadStream(streamId, connection)
end

function writeStream(e, streamId, connection)
	if not isEnabled() then
		return
	end

	autoLookAround:onWriteStream(streamId, connection)
end

init()