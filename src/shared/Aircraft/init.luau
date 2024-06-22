local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local GoodSignal = require(Packages:WaitForChild("GoodSignal"))

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Utilities = require(Shared:WaitForChild("Utilities"))
local AnimationCurve = require(Shared:WaitForChild("AnimationCurve"))

local SimpleRigidBody = require(Shared:WaitForChild("SimpleRigidBody"))

local function sqrMagnitude(vector: Vector3): number
	local dot = vector:Dot(vector)
	return math.sqrt(dot)
end

local function projectOnPlane(vector: Vector3, planeNormal: Vector3): Vector3
	local dot = vector:Dot(planeNormal)
	return vector - planeNormal * dot
end

local function vectorToRad(vector: Vector3): Vector3
	return Vector3.new(math.rad(vector.X), math.rad(vector.Y), math.rad(vector.Z))
end

local function vectorToDeg(vector: Vector3): Vector3
	return Vector3.new(math.deg(vector.X), math.deg(vector.Y), math.deg(vector.Z))
end

local function vectorScale(vector: Vector3, scale: Vector3): Vector3
	local x = vector.X * scale.X
	local y = vector.Y * scale.Y
	local z = vector.Z * scale.Z
	return Vector3.new(x, y, z)
end

local function Vector3Angle(vector: Vector3, vector2: Vector3): number
	local dot = vector:Dot(vector2)
	return math.acos(dot / (vector.Magnitude * vector2.Magnitude))
end

local function Vector3RotateTowards(
	current: Vector3,
	target: Vector3,
	maxRadiansDelta: number,
	maxMagnitudeDelta: number
)
	local angle = Vector3Angle(current, target)
	if angle == 0 then
		return target
	end

	local t = math.min(1, maxRadiansDelta / angle)
	local newAngle = angle * t
	local axis = current:Cross(target).Unit
	local rotation = CFrame.fromAxisAngle(axis, newAngle)

	local newVector = rotation:VectorToWorldSpace(current)
	local magnitude = math.min(target.Magnitude, current.Magnitude + maxMagnitudeDelta)
	return newVector.Unit * magnitude
end

function CalculateGForce(angularVelocity: Vector3, velocity: Vector3)
	return angularVelocity:Cross(velocity)
end

local Aircraft = setmetatable({}, SimpleRigidBody)
Aircraft.__index = Aircraft

type self = {
	ClassName: string,
	steeringCurve: AnimationCurve.AnimationCurve,
	dragForward: AnimationCurve.AnimationCurve,
	dragBack: AnimationCurve.AnimationCurve,
	dragRight: AnimationCurve.AnimationCurve,
	dragLeft: AnimationCurve.AnimationCurve,
	dragTop: AnimationCurve.AnimationCurve,
	dragBottom: AnimationCurve.AnimationCurve,
	MissileLocked: boolean,
	MissileTracking: boolean,
	MissileLockDirection: Vector3,
	LockRange: number,
	LockAngle: number,
	LockSpeed: number,
	MissileDebounceTime: number,
	MissileDebounceTimer: number,
	MissileReloadTime: number,
	MissileIndex: number,
	FiredMissile: RBXScriptSignal,
	FiredCannon: RBXScriptSignal,
	Target: SimpleRigidBody.SimpleRigidBody,
	MissileReloadTimers: { number },
	_Hardpoints: { Attachment },
	rudderAOACurve: AnimationCurve.AnimationCurve,
	rudderInducedDragCurve: AnimationCurve.AnimationCurve,
	inducedDragCurve: AnimationCurve.AnimationCurve,
	liftAOACurve: AnimationCurve.AnimationCurve,
	Velocity: Vector3,
	LocalVelocity: Vector3,
	LocalAngularVelocity: Vector3,
	EffectiveInput: Vector3,
	AngleOfAttack: number,
	AngleOfAttackYaw: number,
	LocalGForce: Vector3,
	Throttle: number,
	maxThrust: number,
	throttleSpeed: number,
	gLimit: number,
	gLimitPitch: number,
	throttleInput: number,
	inducedDrag: number,
	rudderPower: number,
	flapsLiftPower: number,
	flapsAOABias: number,
	flapsDrag: number,
	flapsRetractSpeed: number,
	turnSpeed: Vector3,
	turnAcceleration: Vector3,
	angularDrag: Vector3,
	airbrakeDrag: number,
	liftPower: number,
	controlInput: Vector3,
	flareTimer: number,
	flareCooldown: number,
	DeployedFlares: RBXScriptSignal,
	_debugMotorForce: Attachment,
	_debugLiftForce: Attachment,
	_debugYawForce: Attachment,
	_debugDragForce: Attachment,
	_lastVelocity: Vector3,
	_AI_State: string,
	_AI_State_Change: RBXScriptSignal,
	_AI_State_Last: string,
}

