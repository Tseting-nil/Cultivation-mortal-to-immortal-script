--[[
    BlackMarketEquipTooltip.lua
    黑市裝備詞條 Tooltip

    UI 結構：
      腳本載入時、為每張卡片在 活动商品N.按钮 之下預建立 Tooltip Frame
      Tooltip 用 UDim2 相對父層定位（卡片正上方）、不需手動算座標

    互動：
      開關按鈕「顯示裝備屬性」（位於 背景.提示 內、原 i 按鈕右側）：
      toggle 所有裝備 Tooltip 顯示/隱藏

    UI 路徑：
      卡片：背景.列表.活动商品N.按钮
      開關掛點：背景.提示

    資料對應：var21_upvw["商品列表"][N]
]]

-- ==================== 服務 ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==================== UI 路徑 ====================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local mainGui = PlayerGui:WaitForChild("GUI")
local secondLayer = mainGui:WaitForChild("二级界面")
local blackMarketUi = secondLayer:WaitForChild("黑市商人")
local background = blackMarketUi:WaitForChild("背景")
local productList = background:WaitForChild("列表")
local promptFrame = background:WaitForChild("提示")

-- ── i18n ──────────────────────────────────────────────
local _lang = "zh"
do
	local ok, raw = pcall(readfile, "Tsetingnil_script/keysystem.json")
	if ok and raw and raw ~= "" then
		local hs = game:GetService("HttpService")
		local ok2, cfg = pcall(function() return hs:JSONDecode(raw) end)
		if ok2 and type(cfg) == "table" and cfg.script_language then
			if cfg.script_language ~= "Chinese" then
				_lang = "en"
			end
		end
	end
end

local _i18n = {
	zh = {
		qualityLabel = {
			[1]="普通", [2]="優秀", [3]="精良", [4]="稀有",  [5]="完美",
			[6]="珍稀", [7]="史詩", [8]="傳奇", [9]="不朽",  [10]="神話",
			[11]="永恆", [12]="神祇", [13]="太初",
		},
		equipSuffix = "裝備",
		toggleOff   = "顯示裝備屬性：關",
		toggleOn    = "顯示裝備屬性：開",
		["生命值"] = "生命值",
		["生命恢复"] = "生命恢复",
		["攻击力"] = "攻擊力",
		["暴击概率"] = "暴擊概率",
		["暴击伤害"] = "暴擊傷害",
		["攻击速度"] = "攻擊速度",
		["闪避概率"] = "閃避概率",
		["忽视闪避概率"] = "忽視閃避概率",
		["首领减伤"] = "首領減傷",
		["首领伤害"] = "首領傷害",
		["反弹伤害"] = "反彈傷害",
		["反弹伤害概率"] = "反彈傷害概率",
		["法宝伤害"] = "法寶傷害",
		["技能伤害"] = "技能傷害",
	},
	en = {
		qualityLabel = {
			[1]="Common",    [2]="Good",      [3]="Sturdy",      [4]="Rare",     [5]="Perfect",
			[6]="Scarce",    [7]="Epic",      [8]="Legendary",   [9]="Immortal", [10]="Myth",
			[11]="Eternal",  [12]="Celestial",[13]="Primordial",
		},
		equipSuffix = " Equipment",
		toggleOff   = "Show Equip Info: OFF",
		toggleOn    = "Show Equip Info: ON",
		["生命值"] = "HP",
		["生命恢复"] = "HP Recovery",
		["攻击力"] = "Attack",
		["暴击概率"] = "Critical Hit Rate",
		["暴击伤害"] = "Critical Hit Damage",
		["攻击速度"] = "Attack Speed",
		["闪避概率"] = "Dodge Chance",
		["忽视闪避概率"] = "Ignore Dodge Chance",
		["首领减伤"] = "Boss Damage Reduction",
		["首领伤害"] = "Boss Damage",
		["反弹伤害"] = "Thorns Damage",
		["反弹伤害概率"] = "Thorns Damage Chance",
		["法宝伤害"] = "Talisman Damage",
		["技能伤害"] = "Skill Damage",
	},
}
local _t = _i18n[_lang]

-- ==================== 引用管理器 ====================
local refModule = require(ReplicatedStorage:WaitForChild("脚本模块"):WaitForChild("公用"):WaitForChild("引用管理器"))

local syncBlackMarketDataEvent = refModule["获取事件引用"]("黑市商人", "同步数据")
local openBlackMarketEvent     = refModule["获取事件引用"]("客户端UI", "打开黑市商店")

