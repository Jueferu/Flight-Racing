local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Aircraft = require(Shared:WaitForChild("Aircraft"))

local Utilities = require(script.Parent:WaitForChild("Utilities"))

--[[
	Calculates the signed angle between vectors from and to in relation to axis.

The angle returned is the angle of rotation from the first vector to the second, when treating these first two vector inputs as directions. These two vectors also define the plane of rotation, meaning they are parallel to the plane. This means the axis of rotation around which the angle is calculated is the cross product of the first and second vectors (and not the 3rd "axis" parameter). You can use the "left hand rule" to determine the axis of rotation, given the two input vectors. The third input (named the “axis” parameter), gives you a way to provide a contextual direction to include in the calculation. This has the result of flipping the sign of the result depending on whether this third vector that you supply falls above or below the plane of rotation defined by the first two input vectors. Therefore the sign of the final result depends on two things: the order in which you supply the "from" and "to" vector, and the direction of the third "axis" vector.
Note: The angle returned will always be between -180 and 180 degrees, because the method returns the smallest angle between the vectors. That is, it will never return a reflex angle.

]]
function Vector3SignedAngle(from: Vector3, to: Vector3, axis: Vector3)
	local angle = math.acos(math.clamp(from:Dot(to) / (from.Magnitude * to.Magnitude), -1, 1))
	local sign = 1
	if axis:Dot(from:Cross(to)) < 0 then
		sign = -1
	end
	return angle * sign
end

function Vector3Angle(v1: Vector3, v2: Vector3)
	return math.acos(math.clamp(v1:Dot(v2) / (v1.Magnitude * v2.Magnitude), -1, 1))
end

function CFrameLookRotation(forward, up)
	forward = forward.Unit
	local right = up:Cross(forward).Unit
	up = forward:Cross(right).Unit
	return CFrame.fromMatrix(Vector3.new(), right, up, forward)
end

function Vector3MoveTowards(v1: Vector3, v2: Vector3, maxDistanceDelta: number)
	local delta = v2 - v1
	local sqrDelta = delta.Magnitude
	if sqrDelta == 0 or maxDistanceDelta >= sqrDelta then
		return v2
	end

	return v1 + delta / sqrDelta * maxDistanceDelta
end

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
	minSpeed: number,
	maxSpeed: number,
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
	@prop minSpeed number
	@within AI
]=]

