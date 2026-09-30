-- Studio-safe recreation of the uploaded Cam Lock Panel
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Smoothness slider: 0.10 to 1.00, default 0.18.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local lockedTarget = nil
local lockEnabled = false
local systemEnabled = true
local maxDistance = 10000

local smoothness = 0.18
local minSmoothness = 0.10
local maxSmoothness = 1.00

local keybind = Enum.KeyCode.X
local waitingForKeybind = false

local function validTarget(target)
	if not target or target == player then return false end
	local character = target.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 or not head or not root then
		return false
	end

	return (camera.CFrame.Position - root.Position).Magnitude <= maxDistance
end

local function closestTarget()
	local bestTarget
	local bestDistance = math.huge
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

	for _, target in ipairs(Players:GetPlayers()) do
		if validTarget(target) then
			local head = target.Character.Head
			local screenPos, visible = camera:WorldToViewportPoint(head.Position)

			if visible and screenPos.Z > 0 then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestTarget = target
				end
			end
		end
	end

	return bestTarget
end

local gui = Instance.new("ScreenGui")
gui.Name = "ModernCamLockUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 190)
main.Position = UDim2.new(0, 25, 0.5, -95)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 28)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

local outline = Instance.new("UIStroke", main)
outline.Color = Color3.fromRGB(65, 115, 255)
outline.Thickness = 2

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
topBar.BorderSizePixel = 0
topBar.Parent = main

Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 18)

local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 2)
accent.Position = UDim2.fromOffset(0, 40)
accent.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
accent.BorderSizePixel = 0
accent.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(15, 5)
title.Size = UDim2.new(1, -30, 0, 22)
title.Font = Enum.Font.GothamBold
title.Text = "Cam Lock Panel"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(15, 44)
subtitle.Size = UDim2.new(1, -30, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Press chosen key to lock to nearest head"
subtitle.TextColor3 = Color3.fromRGB(155, 162, 185)
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = main

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(15, 65)
status.Size = UDim2.new(0.5, 0, 0, 18)
status.Font = Enum.Font.GothamMedium
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundTransparency = 1
targetLabel.Position = UDim2.fromOffset(15, 84)
targetLabel.Size = UDim2.new(1, -30, 0, 18)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextColor3 = Color3.fromRGB(180, 186, 210)
targetLabel.TextSize = 10
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Text = "Target: None"
targetLabel.Parent = main

-- Compact smoothness control
local smoothText = Instance.new("TextLabel")
smoothText.BackgroundTransparency = 1
smoothText.Position = UDim2.fromOffset(15, 107)
smoothText.Size = UDim2.fromOffset(82, 18)
smoothText.Font = Enum.Font.GothamMedium
smoothText.Text = "Smoothness"
smoothText.TextColor3 = Color3.fromRGB(205, 210, 230)
smoothText.TextSize = 10
smoothText.TextXAlignment = Enum.TextXAlignment.Left
smoothText.Parent = main

local valueText = Instance.new("TextLabel")
valueText.BackgroundTransparency = 1
valueText.Position = UDim2.new(1, -52, 0, 107)
valueText.Size = UDim2.fromOffset(37, 18)
valueText.Font = Enum.Font.GothamBold
valueText.TextColor3 = Color3.fromRGB(95, 145, 255)
valueText.TextSize = 10
valueText.TextXAlignment = Enum.TextXAlignment.Right
valueText.Parent = main

local slider = Instance.new("Frame")
slider.Position = UDim2.fromOffset(15, 129)
slider.Size = UDim2.new(1, -30, 0, 6)
slider.BackgroundColor3 = Color3.fromRGB(35, 40, 62)
slider.BorderSizePixel = 0
slider.Parent = main
Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
fill.BorderSizePixel = 0
fill.Size = UDim2.new(0, 0, 1, 0)
fill.Parent = slider
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("TextButton")
knob.Size = UDim2.fromOffset(12, 12)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.fromRGB(235, 240, 255)
knob.BorderSizePixel = 0
knob.Text = ""
knob.AutoButtonColor = false
knob.Parent = slider
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(105, 34)
toggle.Position = UDim2.new(1, -120, 1, -48)
toggle.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.Text = "ON"
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.TextSize = 12
toggle.Parent = main
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)

