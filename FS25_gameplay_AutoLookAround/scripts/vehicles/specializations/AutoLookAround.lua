
AutoLookAround = {}

function AutoLookAround.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType("autoLookAround")
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	local SavegameKey = string.format("vehicles.vehicle(?).%s.autoLookAround", g_autoLookAroundModName)
	schemaSavegame:register(XMLValueType.FLOAT, SavegameKey .. "#rotation", "")
	schemaSavegame:register(XMLValueType.FLOAT, SavegameKey .. "#rotationStep", "")
	schemaSavegame:register(XMLValueType.BOOL, SavegameKey .. "#isBackward", "")
	schemaSavegame:register(XMLValueType.FLOAT, SavegameKey .. "#rotationbackward", "")
	schemaSavegame:register(XMLValueType.FLOAT, SavegameKey .. "#rotationStepbackward", "")
	schema:setXMLSpecializationType()
end

function AutoLookAround.prerequisitesPresent(specializations)
	return true
end

function AutoLookAround.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", AutoLookAround)
end

function AutoLookAround.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "startCameraRotation", AutoLookAround.startCameraRotation)
	SpecializationUtil.registerFunction(vehicleType, "startBackWardCameraRotation", AutoLookAround.startBackWardCameraRotation)
end

function AutoLookAround:onLoad(savegame)
	if self.spec_autoLookAround == nil then
		self.spec_autoLookAround = {}
	end
	local spec = self.spec_autoLookAround
	
	spec.rotation = 45
	spec.rotationStep = 1.5
	if self.typeName == 'combineDrivable' then
		spec.isBackward = false
	else
		spec.isBackward = true
	end 
	spec.rotationbackward = 165
	spec.rotationStepbackward = 3.2

	spec.autoLookAroundVisiblyText = false
	spec.autoLookAroundActive = false
	spec.isButtonPressed = false
	spec.startTime = 0
	spec.activated = false
	spec.backwardactivated = false
	spec.lookaroundLeftRight = 0
	spec.lookbackward = 0
	spec.pause = 0
	spec.previousCamIndex = nil
	spec.actionEvents = {}
end

function AutoLookAround:onPostLoad(savegame)
	if savegame == nil or savegame.resetVehicles then
		return
	end
	local spec = self.spec_autoLookAround
	local key = string.format("%s.%s.%s", savegame.key, g_autoLookAroundModName, "autoLookAround")
	spec.rotation = savegame.xmlFile:getValue(key .. "#rotation", 45)
	spec.rotationStep = savegame.xmlFile:getValue(key .. "#rotationStep", 1.5)
	spec.isBackward = savegame.xmlFile:getValue(key .. "#isBackward", true)
	spec.rotationbackward = savegame.xmlFile:getValue(key .. "#rotationbackward", 165)
	spec.rotationStepbackward = savegame.xmlFile:getValue(key .. "#rotationStepbackward", 3.2)
end

function AutoLookAround:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if isActiveForInputIgnoreSelection and self.getIsEntered ~= nil and self:getIsEntered() then
		local spec = self.spec_autoLookAround
		if spec == nil then return end

		local camIndex = self.spec_enterable.camIndex
		local camera = self.spec_enterable.cameras[camIndex]
		if spec.previousCamIndex ~= camIndex then
			spec.previousCamIndex = camIndex
			AutoLookAround.updateActionEvents(self) 
		end
		if camera ~= nil and camera.cameraNode ~= nil and camera.isInside then
			if spec.isButtonPressed then
				local currentTime = g_currentMission.time
				--if currentTime - spec.startTime >= 300 and not spec.activated then
					spec.activated = true
				--end
			end
			if spec.activated then
				if g_time > spec.pause then
					AutoLookAround:startCameraRotation(self, camera)
				end
			end
			if self:getLastSpeed() > 1.0 and self.movingDirection == -1 and spec.lookbackward == 0 then
				spec.backwardactivated = true
			end
			if self:getLastSpeed() > 1.0 and self.movingDirection == 1 and spec.lookbackward == 1 then
				spec.backwardactivated = true
			end
			if spec.backwardactivated and spec.isBackward then
				AutoLookAround:startBackWardCameraRotation(self, camera)
			end
		else
			spec.isButtonPressed = false
			spec.startTime = 0
			spec.activated = false
			spec.backwardactivated = false
			spec.lookaroundLeftRight = 0
			spec.pause = 0
		end
	end
end