export type Aircraft = typeof(setmetatable({} :: self, Aircraft)) & SimpleRigidBody.SimpleRigidBody

function Aircraft.new(root: BasePart): Aircraft
	local self = setmetatable(SimpleRigidBody.new(root) :: Aircraft, Aircraft)

	self.steeringCurve = require(script:WaitForChild("steeringCurve"))
	self.dragForward = require(script:WaitForChild("dragForward"))
	self.dragBack = require(script:WaitForChild("dragBack"))
	self.dragRight = self.dragBack
	self.dragLeft = self.dragBack
	self.dragTop = self.dragBack
	self.dragBottom = self.dragBack

	self.MissileLocked = false
	self.MissileTracking = false
	self.MissileLockDirection = -Vector3.zAxis
	self.LockRange = 10000
	self.LockAngle = math.rad(45)
	self.LockSpeed = 30
	self.MissileDebounceTime = 0.5
	self.MissileDebounceTimer = 0
	self.MissileReloadTime = 5
	self.MissileIndex = 0

	self.CannonDebounceTimer = 0
	self.CannonFiringTimer = 0

	self.FiredMissile = GoodSignal.new()
	self.FiredCannon = GoodSignal.new()
	self.DeployedFlares = GoodSignal.new()

	self.Target = nil

	self.MissileReloadTimers = {}
	self._Hardpoints = {}

	self.rudderAOACurve = require(script:WaitForChild("rudderAOACurve"))
	self.rudderInducedDragCurve = require(script:WaitForChild("rudderInducedDragCurve"))
	self.inducedDragCurve = require(script:WaitForChild("inducedDragCurve"))
	self.liftAOACurve = require(script:WaitForChild("liftAOACurve"))

	self.Velocity = Vector3.zero
	self.LocalVelocity = Vector3.zero
	self.LocalAngularVelocity = Vector3.zero
	self.AngleOfAttack = 0
	self.AngleOfAttackYaw = 0
	self.LocalGForce = Vector3.zero
	self.Throttle = 0.5

	self.EffectiveInput = Vector3.zero

	self.thurstMultiplier = 2500
	self.maxThrust = self.thurstMultiplier * self.mass
	if self.Player == Players.LocalPlayer and RunService:IsClient() then
		self.maxThrust = self.root.Mass * self.thurstMultiplier
	end
	self.throttleSpeed = 0.25
	self.gLimit = self.thurstMultiplier * (1 / 10)
	self.gLimitPitch = self.gLimit * 2
	self.throttleInput = 0

	self.inducedDrag = 75
	self.rudderPower = 100
	self.flapsLiftPower = 100
	self.flapsAOABias = 1
	self.flapsDrag = 5
	self.flapsRetractSpeed = 115
	self.turnSpeed = Vector3.new(60, 15, 180 * 0.5)
	self.turnAcceleration = self.turnSpeed * 2
	self.angularDrag = Vector3.one
	self.airbrakeDrag = 5
	self.liftPower = 150

	self.flareTimer = 0
	self.flareCooldown = 15

	self.CannonFiring = false
	self.CannonFireRate = 600
	self.CannonSpeed = 20000

	self.controlInput = Vector3.zero
	self._AI_State = ""
	self._AI_State_Change = GoodSignal.new()
	self._AI_State_Last = ""

	self._lastVelocity = Vector3.zero

	return self
end

function Aircraft.SetThrottleInput(self: Aircraft, input: number)
	if self.Health <= 0 then
		return
	end
	self.throttleInput = input
end

function Aircraft.SetControlInput(self: Aircraft, input: Vector3)
	if self.Health <= 0 then
		return
	end

	input = Vector3.new(math.clamp(input.X, -1, 1), math.clamp(input.Y, -1, 1), math.clamp(input.Z, -1, 1))

	self.controlInput = input
end

function Aircraft.SetCannonInput(self: Aircraft, input: boolean)
	if self.Health <= 0 then
		return
	end

	self.CannonFiring = input
end

function Aircraft.UpdateFlaps(self: Aircraft)
	local localVelocity = self.LocalVelocity
	if localVelocity.Z < self.flapsRetractSpeed then
		self.FlapsDeployed = false
		return
	end
