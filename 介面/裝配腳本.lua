local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local saveFilename = "Tsetingnil_script/Cultivation/Equip_cfg.json"

-- 載入 ReGui
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
-- 載入側邊訊息模組
local Msg = loadstring(game:HttpGet('https://raw.githubusercontent.com/Tseting-nil/Cultivation-mortal-to-immortal-script/refs/heads/main/%E5%81%B4%E9%82%8A%E8%A8%8A%E6%81%AF%E6%A8%A1%E7%B5%84.lua'))()
-- 建立主視窗
local Window = ReGui:TabsWindow({
	Title = "裝備配置腳本",
	TextSize = 16,
	Size = UDim2.fromOffset(350, 280)
})

-- 建立五個頁籤
local ConfigTabs, ConfigContents = {}, {}
for i = 1, 5 do
	ConfigTabs[i] = Window:CreateTab({
		Name = "配置" .. i,
		TextSize = 18
	})
	ConfigContents[i] = ConfigTabs[i]:ScrollingCanvas({
		Fill = true,
		UiPadding = UDim.new(0, 0)
	})
end

-- 設置頁籤
local SettingsTab = Window:CreateTab({
	Name = "設置",
	TextSize = 18
})
local SettingsContent = SettingsTab:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

-- 修改 Tab 字體和大小
spawn(function()
	task.wait(0.1)
	local tabs = {
		ConfigTabs[1],
		ConfigTabs[2],
		ConfigTabs[3],
		ConfigTabs[4],
		ConfigTabs[5],
		SettingsTab
	}
	for _, tab in ipairs(tabs) do
		local tabButton = tab.TabButton.Button
		local label = tabButton:FindFirstChildOfClass("TextLabel")
		if label then
			label.TextSize = 18
			label.Font = Enum.Font.Ubuntu
		end
	end
end)

