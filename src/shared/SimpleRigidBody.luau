type ForceMode = "Force" | "Impulse" | "VelocityChange" | "Acceleration"

local SimpleRigidBody = {}
SimpleRigidBody.__index = SimpleRigidBody

type self = {
	root: BasePart,
	cframe: CFrame,
	linearVelocity: Vector3,
	angularVelocity: Vector3,
	mass: number,
	useGravity: boolean,
	force: Vector3,
	torque: Vector3,
	raycastParams: RaycastParams,
	overlapParams: OverlapParams,
}

export type SimpleRigidBody = typeof(setmetatable({} :: self, SimpleRigidBody))

function SimpleRigidBody.new(root: BasePart)
	local self = setmetatable({}, SimpleRigidBody)

	self.root = root
	self.cframe = root.CFrame
	self.linearVelocity = Vector3.new()
	self.angularVelocity = Vector3.new()

	self.mass = 1

	self.useGravity = true

	self.force = Vector3.new()
	self.torque = Vector3.new()

	self.raycastParams = RaycastParams.new()
	self.raycastParams.CollisionGroup = "Default"
	self.raycastParams.IgnoreWater = false
	self.raycastParams.RespectCanCollide = true

	self.overlapParams = OverlapParams.new()
	self.overlapParams.CollisionGroup = "Default"
	self.overlapParams.MaxParts = 1
	self.overlapParams.RespectCanCollide = true

	return self
end

function SimpleRigidBody.addForce(self: SimpleRigidBody, force: Vector3, forceMode: ForceMode)
	if forceMode == "Force" then
		self.force += force
		return
	end

	if forceMode == "Impulse" then
		self.force += force * self.mass
		return
	end

	if forceMode == "VelocityChange" then
		self.linearVelocity += force
		return
	end

	if forceMode == "Acceleration" then
		self.linearVelocity += force * self.mass
		return
	end
end

function SimpleRigidBody.addRelativeForce(self: SimpleRigidBody, force: Vector3, forceMode: ForceMode)
	local worldForce = self.cframe:VectorToWorldSpace(force)
	self:addForce(worldForce, forceMode)
end

function SimpleRigidBody.updateLinear(self: SimpleRigidBody, dt: number)
	if self.useGravity then
		local gravityForce = Vector3.new(0, -workspace.Gravity, 0) * self.mass
		self.force += gravityForce
	end
	
	local acceleration = self.force / self.mass
	self.linearVelocity += acceleration * dt

	self.force = Vector3.zero
end

function SimpleRigidBody.addTorque(self: SimpleRigidBody, torque: Vector3, forceMode: ForceMode)
	if forceMode == "Force" then
		self.torque += torque
		return
	end

	if forceMode == "Impulse" then
		self.torque += torque * self.mass
		return
	end

	if forceMode == "VelocityChange" then
		self.angularVelocity += torque
		return
	end

	if forceMode == "Acceleration" then
		self.angularVelocity += torque * self.mass
		return
	end
end

function SimpleRigidBody.addRelativeTorque(self: SimpleRigidBody, torque: Vector3, forceMode: ForceMode)
	local worldTorque = self.cframe:VectorToWorldSpace(torque)
	self:addTorque(worldTorque, forceMode)
end

function SimpleRigidBody.updateAngular(self: SimpleRigidBody, dt: number)
	local acceleration = self.torque / self.mass
	self.angularVelocity += acceleration * dt

	self.torque = Vector3.zero
end

function SimpleRigidBody.checkCollision(self: SimpleRigidBody, newCFrame: CFrame, worldModel: WorldModel)
	local currentCFrame = self.cframe
	local direction = newCFrame.Position - currentCFrame.Position

	local rayResult = worldModel:Blockcast(currentCFrame, self.root.Size, direction, self.raycastParams)
	if rayResult then
		return true
	end

	return #worldModel:GetPartBoundsInBox(newCFrame, self.root.Size) > 0
end

function SimpleRigidBody.physics(self: SimpleRigidBody, dt: number)
	self:updateLinear(dt)
	self:updateAngular(dt)

	local linearVelocity = self.linearVelocity
	local angularVelocity = self.root.CFrame:VectorToObjectSpace(self.angularVelocity)

	local positionOffset = linearVelocity * dt
	local rotationOffset = angularVelocity * dt
	local rotationAngles = CFrame.Angles(rotationOffset.X, rotationOffset.Y, rotationOffset.Z)

	local positionedCF = self.cframe + positionOffset
	if self:checkCollision(positionedCF, workspace) then
		return
	end
	local rotatedCF = positionedCF * rotationAngles
	if self:checkCollision(rotatedCF, workspace) then
		return
	end

	self.root.CFrame = rotatedCF
	self.cframe = rotatedCF
end

return SimpleRigidBody