local toggleStroke = Instance.new("UIStroke", toggle)
toggleStroke.Color = Color3.fromRGB(95, 145, 255)
toggleStroke.Thickness = 1

local keybind = Instance.new("TextButton")
keybind.Size = UDim2.fromOffset(70, 24)
keybind.Position = UDim2.fromOffset(15, 147)
keybind.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
keybind.BorderSizePixel = 0
keybind.Font = Enum.Font.GothamMedium
keybind.TextColor3 = Color3.fromRGB(205, 210, 230)
keybind.TextSize = 10
keybind.Text = "Key: X"
keybind.Parent = main
Instance.new("UICorner", keybind).CornerRadius = UDim.new(0, 7)

local keyStroke = Instance.new("UIStroke", keybind)
keyStroke.Color = Color3.fromRGB(55, 65, 95)
keyStroke.Thickness = 1

local function updateSlider()
	local alpha = math.clamp(
		(smoothness - minSmoothness) / (maxSmoothness - minSmoothness),
		0, 1
	)

	fill.Size = UDim2.new(alpha, 0, 1, 0)
	knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	valueText.Text = string.format("%.2f", smoothness)
end

local function setSlider(x)
	local left = slider.AbsolutePosition.X
	local width = slider.AbsoluteSize.X
	local alpha = math.clamp((x - left) / width, 0, 1)

	smoothness = minSmoothness + (maxSmoothness - minSmoothness) * alpha
	smoothness = math.floor(smoothness * 100 + 0.5) / 100
	updateSlider()
end

local sliding = false

slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliding = true
		setSlider(input.Position.X)
	end
end)

knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliding = true
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
		setSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliding = false
	end
end)

local function updateUI()
	status.Text = "Status: " .. (systemEnabled and "Enabled" or "Disabled")
	status.TextColor3 = systemEnabled
		and Color3.fromRGB(75, 220, 125)
		or Color3.fromRGB(240, 90, 90)

	toggle.Text = systemEnabled and "ON" or "OFF"
	toggle.BackgroundColor3 = systemEnabled
		and Color3.fromRGB(65, 115, 255)
		or Color3.fromRGB(65, 70, 90)

	keybind.Text = waitingForKeybind and "Press Key" or ("Key: " .. keybind.Name)

	targetLabel.Text = (lockedTarget and validTarget(lockedTarget))
		and ("Target: " .. lockedTarget.Name)
		or "Target: None"

	updateSlider()
end

toggle.MouseButton1Click:Connect(function()
	systemEnabled = not systemEnabled

	if not systemEnabled then
		lockEnabled = false
		lockedTarget = nil
	end

	updateUI()
end)

keybind.MouseButton1Click:Connect(function()
	waitingForKeybind = true
	keybind.Text = "Press Key"
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if waitingForKeybind then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			keybind = input.KeyCode
			waitingForKeybind = false
			updateUI()
		end
		return
	end

	if systemEnabled and input.UserInputType == Enum.UserInputType.Keyboard
		and input.KeyCode == keybind then

		lockEnabled = not lockEnabled

		if lockEnabled then
			lockedTarget = closestTarget()
		else
			lockedTarget = nil
		end

		updateUI()
	end
end)

-- Dragging, matching the original top-bar behavior
local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

RunService.RenderStepped:Connect(function()
	if not systemEnabled or not lockEnabled then return end

	if not validTarget(lockedTarget) then
		lockedTarget = closestTarget()
		updateUI()
	end

	if lockedTarget and validTarget(lockedTarget) then
		local head = lockedTarget.Character:FindFirstChild("Head")

		if head then
			local targetCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
			camera.CFrame = camera.CFrame:Lerp(targetCF, smoothness)
		end
	end
end)

updateUI()
