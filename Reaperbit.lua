local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local GETKEY_URL = "https://v2-project-ochre.vercel.app"
local DATABASE_URL = "https://keysystem-reaper-default-rtdb.asia-southeast1.firebasedatabase.app/keys/"
local SAVE_FILE_NAME = "reaper_saved_key.txt"

local function GetHWID()
    local success, hwidValue = pcall(function()
        return gethwid and gethwid() or nil
    end)
    if success and hwidValue and hwidValue ~= "Not Supported" and hwidValue ~= "" then
        return hwidValue
    end
    local successClient, clientId = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if successClient and clientId then 
        return clientId 
    end
    return tostring(LocalPlayer.UserId)
end

local function SafeHttpRequest(requestData)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        local success, result = pcall(function() return req(requestData) end)
        if success then return result end
    end
    return nil
end

local function RunMainScript()
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/caomod2077/Script/refs/heads/main/Fn-stealanegg.lua"))()
        end)
    end)
end

local API = {}

function API.get_key_link()
    return GETKEY_URL
end

function API.check_key(key)
    if not key or key == "" then
        return {
            valid = false,
            message = "Please enter key"
        }
    end

    if not string.match(key, "^REAPER%-[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$") then
        return {
            valid = false,
            message = "Invalid format"
        }
    end

    local requestUrl = DATABASE_URL .. key .. ".json"
    local success, responseRaw = pcall(function() return game:HttpGet(requestUrl) end)

    if not success or not responseRaw or responseRaw == "null" then
        return {
            valid = false,
            message = "Key not found"
        }
    end

    local decodeSuccess, keyData = pcall(function() return HttpService:JSONDecode(responseRaw) end)
    if not decodeSuccess or not keyData then
        return {
            valid = false,
            message = "Data Error"
        }
    end

    if keyData.expiresAt and keyData.expiresAt > 0 then
        if (os.time() * 1000) > keyData.expiresAt then
            return {
                valid = false,
                message = "Key expired"
            }
        end
    end

    local currentHWID = GetHWID()
    if not keyData.hwid or keyData.hwid == "" then
        SafeHttpRequest({
            Url = requestUrl,
            Method = "PATCH",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ hwid = currentHWID })
        })
    elseif keyData.hwid ~= currentHWID then
        return {
            valid = false,
            message = "HWID Mismatch"
        }
    end

    return {
        valid = true,
        message = "KEY_VALID"
    }
end

local function hasFileSystemSupport()
    local hasWrite = pcall(function() return type(writefile) == "function" end)
    local hasRead = pcall(function() return type(readfile) == "function" end)
    local hasIs = pcall(function() return type(isfile) == "function" end)
    return hasWrite and hasRead and hasIs
end

local fileSystemSupported = hasFileSystemSupport()

local function saveVerifiedKey(key)
    if not fileSystemSupported then return false end
    return pcall(function() writefile(SAVE_FILE_NAME, key) end)
end

local function loadVerifiedKey()
    if not fileSystemSupported then return nil end
    local ok, content = pcall(function() return readfile(SAVE_FILE_NAME) end)
    if not ok or not content or content == "" then return nil end
    return content
end

local Icons = {
	Lock = "rbxassetid://114355063515473",
	Key = "rbxassetid://93569468678423",
	CheckCircle = "rbxassetid://10709790644",
	XCircle = "rbxassetid://10747384394",
	Warning = "rbxassetid://130226573962640",
	Info = "rbxassetid://94529541997278",
	Copy = "rbxassetid://107485544510830",
	ErrorFolder = "rbxassetid://113312905787220",
	ReaperIcon = "rbxassetid://131279093559313"
}