end

function Aircraft.CalculateState(self: Aircraft)
	local velocity = self.linearVelocity
	local angularVelocity = self.angularVelocity

	if velocity ~= velocity then
		velocity = Vector3.zero
	end

	if angularVelocity ~= angularVelocity then
		angularVelocity = Vector3.zero
	end

	self.Velocity = velocity
	self.LocalVelocity = self.CFrame:VectorToObjectSpace(velocity)
	self.LocalAngularVelocity = self.CFrame:VectorToObjectSpace(angularVelocity)

	self:CalculateAngleOfAttack()
end

function Aircraft.CalculateAngleOfAttack(self: Aircraft)
	local LocalVelocity = self.LocalVelocity * Vector3.new(1, 1, -1)
	if sqrMagnitude(LocalVelocity) < 0.1 then
		self.AngleOfAttack = 0
		self.AngleOfAttackYaw = 0
		return
	end

	self.AngleOfAttack = math.atan2(-LocalVelocity.Y, LocalVelocity.Z)
	self.AngleOfAttackYaw = math.atan2(LocalVelocity.X, LocalVelocity.Z)
end

function Aircraft.CalculateGForce(self: Aircraft, deltaTime: number)
	local acceleration = (self.Velocity - self._lastVelocity) / deltaTime
	self.LocalGForce = self.root.CFrame:VectorToObjectSpace(acceleration) * Vector3.new(1, -1, 1) -- / 9.81 -- Convert to Gs
	self._lastVelocity = self.Velocity
end

function Aircraft.CalculateGForceLimit(self: Aircraft, input: Vector3)
	local gLimit = self.gLimit
	return Utilities.Scale6(input, gLimit, self.gLimitPitch, gLimit, gLimit, gLimit, gLimit) * 9.81
end

function Aircraft.CalculateGLimiter(self: Aircraft, controlInput: Vector3, maxAngularVelocity: Vector3)
	local maxInput = controlInput.Unit

	local limit = self:CalculateGForceLimit(controlInput)
	local maxGForce = CalculateGForce(vectorScale(maxInput, maxAngularVelocity), self.LocalVelocity)

	if maxGForce.Magnitude > limit.Magnitude then
		return limit.Magnitude / maxGForce.Magnitude
	end

	return 1
end

function Aircraft.UpdateThrottle(self: Aircraft, deltaTime: number)
	local target = 0
	if self.throttleInput > 0 then
		target = 1
	end

	self.Throttle =
		Utilities.MoveTo(self.Throttle, target, self.throttleSpeed * math.abs(self.throttleInput), deltaTime)
	self.AirbreakDeployed = self.Throttle == 0 and self.throttleInput < 0
end

function Aircraft.UpdateThurst(self: Aircraft)
	local maxThrust = self.maxThrust
	local Throttle = self.Throttle

	local force = Vector3.zAxis * (maxThrust * Throttle)
	self:addRelativeForce(force, "Force")
end

function Aircraft.UpdateAngularDrag(self: Aircraft)
	local av = self.LocalAngularVelocity
	local drag = sqrMagnitude(av) * -av.Unit

	local vector = vectorScale(drag, self.angularDrag)

	if vector ~= vector then
		vector = Vector3.zero
	end

	self:addRelativeTorque(vector, "Acceleration")
end

function Aircraft.UpdateDrag(self: Aircraft)
	local LocalVelocity = self.LocalVelocity * Vector3.new(1, 1, -1)
	local LocalVelocity2 = sqrMagnitude(LocalVelocity)

	local airbrakeDrag = if self.AirbrakeDeployed then self.airbrakeDrag else 0
	local flapsDrag = if self.FlapsDeployed then self.flapsDrag else 0

	local coefficient = Utilities.Scale6(
		LocalVelocity.Unit,
		self.dragRight:Evaluate(math.abs(LocalVelocity.X)),
		self.dragLeft:Evaluate(math.abs(LocalVelocity.X)),
		self.dragTop:Evaluate(math.abs(LocalVelocity.Y)),
		self.dragBottom:Evaluate(math.abs(LocalVelocity.Y)),
		self.dragForward:Evaluate(math.abs(LocalVelocity.Z)) + airbrakeDrag + flapsDrag,
		self.dragBack:Evaluate(math.abs(LocalVelocity.Z))
	)

	local drag = coefficient.Magnitude * LocalVelocity2 * -LocalVelocity.Unit
	drag *= Vector3.new(1, 1, -1)

	if drag ~= drag then
		return
	end

	self:addRelativeForce(drag)
