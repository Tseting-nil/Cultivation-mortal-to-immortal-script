local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local saveFilename = "Tsetingnil_script/Cultivation/Equip_cfg.json"

-- 載入 ReGui
local ReGui = loadstring(game:HttpGet('https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/52b66144f1e520a4f840c01a6f95d7fe4421bd50/GUI:ReGui'))()
-- 載入側邊訊息模組
local Msg = loadstring(game:HttpGet('https://raw.githubusercontent.com/Tseting-nil/Cultivation-mortal-to-immortal-script/refs/heads/main/%E5%81%B4%E9%82%8A%E8%A8%8A%E6%81%AF%E6%A8%A1%E7%B5%84.lua'))()
-- 建立主視窗
local Window = ReGui:TabsWindow({
	Title = "Equipment Configuration Script",
	TextSize = 16,
	Size = UDim2.fromOffset(350, 280)
})

-- 建立五個頁籤
local ConfigTabs, ConfigContents = {}, {}
for i = 1, 5 do
	ConfigTabs[i] = Window:CreateTab({
		Name = "Cfg " .. i,
		TextSize = 18
	})
	ConfigContents[i] = ConfigTabs[i]:ScrollingCanvas({
		Fill = true,
		UiPadding = UDim.new(0, 0)
	})
end

-- 設置頁籤
local SettingsTab = Window:CreateTab({
	Name = "Settings",
	TextSize = 18
})
local SettingsContent = SettingsTab:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

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
	local displayTitle = (title == "Sword") and "Sword Statue" or title
	local buttonTitle = (title == "Sword") and "" or title
	parent:Separator({
		Text = displayTitle
	})
	local row = parent:Row()
	local buttons = {}
	local isSwitching = false
	for i = 1, count do
		buttons[i] = row:Radiobox({
			Label = buttonTitle .. " " .. i,
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
			local displayName = (conf.name == "") and "Not Saved" or conf.name
			GUI["ConfigLabel" .. i].Text = "Name: " .. displayName
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
		Text = "Name: Not Saved",
		TextSize = 20,
		TextWrapped = true,
		TextColor3 = ReGui.Accent.Red
	})

    -- 名稱輸入框
	GUI["NameInput" .. i] = content:InputText({
		Label = "Enter Config Name",
		Value = "",
		Callback = function(self, Name)
			tempNames[i] = Name
		end
	})

    -- 儲存和載入按鈕（並排顯示）
	local buttonRow = content:Row()
	buttonRow:Button({
		Text = "Save",
		Callback = function()
            -- 從臨時名稱更新實際配置
			local finalName = tempNames[i]
			GUItable["config" .. i].name = finalName
            
            -- 更新顯示
			local displayName = (finalName == "") and "Not Saved" or finalName
			GUI["ConfigLabel" .. i].Text = "Name: " .. displayName
			SaveConfig()
			Msg:Success(" File saved successfully!")
		end
	})
	buttonRow:Button({
		Text = "Load",
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
			local configName = (config.name == "") and "Config " .. i or config.name
			Msg:Success("Loaded " .. configName)
		end
	})

    -- 裝備選項群組
	GUI["EquipButtons" .. i] = CreateRadioboxGroup(content, "Equipment", 3)
	GUI["SkillButtons" .. i] = CreateRadioboxGroup(content, "Skill", 3)
	GUI["RelicButtons" .. i] = CreateRadioboxGroup(content, "Relic", 3)
	GUI["RuneButtons" .. i] = CreateRadioboxGroup(content, "Rune", 3)
	GUI["TreeButtons" .. i] = CreateRadioboxGroup(content, "World Tree", 3)
	GUI["SwordButtons" .. i] = CreateRadioboxGroup(content, "Sword", 6)
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

-- Dictionary compression configuration (to reduce JSON size)
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

-- JSON compression function
local function compressJSON(jsonString)
	local compressed = jsonString
	-- Remove all spaces and newlines to reduce size
	compressed = compressed:gsub("%s+", "")
	-- Replace repeated key names with short characters
	for original, short in pairs(compressionDict) do
		compressed = compressed:gsub('"' .. original .. '"', '"' .. short .. '"')
	end
	return compressed
end

-- JSON decompression function
local function decompressJSON(compressed)
	local decompressed = compressed
	-- Restore key names
	for original, short in pairs(compressionDict) do
		decompressed = decompressed:gsub('"' .. short .. '"', '"' .. original .. '"')
	end
	return decompressed
end

-- Generate config code (Compression + Base64)
local function GenerateConfigCode()
	SaveConfig() -- Save current configuration first
	local data = HttpService:JSONDecode(readfile(saveFilename))
	local jsonString = HttpService:JSONEncode(data)
	local compressed = compressJSON(jsonString) -- Compress
	return base64Encode(compressed) -- Base64 encode
end

-- Import config code (Base64 decode + Decompress)
local function ImportConfigCode(code)
	local success, result = pcall(function()
		local compressed = base64Decode(code) -- Base64 decode
		local jsonString = decompressJSON(compressed) -- Decompress
		local data = HttpService:JSONDecode(jsonString)
        
        -- Validate data format
		for i = 1, 5 do
			local conf = data["config" .. i]
			if not conf or type(conf) ~= "table" then
				error("Invalid configuration format")
			end
		end
        
        -- Write to file
		writefile(saveFilename, HttpService:JSONEncode(data))
        
        -- Reload configuration
		LoadConfig()
		return true
	end)
	return success, result
end

-- Config code output
local configCodeOutput = ""
SettingsContent:Separator({
	Text = "Export Config Code",
})
local exportRow = SettingsContent:Row()
exportRow:Button({
	Text = "Generate Config Code",
	Callback = function()
		configCodeOutput = GenerateConfigCode()
		GUI["ConfigCodeDisplay"]:SetValue(configCodeOutput)
		setclipboard(configCodeOutput)
		Msg:Success("Config code generated and copied to clipboard")
	end
})

GUI["ConfigCodeDisplay"] = SettingsContent:InputText({
	Label = "Config Code (Copyable)",
	Value = "",
	Multiline = true,
	Callback = function()
	end
})

-- Config code import
SettingsContent:Separator({
	Text = "Import Config Code",
})
local importCode = ""
GUI["ConfigCodeInput"] = SettingsContent:InputText({
	Label = "Paste Config Code",
	Value = "",
	Multiline = true,
	Callback = function(self, text)
		importCode = text
	end
})

SettingsContent:Button({
	Text = "Import Config",
	Callback = function()
		if importCode == "" then
			Msg:Warning("Please enter config code first")
			return
		end
		local success, result = ImportConfigCode(importCode)
		if success then
			Msg:Success("Config imported successfully!")
			GUI["ConfigCodeInput"]:SetValue("")
		else
			Msg:Error("Config import failed: Invalid format")
		end
	end
})

-- Settings page - Delete local configuration
SettingsContent:Separator({
	Text = "Other Settings"
})
SettingsContent:Button({
	Text = "Delete Local Configuration",
	Callback = function()
		if isfile(saveFilename) then
			delfile(saveFilename)
			Msg:Success("Local configuration file deleted")
		else
			Msg:Warning("Local configuration file not found")
		end
	end
})
-- 啟動時讀取配置
LoadConfig()