-- 屬性計算與常量模組
local equipAttrCalc = require(ReplicatedStorage:WaitForChild("脚本模块"):WaitForChild("公用"):WaitForChild("工具"):WaitForChild("装备属性计算工具"))
local constantMod   = require(ReplicatedStorage:WaitForChild("脚本模块"):WaitForChild("公用"):WaitForChild("数学"):WaitForChild("常量"))

-- ==================== 常數 ====================
local DEBUG = false                         -- ★ Debug 開關：true = 顯示原始係數（除錯用），false = 顯示實際數值（正式）
local TOOLTIP_NAME = "_EquipTooltip"        -- 內嵌在 按钮 下的 Tooltip Frame Name
local TOGGLE_BTN_NAME = "_EquipInfoToggle"  -- 開關按鈕 Name

-- 品質 → 邊框/標題顏色（依遊戲實際配色，13 階）
local QUALITY_COLOR = {
    [1]  = Color3.fromRGB(225, 220, 200), -- 普通  米白
    [2]  = Color3.fromRGB(170, 220, 110), -- 優秀  黃綠
    [3]  = Color3.fromRGB(110, 230, 230), -- 精良  青
    [4]  = Color3.fromRGB(80, 210, 80),   -- 稀有  鮮綠
    [5]  = Color3.fromRGB(70, 160, 220),  -- 完美  藍
    [6]  = Color3.fromRGB(220, 180, 230), -- 珍稀  淡紫
    [7]  = Color3.fromRGB(240, 150, 70),  -- 史詩  橙
    [8]  = Color3.fromRGB(180, 130, 230), -- 傳奇  紫
    [9]  = Color3.fromRGB(240, 130, 200), -- 不朽  粉紅
    [10] = Color3.fromRGB(240, 110, 90),  -- 神話  橙紅
    [11] = Color3.fromRGB(245, 230, 100), -- 永恆  黃
    [12] = Color3.fromRGB(220, 70, 70),   -- 神祇  紅
    [13] = Color3.fromRGB(80, 200, 160),  -- 太初  翡翠青綠
}


-- ==================== 狀態 ====================
local currentProductList = nil  -- 當前 商品列表 引用
local toggleEnabled = false     -- 開關狀態

-- ==================== 工具函數 ====================

local function isAdaptiveEquip(slot)
    if type(slot) ~= "table" then return false end
    if type(slot["装备数据"]) ~= "table" then return false end
    return true
end

local function getEquipAttrs(equipData)
    local attrs = rawget(equipData, "属性")
    if type(attrs) == "table" then return attrs end
    attrs = rawget(equipData, 5)
    if type(attrs) == "table" then return attrs end
    return nil
end

local function getEquipQuality(equipData)
    local q = rawget(equipData, "品质")
    if type(q) == "number" then return q end
    q = rawget(equipData, 6)
    if type(q) == "number" then return q end
    return 1
end

local function getEquipLevel(equipData)
    local lv = rawget(equipData, "等级")
    if type(lv) == "number" then return lv end
    lv = rawget(equipData, 2)
    if type(lv) == "number" then return lv end
    return 1
end

local function parseAttrEntry(entry)
    if type(entry) ~= "table" then return nil end
    local name = rawget(entry, "名称") or rawget(entry, 2)
    local value = rawget(entry, "系数") or rawget(entry, 1)
    if type(name) ~= "string" or type(value) ~= "number" then return nil end
    return name, value
end

local function formatCoef(value)
    local txt = string.format("%.4f", value)
    txt = txt:gsub("0+$", ""):gsub("%.$", "")
    return txt
end

local function getSlot(slotIndex)
    if not currentProductList then return nil end
    return currentProductList[slotIndex]
end

-- ==================== Tooltip Frame 建立（預建立、內嵌在 按钮 之下） ====================