end

function Aircraft.CalculateLift(
	self: Aircraft,
	angleOfAttack: number,
	rightAxis: Vector3,
	liftPower: number,
	aoaCurve,
	inducedDragCurve
)
	local liftVelocity = projectOnPlane(self.LocalVelocity, rightAxis)
	local liftVelocity2 = sqrMagnitude(liftVelocity)

	local liftCoefficient = aoaCurve:Evaluate(angleOfAttack)
	local liftForce = liftVelocity2 * liftCoefficient * liftPower

	local liftDirection = liftVelocity.Unit:Cross(rightAxis)
	local lift = liftDirection * liftForce

	local dragForce = liftCoefficient ^ 2 * self.inducedDrag
	local dragDirection = -liftVelocity.Unit
	local inducedDrag = dragDirection
		* liftVelocity2
		* dragForce
		* inducedDragCurve:Evaluate(math.max(0, -self.LocalVelocity.Z))

	return lift + inducedDrag
end

function Aircraft.UpdateLift(self: Aircraft)
	local LocalVelocity = self.LocalVelocity
	if sqrMagnitude(LocalVelocity) < 0.1 then
		return
	end

	local flapsLiftPower = if self.FlapsDeployed then self.flapsLiftPower else 0
	local flapsAOABias = if self.FlapsDeployed then self.flapsAOABias else 0

	local liftForce = self:CalculateLift(
		self.AngleOfAttack + math.rad(flapsAOABias),
		Vector3.xAxis,
		self.liftPower + flapsLiftPower,
		self.liftAOACurve,
		self.inducedDragCurve
	)
	liftForce *= Vector3.new(1, -1, 1)

	local yawForce = self:CalculateLift(
		self.AngleOfAttackYaw,
		Vector3.yAxis,
		self.rudderPower,
		self.rudderAOACurve,
		self.rudderInducedDragCurve
	)

	if liftForce ~= liftForce then
		return
	end

	if yawForce ~= yawForce then
		return
	end

	self:addRelativeForce(liftForce, "Force")
	self:addRelativeForce(yawForce, "Force")
end

function Aircraft.CalculateSteering(
	_: Aircraft,
	deltaTime: number,
	angularVelocity: number,
	targetVelocity: number,
	acceleration: number
)
	local error = targetVelocity - angularVelocity
	local accel = acceleration * deltaTime
	return math.clamp(error, -accel, accel)
end

function Aircraft.UpdateSteering(self: Aircraft, deltaTime: number)
	local speed = math.max(0, -self.LocalVelocity.Z)
	local steeringPower = self.steeringCurve:Evaluate(speed)

	local gForceScaling = self:CalculateGLimiter(self.controlInput, vectorToRad(self.turnSpeed) * steeringPower)

	local targetAV = vectorScale(self.controlInput, self.turnSpeed * steeringPower * gForceScaling)
	local av = vectorToDeg(self.LocalAngularVelocity)
	local turnAcceleration = self.turnAcceleration

	local correction = Vector3.new(
		self:CalculateSteering(deltaTime, av.X, targetAV.X, turnAcceleration.X * steeringPower),
		self:CalculateSteering(deltaTime, av.Y, targetAV.Y, turnAcceleration.Y * steeringPower),
		self:CalculateSteering(deltaTime, av.Z, targetAV.Z, turnAcceleration.Z * steeringPower)
	)

	local torque = vectorToRad(correction)
	self:addRelativeTorque(torque, "VelocityChange")

	local correctionInput = Vector3.new(
		math.clamp((targetAV.X - av.X) / turnAcceleration.X, -1, 1),
		math.clamp((targetAV.Y - av.Y) / turnAcceleration.Y, -1, 1),
		math.clamp((targetAV.Z - av.Z) / turnAcceleration.Z, -1, 1)
	)

	local effectiveInput = (correctionInput + self.controlInput) * gForceScaling

	local EffectiveInput = Vector3.new(
		math.clamp(effectiveInput.X, -1, 1),
		math.clamp(effectiveInput.Y, -1, 1),
		math.clamp(effectiveInput.Z, -1, 1)
	)

	self.EffectiveInput = EffectiveInput
end

function Aircraft.UpdateWeapons(self: Aircraft, deltaTime: number)
	self:UpdateWeaponCooldown(deltaTime)
	self:UpdateMissileLock(deltaTime)
	self:UpdateCannon(deltaTime)