--[=[
	@prop maxSpeed number
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
	local maxThrust = aircraft.maxThrust / aircraft.Root.Mass

	self.steeringSpeed = 25
	self.minSpeed = maxThrust * 0.25
	self.maxSpeed = maxThrust * 0.6
	self.desiredSpeed = (self.minSpeed + self.maxSpeed) / 2

	self.groundCollisionMask = RaycastParams.new()
	self.groundCollisionMask.FilterDescendantsInstances = { aircraft.Root.Parent }

	self.groundCollisionDistance = 3000
	self.groundAvoidanceAngle = 10
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

	return self
end

--[=[
	Sets the desired speed of the aircraft.
	
	@param mult number -- The multiplier for the desired speed.
	@return nil
]=]
function AI.SetDesiredSpeed(self: AI, mult: number)
	if mult ~= mult then
		mult = 0
	end

	local desiredSpeed = self.minSpeed + ((self.maxSpeed - self.minSpeed) * mult)
	self.desiredSpeed = desiredSpeed
end

--[=[
	Steers the aircraft to avoid the ground.
	
	@param deltaTime number -- The time since the last frame.
	@param normal Vector3 -- The normal of the ground.
	@return Vector3 -- The steering input.
]=]
function AI.AvoidGround(self: AI, deltaTime: number, normal: Vector3)
	self:SetDesiredSpeed(0.1)
	return self:CalculateSteering(deltaTime, self.aircraft.Root.CFrame.Position + (normal * 100))
end

--[=[
	Gets the target position of the aircraft.
	
	@return Vector3 -- The target position.
]=]
function AI.GetTargetPosition(self: AI)
	local aircraft = self.aircraft
	local target = aircraft.Target

	if not target then
		return aircraft.Root.Position
	end

	local targetPosition = target.Root.Position
	local dist = (targetPosition - aircraft.Root.Position).Magnitude

	if dist < self.cannonRange then
		return Utilities.FirstOrderIntercept(
			aircraft.Root.Position,
			aircraft.Root.AssemblyLinearVelocity,
			self.bulletSpeed,
			targetPosition,
			target.Root.AssemblyLinearVelocity
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

	local target = self.aircraft.Target
	if not target then
		targetPosition = Vector3.new(0, 10000, 0)
	end

	local error = targetPosition - aircraft.Root.Position
	local errorDir = aircraft.Root.CFrame:VectorToObjectSpace(error).Unit
	local pitchError = Vector3.new(0, errorDir.Y, errorDir.Z).Unit
	local rollError = Vector3.new(errorDir.X, errorDir.Y, 0).Unit
	local yawError = Vector3.new(errorDir.X, 0, errorDir.Z).Unit

	local targetInput = Vector3.zero

	local pitch = Vector3SignedAngle(-Vector3.zAxis, pitchError, Vector3.xAxis)
	if -pitch < self.pitchUpThreshold then
		pitch += math.rad(360)
	end
	targetInput = Vector3.new(pitch, 0, 0)

	if Vector3Angle(-Vector3.zAxis, errorDir) < self.fineSteeringAngle then
		local yaw = Vector3SignedAngle(-Vector3.zAxis, yawError, Vector3.yAxis)
		targetInput = Vector3.new(targetInput.X, yaw * self.yawFactor, targetInput.Z)
	else
		local roll = Vector3SignedAngle(-Vector3.yAxis, rollError, -Vector3.zAxis)
		targetInput = Vector3.new(targetInput.X, targetInput.Y, roll * self.rollFactor)
	end

	targetInput = Vector3.new(
		math.clamp(targetInput.X, -1, 1),
		math.clamp(targetInput.Y, -1, 1),
		math.clamp(targetInput.Z, -1, 1)
	)

	self.lastInput = Vector3MoveTowards(self.lastInput, targetInput, self.steeringSpeed * deltaTime)
	if self.lastInput ~= self.lastInput then
		self.lastInput = Vector3.zero
	end
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
	local velocity = self.aircraft.Root.AssemblyLinearVelocity
	local localVelocity = self.aircraft.Root.CFrame:VectorToObjectSpace(velocity) * Vector3.new(1, 1, -1)

	local difference = self.desiredSpeed - localVelocity.Z
	local input = math.clamp(difference, -1, 1)

	input = input == input and input or 0
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
	local targetAngle = Vector3Angle(targetDir, self.aircraft.Root.CFrame.LookVector)

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
	local targetAngle = Vector3Angle(targetDir, self.aircraft.Root.CFrame.LookVector)

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

	if (aircraftPosition - self.aircraft.Root.Position).Magnitude < self.reactionDelayDistance then
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
	Updates the AI controller.
	
	@param deltaTime number -- The time since the last frame.
	@return nil
]=]
function AI.Update(self: AI, deltaTime: number)
	if self.aircraft.Health <= 0 then
		return
	end

	local steering = Vector3.zero
	local emergency = false
	local targetPosition = self.aircraft.Target and self.aircraft.Target.Root.Position

	if not targetPosition then
		local leader = self.Leader
		if leader then
			targetPosition = leader.Root.Position
		else
			targetPosition = self.aircraft.Root.Position
		end
	end

	local velocity = self.aircraft.Root.AssemblyLinearVelocity
	local velocityRot = CFrameLookRotation(velocity, Vector3.yAxis)
	local origin = self.aircraft.Root.Position
	local direction = velocityRot * CFrame.fromEulerAnglesYXZ(self.groundAvoidanceAngle, 0, 0) * -Vector3.zAxis

	direction = direction.Unit
	direction *= self.groundCollisionDistance

	local rayResult =
		workspace:Raycast(origin, origin + direction * self.groundCollisionDistance, self.groundCollisionMask)
	if rayResult or (origin + direction).Y <= 0 then
		steering = self:AvoidGround(deltaTime, rayResult and rayResult.Normal or Vector3.new(0, 1, 0))
		emergency = true

		self:SetDesiredSpeed(0.1)
		if not self.aircraft.MissileTracking then
			self:SetState("Steering")
		end
	else
		local incomingMissile = self.incomingMissile

		if incomingMissile then
			if not self.dodging then
				self.dodging = true
				self.lastDodgePoint = origin
				self.dodgeTimer = 0
			end

			local dodgePosition = self:GetMissileDodgePosition(deltaTime, incomingMissile)
			steering = self:CalculateSteering(deltaTime, dodgePosition)
			emergency = true

			self.isRecoveringSpeed = false
			self:SetState("Dodging")
			self:SetDesiredSpeed(0.2)

			self.aircraft:TryDeployFlare()
		else
			self.dodging = false
			targetPosition = self:GetTargetPosition()
		end
	end

	table.insert(self.inputQueue, { time = os.clock(), targetPosition = targetPosition })

	self.aircraft:SetThrottleInput(self:CalculateThrottle())

	if emergency then
		if self.isRecoveringSpeed then
			if not self.aircraft.MissileTracking then
				self:SetState("Steering")
			end
			steering = Vector3.new(math.clamp(steering.X, math.rad(-0.5), math.rad(0.5)), steering.Y, steering.Z)
		end

		self.aircraft:SetControlInput(steering)
	else
		local goalCF = CFrame.new(self.aircraft.Root.Position, targetPosition)
		local delta = self.aircraft.Root.CFrame:ToObjectSpace(goalCF)
		local rotation = Vector3.new(delta:ToEulerAnglesXYZ())
		local turn = rotation.Magnitude / math.rad(180)
		turn = turn == turn and turn or 0

		self:SetDesiredSpeed(1 - turn)

		self:SteerToTarget(deltaTime, targetPosition)

		if not self.aircraft.MissileTracking then
			self:SetState("Steering")
		end
	end

	self:CalculateWeapons(deltaTime)
end

return AI