-- Credits to https://scriptblox.com/u/blud_wtf (blud_wtf in discord) and me 

local library = {}

-- Dependencies
local TweenService = game:GetService("TweenService")
local Players = game.Players

-- Configuration (Internal to the library, but could be exposed/modified if needed)
local CONFIG = {
	NotificationWidth = 360,
	NotificationHeight = 80,  -- Base height, might grow with content
	Padding = 10,             -- Space between notifications
	InternalPadding = 10,     -- Padding inside the notification frame
	IconSize = 40,
	DisplayTime = 4,          -- How long notifications stay visible

	BackgroundColor = Color3.fromRGB(45, 45, 45),
	BackgroundTransparency = 0.1,
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeThickness = 4,
	TextColor = Color3.fromRGB(255, 0, 0),

	TitleFont = Enum.Font.RobotoMono,
	TitleSize = 18,
	ContentFont = Enum.Font.Cartoon,
	ContentSize = 15,

	EntryEasingStyle = Enum.EasingStyle.Back,
	EntryEasingDirection = Enum.EasingDirection.Out,
	EntryTime = 0.5,

	ExitEasingStyle = Enum.EasingStyle.Quad,
	ExitEasingDirection = Enum.EasingDirection.In,
	ExitTime = 0.4,

	Icons = {
		Info = "rbxassetid://112082878863231", -- Example: Using Roblox default icons
		Warn = "rbxassetid://117107314745025",
		Error = "rbxassetid://77067602950967",
	}
}

-- Private Variables (Module Scope)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = nil -- Will be created on first notification
local notificationList = {} -- Stores active notification Frames
local isInitialized = false

-- Private Function: Create the main ScreenGui if it doesn't exist
local function initializeUI()
	if isInitialized then return end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EnhancedNotifUI"
	screenGui.Parent = playerGui
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999 -- High display order
	screenGui.ResetOnSpawn = false -- Keep UI persistent across respawns

	isInitialized = true
end

-- Private Function: Update notification positions smoothly
local function updateNotificationPositions()
	if not screenGui then return end -- Don't update if UI not ready

	local currentY = -CONFIG.Padding -- Start position for the topmost notification
	local itemsToRemove = {} -- Keep track of notifications to remove safely

	for i = 1, #notificationList do
		local notifFrame = notificationList[i]
		if not notifFrame or not notifFrame.Parent then
			table.insert(itemsToRemove, i) -- Mark for removal
			continue
		end

		local targetPos = UDim2.new(
			1, -CONFIG.Padding,          -- X: Right side with padding
			1, currentY                  -- Y: Calculated stacked position
		)

		-- Use Sine for repositioning for a slightly softer feel than Quart
		notifFrame:TweenPosition(
			targetPos,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Sine,
			0.3, -- Faster repositioning
			true
		)
		-- Update Y position for the next notification, considering its actual height
		currentY = currentY - (notifFrame.AbsoluteSize.Y + CONFIG.Padding)
	end

	-- Remove marked items safely (iterate backwards)
	for i = #itemsToRemove, 1, -1 do
		table.remove(notificationList, itemsToRemove[i])
	end
end
local function Sound() 
	local s = Instance.new("Sound", game.Workspace)
	s.SoundId = "rbxassetid://8036518208"
	s:Play()
end

-- Private Function: Create a single notification instance
local function createNotification(contentText, titleText, notifType)
	initializeUI() -- Ensure the ScreenGui exists

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrame"
	-- Start off-screen to the right, slightly below the final position for the Back easing effect
	frame.Position = UDim2.new(1, CONFIG.NotificationWidth + 50, 1, 0)
	frame.Size = UDim2.new(0, CONFIG.NotificationWidth, 0, CONFIG.NotificationHeight) -- Initial height
	frame.AnchorPoint = Vector2.new(1, 1) -- Anchor to BottomRight
	frame.BackgroundColor3 = CONFIG.BackgroundColor
	frame.BackgroundTransparency = CONFIG.BackgroundTransparency
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.LayoutOrder = -#notificationList -- Ensure new notifications appear on top visually
	frame.Parent = screenGui
	frame.AutomaticSize = Enum.AutomaticSize.Y -- Allow frame height to adjust to content

	-- Styling
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = frame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = CONFIG.StrokeColor
	uiStroke.Thickness = CONFIG.StrokeThickness
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
}
gradient.Parent = uiStroke

local rs = game:GetService("RunService")
local t = 0
rs.RenderStepped:Connect(function(dt)
    t += dt
    local function hsv(i) return Color3.fromHSV((t + i) % 1, 1, 1) end
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, hsv(0)),
        ColorSequenceKeypoint.new(1, hsv(0.2))
    }
