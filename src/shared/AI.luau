local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Aircraft = require(Shared:WaitForChild("Aircraft"))

local Utilities = require(script.Parent:WaitForChild("Utilities"))

--[=[
	@class AI
	
	Represents an AI controller for an aircraft.
]=]

local AI = {}
AI.__index = AI

--[=[
	@interface ControlInput
	@within AI
	.time number -- The time the input was received.
	.targetPosition Vector3 -- The target position of the input.
	
	Represents a control input for the AI.
]=]
type ControlInput = {
	time: number,
	targetPosition: Vector3,
}

type self = {
	steeringSpeed: number,
	recoverSpeedMin: number,
	recoverSpeedMax: number,
	groundCollisionMask: RaycastParams,
	groundCollisionDistance: number,
	groundAvoidanceAngle: number,
	groundAvoidanceMinSpeed: number,
	groundAvoidanceMaxSpeed: number,
	pitchUpThreshold: number,
	fineSteeringAngle: number,
	rollFactor: number,
	yawFactor: number,
	canUseMissiles: boolean,
	canUseCannon: boolean,
	missileLockFiringDelay: number,
	missileFiringCooldown: number,
	missileMinRange: number,
	missileMaxRange: number,
	missileMaxFireAngle: number,
	bulletSpeed: number,
	cannonRange: number,
	cannonMaxFireAngle: number,
	cannonBurstLength: number,
	cannonBurstCooldown: number,
	minMissileDodgeDistance: number,
	reactionDelayMin: number,
	reactionDelayMax: number,
	reactionDelayDistance: number,

	lastInput: Vector3,
	isRecoveringSpeed: boolean,

	missileDelayTimer: number,
	missileCooldownTimer: number,

	cannonFiring: boolean,
	cannonBurstTimer: number,
	cannonCooldownTimer: number,

	inputQueue: { ControlInput },

	dodging: boolean,
	lastDodgePoint: Vector3,
	dodgeOffsets: { Vector3 },
	dodgeTimer: number,
	dodgeUpdateInterval: number,

	aircraft: Aircraft.Aircraft,
	incomingMissile: any,
}
--[=[
	@prop steeringSpeed number
	@within AI
]=]

--[=[
	@prop recoverSpeedMin number
	@within AI
]=]

--[=[
	@prop recoverSpeedMax number
	@within AI
]=]

--[=[
	@prop groundCollisionMask RaycastParams
	@within AI
]=]

--[=[
	@prop groundCollisionDistance number
	@within AI
]=]

--[=[
	@prop groundAvoidanceAngle number
	@within AI
]=]

--[=[
	@prop groundAvoidanceMinSpeed number
	@within AI
]=]

--[=[
	@prop groundAvoidanceMaxSpeed number
	@within AI
]=]

--[=[
	@prop pitchUpThreshold number
	@within AI
]=]

--[=[
	@prop fineSteeringAngle number
	@within AI
]=]

--[=[
	@prop rollFactor number
	@within AI
]=]

--[=[
	@prop yawFactor number
	@within AI
]=]

--[=[
	@prop canUseMissiles boolean
	@within AI
]=]

--[=[
	@prop canUseCannon boolean
	@within AI
]=]

--[=[
	@prop missileLockFiringDelay number
	@within AI
]=]

--[=[
	@prop missileFiringCooldown number
	@within AI
]=]

--[=[
	@prop missileMinRange number
	@within AI
]=]

--[=[
	@prop missileMaxRange number
	@within AI
]=]

--[=[
	@prop missileMaxFireAngle number
	@within AI
]=]

--[=[
	@prop bulletSpeed number
	@within AI
]=]

--[=[
	@prop cannonRange number
	@within AI
]=]

--[=[
	@prop cannonMaxFireAngle number
	@within AI
]=]

--[=[
	@prop cannonBurstLength number
	@within AI
]=]

--[=[
	@prop cannonBurstCooldown number
	@within AI
]=]

--[=[
	@prop minMissileDodgeDistance number
	@within AI
]=]

--[=[
	@prop reactionDelayMin number
	@within AI
]=]

