--[[
    通知系統模組 (NotificationModule)
    功能：創建美觀的通知彈窗，支援多種類型和防刷屏機制
    
    使用方法：
    local NotificationModule = require(script.NotificationModule)
    
    -- 基本使用
    NotificationModule:Show("Hello World!", "success", 3)
    
    -- 便捷方法
    NotificationModule:Success("操作完成！")
    NotificationModule:Error("發生錯誤")
    NotificationModule:Warning("注意事項")
    NotificationModule:Info("資訊通知")
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local NotificationModule = {}
NotificationModule.__index = NotificationModule

-- 私有變數
local notifications = {}
local callHistory = {}
local blockedUntil = {}

-- 配置設定
local CONFIG = {
    maxNotifications = 5,
    notificationHeight = 70,
    notificationSpacing = 10,
    basePosition = UDim2.new(1, -330, 1, -90),
    maxCallsInWindow = 15,     -- 5秒內最多15次
    timeWindow = 5,           -- 時間窗口：5秒
    blockDuration = 10,       -- 阻擋時間：10秒
    containerName = "NotificationContainer",
    displayOrder = 10
}

-- 通知類型配置
local NOTIFICATION_TYPES = {
    success = {
        icon = "✅",
        colors = {
            background = Color3.fromRGB(46, 125, 50),
            accent = Color3.fromRGB(76, 175, 80),
            glow = Color3.fromRGB(129, 199, 132)
        }
    },
    error = {
        icon = "❌",
        colors = {
            background = Color3.fromRGB(183, 28, 28),
            accent = Color3.fromRGB(244, 67, 54),
            glow = Color3.fromRGB(239, 154, 154)
        }
    },
    warning = {
        icon = "⚠️",
        colors = {
            background = Color3.fromRGB(245, 124, 0),
            accent = Color3.fromRGB(255, 152, 0),
            glow = Color3.fromRGB(255, 204, 128)
        }
    },
    info = {
        icon = "ℹ️",
        colors = {
            background = Color3.fromRGB(25, 118, 210),
            accent = Color3.fromRGB(33, 150, 243),
            glow = Color3.fromRGB(144, 202, 249)
        }
    },
    default = {
        icon = "🔔",
        colors = {
            background = Color3.fromRGB(69, 90, 100),
            accent = Color3.fromRGB(96, 125, 139),
            glow = Color3.fromRGB(176, 190, 197)
        }
    }
}

-- 動畫配置
local ANIMATION_CONFIG = {
    slideIn = {
        time = 0.4,
        style = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    slideOut = {
        time = 0.3,
        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    hover = {
        time = 0.2,
        style = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    iconGrow = {
        time = 0.3,
        style = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    reposition = {
        time = 0.3,
        style = Enum.EasingStyle.Quart,
        direction = Enum.EasingDirection.Out
    }
}

-- 私有方法：創建通知容器
local function createNotificationContainer()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local existingContainer = playerGui:FindFirstChild(CONFIG.containerName)
    if existingContainer then
        return existingContainer
    end
    
    local container = Instance.new("ScreenGui")
    container.Name = CONFIG.containerName
    container.ResetOnSpawn = false
    container.DisplayOrder = CONFIG.displayOrder
    container.Parent = playerGui
    
    return container
end

-- 私有方法：更新所有通知位置
local function updateNotificationPositions()
    for i, notification in ipairs(notifications) do
        if notification and notification.Parent then
            local targetY = CONFIG.basePosition.Y.Offset - ((i - 1) * (CONFIG.notificationHeight + CONFIG.notificationSpacing))
            local targetPosition = UDim2.new(1, -330, 1, targetY)
            
            local moveTween = TweenService:Create(
                notification,
                TweenInfo.new(
                    ANIMATION_CONFIG.reposition.time,
                    ANIMATION_CONFIG.reposition.style,
                    ANIMATION_CONFIG.reposition.direction
                ),
                {Position = targetPosition}
            )
            moveTween:Play()
        end
    end
end

-- 私有方法：移除通知
local function removeNotification(notification)
    for i, notif in ipairs(notifications) do
        if notif == notification then
            table.remove(notifications, i)
            break
        end
    end
    updateNotificationPositions()
end

-- 私有方法：獲取通知類型數據
local function getNotificationData(notificationType)
    return NOTIFICATION_TYPES[notificationType] or NOTIFICATION_TYPES.default
end

-- 私有方法：防刷屏檢查
local function shouldBlockNotification(message)
    local currentTime = tick()
    local messageKey = tostring(message):lower()
    
    -- 檢查是否還在阻擋期間
    if blockedUntil[messageKey] then
        if currentTime < blockedUntil[messageKey] then
            return true, "blocked"
        else
            blockedUntil[messageKey] = nil
            callHistory[messageKey] = nil
        end
    end
    
    -- 初始化該訊息的調用歷史
    if not callHistory[messageKey] then
        callHistory[messageKey] = {}
    end
    
    local history = callHistory[messageKey]
    
    -- 清理過期的調用記錄
    for i = #history, 1, -1 do
        if currentTime - history[i] > CONFIG.timeWindow then
            table.remove(history, i)
        end
    end
    
    -- 檢查調用頻率
    if #history >= CONFIG.maxCallsInWindow then
        blockedUntil[messageKey] = currentTime + CONFIG.blockDuration
        callHistory[messageKey] = nil
        
        -- 顯示警告通知（避免遞歸）
        task.spawn(function()
            task.wait(0.1)
            NotificationModule:Show("🚫 通知頻率過高，已暫時阻擋重複訊息", "warning", 3)
        end)
        
        return true, "rate_limited"
    end
    
    -- 記錄本次調用
    table.insert(history, currentTime)
    return false, "allowed"
end

-- 私有方法：創建通知UI
local function createNotificationUI(message, notificationData, duration)
    local container = createNotificationContainer()
    local colors = notificationData.colors
    local icon = notificationData.icon
    
    -- 創建通知框架
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 320, 0, CONFIG.notificationHeight)
    notification.Position = UDim2.new(1, 50, 1, CONFIG.basePosition.Y.Offset)
    notification.BackgroundColor3 = colors.background
    notification.BorderSizePixel = 0
    notification.ClipsDescendants = true
    notification.Parent = container
    
    -- 添加圓角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    -- 添加邊框光暈
    local stroke = Instance.new("UIStroke")
    stroke.Color = colors.accent
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = notification
    
    -- 左側強調條
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = colors.accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = notification
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 12)
    accentCorner.Parent = accentBar
    
    -- 圖標
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 16, 0, 16)
    iconLabel.Position = UDim2.new(0, 15, 0, 27)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = notification
    
    -- 文字標籤
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, -10)
    label.Position = UDim2.new(0, 50, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = notification
    
    -- 關閉按鈕
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -30, 0, 10)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notification
    
    -- 進度條
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 3)
    progressBar.Position = UDim2.new(0, 0, 1, -3)
    progressBar.BackgroundColor3 = colors.accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notification
    
    return notification, iconLabel, progressBar, closeButton
end

-- 私有方法：設置通知動畫和互動
local function setupNotificationBehavior(notification, iconLabel, progressBar, closeButton, duration)
    -- 添加到通知列表
    table.insert(notifications, notification)
    updateNotificationPositions()
    
    -- 入場動畫
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(
            ANIMATION_CONFIG.slideIn.time,
            ANIMATION_CONFIG.slideIn.style,
            ANIMATION_CONFIG.slideIn.direction
        ),
        {Position = UDim2.new(1, -330, notification.Position.Y.Scale, notification.Position.Y.Offset)}
    )
    slideIn:Play()
    
    -- 圖標生長動畫
    local iconGrow = TweenService:Create(
        iconLabel,
        TweenInfo.new(
            ANIMATION_CONFIG.iconGrow.time,
            ANIMATION_CONFIG.iconGrow.style,
            ANIMATION_CONFIG.iconGrow.direction
        ),
        {Size = UDim2.new(0, 24, 0, 24)}
    )
    task.wait(0.2)
    iconGrow:Play()
    
    -- 進度條動畫
    local progressTween = TweenService:Create(
        progressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 3)}
    )
    progressTween:Play()
    
    -- 懸停效果
    local hoverTweenIn, hoverTweenOut
    
    notification.MouseEnter:Connect(function()
        if hoverTweenOut then hoverTweenOut:Cancel() end
        hoverTweenIn = TweenService:Create(
            notification,
            TweenInfo.new(
                ANIMATION_CONFIG.hover.time,
                ANIMATION_CONFIG.hover.style,
                ANIMATION_CONFIG.hover.direction
            ),
            {Position = UDim2.new(1, -340, notification.Position.Y.Scale, notification.Position.Y.Offset)}
        )
        hoverTweenIn:Play()
        progressTween:Pause()
    end)
    
    notification.MouseLeave:Connect(function()
        if hoverTweenIn then hoverTweenIn:Cancel() end
        hoverTweenOut = TweenService:Create(
            notification,
            TweenInfo.new(
                ANIMATION_CONFIG.hover.time,
                ANIMATION_CONFIG.hover.style,
                ANIMATION_CONFIG.hover.direction
            ),
            {Position = UDim2.new(1, -330, notification.Position.Y.Scale, notification.Position.Y.Offset)}
        )
        hoverTweenOut:Play()
        progressTween:Resume()
    end)
    
    -- 關閉功能
    local function closeNotification()
        removeNotification(notification)
        local slideOut = TweenService:Create(
            notification,
            TweenInfo.new(
                ANIMATION_CONFIG.slideOut.time,
                ANIMATION_CONFIG.slideOut.style,
                ANIMATION_CONFIG.slideOut.direction
            ),
            {
                Position = UDim2.new(1, 50, notification.Position.Y.Scale, notification.Position.Y.Offset),
                BackgroundTransparency = 1
            }
        )
        slideOut:Play()
        slideOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end
    
    closeButton.MouseButton1Click:Connect(closeNotification)
    progressTween.Completed:Connect(closeNotification)
    
    -- 點擊通知關閉
    notification.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeNotification()
        end
    end)
    
    return notification
