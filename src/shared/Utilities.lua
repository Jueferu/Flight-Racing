local Utilities = {}
Utilities.Vector3 = {}
Utilities.Region3 = {}

function Utilities.MoveTo(value, target, speed, deltaTime, min, max)
	local diff = target - value
	local delta = math.clamp(diff, -speed * deltaTime, speed * deltaTime)
	return math.clamp(value + delta, min or 0, max or 1)
end

--similar to Vector3.Scale, but has separate factor negative values on each axis
function Utilities.Scale6(value: Vector3, posX: number, negX: number, posY: number, negY: number, posZ: number, negZ)
	local result = value

	if result.X > 0 then
		result *= Vector3.new(posX, 1, 1)
	elseif result.X < 0 then
		result *= Vector3.new(negX, 1, 1)
	end

	if result.Y > 0 then
		result *= Vector3.new(1, posY, 1)
	elseif result.Y < 0 then
		result *= Vector3.new(1, negY, 1)
	end

	if result.Z > 0 then
		result *= Vector3.new(1, 1, posZ)
	elseif result.Z < 0 then
		result *= Vector3.new(1, 1, negZ)
	end

	return result
end

function Utilities.TransformAngle(angle, fov, pixelHeight)
	return (math.tan(angle * math.rad) / math.tan(fov / 2 * math.rad)) * pixelHeight / 2
end

function Utilities.FirstOrderIntercept(shooterPosition, shooterVelocity, shotSpeed, targetPosition, targetVelocity)
	local targetRelativePosition = targetPosition - shooterPosition
	local targetRelativeVelocity = targetVelocity - shooterVelocity
	local t = Utilities.FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity)
	return targetPosition + t * targetRelativeVelocity
end

function Utilities.FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity)
	local velocitySquared = targetRelativeVelocity.Magnitude
	if velocitySquared < 0.001 then
		return 0
	end

	local a = velocitySquared - shotSpeed * shotSpeed

	--handle similar velocities
	if math.abs(a) < 0.001 then
		local t = -targetRelativePosition.Magnitude / (2 * targetRelativeVelocity:Dot(targetRelativePosition))
		return math.max(t, 0) --don't shoot back in time
	end

	local b = 2 * targetRelativeVelocity:Dot(targetRelativePosition)
	local c = targetRelativePosition.Magnitude
	local determinant = b * b - 4 * a * c

	if determinant > 0 then --determinant > 0; two intercept paths (most common)
		local t1 = (-b + math.sqrt(determinant)) / (2 * a)
		local t2 = (-b - math.sqrt(determinant)) / (2 * a)
		if t1 > 0 then
			if t2 > 0 then
				return math.min(t1, t2) --both are positive
			else
				return t1 --only t1 is positive
			end
		else
			return math.max(t2, 0) --don't shoot back in time
		end
	elseif determinant < 0 then --determinant < 0; no intercept path
		return 0
	else --determinant = 0; one intercept path, pretty much never happens
		return math.max(-b / (2 * a), 0) --don't shoot back in time
	end
end

function Utilities.Vector3.SignedAngle(self: Vector3, to: Vector3, axis: Vector3): number
	local angle = math.acos(math.clamp(self:Dot(to) / (self.Magnitude * to.Magnitude), -1, 1))
	local sign = 1
	if axis:Dot(self:Cross(to)) < 0 then
		sign = -1
	end
	return angle * sign
end

function Utilities.Vector3.Angle(self: Vector3, to: Vector3): number
	return math.acos(math.clamp(self:Dot(to) / (self.Magnitude * to.Magnitude), -1, 1))
end

function Utilities.Vector3.MoveTowards(self: Vector3, target: Vector3, maxDistanceDelta: number): Vector3
	local delta = target - self
	local sqrDelta = delta.Magnitude
	if sqrDelta == 0 or maxDistanceDelta >= sqrDelta then
		return target
	end

	return self + delta / sqrDelta * maxDistanceDelta
end

function Utilities.Vector3.Clamp(self: Vector3, min: number, max: number): Vector3
	return Vector3.new(math.clamp(self.X, min, max), math.clamp(self.Y, min, max), math.clamp(self.Z, min, max))
end

function Utilities.Vector3.FixNanVector(self: Vector3): Vector3
	return if self == self then self else Vector3.zero
end

function Utilities.Vector3.Reflect(self: Vector3, normal: Vector3): Vector3
	return self - 2 * self:Dot(normal) * normal
end

function Utilities.Vector3.ToDeg(self: Vector3): Vector3
	return Vector3.new(math.deg(self.X), math.deg(self.Y), math.deg(self.Z))
end

function Utilities.Vector3.ToRad(self: Vector3): Vector3
	return Vector3.new(math.rad(self.X), math.rad(self.Y), math.rad(self.Z))
end

function Utilities.Vector3.ProjectOnPlane(self: Vector3, planeNormal: Vector3): Vector3
	local dot = self:Dot(planeNormal)
	return self - planeNormal * dot
end

function Utilities.Vector3.RotateTowards(self: Vector3, target: Vector3, maxRadiansDelta: number, maxMagnitudeDelta: number): Vector3
	local angle = Utilities.Vector3.Angle(self, target)
	if angle == 0 then
		return target
	end

	local t = math.min(1, maxRadiansDelta / angle)
	local newAngle = angle * t
	local axis = self:Cross(target).Unit
	local rotation = CFrame.fromAxisAngle(axis, newAngle)

	local newVector = rotation:VectorToWorldSpace(self)
	local magnitude = math.min(target.Magnitude, self.Magnitude + maxMagnitudeDelta)
	return newVector.Unit * magnitude
end

function Utilities.Region3.ContainsPoint(self: Region3, point: Vector3): boolean
	local size = self.Size
	local halfSize = size / 2
	local center = self.CFrame.Position
	local relativePoint = point - center
	return math.abs(relativePoint.X) <= halfSize.X and math.abs(relativePoint.Y) <= halfSize.Y and math.abs(relativePoint.Z) <= halfSize.Z
end

return Utilities
