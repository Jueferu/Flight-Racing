local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationCurve = require(Shared:WaitForChild("AnimationCurve"))

--[[
    - serializedVersion: 3
      time: -90
      value: 0
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
    - serializedVersion: 3
      time: -30
      value: -1
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
    - serializedVersion: 3
      time: 0
      value: 0
      inSlope: 0.033333335
      outSlope: 0.033333335
      tangentMode: 69
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
    - serializedVersion: 3
      time: 30
      value: 1
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
    - serializedVersion: 3
      time: 90
      value: 0
      inSlope: 0
      outSlope: 0
      tangentMode: 136
      weightedMode: 0
      inWeight: 0.33333334
      outWeight: 0.33333334
]]

local points = {} :: { AnimationCurve.point }

points[1] = {
	time = -90,
	value = 0,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

points[2] = {
	time = -30,
	value = -1,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

points[3] = {
	time = 0,
	value = 0,
	inSlope = 0.033333335,
	outSlope = 0.033333335,
	tangentMode = 69,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

points[4] = {
	time = 30,
	value = 1,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

points[5] = {
	time = 90,
	value = 0,
	inSlope = 0,
	outSlope = 0,
	tangentMode = 136,
	weightedMode = 0,
	inWeight = 0.33333334,
	outWeight = 0.33333334,
}

local curve = AnimationCurve.new(points)
return curve