end

-- 公開方法：顯示通知
function NotificationModule:Show(message, notificationType, duration)
    notificationType = notificationType or "default"
    duration = duration or 3
    
    -- 防刷屏檢查
    local shouldBlock, reason = shouldBlockNotification(message)
    if shouldBlock then
        if reason == "rate_limited" then
            warn("⚠️ 通知被阻擋：" .. message .. " (頻率過高)")
        elseif reason == "blocked" then
            warn("🚫 通知被阻擋：" .. message .. " (仍在阻擋期間)")
        end
        return false
    end
    
    local notificationData = getNotificationData(notificationType)
    
    -- 如果超過最大通知數量，移除最舊的
    if #notifications >= CONFIG.maxNotifications then
        local oldestNotification = notifications[1]
        if oldestNotification and oldestNotification.Parent then
            local fadeOut = TweenService:Create(
                oldestNotification,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(1, 50, oldestNotification.Position.Y.Scale, oldestNotification.Position.Y.Offset),
                    BackgroundTransparency = 1
                }
            )
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                oldestNotification:Destroy()
            end)
            removeNotification(oldestNotification)
        end
    end
    
    local notification, iconLabel, progressBar, closeButton = createNotificationUI(message, notificationData, duration)
    setupNotificationBehavior(notification, iconLabel, progressBar, closeButton, duration)
    
    return true