function AutoLookAround:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
		local camera = camIndex and self.spec_enterable.cameras[camIndex]
		if self.getIsEntered ~= nil and self:getIsEntered() and camera ~= nil and camera.cameraNode ~= nil then
			local spec = self.spec_autoLookAround
			if spec ~= nil and spec.actionEvents ~= nil then
				self:clearActionEventsTable(spec.actionEvents)
				if isActiveForInputIgnoreSelection then
					local added, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND, self, AutoLookAround.actionEventCameraRotation, true, true, false, true, nil)
					if added then
						g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventId, camera.isInside)
						g_inputBinding:setActionEventActive(actionEventId, camera.isInside)
					end
					local set, actionEventIdSet = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND_DEBACK, self, AutoLookAround.actionEventBackRotation, true, true, false, true, nil)
					if set then
						g_inputBinding:setActionEventTextPriority(actionEventIdSet, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventIdSet, camera.isInside)
						g_inputBinding:setActionEventActive(actionEventIdSet, camera.isInside)
					end
					local quickL, actionEventIdquickL = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND_QUICK_L, self, AutoLookAround.actionEventQuickLookL, true, true, false, true, nil)
					if quickL then
						g_inputBinding:setActionEventTextPriority(actionEventIdquickL, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventIdquickL, camera.isInside)
						g_inputBinding:setActionEventActive(actionEventIdquickL, camera.isInside)
					end
					local quickR, actionEventIdquickR = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND_QUICK_R, self, AutoLookAround.actionEventQuickLookR, true, true, false, true, nil)
					if quickR then
						g_inputBinding:setActionEventTextPriority(actionEventIdquickR, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventIdquickR, camera.isInside)
						g_inputBinding:setActionEventActive(actionEventIdquickR, camera.isInside)
					end
					local quickB, actionEventIdquickB = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND_QUICK_B, self, AutoLookAround.actionEventQuickLookB, true, true, false, true, nil)
					if quickR then
						g_inputBinding:setActionEventTextPriority(actionEventIdquickR, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventIdquickB, camera.isInside)
						g_inputBinding:setActionEventActive(actionEventIdquickB, camera.isInside)
					end
					AutoLookAround.updateActionEvents(self)
				end
			end
		end
	end
end

function AutoLookAround:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_autoLookAround
	xmlFile:setValue(key .. "#rotation", spec.rotation)
	xmlFile:setValue(key .. "#rotationStep", spec.rotationStep)
	xmlFile:setValue(key .. "#isBackward", spec.isBackward)
	xmlFile:setValue(key .. "#rotationbackward", spec.rotationbackward)
	xmlFile:setValue(key .. "#rotationStepbackward", spec.rotationStepbackward)
end

function AutoLookAround:startCameraRotation(self, camera)
	local spec = self.spec_autoLookAround
	if spec.activated then
		local rotationStep
		rotationStep = spec.rotationStep * 0.001 * g_currentDt
		local addrotY = math.rad(spec.rotation)
		if spec.lookaroundLeftRight == 0 then
			if (camera.origRotY + addrotY) >= camera.rotY then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight - rotationStep
			else
				spec.lookaroundLeftRight = 1
				spec.pause = g_time + 250
			end
		elseif spec.lookaroundLeftRight == 1 then
			if camera.rotY >= (camera.origRotY - addrotY) then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight + rotationStep
			else
				spec.lookaroundLeftRight = 2
				spec.pause = g_time + 250
			end
		elseif spec.lookaroundLeftRight == 2 then
			if camera.origRotY >= camera.rotY then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight - rotationStep
			else
				spec.isButtonPressed = false
				spec.startTime = 0
				spec.activated = false
				spec.lookaroundLeftRight = 0
				spec.pause = 0
			end
		end
	end
end