local Configuration = {
	ScreenGuiName = "ReaperHubHorizontalKeyUI",
	Window = {Size = UDim2.new(0, 520, 0, 255)},
	Colors = {
		Bg = Color3.fromRGB(10, 10, 12),
		Primary = Color3.fromRGB(239, 68, 68),
		PrimaryDark = Color3.fromRGB(153, 27, 27),
		StatusIdle = Color3.fromRGB(249, 115, 22),
		StatusSuccess = Color3.fromRGB(16, 185, 129),
		StatusError = Color3.fromRGB(239, 68, 68),
		StatusVerifying = Color3.fromRGB(239, 68, 68),
		TextMain = Color3.fromRGB(255, 255, 255),
		TextSec = Color3.fromRGB(161, 161, 170),
		TextMuted = Color3.fromRGB(113, 113, 122),
		Border = Color3.fromRGB(239, 68, 68),
		TrafficRed = Color3.fromRGB(255, 95, 87),
		TrafficYellow = Color3.fromRGB(254, 188, 46),
		TrafficGreen = Color3.fromRGB(40, 200, 64),
		Success = Color3.fromRGB(50, 205, 110),
		Error = Color3.fromRGB(245, 70, 90),
		Warning = Color3.fromRGB(255, 200, 50)
	},
	Animations = { Fast = 0.2, Medium = 0.4, Bounce = 0.6 },
	Fonts = { Body = 13, Small = 11 }
}

local Utils = {}