end

function Aircraft.UpdateWeaponCooldown(self: Aircraft, deltaTime: number)
	self.MissileDebounceTimer = math.max(0, self.MissileDebounceTimer - deltaTime)
	self.CannonDebounceTimer = math.max(0, self.CannonDebounceTimer - deltaTime)
	self.CannonFiringTimer = math.max(0, self.CannonFiringTimer - deltaTime)
	self.flareTimer = math.max(0, self.flareTimer - deltaTime)

	for i, v in ipairs(self.MissileReloadTimers) do
		self.MissileReloadTimers[i] = math.max(0, v - deltaTime)
	end
end

function Aircraft.UpdateMissileLock(self: Aircraft, deltaTime: number)
	local targetDir = -Vector3.zAxis
	self.MissileTracking = false

	if self.Target and self.Target.Health > 0 then
		local error = self.Target.Root.Position - self.root.Position
		local errorDir = self.root.CFrame:VectorToObjectSpace(error.Unit)

		if error.Magnitude <= self.LockRange and Vector3Angle(-Vector3.zAxis, errorDir) <= self.LockAngle then
			self.MissileTracking = true
			targetDir = errorDir
		end
	end

	self.MissileLockDirection =
		Vector3RotateTowards(self.MissileLockDirection, targetDir, math.rad(self.LockSpeed) * deltaTime, 0)
	self.MissileLocked = self.Target
		and self.MissileTracking
		and Vector3Angle(self.MissileLockDirection, targetDir) < self.LockSpeed * deltaTime

	if self.MissileLockDirection ~= self.MissileLockDirection then
		self.MissileLockDirection = -Vector3.zAxis
	end
end

function Aircraft.TryFireMissile(self: Aircraft)
	if self.Health <= 0 then
		return
	end

	if self.MissileDebounceTimer > 0 then
		return
	end

	for i, _ in ipairs(self._Hardpoints) do
		local cooldownValue = self.MissileReloadTimers[i]
		if cooldownValue > 0 then
			continue
		end

		self:FireMissile(i)
		self.MissileReloadTimers[i] = self.MissileReloadTime
		self.MissileDebounceTimer = self.MissileDebounceTime
		return
	end
end

function Aircraft.TryDeployFlare(self: Aircraft)
	local timer = self.flareTimer
	if timer > 0 then
		return
	end

	self.DeployedFlares:Fire()
end

function Aircraft.FireMissile(self: Aircraft, index: number)
	local targetName = self.Target and self.Target.Name
	if not self.MissileLocked then
		targetName = nil
	end
	self.FiredMissile:Fire(index, targetName)
end

function Aircraft.UpdateCannon(self: Aircraft, _: number)
	if not self.CannonFiring then
		return
	end
	if self.CannonFiringTimer > 0 then
		return
	end

	self.CannonFiringTimer = 60 / self.CannonFireRate
	self.FiredCannon:Fire()
	print("FIREEEE")
end

function Aircraft.Update(self: Aircraft, deltaTime: number)
	if not self.root or self.root.Parent == nil then
		warn(`{self.Name} has been destroyed and still being updated.`)
		return
	end

	self:CalculateState()
	self:CalculateGForce(deltaTime)
	self:UpdateFlaps()

	if self.Health <= 0 then
		local motor: VectorForce = self.root.MotorVectorForce

		if motor.RelativeTo ~= Enum.ActuatorRelativeTo.World then
			motor.RelativeTo = Enum.ActuatorRelativeTo.World
			motor.Force = self.root.CFrame:VectorToWorldSpace(motor.Force)
		end

		self.controlInput = self.controlInput * Vector3.new(0, 0, 1)
	else
		self:UpdateThurst()
		self:UpdateThrottle(deltaTime)
		self:UpdateSteering(deltaTime)
	end

	self:UpdateLift()

	self:UpdateDrag()
	self:UpdateAngularDrag()

	self:CalculateState()
	--self:UpdateWeapons(deltaTime)
end

function Aircraft.Start(self: Aircraft)
	local model = self.Model
	local modelRoot = model.PrimaryPart

	local hardpoints = {}
	for _, v in ipairs(modelRoot:GetChildren()) do
		if v.Name == "Hardpoint" then
			table.insert(hardpoints, v)
			table.insert(self.MissileReloadTimers, 0)
		end
	end

	self._Hardpoints = hardpoints
end

return Aircraft