function AutoLookAround:startBackWardCameraRotation(self, camera)
	local spec = self.spec_autoLookAround
	if spec.backwardactivated then
		local rotationStep, rotationXStep
		rotationStep = spec.rotationStepbackward * 0.001 * g_currentDt
		rotationXStep = 0.7 * 0.001 * g_currentDt
		if spec.lookbackward == 0 then
			local addrotY = math.rad(spec.rotationbackward)
			if (camera.origRotY + addrotY) >= camera.rotY then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight - rotationStep
			else
				local addrotX = -math.rad(10)
				if (camera.origRotX + addrotX) <= camera.rotX then
					camera.lastInputValues.upDown = camera.lastInputValues.upDown + rotationXStep
				else
					spec.backwardactivated = false
					spec.lookbackward = 1
				end
			end
		elseif spec.lookbackward == 1 and spec.backwardactivated then
			if camera.rotX <= camera.origRotX then
				camera.lastInputValues.upDown = camera.lastInputValues.upDown - rotationXStep
			else
				if camera.rotY >= camera.origRotY then
					camera.lastInputValues.leftRight = camera.lastInputValues.leftRight + rotationStep
				else
					if camera.rotX ~= camera.origRotX then
						camera.rotX = camera.origRotX
					end
					if camera.rotY ~= camera.origRotY then
						camera.rotY = camera.origRotY
					end
					spec.backwardactivated = false
					spec.lookbackward = 0
				end
			end
		end
	end
end

function AutoLookAround:actionEventCameraRotation(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_autoLookAround
	if actionName == "AUTOLOOKAROUND" then
		if inputValue > 0 then
			if not spec.isButtonPressed then
				spec.isButtonPressed = true
				spec.startTime = g_currentMission.time
				spec.activated = false
			end
		else
			spec.isButtonPressed = false
		end
	end
end

function AutoLookAround:actionEventBackRotation(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_autoLookAround
	if actionName == "AUTOLOOKAROUND_DEBACK" then
		if inputValue > 0 then
			if spec.isBackward then
				spec.isBackward = false
			else
				spec.isBackward = true
			end
			AutoLookAround.updateActionEvents(self)
		end
	end
end

function AutoLookAround:actionEventQuickLookL(actionName, inputValue, callbackState, isAnalog)
	local vehicle = g_currentMission.hud.controlledVehicle
	if not vehicle then
		return
	end

	local specEnterable = vehicle.spec_enterable
	if not specEnterable then
		return
	end

	local camera = specEnterable.cameras[specEnterable.camIndex]
	if not camera or not camera.isInside then
		return
	end

	if actionName == "AUTOLOOKAROUND_QUICK_L" then
		if inputValue > 0 then
			camera.rotY = camera.origRotY + math.rad(45)
		else
			camera.rotY = camera.origRotY
		end
	end
end

function AutoLookAround:actionEventQuickLookR(actionName, inputValue, callbackState, isAnalog)
	local vehicle = g_currentMission.hud.controlledVehicle
	if not vehicle then
		return
	end

	local specEnterable = vehicle.spec_enterable
	if not specEnterable then
		return
	end

	local camera = specEnterable.cameras[specEnterable.camIndex]
	if not camera or not camera.isInside then
		return
	end

	if actionName == "AUTOLOOKAROUND_QUICK_R" then
		if inputValue > 0 then
			camera.rotY = camera.origRotY - math.rad(45)
		else
			camera.rotY = camera.origRotY
		end
	end
end

function AutoLookAround:actionEventQuickLookB(actionName, inputValue, callbackState, isAnalog)
	local vehicle = g_currentMission.hud.controlledVehicle
	if not vehicle then
		return
	end

	local specEnterable = vehicle.spec_enterable
	if not specEnterable then
		return
	end

	local camera = specEnterable.cameras[specEnterable.camIndex]
	if not camera or not camera.isInside then
		return
	end

	if actionName == "AUTOLOOKAROUND_QUICK_B" then
		if inputValue > 0 then
			camera.rotY = camera.origRotY + math.rad(180)
			camera.rotX = camera.origRotX - math.rad(10)
		else
			camera.rotY = camera.origRotY
			camera.rotX = camera.origRotX
		end
	end
end

function AutoLookAround.updateActionEvents(self)
	local spec = self.spec_autoLookAround
	if spec == nil then return end
	local actionEvent = spec.actionEvents[InputAction.AUTOLOOKAROUND]
	if actionEvent ~= nil then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
		local camera = camIndex and self.spec_enterable.cameras[camIndex]
		local active = camera ~= nil and camera.isInside
		g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, active)
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, active)
	end
	local edBackEvent = spec.actionEvents[InputAction.AUTOLOOKAROUND_DEBACK]
	if edBackEvent ~= nil then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
		local camera = camIndex and self.spec_enterable.cameras[camIndex]
		local active = camera ~= nil and camera.isInside
		local enabledisable
		if spec.isBackward then
			enabledisable = g_i18n:getText("input_AUTOLOOKAROUND_DEBACK")
			spec.backwardactivated = false
			spec.lookbackward = 0
		else
			enabledisable = g_i18n:getText("input_AUTOLOOKAROUND_EBACK")
		end
		g_inputBinding:setActionEventTextVisibility(edBackEvent.actionEventId, active)
		g_inputBinding:setActionEventActive(edBackEvent.actionEventId, active)
		g_inputBinding:setActionEventText(edBackEvent.actionEventId, enabledisable)
	end
	local quickLEvent = spec.actionEvents[InputAction.AUTOLOOKAROUND_QUICK_L]
	if quickLEvent ~= nil then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
        local camera = camIndex and self.spec_enterable.cameras[camIndex]
		local active = camera ~= nil and camera.isInside
		g_inputBinding:setActionEventTextVisibility(quickLEvent.actionEventId, active)
		g_inputBinding:setActionEventActive(quickLEvent.actionEventId, active)
	end
	local quickREvent = spec.actionEvents[InputAction.AUTOLOOKAROUND_QUICK_R]
	if quickREvent ~= nil then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
		local camera = camIndex and self.spec_enterable.cameras[camIndex]
		local active = camera ~= nil and camera.isInside
		g_inputBinding:setActionEventTextVisibility(quickREvent.actionEventId, active)
		g_inputBinding:setActionEventActive(quickREvent.actionEventId, active)
	end
	local quickBEvent = spec.actionEvents[InputAction.AUTOLOOKAROUND_QUICK_B]
	if quickBEvent ~= nil then
		local camIndex = self.spec_enterable and self.spec_enterable.camIndex
		local camera = camIndex and self.spec_enterable.cameras[camIndex]
		local active = camera ~= nil and camera.isInside
		g_inputBinding:setActionEventTextVisibility(quickBEvent.actionEventId, active)
		g_inputBinding:setActionEventActive(quickBEvent.actionEventId, active)
	end
