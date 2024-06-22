local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationCurve = require(Shared:WaitForChild("AnimationCurve"))

--[[
    - serializedVersion: 3
      time: 0
      value: 0
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
    - serializedVersion: 3
      time: 100
      value: 0.25
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
]]

local points = {} :: { AnimationCurve.point }

points[1] = {
	time = 0,
	value = 0,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

points[2] = {
	time = 100,
	value = 0.25,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

local curve = AnimationCurve.new(points)
return curve