Utils.Tween = function(obj, props, time, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

Utils.Round = function(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = obj
	return c
end

Utils.Stroke = function(obj, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(1, 1, 1)
	s.Thickness = thick or 1
	s.Transparency = trans or 0.9
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function SetBlur(enabled)
	local blur = Lighting:FindFirstChild("ReaperBlur")
	if enabled then
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "ReaperBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end
		Utils.Tween(blur, {Size = 24}, Configuration.Animations.Bounce)
	elseif blur then
		Utils.Tween(blur, {Size = 0}, Configuration.Animations.Medium)
		task.delay(0.4, function() blur:Destroy() end)
	end
end

local ToastSystem = {ActiveToasts = {}, MaxToasts = 3, ToastSpacing = 10}

ToastSystem.Create = function(parent, message, toastType, duration)
	local colors = {
		success = Configuration.Colors.Success,
		error = Configuration.Colors.Error,
		warning = Configuration.Colors.Warning,
		info = Configuration.Colors.Primary
	}
	local icons = {
		success = Icons.CheckCircle,
		error = Icons.ErrorFolder,
		warning = Icons.Warning,
		info = Icons.Info
	}
	local toastColor = colors[toastType] or colors.info
	local toastIcon = icons[toastType] or Icons.Info

	if #ToastSystem.ActiveToasts >= ToastSystem.MaxToasts then
		local oldest = table.remove(ToastSystem.ActiveToasts, 1)
		if oldest and oldest.Parent then oldest:Destroy() end
	end

	local toastHeight = 56
	local toast = Instance.new("Frame")
	toast.Name = tick()
	toast.Size = UDim2.new(0, 0, 0, toastHeight)
	toast.Position = UDim2.new(0.5, 0, 0, 20)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = Configuration.Colors.Bg
	toast.BackgroundTransparency = 0.5
	toast.BorderSizePixel = 0
	toast.ZIndex = 300
	toast.ClipsDescendants = true
	toast.Parent = parent

	Utils.Round(toast, 14)
	Utils.Stroke(toast, toastColor, 1, 0.1)

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 36, 0, 36)
	iconBg.Position = UDim2.new(0, 12, 0.5, 0)
	iconBg.AnchorPoint = Vector2.new(0, 0.5)
	iconBg.BackgroundColor3 = toastColor
	iconBg.BackgroundTransparency = 0.85
	iconBg.ZIndex = 301
	iconBg.Parent = toast
	Utils.Round(iconBg, 18)

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = toastIcon
	icon.ImageColor3 = toastColor
	icon.ZIndex = 302
	icon.Parent = iconBg

	local textContainer = Instance.new("Frame")
	textContainer.Size = UDim2.new(1, -60, 1, 0)
	textContainer.Position = UDim2.new(0, 56, 0, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 301
	textContainer.Parent = toast

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = message or ""
	text.TextColor3 = Configuration.Colors.TextMain
	text.TextSize = Configuration.Fonts.Body
	text.Font = Enum.Font.GothamMedium
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextWrapped = true
	text.ZIndex = 301
	text.Parent = textContainer

	table.insert(ToastSystem.ActiveToasts, toast)
	ToastSystem.RepositionToasts()

	Utils.Tween(toast, {Size = UDim2.new(0, 320, 0, toastHeight)}, Configuration.Animations.Medium)

	task.delay(duration or 3.5, function()
		if toast.Parent then
			Utils.Tween(toast, {Position = UDim2.new(0.5, 0, 0, -80), BackgroundTransparency = 1}, Configuration.Animations.Medium)
			for i, t in ipairs(ToastSystem.ActiveToasts) do
				if t == toast then table.remove(ToastSystem.ActiveToasts, i) break end
			end
			task.wait(Configuration.Animations.Medium)
			toast:Destroy()
			ToastSystem.RepositionToasts()
		end
	end)

	return toast
end

ToastSystem.RepositionToasts = function()
	for i, toast in ipairs(ToastSystem.ActiveToasts) do
		local targetY = 20 + ((i - 1) * (60 + ToastSystem.ToastSpacing))
		Utils.Tween(toast, {Position = UDim2.new(0.5, 0, 0, targetY)}, Configuration.Animations.Medium)
	end
end

local function Build()
	local parent = game:GetService("CoreGui")
	local old = parent:FindFirstChild(Configuration.ScreenGuiName)
	if old then old:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = Configuration.ScreenGuiName
	screen.ResetOnSpawn = false
	screen.Parent = parent

	SetBlur(true)

	local introLogo = Instance.new("ImageLabel")
	introLogo.Size = UDim2.new(0, 5, 0, 5)
	introLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
	introLogo.AnchorPoint = Vector2.new(0.5, 0.5)
	introLogo.BackgroundTransparency = 1
	introLogo.Image = Icons.ReaperIcon
	introLogo.ScaleType = Enum.ScaleType.Fit
	introLogo.ZIndex = 100
	introLogo.Parent = screen

	task.wait(1.0)
	Utils.Tween(introLogo, {Size = UDim2.new(0, 80, 0, 80)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.wait(2.0)
	introLogo:Destroy()

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 0, 0, 0)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = Configuration.Colors.Bg
	main.BackgroundTransparency = 0.2
	main.ClipsDescendants = true
	main.Parent = screen
	Utils.Round(main, 24)
	Utils.Stroke(main, Configuration.Colors.Border, 1, 0.85)

	Utils.Tween(main, {Size = Configuration.Window.Size}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 40)
	bar.BackgroundTransparency = 1
	bar.Parent = main

	local dots = Instance.new("Frame")
	dots.Size = UDim2.new(0, 54, 0, 12)
	dots.Position = UDim2.new(0, 20, 0.5, 0)
	dots.AnchorPoint = Vector2.new(0, 0.5)
	dots.BackgroundTransparency = 1
	dots.Parent = bar

	local dColors = { Configuration.Colors.TrafficRed, Configuration.Colors.TrafficYellow, Configuration.Colors.TrafficGreen }
	for i, c in ipairs(dColors) do
		local d = Instance.new("Frame")
		d.Size = UDim2.fromOffset(12, 12)
		d.Position = UDim2.fromOffset((i - 1) * 18, 0)
		d.BackgroundColor3 = c
		d.Parent = dots
		Utils.Round(d, 6)
	end

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 1, 0)
	titleText.Text = "REAPER HUB"
	titleText.TextColor3 = Color3.new(1, 1, 1)
	titleText.TextTransparency = 0.7
	titleText.TextSize = 10
	titleText.Font = Enum.Font.GothamBold
	titleText.BackgroundTransparency = 1
	titleText.Parent = bar

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -36, 1, -50)
	body.Position = UDim2.new(0, 18, 0, 45)
	body.BackgroundTransparency = 1
	body.Parent = main

	local leftCol = Instance.new("Frame")
	leftCol.Size = UDim2.new(0, 150, 1, 0)
	leftCol.BackgroundTransparency = 1
	leftCol.Parent = body

	local logoContainer = Instance.new("Frame")
	logoContainer.Size = UDim2.fromOffset(72, 72)
	logoContainer.Position = UDim2.new(0.5, -36, 0, 10)
	logoContainer.BackgroundTransparency = 1
	logoContainer.BorderSizePixel = 0
	logoContainer.Parent = leftCol

	local sIcon = Instance.new("ImageLabel")
	sIcon.Size = UDim2.fromScale(1, 1)
	sIcon.Position = UDim2.fromScale(0.5, 0.5)
	sIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	sIcon.Image = Icons.ReaperIcon
	sIcon.ScaleType = Enum.ScaleType.Fit
	sIcon.BackgroundTransparency = 1
	sIcon.Parent = logoContainer

	local mainTitle = Instance.new("TextLabel")
	mainTitle.Size = UDim2.new(1, 0, 0, 22)
	mainTitle.Position = UDim2.new(0, 0, 0, 90)
	mainTitle.Text = "REAPER HUB"
	mainTitle.TextColor3 = Color3.new(1, 1, 1)
	mainTitle.TextSize = 18
	mainTitle.Font = Enum.Font.GothamBold
	mainTitle.TextXAlignment = Enum.TextXAlignment.Center
	mainTitle.BackgroundTransparency = 1
	mainTitle.Parent = leftCol

	local subTitle = Instance.new("TextLabel")
	subTitle.Size = UDim2.new(1, 0, 0, 14)
	subTitle.Position = UDim2.new(0, 0, 0, 114)
	subTitle.Text = "Key System"
	subTitle.TextColor3 = Configuration.Colors.TextSec
	subTitle.TextSize = 12
	subTitle.Font = Enum.Font.Gotham
	subTitle.TextXAlignment = Enum.TextXAlignment.Center
	subTitle.BackgroundTransparency = 1
	subTitle.Parent = leftCol

	local rightCol = Instance.new("Frame")
	rightCol.Size = UDim2.new(1, -165, 1, 0)
	rightCol.Position = UDim2.new(0, 165, 0, 0)
	rightCol.BackgroundTransparency = 1
	rightCol.Parent = body

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLayout.Parent = rightCol

	local statusCard = Instance.new("Frame")
	statusCard.Size = UDim2.new(1, 0, 0, 48)
	statusCard.BackgroundColor3 = Color3.new(1, 1, 1)
	statusCard.BackgroundTransparency = 0.96
	statusCard.Parent = rightCol
	Utils.Round(statusCard, 12)
	Utils.Stroke(statusCard, Color3.new(1, 1, 1), 1, 0.95)

	local sIconBg = Instance.new("Frame")
	sIconBg.Size = UDim2.fromOffset(32, 32)
	sIconBg.Position = UDim2.new(0, 10, 0.5, 0)
	sIconBg.AnchorPoint = Vector2.new(0, 0.5)
	sIconBg.BackgroundColor3 = Configuration.Colors.StatusIdle
	sIconBg.BackgroundTransparency = 0.9
	sIconBg.Parent = statusCard
	Utils.Round(sIconBg, 16)

	local sImg = Instance.new("ImageLabel")
	sImg.Size = UDim2.fromScale(0.5, 0.5)
	sImg.Position = UDim2.fromScale(0.5, 0.5)
	sImg.AnchorPoint = Vector2.new(0.5, 0.5)
	sImg.Image = Icons.Lock
	sImg.ImageColor3 = Configuration.Colors.StatusIdle
	sImg.BackgroundTransparency = 1
	sImg.Parent = sIconBg

	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(1, -50, 0, 12)
	sLabel.Position = UDim2.fromOffset(50, 8)
	sLabel.Text = "CURRENT STATUS"
	sLabel.TextColor3 = Configuration.Colors.TextMuted
	sLabel.TextSize = 9
	sLabel.Font = Enum.Font.GothamBold
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.BackgroundTransparency = 1
	sLabel.Parent = statusCard

	local sValue = Instance.new("TextLabel")
	sValue.Size = UDim2.new(1, -50, 0, 18)
	sValue.Position = UDim2.fromOffset(50, 21)
	sValue.Text = "No key detected"
	sValue.TextColor3 = Configuration.Colors.StatusIdle
	sValue.TextSize = 13
	sValue.Font = Enum.Font.GothamMedium
	sValue.TextXAlignment = Enum.TextXAlignment.Left
	sValue.BackgroundTransparency = 1
	sValue.Parent = statusCard

	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, 0, 0, 44)
	inputFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	inputFrame.BackgroundTransparency = 0.975
	inputFrame.Parent = rightCol
	Utils.Round(inputFrame, 12)
	local iStroke = Utils.Stroke(inputFrame, Color3.new(1, 1, 1), 1, 0.95)

	local kIcon = Instance.new("ImageLabel")
	kIcon.Size = UDim2.fromOffset(16, 16)
	kIcon.Position = UDim2.new(0, 12, 0.5, 0)
	kIcon.AnchorPoint = Vector2.new(0, 0.5)
	kIcon.Image = Icons.Key
	kIcon.ImageColor3 = Configuration.Colors.TextMuted
	kIcon.BackgroundTransparency = 1
	kIcon.Parent = inputFrame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -68, 1, 0)
	box.Position = UDim2.fromOffset(38, 0)
	box.Text = ""
	box.PlaceholderText = "Enter your key..."
	box.TextColor3 = Color3.new(1, 1, 1)
	box.TextSize = 13
	box.Font = Enum.Font.Gotham
	box.BackgroundTransparency = 1
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = inputFrame

	local paste = Instance.new("ImageButton")
	paste.Size = UDim2.fromOffset(16, 16)
	paste.Position = UDim2.new(1, -12, 0.5, 0)
	paste.AnchorPoint = Vector2.new(1, 0.5)
	paste.Image = Icons.Copy
	paste.ImageColor3 = Configuration.Colors.TextMuted
	paste.BackgroundTransparency = 1
	paste.Parent = inputFrame

	local btnRow = Instance.new("Frame")
	btnRow.Size = UDim2.new(1, 0, 0, 42)
	btnRow.BackgroundTransparency = 1
	btnRow.Parent = rightCol

	local getKey = Instance.new("TextButton")
	getKey.Size = UDim2.new(0.5, -4, 1, 0)
	getKey.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	getKey.Text = "Buy Key"
	getKey.TextColor3 = Color3.new(1, 1, 1)
	getKey.Font = Enum.Font.GothamBold
	getKey.TextSize = 13
	getKey.AutoButtonColor = false
	getKey.Parent = btnRow
	Utils.Round(getKey, 12)
	Utils.Stroke(getKey, Color3.new(1, 1, 1), 1, 0.94)

	local verifyBtn = Instance.new("TextButton")
	verifyBtn.Size = UDim2.new(0.5, -4, 1, 0)
	verifyBtn.Position = UDim2.new(0.5, 4, 0, 0)
	verifyBtn.BackgroundColor3 = Configuration.Colors.Primary
	verifyBtn.Text = "Verify"
	verifyBtn.TextColor3 = Color3.new(1, 1, 1)
	verifyBtn.Font = Enum.Font.GothamBold
	verifyBtn.TextSize = 13
	verifyBtn.AutoButtonColor = false
	verifyBtn.Parent = btnRow
	Utils.Round(verifyBtn, 12)

	local function ApplyHover(btn)
		local baseColor = btn.BackgroundColor3
		btn.MouseEnter:Connect(function()
			Utils.Tween(btn, {BackgroundColor3 = baseColor:Lerp(Color3.new(1, 1, 1), 0.1)}, 0.2)
		end)
		btn.MouseLeave:Connect(function()
			Utils.Tween(btn, {BackgroundColor3 = baseColor}, 0.2)
		end)
	end
	ApplyHover(verifyBtn)
	ApplyHover(getKey)

	local spinConnection
	local dotsThread

	local function SetStatus(state)
		if spinConnection then spinConnection:Disconnect() spinConnection = nil sImg.Rotation = 0 end
		if dotsThread then task.cancel(dotsThread) dotsThread = nil end

		local color = Configuration.Colors.StatusIdle
		local icon = Icons.Lock
		local text = "No key detected"

		if state == "verifying" then
			color = Configuration.Colors.StatusVerifying
			icon = Icons.Key
			text = "Verifying access"
			spinConnection = RunService.Heartbeat:Connect(function(dt)
				if sImg and sImg.Parent then
					sImg.Rotation = (sImg.Rotation + dt * 360) % 360
				end
			end)
			local dots = {".", "..", "...", ""}
			local i = 1
			dotsThread = task.spawn(function()
				while sValue and sValue.Parent do
					if not sValue.Text:find("Verifying access", 1, true) then break end
					sValue.Text = text .. dots[i]
					i = (i % #dots) + 1
					task.wait(0.45)
				end
			end)
		elseif state == "success" then
			color = Configuration.Colors.StatusSuccess
			icon = Icons.CheckCircle
			text = "Access Granted"
		elseif state == "error" then
			color = Configuration.Colors.StatusError
			icon = Icons.XCircle
			text = "Invalid Key"
		end

		Utils.Tween(sValue, {TextColor3 = color}, 0.35)
		Utils.Tween(sImg, {ImageColor3 = color}, 0.35)
		Utils.Tween(sIconBg, {BackgroundColor3 = color}, 0.35)
		sValue.Text = text
		sImg.Image = icon
	end

	local function PlayCloseAnimation(onComplete)
		for _, child in ipairs(main:GetChildren()) do
			if child:IsA("GuiObject") then
				Utils.Tween(child, {BackgroundTransparency = 1}, 0.2)
				for _, sub in ipairs(child:GetDescendants()) do
					if sub:IsA("TextLabel") or sub:IsA("TextBox") or sub:IsA("ImageLabel") then
						pcall(function() Utils.Tween(sub, {TextTransparency = 1, ImageTransparency = 1}, 0.2) end)
					end
				end
			end
		end

		Utils.Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.4)
		main.Visible = false

		local outLogo = Instance.new("ImageLabel")
		outLogo.Size = UDim2.new(0, 80, 0, 80)
		outLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
		outLogo.AnchorPoint = Vector2.new(0.5, 0.5)
		outLogo.BackgroundTransparency = 1
		outLogo.Image = Icons.ReaperIcon
		outLogo.ScaleType = Enum.ScaleType.Fit
		outLogo.ZIndex = 200
		outLogo.Parent = screen

		SetBlur(false)

		Utils.Tween(outLogo, {Size = UDim2.new(0, 0, 0, 0), ImageTransparency = 1}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.4)

		if onComplete then onComplete() end
	end

	verifyBtn.MouseButton1Click:Connect(function()
		local userKey = box.Text:gsub("%s+", "")
		SetStatus("verifying")
		verifyBtn.Text = "..."
		verifyBtn.Active = false

		local result = API.check_key(userKey)

		verifyBtn.Active = true
		verifyBtn.Text = "Verify"

		if result and result.valid then
			saveVerifiedKey(userKey)
			getgenv().SCRIPT_KEY = userKey

			SetStatus("success")
			ToastSystem.Create(screen, "Access granted!", "success")
			task.wait(0.8)

			PlayCloseAnimation(function()
				screen:Destroy()
				RunMainScript()
			end)
		else
			SetStatus("error")
			ToastSystem.Create(screen, result and result.message or "Invalid Key", "error")
		end
	end)

	getKey.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(API.get_key_link())
			ToastSystem.Create(screen, "Key link copied to clipboard!", "success")
		else
			ToastSystem.Create(screen, "setclipboard not supported!", "error")
		end
	end)

	paste.MouseButton1Click:Connect(function()
		local clipText = getclipboard and getclipboard() or nil
		if clipText and clipText ~= "" then
			box.Text = clipText
			ToastSystem.Create(screen, "Key pasted from clipboard!", "info")
		else
			ToastSystem.Create(screen, "Clipboard is empty or not supported", "warning")
		end
	end)

	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragging = false
		end
	end)

	return screen
end

local savedKey = loadVerifiedKey()
local keyToCheck = savedKey or getgenv().SCRIPT_KEY

if keyToCheck then
    local result = API.check_key(keyToCheck)
    if result and result.valid then
        getgenv().SCRIPT_KEY = keyToCheck
        RunMainScript()
        return
    end
end

Build()