end

-- 便捷方法
function NotificationModule:Success(message, duration)
    return self:Show(message, "success", duration)
end

function NotificationModule:Error(message, duration)
    return self:Show(message, "error", duration)
end

function NotificationModule:Warning(message, duration)
    return self:Show(message, "warning", duration)
end

function NotificationModule:Info(message, duration)
    return self:Show(message, "info", duration)
end

-- 清除所有通知
function NotificationModule:ClearAll()
    for _, notification in ipairs(notifications) do
        if notification and notification.Parent then
            notification:Destroy()
        end
    end
    notifications = {}
end

-- 重置防刷屏系統
function NotificationModule:ResetFilters()
    callHistory = {}
    blockedUntil = {}
    print("🔄 通知過濾器已重置")
end

-- 檢查訊息狀態
function NotificationModule:GetNotificationStatus(message)
    local messageKey = tostring(message):lower()
    local currentTime = tick()
    
    if blockedUntil[messageKey] then
        if currentTime < blockedUntil[messageKey] then
            local remainingTime = math.ceil(blockedUntil[messageKey] - currentTime)
            return "blocked", remainingTime
        end
    end
    
    local history = callHistory[messageKey] or {}
    local recentCalls = 0
    for _, callTime in ipairs(history) do
        if currentTime - callTime <= CONFIG.timeWindow then
            recentCalls = recentCalls + 1
        end
    end
    
    return "active", {
        recentCalls = recentCalls,
        maxCalls = CONFIG.maxCallsInWindow,
        remainingCalls = CONFIG.maxCallsInWindow - recentCalls
    }