end

function AutoLookAround:consoleCommandCameraRotation(newrotation)

	if g_currentMission.hud.controlledVehicle == nil then
		return "Please enter a vehicle first"
	end

	if tonumber(newrotation) then
		local spec = g_currentMission.hud.controlledVehicle.spec_autoLookAround
		if spec then
			spec.rotation = math.min(math.max(newrotation, 30), 100)
			print(("[AutoLookAround] Increase or decrease look-around angle(min.: 30 max.: 100): %s"):format(spec.rotation))
		else
			print("Error: AutoLookAround specialization not found for controlled vehicle.")
		end
	else
		print("Error: The value entered is not a number!")
	end

end

function AutoLookAround:consoleCommandCameraRotationBackWard(newrotationbackward)

	if g_currentMission.hud.controlledVehicle == nil then
		return "Please enter a vehicle first"
	end

	if tonumber(newrotationbackward) then
		local spec = g_currentMission.hud.controlledVehicle.spec_autoLookAround
		if spec then
			spec.rotationbackward = math.min(math.max(newrotationbackward, 30), 180)
			print(("[AutoLookAround] Increase or decrease look-back angle(min.: 30 max.: 180): %s"):format(spec.rotationbackward))
		else
			print("Error: AutoLookAround specialization not found for controlled vehicle.")
		end
	else
		print("Error: The value entered is not a number!")
	end

end

function AutoLookAround:consoleCommandBackWard(backwardEnable)

	if g_currentMission.hud.controlledVehicle == nil then
		return "Please enter a vehicle first"
	end

	local isBackward = nil
	if tonumber(backwardEnable) then
		if tonumber(backwardEnable) == 0 then
			isBackward = false
		elseif tonumber(backwardEnable) == 1 then
			isBackward = true
		else
			print("Error!")
			return "Invalid backwardEnable value"
		end
		if isBackward ~= nil then
			local spec = g_currentMission.hud.controlledVehicle.spec_autoLookAround
			if spec then
				spec.isBackward = isBackward
				print(("[AutoLookAround] Look Back Disable/Enable: %s"):format(tostring(isBackward)))
			else
				print("Error: AutoLookAround specialization not found for controlled vehicle.")
			end
		end
	else
		print("Error: The value entered is not a number!")
	end

end

addConsoleCommand("ALAChangeRotation", "Increase or decrease look around angle", "consoleCommandCameraRotation", AutoLookAround)
addConsoleCommand("ALAChangeRotationBack", "Increase or decrease look backward angle", "consoleCommandCameraRotationBackWard", AutoLookAround)
addConsoleCommand("ALALookBackEnable", "Look Back Disable/Enable", "consoleCommandBackWard", AutoLookAround)