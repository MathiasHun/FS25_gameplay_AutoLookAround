
AutoLookAround = {}
AutoLookAround.specName = "spec_" .. g_currentModName .. ".autoLookAround"
AutoLookAround.rotation = 0.8

function AutoLookAround.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function AutoLookAround.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AutoLookAround)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutoLookAround)
end

function AutoLookAround.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "startCameraRotation", AutoLookAround.startCameraRotation)
end

function AutoLookAround:onLoad(savegame)
	local spec = self[AutoLookAround.specName]
	spec.autoLookAroundVisiblyText = false
	spec.autoLookAroundActive = false
	spec.isButtonPressed = false
	spec.startTime = 0
	spec.activated = false
	spec.lookaroundLeftRight = 0
	spec.pause = 0
end

function AutoLookAround:startCameraRotation(spec, camera)
	if spec.activated then
		local rotationStep = 1.2
		rotationStep = rotationStep * 0.001 * g_currentDt

		if spec.lookaroundLeftRight == 0 then
			if (camera.origRotY + AutoLookAround.rotation) >= camera.rotY then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight - rotationStep
			else
				spec.lookaroundLeftRight = 1
				spec.pause = g_time + 300
			end
		elseif spec.lookaroundLeftRight == 1 then
			if camera.rotY >= (camera.origRotY - AutoLookAround.rotation) then
				camera.lastInputValues.leftRight = camera.lastInputValues.leftRight + rotationStep
			else
				spec.lookaroundLeftRight = 2
				spec.pause = g_time + 300
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


function AutoLookAround:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if isActiveForInputIgnoreSelection and self.getIsEntered ~= nil and self:getIsEntered() then
		local spec = self[AutoLookAround.specName]
		if spec == nil then return end
		local camIndex = self.spec_enterable.camIndex
		local camera = self.spec_enterable.cameras[camIndex]
		
		if camera ~= nil and camera.cameraNode ~= nil and camera.isInside then
			if spec.isButtonPressed then
				local currentTime = g_currentMission.time
				--if currentTime - spec.startTime >= 300 and not spec.activated then
					spec.activated = true
				--end
			end
			if spec.activated then
				if g_time > spec.pause then
				AutoLookAround:startCameraRotation(spec, camera)
				end
			end
		else
			spec.isButtonPressed = false
			spec.startTime = 0
			spec.activated = false
			spec.lookaroundLeftRight = 0
			spec.pause = 0
		end

	end
end

function AutoLookAround:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	AutoLookAround.updateActionEvents(self)
end

function AutoLookAround.updateActionEvents(self)
	local spec = self[AutoLookAround.specName]

	if spec == nil then return end
	local actionEvent = spec.actionEvents[InputAction.AUTOLOOKAROUND]
	if actionEvent ~= nil then
		local active
		local camera = self.spec_enterable.cameras[self.spec_enterable.camIndex]
		if camera.isInside then
			active = true
		else
			active = false
		end
		g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, active)
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, active)
	end
end

function AutoLookAround:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)

	if self.isClient then
		
		local camIndex = self.spec_enterable.camIndex
		local camera = self.spec_enterable.cameras[2]
		if self.getIsEntered ~= nil and self:getIsEntered() and camera ~= nil and camera.cameraNode ~= nil then
			local spec = self[AutoLookAround.specName]
			if spec ~= nil and spec.actionEvents ~= nil then
				self:clearActionEventsTable(spec.actionEvents)
				if isActiveForInputIgnoreSelection then
					local added, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AUTOLOOKAROUND, self, AutoLookAround.actionEventCameraRotation, true, true, false, true, nil)
					if added then
						g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
						g_inputBinding:setActionEventTextVisibility(actionEventId, spec.autoLookAroundVisiblyText)
						g_inputBinding:setActionEventActive(actionEventId, spec.autoLookAroundActive)
					end
					AutoLookAround.updateActionEvents(self)
				end
			end
			
		end
	end
end

function AutoLookAround:actionEventCameraRotation(actionName, inputValue, callbackState, isAnalog)
	local spec = self[AutoLookAround.specName]

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