--[=[
	@prop reactionDelayMax number
	@within AI
]=]

--[=[
	@prop reactionDelayDistance number
	@within AI
]=]

--[=[
	@prop lastInput Vector3
	@within AI
]=]

--[=[
	@prop isRecoveringSpeed boolean
	@within AI
]=]

--[=[
	@prop missileDelayTimer number
	@within AI
]=]

--[=[
	@prop missileCooldownTimer number
	@within AI
]=]

--[=[
	@prop cannonFiring boolean
	@within AI
]=]

--[=[
	@prop cannonBurstTimer number
	@within AI
]=]

--[=[
	@prop cannonCooldownTimer number
	@within AI
]=]

--[=[
	@prop inputQueue { ControlInput }
	@within AI
]=]

--[=[
	@prop dodging boolean
	@within AI
]=]

--[=[
	@prop lastDodgePoint Vector3
	@within AI
]=]

--[=[
	@prop dodgeOffsets { Vector3 }
	@within AI
]=]

--[=[
	@prop dodgeTimer number
	@within AI
]=]

--[=[
	@prop dodgeUpdateInterval number
	@within AI
]=]

--[=[
	@prop aircraft Aircraft
	@within AI
]=]

--[=[
	@prop incomingMissile Missile?
	@within AI
]=]

export type AI = typeof(setmetatable({} :: self, AI))

--[=[
	Creates a new AI controller for an aircraft.
	
	@param aircraft Aircraft -- The aircraft to control.
	@return AI -- The AI controller.
]=]
function AI.new(aircraft: Aircraft.Aircraft)
	local self = setmetatable({}, AI)

	self.steeringSpeed = 25
	self.targetThrottle = 0

	self.groundCollisionMask = RaycastParams.new()
	self.groundCollisionMask.FilterDescendantsInstances = { aircraft.root.Parent }

	self.pitchUpThreshold = math.rad(-7.5)
	self.fineSteeringAngle = math.rad(5)
	self.rollFactor = 1
	self.yawFactor = 1
	self.canUseMissiles = true
	self.canUseCannon = false
	self.missileLockFiringDelay = 0
	self.missileFiringCooldown = 2.5
	self.missileMinRange = 100
	self.missileMaxRange = 10000
	self.missileMaxFireAngle = 45
	self.bulletSpeed = 1000
	self.cannonRange = 1000
	self.cannonMaxFireAngle = 2.5
	self.cannonBurstLength = 0.5
	self.cannonBurstCooldown = 2.5
	self.minMissileDodgeDistance = 100
	self.reactionDelayMin = 0.5
	self.reactionDelayMax = 1
	self.reactionDelayDistance = 1000

	self.lastInput = Vector3.zero
	self.isRecoveringSpeed = false

	self.missileDelayTimer = 0.5
	self.missileCooldownTimer = 5

	self.cannonFiring = false
	self.cannonBurstTimer = 0
	self.cannonCooldownTimer = 0

	self.inputQueue = {} :: { ControlInput }

	self.dodging = false
	self.lastDodgePoint = Vector3.zero
	self.dodgeOffsets = {} :: { Vector3 }
	self.dodgeTimer = 0
	self.dodgeUpdateInterval = 0.25

	self.aircraft = aircraft
	self.incomingMissile = nil

	self.enemies = {} :: { Aircraft.Aircraft }
	self.allies = {} :: { Aircraft.Aircraft }

	return self
end

function AI.FindBestTarget(self: AI): Aircraft.Aircraft?
	return self.enemies[1] -- temporary
end