-- 使用裝備配置
local function UseConfig(Equip, Skill, Relic, Rune, Tree, Sword)
    -- 切換裝備組
	local args = {
		[1] = Equip
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\232\163\133\229\164\135"):FindFirstChild("\229\136\135\230\141\162\232\163\133\229\164\135\231\187\132"):FireServer(unpack(args))
    
    -- 切換技能組
	local args = {
		[1] = Skill
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\230\138\128\232\131\189"):FindFirstChild("\229\136\135\230\141\162\232\163\133\229\164\135\231\187\132"):FireServer(unpack(args))
    
    -- 切換遺物組
	local args = {
		[1] = Relic
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\233\129\151\231\137\169"):FindFirstChild("\229\136\135\230\141\162\232\163\133\229\164\135\231\187\132"):FireServer(unpack(args))
    
    -- 切換符文組
	local args = {
		[1] = Rune
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\233\152\181\230\179\149"):FindFirstChild("\229\136\135\230\141\162\232\163\133\229\164\135\231\187\132"):FireServer(unpack(args))
    
    -- 切換世界樹組
	local args = {
		[1] = Tree
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\228\184\150\231\149\140\230\160\145"):FindFirstChild("\229\136\135\230\141\162\232\163\133\229\164\135\231\187\132"):FireServer(unpack(args))
    
    -- 切換劍雕像
	local args = {
		[1] = Sword
	}
	game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\229\137\145\233\155\149\229\131\143"):FindFirstChild("\229\136\135\230\141\162\231\187\132"):FireServer(unpack(args))
end

-- 單選 Radiobox 群組函數
local function CreateRadioboxGroup(parent, title, count)
	local displayTitle = (title == "劍") and "劍雕像" or title
	local buttonTitle = title
	parent:Separator({
		Text = displayTitle
	})
	local row = parent:Row()
	local buttons = {}
	local isSwitching = false
	for i = 1, count do
		buttons[i] = row:Radiobox({
			Label = buttonTitle .. i,
			Value = (i == 1),
			Callback = function(self)
				if isSwitching then
					return
				end
				isSwitching = true
				if self.Value then
					for j, btn in ipairs(buttons) do
						if j ~= i then
							btn:SetValue(false)
						end
					end
				else
					local anySelected = false
					for _, btn in ipairs(buttons) do
						if btn.Value then
							anySelected = true
							break
						end
					end
					if not anySelected then
						self:SetValue(true)
					end
				end
				isSwitching = false
			end
		})
	end
	return buttons
end

-- 初始化數據
local GUI, GUItable, tempNames = {}, {}, {}
for i = 1, 5 do
	GUItable["config" .. i] = {
		name = "",
		Equip = 1,
		Skill = 1,
		Relic = 1,
		Rune = 1,
		Tree = 1,
		Sword = 1
	}
	tempNames[i] = ""
end

-- JSON 儲存函數
local function SaveConfig()
	local data = {}
	for i = 1, 5 do
        -- 讀取 GUI 選擇值
		local function GetSelected(buttons)
			for idx, btn in ipairs(buttons) do
				if btn.Value then
					return idx
				end
			end
			return 1
		end
		data["config" .. i] = {
			name = GUItable["config" .. i].name,
			Equip = GetSelected(GUI["EquipButtons" .. i]),
			Skill = GetSelected(GUI["SkillButtons" .. i]),
			Relic = GetSelected(GUI["RelicButtons" .. i]),
			Rune = GetSelected(GUI["RuneButtons" .. i]),
			Tree = GetSelected(GUI["TreeButtons" .. i]),
			Sword = GetSelected(GUI["SwordButtons" .. i])
		}
	end
	writefile(saveFilename, HttpService:JSONEncode(data))
end

-- JSON 讀取函數
local function LoadConfig()
	-- 檢查並創建目錄
	local folderPath = "Tsetingnil_script/Cultivation/"
	if not isfolder("Tsetingnil_script") then
		makefolder("Tsetingnil_script")
	end
	if not isfolder(folderPath) then
		makefolder(folderPath)
	end
	
	if not isfile(saveFilename) then
        -- JSON 不存在，創建預設文件
		local defaultData = {}
		for i = 1, 5 do
			defaultData["config" .. i] = {
				name = "",
				Equip = 1,
				Skill = 1,
				Relic = 1,
				Rune = 1,
				Tree = 1,
				Sword = 1
			}
		end
		writefile(saveFilename, HttpService:JSONEncode(defaultData))
	end

    -- 讀取 JSON 並回填 GUI
	local data = HttpService:JSONDecode(readfile(saveFilename))
	for i = 1, 5 do
		local conf = data["config" .. i]
		if conf then
			GUItable["config" .. i] = conf
            -- 回填名稱 Label 和輸入框
			local displayName = (conf.name == "") and "未儲存" or conf.name
			GUI["ConfigLabel" .. i].Text = "名稱:" .. displayName
            -- 設置輸入框的值和臨時名稱
			tempNames[i] = conf.name
			GUI["NameInput" .. i]:SetValue(conf.name)
            
            -- 回填群組選擇
			local function SetSelected(buttons, value)
				for idx, btn in ipairs(buttons) do
					btn:SetValue(idx == value)
				end
			end
			SetSelected(GUI["EquipButtons" .. i], conf.Equip)
			SetSelected(GUI["SkillButtons" .. i], conf.Skill)
			SetSelected(GUI["RelicButtons" .. i], conf.Relic)
			SetSelected(GUI["RuneButtons" .. i], conf.Rune)
			SetSelected(GUI["TreeButtons" .. i], conf.Tree)
			SetSelected(GUI["SwordButtons" .. i], conf.Sword)
		end
	end
end

-- 生成 GUI
for i = 1, 5 do
	local content = ConfigContents[i]

    -- 名稱 Label
	GUI["ConfigLabel" .. i] = content:Label({
		Text = "名稱:未儲存",
		TextSize = 20,
		TextWrapped = true,
		TextColor3 = ReGui.Accent.Red
	})

    -- 名稱輸入框
	GUI["NameInput" .. i] = content:InputText({
		Label = "輸入配置名稱",
		Value = "",
		Callback = function(self, Name)
			tempNames[i] = Name
		end
	})

    -- 儲存和載入按鈕（並排顯示）
	local buttonRow = content:Row()
	buttonRow:Button({
		Text = "儲存",
		Callback = function()
            -- 從臨時名稱更新實際配置
			local finalName = tempNames[i]
			GUItable["config" .. i].name = finalName
            
            -- 更新顯示
			local displayName = (finalName == "") and "未儲存" or finalName
			GUI["ConfigLabel" .. i].Text = "名稱:" .. displayName
			SaveConfig()
			Msg:Success(" 檔案儲存成功！")
		end
	})
	buttonRow:Button({
		Text = "載入",
		Callback = function()
            -- 讀取 GUI 選擇值
			local function GetSelected(buttons)
				for idx, btn in ipairs(buttons) do
					if btn.Value then
						return idx
					end
				end
				return 1
			end
			local config = GUItable["config" .. i]
			local currentEquip = GetSelected(GUI["EquipButtons" .. i])
			local currentSkill = GetSelected(GUI["SkillButtons" .. i])
			local currentRelic = GetSelected(GUI["RelicButtons" .. i])
			local currentRune = GetSelected(GUI["RuneButtons" .. i])
			local currentTree = GetSelected(GUI["TreeButtons" .. i])
			local currentSword = GetSelected(GUI["SwordButtons" .. i])
            
            -- 使用當前GUI選擇的配置
			UseConfig(currentEquip, currentSkill, currentRelic, currentRune, currentTree, currentSword)
            
            -- 顯示載入成功通知
			local configName = (config.name == "") and "配置" .. i or config.name
			Msg:Success("已載入 " .. configName)
		end
	})

    -- 裝備選項群組
	GUI["EquipButtons" .. i] = CreateRadioboxGroup(content, "裝備", 3)
	GUI["SkillButtons" .. i] = CreateRadioboxGroup(content, "技能", 3)
	GUI["RelicButtons" .. i] = CreateRadioboxGroup(content, "遺物", 3)
	GUI["RuneButtons" .. i] = CreateRadioboxGroup(content, "符文", 3)
	GUI["TreeButtons" .. i] = CreateRadioboxGroup(content, "世界樹", 3)
	GUI["SwordButtons" .. i] = CreateRadioboxGroup(content, "劍", 6)
end

-- Base64 編碼表
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64Encode(data)
	return ((data:gsub('.', function(x)
		local r, b = '', x:byte()
		for i = 8, 1, - 1 do
			r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r;
	end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (# x < 6) then
			return ''
		end
		local c = 0
		for i = 1, 6 do
			c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
		end
		return b64chars:sub(c + 1, c + 1)
	end) .. ({
		'',
		'==',
		'='
	})[# data % 3 + 1])
end

local function base64Decode(data)
	data = string.gsub(data, '[^' .. b64chars .. '=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then
			return ''
		end
		local r, f = '', (b64chars:find(x) - 1)
		for i = 6, 1, - 1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (# x ~= 8) then
			return ''
		end
		local c = 0
		for i = 1, 8 do
			c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
		end
		return string.char(c)
	end))
end

-- 字典壓縮配置 (用於減少 JSON 大小)
local compressionDict = {
	["config"] = "c",
	["name"] = "n",
	["Equip"] = "e",
	["Skill"] = "s",
	["Relic"] = "r",
	["Rune"] = "u",
	["Tree"] = "t",
	["Sword"] = "w"
}

-- 壓縮 JSON 函數
local function compressJSON(jsonString)
	local compressed = jsonString
	-- 移除所有空格和換行,減少大小
	compressed = compressed:gsub("%s+", "")
	-- 替換重複的鍵名為短字符
	for original, short in pairs(compressionDict) do
		compressed = compressed:gsub('"' .. original .. '"', '"' .. short .. '"')
	end
	return compressed
end

-- 解壓 JSON 函數
local function decompressJSON(compressed)
	local decompressed = compressed
	-- 還原鍵名
	for original, short in pairs(compressionDict) do
		decompressed = decompressed:gsub('"' .. short .. '"', '"' .. original .. '"')
	end
	return decompressed
end

-- 生成配置代碼 (壓縮 + Base64)
local function GenerateConfigCode()
	SaveConfig() -- 先保存當前配置
	local data = HttpService:JSONDecode(readfile(saveFilename))
	local jsonString = HttpService:JSONEncode(data)
	local compressed = compressJSON(jsonString) -- 壓縮
	return base64Encode(compressed) -- Base64 編碼
end

-- 導入配置代碼 (Base64 解碼 + 解壓)
local function ImportConfigCode(code)
	local success, result = pcall(function()
		local compressed = base64Decode(code) -- Base64 解碼
		local jsonString = decompressJSON(compressed) -- 解壓
		local data = HttpService:JSONDecode(jsonString)
        
        -- 驗證數據格式
		for i = 1, 5 do
			local conf = data["config" .. i]
			if not conf or type(conf) ~= "table" then
				error("無效的配置格式")
			end
		end
        
        -- 寫入文件
		writefile(saveFilename, HttpService:JSONEncode(data))
        
        -- 重新載入配置
		LoadConfig()
		return true
	end)
	return success, result
end

-- 配置代碼輸出框
local configCodeOutput = ""
SettingsContent:Separator({
	Text = "配置代碼導出",
	TextSize = 16,
})
local exportRow = SettingsContent:Row()
exportRow:Button({
	Text = "生成配置代碼",
	TextSize = 16,
	Callback = function()
		configCodeOutput = GenerateConfigCode()
		GUI["ConfigCodeDisplay"]:SetValue(configCodeOutput)
		setclipboard(configCodeOutput)
		Msg:Success("配置代碼已生成並複製到剪貼板")
	end
})

GUI["ConfigCodeDisplay"] = SettingsContent:InputText({
	Label = "配置代碼(可複製)",
	Value = "",
	Multiline = true,
	Callback = function()
	end
})

-- 配置代碼導入
SettingsContent:Separator({
	Text = "配置代碼導入",
  TextSize = 16,
})
local importCode = ""
GUI["ConfigCodeInput"] = SettingsContent:InputText({
	Label = "貼上配置代碼",
  TextSize = 16,
	Value = "",
	Multiline = true,
	Callback = function(self, text)
		importCode = text
	end
})

SettingsContent:Button({
	Text = "導入配置",
  TextSize = 16,
	Callback = function()
		if importCode == "" then
			Msg:Warning("請先輸入配置代碼")
			return
		end
		local success, result = ImportConfigCode(importCode)
		if success then
			Msg:Success("配置導入成功！")
			GUI["ConfigCodeInput"]:SetValue("")
		else
			Msg:Error("配置導入失敗：格式錯誤")
		end
	end
})

-- 設置頁面 - 刪除本地配置
SettingsContent:Separator({
	Text = "其他設置"
})
SettingsContent:Button({
	Text = "刪除本地配置",
	TextSize = 16,
	Callback = function()
		if isfile(saveFilename) then
			delfile(saveFilename)
			Msg:Success("已刪除本地配置檔案")
		else
			Msg:Warning("找不到本地配置檔案")
		end
	end
})



-- 啟動時讀取配置
LoadConfig()