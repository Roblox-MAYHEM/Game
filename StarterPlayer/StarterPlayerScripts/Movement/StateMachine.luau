local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cooldown = require(ReplicatedStorage.Utils.Cooldown)

local StateMachine = {}
StateMachine.__index = StateMachine

local function stateKey(name)
	return "state" .. name
end

function StateMachine.new(fsm, transitions)
	local self = {
		fsm = fsm,
		Transitions = transitions,
		BufferedKeys = {
			Space = -math.huge,
		},
		invalidCueCooldown = {},
	}

	return setmetatable(self, StateMachine)
end

function StateMachine:Update()
	local rules = self.Transitions.Auto[self.fsm.state]
	if not rules then return end

	for _, rule in ipairs(rules) do
		local result = rule.when and rule.when(self.fsm)
		if result then
			self:Change(rule.to, type(result) == "table" and result)
			return
		end
	end
end

function StateMachine:ProcessInputPhase(phase, input, gameProcessed)
	if gameProcessed then return end

	local keyName = input.KeyCode.Name
	local statesToCheck = { self.fsm.state }
	local currentState = self.fsm.States[self.fsm.state]
	local parentInputBlocked = currentState and currentState.BlockParentInput == true

	local parents = self.Transitions.Parents[self.fsm.state]
	if parents and not parentInputBlocked then
		for _, parent in ipairs(parents) do
			statesToCheck[#statesToCheck + 1] = parent
		end
	end

	local sawMatchingRule = false
	local attemptedTo = nil

	for _, stateName in ipairs(statesToCheck) do
		local rules = self.Transitions.Key[stateName] and self.Transitions.Key[stateName][phase]
		if not rules then continue end

		for _, rule in ipairs(rules) do
			if rule.key ~= keyName then continue end

			sawMatchingRule = true
			attemptedTo = rule.to

			local result = rule.when and rule.when(self.fsm, input) or false
			if result then
				self:Change(rule.to, type(result) == "table" and result)
				return
			end
		end
	end

	if phase == "OnBegan" and keyName == "Space" and not parentInputBlocked then
		self.BufferedKeys.Space = time() + self.fsm.Config.JumpBufferTime
	end

	if phase == "OnBegan" and sawMatchingRule then
		self:PlayInvalidActionCue(keyName, attemptedTo)
	end
end

function StateMachine:Change(stateName, data)
	local fsm = self.fsm
	if stateName == fsm.state or Cooldown.get(stateKey(stateName)) then
		return
	end

	local oldState = fsm.States[fsm.state]
	if oldState then
		oldState:OnExit(stateName, data)
	end

	fsm.PreviousState = fsm.state
	fsm.state = stateName

	local newState = fsm.States[stateName]
	if newState then
		newState:OnEnter(data)
	end
end

function StateMachine:PlayInvalidActionCue(keyName, _attemptedState)
	local now = time()
	local untilTime = self.invalidCueCooldown[keyName] or 0
	if now < untilTime then
		return
	end

	self.invalidCueCooldown[keyName] = now + 0.12

	if self.fsm.Sounds and self.fsm.Sounds.InvalidInput then
		self.fsm.Sounds.InvalidInput:Play()
	end
end

function StateMachine:HasBufferedKey(keyName)
	return (self.BufferedKeys[keyName] or -math.huge) >= time()
end

return StateMachine