-- 建立或取得卡片 button 之下的 Tooltip Frame
local function ensureTooltipFrame(cardFrame)
    local btn = cardFrame:FindFirstChild("按钮")
    if not btn then return nil end

    local frame = btn:FindFirstChild(TOOLTIP_NAME)
    if frame then return frame end

    frame = Instance.new("Frame")
    frame.Name = TOOLTIP_NAME
    -- 相對父層定位：水平置中、Y=0.6 落在卡片中央偏下（蓋在圖示上）
    frame.AnchorPoint = Vector2.new(0.5, 1)
    frame.Position = UDim2.new(0.5, 0, 0.6, -6)
    frame.Size = UDim2.new(0, 200, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 100   -- 蓋過卡片內的其他元素
    frame.ClipsDescendants = false
    frame.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "QualityStroke"
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = frame

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 2)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.Parent = frame

    -- 標題
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = ""
    titleLabel.LayoutOrder = 0
    titleLabel.ZIndex = 101
    titleLabel.Parent = frame

    -- 副標 Lv.X
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Size = UDim2.new(1, 0, 0, 12)
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextSize = 11
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    subtitleLabel.Text = ""
    subtitleLabel.LayoutOrder = 1
    subtitleLabel.ZIndex = 101
    subtitleLabel.Parent = frame

    -- 分隔線
    local sep = Instance.new("Frame")
    sep.Name = "Sep"
    sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sep.BorderSizePixel = 0
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.LayoutOrder = 2
    sep.ZIndex = 101
    sep.Parent = frame

    -- 屬性容器
    local attrContainer = Instance.new("Frame")
    attrContainer.Name = "AttrContainer"
    attrContainer.BackgroundTransparency = 1
    attrContainer.Size = UDim2.new(1, 0, 0, 0)
    attrContainer.AutomaticSize = Enum.AutomaticSize.Y
    attrContainer.LayoutOrder = 3
    attrContainer.ZIndex = 101
    attrContainer.Parent = frame

    local attrList = Instance.new("UIListLayout")
    attrList.FillDirection = Enum.FillDirection.Vertical
    attrList.SortOrder = Enum.SortOrder.LayoutOrder
    attrList.Padding = UDim.new(0, 2)
    attrList.Parent = attrContainer

    return frame
end

local function clearAttrs(frame)
    local container = frame:FindFirstChild("AttrContainer")
    if not container then return end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function addAttrRow(frame, name, valueText, layoutOrder)
    local container = frame:FindFirstChild("AttrContainer")
    if not container then return end

    local row = Instance.new("Frame")
    row.Name = "Attr_" .. name
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 14)
    row.LayoutOrder = layoutOrder
    row.ZIndex = 101
    row.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.62, 0, 1, 0)
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.ZIndex = 101
    nameLabel.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.38, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.62, 0, 0, 0)
    valueLabel.Text = tostring(valueText or "")
    valueLabel.TextColor3 = Color3.fromRGB(255, 220, 130)
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.ZIndex = 101
    valueLabel.Parent = row
end

-- 用 slot 資料填充 Tooltip 內容、回傳是否成功（false = 不是裝備）
local function fillTooltip(frame, slot)
    if not isAdaptiveEquip(slot) then return false end
    local equipData = slot["装备数据"]
    local rawAttrs = getEquipAttrs(equipData)
    if not rawAttrs then return false end

    local quality = getEquipQuality(equipData)
    local level = getEquipLevel(equipData)
    local color = QUALITY_COLOR[quality] or QUALITY_COLOR[1]
    local qualityName = _t.qualityLabel[quality] or "?"

    frame.Title.Text = qualityName .. _t.equipSuffix
    frame.Title.TextColor3 = color
    frame.Subtitle.Text = "Lv." .. tostring(level)
    frame.QualityStroke.Color = color

    clearAttrs(frame)

    if not DEBUG then
        -- 正式模式：透過遊戲內部計算工具拿實際屬性列表
        -- 回傳格式：{ {名称="攻击力", 值=157, 高于=...}, ... }
        local ok, actualAttrs = pcall(equipAttrCalc["实际属性列表"], equipData)
        if ok and type(actualAttrs) == "table" then
            for i, entry in ipairs(actualAttrs) do
                local attrName = rawget(entry, "名称")
                local attrValue = rawget(entry, "值")
                if attrName and attrValue ~= nil then
                    local displayName = attrName
                    local nameOk, nameRes = pcall(constantMod["属性对应名称"], attrName)
                    if nameOk and type(nameRes) == "string" then
                        displayName = nameRes
                    end
                    -- i18n 覆蓋：優先用腳本自帶翻譯（以原始 key 查詢）
                    if _t[attrName] then
                        displayName = _t[attrName]
                    end

                    local displayValue = tostring(attrValue)
                    local valOk, valRes = pcall(constantMod["属性值转文本"], attrName, attrValue)
                    if valOk and type(valRes) == "string" then
                        displayValue = valRes
                    end

                    addAttrRow(frame, displayName, displayValue, i)
                end
            end
            return true
        end
        -- pcall 失敗 → fallback 走原始係數
    end

    -- DEBUG 模式（或正式模式 fallback）：顯示原始係數
    for i, entry in ipairs(rawAttrs) do
        local name, value = parseAttrEntry(entry)
        if name and value then
            addAttrRow(frame, name, formatCoef(value), i)
        end
    end
    return true