end)
	
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, CONFIG.InternalPadding)
	uiPadding.PaddingBottom = UDim.new(0, CONFIG.InternalPadding)
	uiPadding.PaddingLeft = UDim.new(0, CONFIG.InternalPadding)
	uiPadding.PaddingRight = UDim.new(0, CONFIG.InternalPadding)
	uiPadding.Parent = frame

	-- Icon
	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "Icon"
	iconImage.Size = UDim2.new(0, CONFIG.IconSize, 0, CONFIG.IconSize)
	iconImage.BackgroundTransparency = 1
	iconImage.Image = CONFIG.Icons[notifType] or CONFIG.Icons.Info
	iconImage.ScaleType = Enum.ScaleType.Fit
	iconImage.AnchorPoint = Vector2.new(0, 0.5) -- Anchor to vertical center-left
	iconImage.Position = UDim2.new(0, 0, 0.5, 0) -- Position left, vertical center (relative to padding)
	iconImage.Parent = frame

	local iconAspectRatio = Instance.new("UIAspectRatioConstraint")
	iconAspectRatio.AspectRatio = 1.0
	iconAspectRatio.DominantAxis = Enum.DominantAxis.Height
	iconAspectRatio.Parent = iconImage

	-- Text Container (to hold title and content, allowing icon to be separate)
	local textFrame = Instance.new("Frame")
	textFrame.Name = "TextContainer"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(1, -(CONFIG.IconSize + CONFIG.InternalPadding + 5), 1, 0) -- Fill width minus icon and some spacing
	textFrame.Position = UDim2.new(0, CONFIG.IconSize + 5, 0, 0) -- Position next to icon
	textFrame.Parent = frame
	textFrame.AutomaticSize = Enum.AutomaticSize.Y -- Let this frame adjust height based on text

	local textListLayout = Instance.new("UIListLayout")
	textListLayout.FillDirection = Enum.FillDirection.Vertical
	textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textListLayout.Padding = UDim.new(0, 2) -- Small padding between title and content
	textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	textListLayout.Parent = textFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = titleText or "Message"
	title.Font = CONFIG.TitleFont
	title.TextSize = CONFIG.TitleSize
	title.TextColor3 = CONFIG.TextColor
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.AutomaticSize = Enum.AutomaticSize.Y -- Let height adjust based on text
	title.Size = UDim2.new(1, 0, 0, CONFIG.TitleSize) -- Width = 100%, initial height based on font size
	title.LayoutOrder = 1
	title.Parent = textFrame

	-- Content
	local content = Instance.new("TextLabel")
	content.Name = "Content"
	content.Text = contentText or "c00lkidd"
	content.Font = CONFIG.ContentFont
	content.TextSize = CONFIG.ContentSize
	content.TextColor3 = CONFIG.TextColor
	content.TextWrapped = true
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y -- Let height adjust based on text
	content.Size = UDim2.new(1, 0, 0, CONFIG.ContentSize) -- Width = 100%, initial height based on font size
	content.LayoutOrder = 2
	content.Parent = textFrame
	

	-- Add to the list and update positions
	table.insert(notificationList, 1, frame)
	updateNotificationPositions() -- Shift existing notifications down first

	-- Entry Animation
	-- Need to calculate the correct initial target position based on the list order AFTER updating positions
	local initialTargetY = -CONFIG.Padding
	local initialTargetPos = UDim2.new(1, -CONFIG.Padding, 1, initialTargetY)

	frame:TweenPosition(
		initialTargetPos,
		CONFIG.EntryEasingDirection,
		CONFIG.EntryEasingStyle,
		CONFIG.EntryTime,
		true
	)

	-- Schedule removal
	task.delay(CONFIG.DisplayTime, function()
		-- Check if frame still exists before trying to tween/destroy
		if frame and frame.Parent then
			-- Exit Animation (Slide out to the right and fade)
			local exitPos = UDim2.new(1, CONFIG.NotificationWidth + 50, frame.Position.Y.Scale, frame.Position.Y.Offset)

			local tweenInfo = TweenInfo.new(CONFIG.ExitTime, CONFIG.ExitEasingStyle, CONFIG.ExitEasingDirection)
			local goal = { Position = exitPos, BackgroundTransparency = 1 }
			local tween = TweenService:Create(frame, tweenInfo, goal)

			-- Fade out children elements as well
			local childrenTweens = {}
			for _, child in ipairs(frame:GetChildren()) do
				if child:IsA("GuiObject") then
					if child:IsA("UIStroke") then -- Fade Stroke transparency
						table.insert(childrenTweens, TweenService:Create(child, tweenInfo, { Transparency = 1 }))
					elseif child.Name == "Icon" and child:IsA("ImageLabel") then -- Fade Icon image transparency
						table.insert(childrenTweens, TweenService:Create(child, tweenInfo, { ImageTransparency = 1 }))
					elseif child.Name == "TextContainer" then -- Fade TextLabels inside TextContainer
						for _, textChild in ipairs(child:GetChildren()) do
							if textChild:IsA("TextLabel") then
								table.insert(childrenTweens, TweenService:Create(textChild, tweenInfo, { TextTransparency = 1 }))
							end
						end
					end
				end
			end

			tween:Play()
			for _, childTween in ipairs(childrenTweens) do
				childTween:Play()
			end

			-- Wait for the main tween to finish before destroying and updating
			tween.Completed:Wait()
			-- task.wait(CONFIG.ExitTime) -- Alternative if Completed:Wait() has issues

			-- Remove from list (check again as it might have been removed during wait)
			local foundIndex = table.find(notificationList, frame)
			if foundIndex then
				table.remove(notificationList, foundIndex)
			end

			-- Destroy the frame *after* removing from list
			frame:Destroy()

			-- Update positions of remaining notifications
			updateNotificationPositions()
		end
	end)
	
	return frame -- Return the created frame instance (optional)
end

-- Public API Functions
function library.Info(content, title)
	return createNotification(title or "Information", content or "Info", "Info")
end

function library.Warn(content, title)
	return createNotification(title or "Warning occurred", content or "Warning", "Warn")
	
end

function library.Error(content, title)
	return createNotification(title or "An error occurred", content or "Error", "Error")
	
end

-- Optional: Function to allow changing config externally (use with caution)
-- function library.SetConfig(newConfig)
--    for key, value in pairs(newConfig) do
--        if CONFIG[key] ~= nil then
--            CONFIG[key] = value
--        else
--            warn("NotificationLibrary: Attempted to set invalid config key:", key)
--       end
--    end
-- end

return library
