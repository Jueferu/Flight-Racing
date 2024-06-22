local AnimationCurve = {}
AnimationCurve.__index = AnimationCurve

export type point = {
	time: number,
	value: number,
	inSlope: number,
	outSlope: number,
	tangentMode: number,
	weightedMode: number,
	inWeight: number,
	outWeight: number,
}

type self = {
	points: { point },
}

export type AnimationCurve = typeof(setmetatable({} :: self, AnimationCurve))

function AnimationCurve.new(points: { point }): AnimationCurve
	local curve = setmetatable({}, AnimationCurve)
	curve.points = points

	return curve
end

function AnimationCurve.Evaluate(self: AnimationCurve, time: number): number
	local points = self.points

	if #points == 0 then
		return 0
	end

	if #points == 1 then
		return points[1].value
	end

	local firstPoint = points[1]
	local lastPoint = points[#points]

	if time <= firstPoint.time then
		return firstPoint.value
	end

	if time >= lastPoint.time then
		return lastPoint.value
	end

	local leftIndex = 1
	local rightIndex = #points

	while leftIndex < rightIndex do
		local midIndex = math.floor((leftIndex + rightIndex) / 2)
		local midPoint = points[midIndex]

		if midPoint.time < time then
			leftIndex = midIndex + 1
		else
			rightIndex = midIndex
		end
	end

	local leftPoint = points[leftIndex - 1]

	if leftPoint and leftPoint.tangentMode == 0 then
		return leftPoint.value
	end

	local rightPoint = points[leftIndex]

	if rightPoint and rightPoint.tangentMode == 0 then
		return rightPoint.value
	end

	local deltaTime = rightPoint.time - leftPoint.time
	local timeDelta = time - leftPoint.time
	local t = timeDelta / deltaTime
	local t2 = t * t
	local t3 = t2 * t
	local a = 2 * t3 - 3 * t2 + 1
	local b = t3 - 2 * t2 + t
	local c = -2 * t3 + 3 * t2
	local d = t3 - t2

	local value = a * leftPoint.value
		+ b * leftPoint.outSlope * deltaTime
		+ c * rightPoint.value
		+ d * rightPoint.inSlope * deltaTime

	return value
end

return AnimationCurve