end

-- ==================== 顯示控制 ====================

-- 預先在每張卡片的 按钮 下建立 Tooltip Frame（不論 slot 內容）
local function preBuildAllTooltips()
    for _, child in ipairs(productList:GetChildren()) do
        if string.match(child.Name, "^活动商品(%d+)$") then
            ensureTooltipFrame(child)
        end
    end
end

-- 為某卡片填充內容、回傳 frame（已建立但可能不可見）
local function refillCard(cardFrame, slotIndex)
    local frame = ensureTooltipFrame(cardFrame)
    if not frame then return nil end

    local slot = getSlot(slotIndex)
    if not slot then
        frame:SetAttribute("IsEquip", false)
        frame.Visible = false
        return frame
    end

    if not fillTooltip(frame, slot) then
        frame:SetAttribute("IsEquip", false)
        frame.Visible = false
        return frame
    end
    frame:SetAttribute("IsEquip", true)
    return frame
end

-- 重新填充所有卡片
local function refillAll()
    for _, child in ipairs(productList:GetChildren()) do
        local idx = tonumber(string.match(child.Name, "^活动商品(%d+)$"))
        if idx then
            refillCard(child, idx)
        end
    end
end

-- 套用某卡片的可見性（只看開關狀態）
local function applyCardVisibility(cardFrame, slotIndex)
    local btn = cardFrame:FindFirstChild("按钮")
    if not btn then return end
    local frame = btn:FindFirstChild(TOOLTIP_NAME)
    if not frame then return end

    -- 不是裝備 → 永遠不顯示
    if frame:GetAttribute("IsEquip") ~= true then
        frame.Visible = false
        return
    end

    frame.Visible = toggleEnabled
end

-- 套用所有卡片
local function applyAllVisibility()
    for _, child in ipairs(productList:GetChildren()) do
        local idx = tonumber(string.match(child.Name, "^活动商品(%d+)$"))
        if idx then
            applyCardVisibility(child, idx)
        end
    end
end

-- ==================== 開關按鈕（在 提示 內、原 i 按鈕右側） ====================

-- 配色：跟原 i 按鈕同調的米色羊皮紙
local COLOR_BG_OFF     = Color3.fromRGB(245, 233, 200) -- 米色（關閉）
local COLOR_BG_ON      = Color3.fromRGB(200, 230, 160) -- 淡綠（開啟）
local COLOR_BORDER     = Color3.fromRGB(92, 63, 30)    -- 深棕邊
local COLOR_TEXT_OFF   = Color3.fromRGB(120, 60, 60)   -- 深紅（關）
local COLOR_TEXT_ON    = Color3.fromRGB(40, 90, 30)    -- 深綠（開）