--[=[
	Gets the target position of the aircraft.
	
	@return Vector3 -- The target position.
]=]
function AI.GetTargetPosition(self: AI)
	local aircraft = self.aircraft
	local target = self:FindBestTarget()

	if not target then
		local allies = self.allies
		local cohesion = Vector3.zero
		local separation = Vector3.zero
		local alignment = Vector3.zero
		
		local radius = 10

		for _, ally in ipairs(allies) do
			if ally == self.aircraft then continue end
			cohesion += ally.cframe.Position
			alignment += ally.cframe.LookVector

			local dist = (ally.cframe.Position - aircraft.cframe.Position).Magnitude
			if dist >= radius then
				continue
			end

			separation -= (ally.cframe.Position - aircraft.cframe.Position)
		end

		cohesion /= (#allies - 1)
		alignment /= (#allies - 1)
		alignment *= 100

		local targetPosition = cohesion + separation + alignment
		return targetPosition
	end

	local targetPosition = target.cframe.Position
	local dist = (targetPosition - aircraft.cframe.Position).Magnitude

	if dist < self.cannonRange then
		return Utilities.FirstOrderIntercept(
			aircraft.cframe.Position,
			aircraft.linearVelocity,
			self.bulletSpeed,
			targetPosition,
			target.linearVelocity
		)
	end

	return targetPosition
end

--[=[
	Calculates the steering input for the aircraft.
	
	@param deltaTime number -- The time since the last frame.
	@param targetPosition Vector3 -- The target position.
	@return Vector3 -- The steering input.
]=]
function AI.CalculateSteering(self: AI, deltaTime: number, targetPosition: Vector3): Vector3
	local aircraft = self.aircraft

	local error = targetPosition - aircraft.cframe.Position
	local errorDir = aircraft.cframe:VectorToObjectSpace(error).Unit
	local pitchError = Vector3.new(0, errorDir.Y, errorDir.Z).Unit
	local rollError = Vector3.new(errorDir.X, errorDir.Y, 0).Unit
	local yawError = Vector3.new(errorDir.X, 0, errorDir.Z).Unit

	local targetInput = Vector3.zero

	local pitch = Utilities.Vector3.SignedAngle(-Vector3.zAxis, pitchError, Vector3.xAxis)
	if -pitch < self.pitchUpThreshold then
		pitch += math.rad(360)
	end
	targetInput = Vector3.new(pitch, 0, 0)

	if Utilities.Vector3.Angle(-Vector3.zAxis, errorDir) < self.fineSteeringAngle then
		local yaw = Utilities.Vector3.SignedAngle(-Vector3.zAxis, yawError, Vector3.yAxis)
		targetInput = Vector3.new(targetInput.X, yaw * self.yawFactor, targetInput.Z)
	else
		local roll = Utilities.Vector3.SignedAngle(-Vector3.yAxis, rollError, -Vector3.zAxis)
		targetInput = Vector3.new(targetInput.X, targetInput.Y, roll * self.rollFactor)
	end

	targetInput = Utilities.Vector3.Clamp(targetInput, -1, 1)
	targetInput = Utilities.Vector3.FixNanVector(targetInput)

	self.lastInput = Utilities.Vector3.MoveTowards(self.lastInput, targetInput, self.steeringSpeed * deltaTime)
	return self.lastInput
end

--[=[
	Calculates the position to dodge a missile.
	
	@param deltaTime number -- The time since the last frame.
	@param missile Missile -- The missile to dodge.
	@return Vector3 -- The dodge position.
]=]
function AI.GetMissileDodgePosition(self: AI, deltaTime: number, missile)
	self.dodgeTimer = math.max(0, self.dodgeTimer - deltaTime)
	local missilePos = missile.Root.Position

	local dist = math.max(self.minMissileDodgeDistance, (missilePos - self.aircraft.Root.Position).Magnitude)

	if self.dodgeTimer == 0 then
		local missileFoward = missile.Root.CFrame.LookVector
		self.dodgeOffsets = {
			Vector3.new(0, dist, 0),
			Vector3.new(0, -dist, 0),
			Vector3.new(missileFoward:Cross(Vector3.yAxis) * dist),
			Vector3.new(missileFoward:Cross(-Vector3.yAxis) * dist),
		}

		self.dodgeTimer = self.dodgeUpdateInterval
	end

	local min = math.huge
	local minDodge = missilePos + self.dodgeOffsets[1]
	for _, offset in ipairs(self.dodgeOffsets) do
		local pos = missilePos + offset
		local dist2 = (pos - self.aircraft.Root.Position).Magnitude
		if dist2 < min then
			min = dist2
			minDodge = pos
		end
	end

	self.lastDodgePoint = minDodge
	return minDodge
end

--[=[
	Calculates the throttle input for the aircraft.
	
	@return number -- The throttle input.
]=]
function AI.CalculateThrottle(self: AI)
	local aircraft = self.aircraft
	local targetThrottle = self.targetThrottle
	local throttle = aircraft.Throttle

	local input = targetThrottle - throttle
	input = math.clamp(input, -1, 1)

	return input
end

--[=[
	Calculates the weapons for the aircraft.
	
	@param deltaTime number -- The time since the last frame.
	@return nil
]=]
function AI.CalculateWeapons(self: AI, deltaTime: number)
	if not self.aircraft.Target then
		return
	end

	if self.canUseMissiles then
		self:CalculateMissiles(deltaTime)
	end

	if self.canUseCannon then
		self:CalculateCannon(deltaTime)
	end
end

--[=[
	Calculates the missiles for the aircraft.
	
	@param deltaTime number -- The time since the last frame.
	@return nil
]=]
function AI.CalculateMissiles(self: AI, deltaTime: number)
	self.missileDelayTimer = math.max(0, self.missileDelayTimer - deltaTime)
	self.missileCooldownTimer = math.max(0, self.missileCooldownTimer - deltaTime)

	local error = self.aircraft.Target.Root.Position - self.aircraft.Root.Position
	local range = error.Magnitude
	local targetDir = error.Unit
	local targetAngle = Utilities.Vector3.Angle(targetDir, self.aircraft.Root.CFrame.LookVector)

	if
		not self.aircraft.MissileLocked
		or not (
			targetAngle < math.rad(self.missileMaxFireAngle)
			or (math.rad(180) - targetAngle) < math.rad(self.missileMaxFireAngle)
		)
	then
		self.missileDelayTimer = self.missileLockFiringDelay
		return
	end

	if
		range > self.missileMinRange
		and range < self.missileMaxRange
		and self.missileDelayTimer == 0
		and self.missileCooldownTimer == 0
	then
		self:SetState("Fire")
		if RunService:IsClient() then
			print("try fire")
		end
		self.aircraft:TryFireMissile()
		self.missileCooldownTimer = self.missileFiringCooldown
		return
	end

	if not self._AI_State == "Fire" or not self._AI_State == "Dodging" then
		self:SetState("Tracking")
	end
end

--[=[
	Calculates the cannon for the aircraft.
	
	@param deltaTime number -- The time since the last frame.
	@return nil
]=]
function AI.CalculateCannon(self: AI, deltaTime: number)
	if self.target.Health <= 0 then
		self.cannonFiring = false
		return
	end

	if self.cannonFiring then
		self.cannonBurstTimer = math.max(0, self.cannonBurstTimer - deltaTime)
		if self.cannonBurstTimer == 0 then
			self.cannonFiring = false
			self.cannonCooldownTimer = self.cannonBurstCooldown
			self.aircraft:SetCannonInput(false)
		end
		return
	end

	self.cannonCooldownTimer = math.max(0, self.cannonCooldownTimer - deltaTime)
	local targetPosition = Utilities.FirstOrderIntercept(
		self.aircraft.Root.Position,
		self.aircraft.Root.AssemblyLinearVelocity,
		self.bulletSpeed,
		self.target.Root.Position,
		self.target.Root.AssemblyLinearVelocity
	)

	local error = targetPosition - self.aircraft.Root.Position
	local range = error.Magnitude
	local targetDir = error.Unit
	local targetAngle = Utilities.Vector3.Angle(targetDir, self.aircraft.Root.CFrame.LookVector)

	if
		range < self.cannonRange
		and targetAngle < math.rad(self.cannonMaxFireAngle)
		and self.cannonBurstCooldown == 0
	then
		self.cannonFiring = true
		self.cannonBurstTimer = self.cannonBurstLength
		self.aircraft:SetCannonInput(true)
	end
end

--[=[
	Steers the aircraft to the target position.
	
	@param deltaTime number -- The time since the last frame.
	@param aircraftPosition Vector3 -- The position of the aircraft.
	@return nil
]=]
function AI.SteerToTarget(self: AI, deltaTime: number, aircraftPosition: Vector3)
	local foundTarget = false
	local steering = Vector3.zero
	local targetPosition = Vector3.zero

	local delay = self.reactionDelayMax

	if (aircraftPosition - self.aircraft.cframe.Position).Magnitude < self.reactionDelayDistance then
		delay = self.reactionDelayMin
	end

	while #self.inputQueue > 0 do
		local input = self.inputQueue[1]
		if input.time + delay <= os.clock() then
			targetPosition = input.targetPosition
			foundTarget = true
			table.remove(self.inputQueue, 1)
		else
			break
		end
	end

	if foundTarget then
		steering = self:CalculateSteering(deltaTime, targetPosition)
	end

	self.aircraft:SetControlInput(steering)
end

--[=[
	Returns the most efficient throttle speed for turning.
	This is achieved by calcuating the angle between the aircraft's forward vector and the target position.
	Then the angle is devided by 360 to get a value between 0 and 1.

	@param targetPosition Vector3 -- The target position.
	@return number -- The throttle speed.
]=]
function AI.GetThrottleSpeedForTurn(self: AI, targetPosition): number
	local aircraft = self.aircraft

	local forward = aircraft.cframe.LookVector
	local targetDir = (targetPosition - aircraft.cframe.Position).Unit

	local angle = Utilities.Vector3.Angle(forward, targetDir)
	local turn = angle / math.rad(360)

	turn = if turn == turn then turn else 0
	turn = 1 - turn

	return math.clamp(turn, 0, 1)
end

function AI.WillGoOutOfBounds(self: AI) : Vector3
	local bounds = {
		x = { min = -1024, max = 1024 },
		y = { min = 100, max = 500 },
		z = { min = -1024, max = 1024 }
	}

	local aircraft = self.aircraft
	local origin = aircraft.cframe
	local direction = self.aircraft.linearVelocity

	local nextPosition = origin.Position + direction
	local normal = Vector3.zero

	if nextPosition.X < bounds.x.min then
		normal = Vector3.new(1, 0, 0)
	elseif nextPosition.X > bounds.x.max then
		normal = Vector3.new(-1, 0, 0)
	elseif nextPosition.Y < bounds.y.min then
		normal = Vector3.new(0, 1, 0)
	elseif nextPosition.Y > bounds.y.max then
		normal = Vector3.new(0, -1, 0)
	elseif nextPosition.Z < bounds.z.min then
		normal = Vector3.new(0, 0, 1)
	elseif nextPosition.Z > bounds.z.max then
		normal = Vector3.new(0, 0, -1)
	end

	if normal.Magnitude > 0 then
		return true, origin.Position + (normal * 100)
	end

	return false
end

--[=[
	Updates the AI controller.
	
	@param deltaTime number -- The time since the last frame.
	@return nil
]=]
function AI.Update(self: AI, deltaTime: number)
	local steering = Vector3.zero
	local emergency = false

	local targetPosition = self:GetTargetPosition()
	local isOutOfBounds, boundsCorrectionTarget = self:WillGoOutOfBounds()
	if isOutOfBounds then
		targetPosition = boundsCorrectionTarget
		emergency = true
	end

	steering = self:CalculateSteering(deltaTime, targetPosition)

	table.insert(self.inputQueue, { time = os.clock(), targetPosition = targetPosition })
	self.aircraft:SetThrottleInput(self:CalculateThrottle())

	local targetThrottle = self:GetThrottleSpeedForTurn(targetPosition)
	self.targetThrottle = targetThrottle

	local aColor = Color3.new(0, 1, 0)
	local bColor = Color3.new(1, 0, 0)
	local alpha = self.aircraft.Throttle
	local throttleColor = aColor:Lerp(bColor, alpha)
	self.aircraft.root.Color = throttleColor

	if emergency then
		self.aircraft:SetControlInput(steering)
		return
	end

	self:SteerToTarget(deltaTime, targetPosition)
	--self:CalculateWeapons(deltaTime)
end

return AI