end

-- 設定配置
function NotificationModule:SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
end

-- 獲取配置
function NotificationModule:GetConfig()
    return CONFIG
end

return NotificationModule

--[[
===== 完整使用範例 =====

-- 1. 基本使用方式
local NotificationModule = require(script.NotificationModule)

-- 最簡單的通知
NotificationModule:Show("這是一個基本通知")

-- 指定類型和時間
NotificationModule:Show("操作成功完成！", "success", 5)
NotificationModule:Show("發生嚴重錯誤", "error", 10)
NotificationModule:Show("請注意系統維護時間", "warning", 7)
NotificationModule:Show("系統更新資訊", "info", 4)

-- 2. 便捷方法使用
NotificationModule:Success("✨ 檔案儲存成功！")
NotificationModule:Success("🎉 任務完成，獲得 100 經驗值！", 5)

NotificationModule:Error("💥 網路連線失敗，請檢查設定")
NotificationModule:Error("❗ 權限不足，無法執行此操作", 8)

NotificationModule:Warning("⚡ 電量低於 20%，請及時充電")
NotificationModule:Warning("🔥 CPU 溫度過高，建議降低畫質", 6)

NotificationModule:Info("📢 有新版本可用，點擊更新")
NotificationModule:Info("🔔 您有 3 條未讀訊息", 4)

-- 壓力測試（測試防刷屏機制）
local function stressTest()
    print("開始壓力測試...")
    for i = 1, 10 do
        local success = NotificationModule:Success("壓力測試訊息 #" .. i)
        print("第", i, "次調用:", success and "成功" or "被阻擋")
        task.wait(0.1)
    end
    
    task.wait(5)
    print("🔄 5秒後重試...")
    
    for i = 1, 3 do
        local success = NotificationModule:Success("重試訊息 #" .. i)
        print("重試", i, "次:", success and "成功" or "被阻擋")
        task.wait(0.1)
    end
end

-- 錯誤處理和容錯機制

-- 安全的通知發送（包含錯誤處理）
local function safeNotify(message, notificationType, duration)
    local success, result = pcall(function()
        return NotificationModule:Show(message, notificationType, duration)
    end)
    
    if not success then
        warn("通知發送失敗:", result)
        return false
    end
    
    return result
end

-- 重試機制
local function retryNotification(message, notificationType, duration, maxRetries)
    maxRetries = maxRetries or 3
    
    for attempt = 1, maxRetries do
        if safeNotify(message, notificationType, duration) then
            return true
        end
        
        print("通知發送失敗，重試", attempt, "/", maxRetries)
        task.wait(0.5 * attempt) -- 遞增等待時間
    end
    
    warn("通知發送失敗，已達最大重試次數")
    return false
end

-- 清理和重置功能

-- 遊戲結束時清理
game:BindToClose(function()
    NotificationModule:ClearAll()
    print("通知系統已清理")
end)

-- 場景切換時重置
local function onSceneChange()
    NotificationModule:ClearAll()
    NotificationModule:ResetFilters()
    NotificationModule:Info("🔄 場景載入完成")
end

-- 定期清理（可選）
task.spawn(function()
    while true do
        task.wait(300) -- 每5分鐘
        NotificationModule:ResetFilters() -- 重置過濾器
        print("🔄 通知過濾器已定期重置")
    end
end)
]]