local function ensureToggleButton()
    local btn = promptFrame:FindFirstChild(TOGGLE_BTN_NAME)
    if btn then return btn end

    -- 找原本的 i 按鈕（提示框內第一個 GuiButton 子物件）取得參考尺寸
    local iButton
    for _, child in ipairs(promptFrame:GetChildren()) do
        if child:IsA("GuiButton") and child.Name ~= TOGGLE_BTN_NAME then
            iButton = child
            break
        end
    end

    -- 預設參數（萬一找不到 i 按鈕當保險）
    local btnSize = UDim2.new(0, 50, 0, 50)
    local btnPosX, btnPosXScale = 60, 0
    local btnPosY, btnPosYScale = 0, 0.5
    local btnAnchor = Vector2.new(0, 0.5)

    if iButton then
        -- 用 i 按鈕的 AbsoluteSize 當基準大小
        local refSize = iButton.AbsoluteSize
        if refSize.X > 0 and refSize.Y > 0 then
            btnSize = UDim2.new(0, refSize.X + 120 , 0, refSize.Y)
        end
        -- 計算 i 按鈕在父框內的相對位置（用於跟著它放右邊）
        local iAbsPos = iButton.AbsolutePosition
        local pAbsPos = promptFrame.AbsolutePosition
        local relX = iAbsPos.X - pAbsPos.X
        -- 放在 i 按鈕右側 8px
        btnPosX = relX + refSize.X + 8
        btnPosXScale = 0
        btnPosY = iAbsPos.Y - pAbsPos.Y
        btnPosYScale = 0
        btnAnchor = Vector2.new(0, 0)
    end

    btn = Instance.new("TextButton")
    btn.Name = TOGGLE_BTN_NAME
    btn.Size = btnSize
    btn.AnchorPoint = btnAnchor
    btn.Position = UDim2.new(btnPosXScale, btnPosX, btnPosYScale, btnPosY)
    btn.BackgroundColor3 = COLOR_BG_OFF
    btn.BorderSizePixel = 0
    btn.Text = "" -- 文字放在子 TextLabel 才能多行 + 正確置中
    btn.AutoButtonColor = true
    btn.ZIndex = 50
    btn.Parent = promptFrame

    -- 圓角配合厚邊
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    -- 深棕描邊
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = COLOR_BORDER
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = btn

    -- 子 TextLabel（兩行：上行「裝備」、下行「關 / 開」）
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -4, 1, -4)
    label.Position = UDim2.new(0, 2, 0, 2)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = COLOR_TEXT_OFF
    label.Text = _t.toggleOff
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = false
    label.ZIndex = 51
    label.Parent = btn

    btn.Activated:Connect(function()
        toggleEnabled = not toggleEnabled
        if toggleEnabled then
            btn.BackgroundColor3 = COLOR_BG_ON
            label.Text = _t.toggleOn
            label.TextColor3 = COLOR_TEXT_ON
        else
            btn.BackgroundColor3 = COLOR_BG_OFF
            label.Text = _t.toggleOff
            label.TextColor3 = COLOR_TEXT_OFF
        end
        applyAllVisibility()
    end)

    return btn
end

-- ==================== 後續新增卡片：預建 Tooltip + 填內容 ====================

productList.ChildAdded:Connect(function(child)
    local idx = tonumber(string.match(child.Name, "^活动商品(%d+)$"))
    if idx then
        task.wait(0.05)
        ensureTooltipFrame(child)
        refillCard(child, idx)
        applyCardVisibility(child, idx)
    end
end)

-- ==================== 黑市開關連動 ====================

-- 黑市介面關閉時、隱藏所有 Tooltip（但保留 toggle 狀態，下次打開恢復）
blackMarketUi:GetPropertyChangedSignal("Visible"):Connect(function()
    if not blackMarketUi.Visible then
        for _, child in ipairs(productList:GetChildren()) do
            local btn = child:FindFirstChild("按钮")
            if btn then
                local frame = btn:FindFirstChild(TOOLTIP_NAME)
                if frame then frame.Visible = false end
            end
        end
    else
        applyAllVisibility() -- 重新打開時恢復
    end
end)

-- ==================== 資料同步 ====================

syncBlackMarketDataEvent.OnClientEvent:Connect(function(blackMarketData)
    if type(blackMarketData) == "table"
       and type(blackMarketData["商品列表"]) == "table" then
        currentProductList = blackMarketData["商品列表"]
        task.defer(function()
            refillAll()
            applyAllVisibility()
        end)
    end
end)

-- skill 階段 2：透過 connection upvalue 撈當前 var21_upvw
local function findCurrentBlackMarketData()
    if not getconnections then return nil end
    local getUp = (debug and debug.getupvalue) or getupvalue
    if not getUp then return nil end

    for _, conn in ipairs(getconnections(syncBlackMarketDataEvent.OnClientEvent)) do
        local fn = conn.Function or conn.fn
        if type(fn) == "function" then
            for i = 1, 20 do
                local ok, name, value = pcall(getUp, fn, i)
                if not ok or name == nil then break end
                if value == nil then value = name end
                if type(value) == "table"
                   and type(rawget(value, "商品列表")) == "table" then
                    return value
                end
            end
        end
    end
    return nil
end

openBlackMarketEvent.Event:Connect(function()
    task.wait(0.1)
    local data = findCurrentBlackMarketData()
    if data then
        currentProductList = data["商品列表"]
        refillAll()
        applyAllVisibility()
    end
end)

-- ==================== 啟動 ====================

ensureToggleButton()
preBuildAllTooltips() -- 預先為現有卡片建立 Tooltip Frame

do
    local data = findCurrentBlackMarketData()
    if data then
        currentProductList = data["商品列表"]
        refillAll()
        applyAllVisibility()
    end
end

print("[BlackMarketEquipTooltip] loaded")