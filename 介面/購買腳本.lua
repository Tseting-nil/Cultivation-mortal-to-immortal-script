-- 外部庫載入
local ReGui = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/8dfc8c5dcb9d3ea611ce4a3b597ce01af27614a0/GUI:ReGui"))()

if not getgenv().NotificationModule then
	loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/00001d614d928fc5dafce59133a012dd78419afd/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua"))()
end
local Msg = getgenv().NotificationModule

-- 遊戲服務和GUI元素
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local secondGUI = PlayerGui.GUI:WaitForChild("二级界面")

-- ===== --
-- 本地配置
local Localsetting = {
	ROOT = "Tsetingnil_script/Cultivation-Mortal-to-Immortal/", -- 儲存根目錄
	Shop_cfg = "Shop_cfg.json", -- 商店配置檔案名稱
}

-- 遊戲GUI元素引用表
local GameGUITable = {
	eventshop = {
		EventData = secondGUI:WaitForChild("节日活动商店"):WaitForChild("背景"):WaitForChild("标题"):WaitForChild("活动物品"):WaitForChild("按钮"):WaitForChild("值"),
		EventTime = secondGUI:WaitForChild("节日活动商店"):WaitForChild("背景"):WaitForChild("倒计时"):WaitForChild("文本"),
		EventList = secondGUI:WaitForChild("节日活动商店"):WaitForChild("背景"):WaitForChild("右侧界面"):WaitForChild("兑换"):WaitForChild("列表"),
	},
	arenashop = {
		ArenaData = LocalPlayer:WaitForChild("值"):WaitForChild("货币"):WaitForChild("紫钻"),
		ArenaList = secondGUI:WaitForChild("竞技场"):WaitForChild("背景"):WaitForChild("右侧界面"):WaitForChild("商店"):WaitForChild("列表"),
		ArenaTime = secondGUI:WaitForChild("竞技场"):WaitForChild("背景"):WaitForChild("右侧界面"):WaitForChild("竞技场"):WaitForChild("标题"):WaitForChild("倒计时"):WaitForChild("名称"),
		ArenaTime2 = secondGUI:WaitForChild("竞技场"):WaitForChild("背景"):WaitForChild("右侧界面"):WaitForChild("奖励介绍"):WaitForChild("倒计时"):WaitForChild("文本"),
	},
  guildshop = {
    GuildData = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("公会币"):waitForChild("按钮"):waitForChild("值"),
    GuildItemList = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("列表"),
    GuildShopRefining = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("刷新"):waitForChild("按钮"):waitForChild("值")
  },
}

local Scripttable = {
	GUI = {
		EventShopTab = {
			Enabled = false,
			Select_ID = nil,
			BuyInterval = 0.1,
		},
		ArenaShopTab = {
			Enabled = false,
			Select_ID = nil,
		},
		GuildShopTab = {
      Enabled = false,
      Select = {
        ["Talisman Summon Ticket"] = false,
        ["Skill Summon Ticket"] = false,
        ["Elixir"] = false,
        ["Herb"] = false,
        ["Gem"] = false,
        ["Gold"] = false,
        ["Ore Dungeon Keys"] = false,
        ["Gem Dungeon Keys"] = false,
        ["Rune Dungeon Keys"] = false,
        ["Relic Dungeon Keys"] = false,
        ["Gold Dungeon Keys"] = false,
        ["Hover Dungeon Keys"] = false,
      },
      indextext = {"刷新商店", "儲存" ,"重新加載" ,"刪除配置"},
    },
	},
	EventShopData = {},
	ArenaShopData = {},
	EventItemid_Reverse = {},
	ArenaItemid_Reverse = {},
	EventItemid = {
		["礦石地下城鑰匙"] = {["400"] = 4,["600"] = 17},
		["靈石地下城鑰匙"] = {["600"] = 5,["800"] = 18},
		["符石地下城鑰匙"] = {["400"] = 6,["600"] = 19},
		["遺物地下城鑰匙"] = {["400"] = 7,["600"] = 20},
		["金幣地下城鑰匙"] = {["400"] = 8,["600"] = 21},
		["懸浮地下城鑰匙"] = {["500"] = 9,["800"] = 22},
		["金幣"] = {["400"] = 1,["1200"] = 12},
    ["礦石"] = {["400"] = 2,["900"] = 13},
		["靈石"] = {["400"] = 3,["800"] = 14},
		["武器券"] = {["400"] = 10,["800"] = 15},
    ["技能券"] = {["400"] = 11,["800"] = 16},
		["寵物蛋"] = {["2000"] = 23},
		["靈魂"] = {["1000"] = 24,["2000"] = 25},
	},
	ArenaItemid = {
		["礦石地下城鑰匙"] = {["300"] = 5},
		["靈石地下城鑰匙"] = {["300"] = 6},
		["符石地下城鑰匙"] = {["300"] = 7},
		["遺物地下城鑰匙"] = {["300"] = 8},
		["金幣地下城鑰匙"] = {["300"] = 9},
		["懸浮地下城鑰匙"] = {["300"] = 10},
		["靈魂"] = {["500"] = 11},
		["金幣"] = {["200"] = 1},
		["活動物品"] = {["300"] = 2},
		["世界樹物品"] = {["400"] = 3},
		["生命之水"] = {["300"] = 4},
  },
  -- 公會商店物品順序
  GuildItemOrder = {"Talisman Summon Ticket", "Skill Summon Ticket", "Elixir", "Herb", "Gem", "Gold", "Wing Cores", "Ore Dungeon Keys", "Gem Dungeon Keys", "Rune Dungeon Keys", "Relic Dungeon Keys", "Gold Dungeon Keys", "Hover Dungeon Keys"},
	Translationt = {
		-- ===== 英文 → 中文 =====
		["Ore Dungeon Keys"] = "礦石地下城鑰匙",
		["Gem Dungeon Keys"] = "靈石地下城鑰匙",
		["Rune Dungeon Keys"] = "符石地下城鑰匙",
		["Relic Dungeon Keys"] = "遺物地下城鑰匙",
		["Gold Dungeon Keys"] = "金幣地下城鑰匙",
		["Hover Dungeon Keys"] = "懸浮地下城鑰匙",
		["Gold"] = "金幣",
		["Ore"] = "礦石",
		["Gem"] = "靈石",
		["Soul"] = "靈魂",
		["Egg"] = "寵物蛋",
		["Water of Life"] = "生命之水",
		["Talisman Summon Ticket"] = "武器券",
		["Skill Summon Ticket"] = "技能券",
		["Event Item"] = "活動物品",
		["Random World Tree Decorations"] = "世界樹物品",
    ["Elixir"] = "藥品",
    ["Herb"] = "草藥",
    ["Wing Cores"] = "羽核",
		-- ===== 中文 → 英文 =====
		["礦石地下城鑰匙"] = "Ore Dungeon Keys",
		["靈石地下城鑰匙"] = "Gem Dungeon Keys",
		["符石地下城鑰匙"] = "Rune Dungeon Keys",
		["遺物地下城鑰匙"] = "Relic Dungeon Keys",
		["金幣地下城鑰匙"] = "Gold Dungeon Keys",
		["懸浮地下城鑰匙"] = "Hover Dungeon Keys",
		["金幣"] = "Gold",
		["礦石"] = "Ore",
		["靈石"] = "Gem",
		["靈魂"] = "Soul",
		["寵物蛋"] = "Egg",
		["生命之水"] = "Water of Life",
		["武器券"] = "Talisman Summon Ticket",
		["技能券"] = "Skill Summon Ticket",
		["活動物品"] = "Event Item",
		["世界樹物品"] = "Random World Tree Decorations",
    ["藥品"] = "Elixir",
    ["草藥"] = "Herb",
    ["羽核"] = "Wing Cores",
	},
}

local Mainfunction = {}

Mainfunction.SaveGuildShopconfig = function()
  local configPath = Localsetting.ROOT .. Localsetting.Shop_cfg
  if not isfolder(Localsetting.ROOT) then
    makefolder(Localsetting.ROOT)
  end
  local success, err = pcall(function()
    local jsonData = HttpService:JSONEncode(Scripttable.GUI.GuildShopTab.Select)
    writefile(configPath, jsonData)
  end)
  if success then
    Msg:Success("配置已儲存", 3)
  else
    warn("儲存失敗: " .. tostring(err), 3)
  end
end

Mainfunction.LoadGuildShopconfig = function()
  local configPath = Localsetting.ROOT .. Localsetting.Shop_cfg
  if not isfile(configPath) then
    if not isfolder(Localsetting.ROOT) then
      makefolder(Localsetting.ROOT)
    end
    local defaultData = {}
    for key in pairs(Scripttable.GUI.GuildShopTab.Select) do
      defaultData[key] = false
    end
    writefile(configPath, HttpService:JSONEncode(defaultData))
    return
  end
  local success, result = pcall(function()
    local fileContent = readfile(configPath)
    return HttpService:JSONDecode(fileContent)
  end)
  if success and result then
    for key, value in pairs(result) do
      if Scripttable.GUI.GuildShopTab.Select[key] ~= nil then
        Scripttable.GUI.GuildShopTab.Select[key] = value
        local component = Scripttable.GUI.GuildShopTab.ItemComponents[key]
        if component then
          component:SetValue(value)
        end
      end
    end
  else
    warn("載入失敗: " .. tostring(result), 3)
  end
end

Mainfunction.DeleteGuildShopconfig = function()
  local configPath = Localsetting.ROOT .. Localsetting.Shop_cfg
  if not isfile(configPath) then
    return
  end
  local success, err = pcall(function()
    delfile(configPath)
  end)
  if success then
    Msg:Success("配置已刪除", 3)
  else
    warn("刪除失敗: " .. tostring(err), 3)
  end
end

Mainfunction.Translationtable = function(name)
  name = tostring(name)
	return Scripttable.Translationt[name] or name
end

Mainfunction.GetShopData = function(type)
	local newData = {}
	local list
	if type == "eventshop" then
		list = GameGUITable.eventshop.EventList
	elseif type == "arenashop" then
		list = GameGUITable.arenashop.ArenaList
	end

	for _, obj in ipairs(list:GetDescendants()) do
		if string.match(obj.Name, "^活动商品预制体%d+$") and obj.Visible == true then
			local btn = obj:FindFirstChild("按钮")
			if not btn then
				continue
			end

			local nameObj = btn:FindFirstChild("名称")
			local priceObj = btn:FindFirstChild("价格")
			local stockObj = btn:FindFirstChild("库存")

			if not nameObj or not priceObj or not stockObj then
				continue
			end

			local name = nameObj.Text
			local price = tonumber(priceObj.Text)
			local stock = tonumber(string.match(stockObj.Text, "(%d+)%s*Left"))

			if not price or not stock then
				continue
			end

			if not newData[name] then
				newData[name] = {}
			end

			table.insert(newData[name], {
				price = price,
				stock = stock,
				obj = obj,
			})
		end
	end

	-- 排序（價格低 → 高）
	for name, items in pairs(newData) do
		table.sort(items, function(a, b)
			return a.price < b.price
		end)
	end

	if type == "eventshop" then
		Scripttable.EventShopData = newData
		return Scripttable.EventShopData
	elseif type == "arenashop" then
		Scripttable.ArenaShopData = newData
		return Scripttable.ArenaShopData
	end
end

Mainfunction.GetItemsByType = function(shoptype, itemtype)
	Mainfunction.GetShopData(shoptype)
	local items = shoptype == "arenashop" and Scripttable.ArenaShopData or Scripttable.EventShopData
	local selected_items = {}

	local function isKey(name)
		return string.find(name, "Dungeon Keys") ~= nil or string.find(name, "地下城") ~= nil
	end

	-- 指定優先順序
	local priorityOrder = {
		"Ore Dungeon Keys",
		"Gem Dungeon Keys",
		"Rune Dungeon Keys",
		"Relic Dungeon Keys",
		"Gold Dungeon Keys",
		"Hover Dungeon Keys",
		"Gold",
		"Ore",
		"Gem",
		"Soul",
		"Egg",
		"Water of Life",
		"Talisman Summon Ticket",
		"Skill Summon Ticket",
		"Event Item",
		"Random World Tree Decorations",
	}

	local priorityIndex = {}
	for i, name in ipairs(priorityOrder) do
		priorityIndex[name] = i
	end

	-- 收集符合類型名稱
	local nameList = {}
	for name, data in pairs(items) do
		if data and # data > 0 then
			local keyCheck = isKey(name)
			if (itemtype == "Key" and keyCheck) or (itemtype == "Item" and not keyCheck) then
				table.insert(nameList, name)
			end
		end
	end

	-- 依照指定順序排序（不在清單的排最後，再按字母）
	table.sort(nameList, function(a, b)
		local ia = priorityIndex[a] or (999 + (a < b and 0 or 1))
		local ib = priorityIndex[b] or (999 + (a < b and 1 or 0))
		if ia ~= ib then
			return ia < ib
		end
		return a < b
	end)

	-- 取 [1]（最低價）
	for _, name in ipairs(nameList) do
		local item = items[name][1]
		if item then
			local stockStr = item.stock == 0 and "--" or string.format("%02d", item.stock)
			local display = string.format("%s | 庫存: %s | 價格: %d", Mainfunction.Translationtable(name), stockStr, item.price)
			table.insert(selected_items, display)
		end
	end

	-- 取 [2]（高價）
	for _, name in ipairs(nameList) do
		local item = items[name][2]
		if item then
			local stockStr = item.stock == 0 and "--" or string.format("%02d", item.stock)
			local display = string.format("%s | 庫存: %s | 價格: %d", Mainfunction.Translationtable(name), stockStr, item.price)
			table.insert(selected_items, display)
		end
	end

	return selected_items
end

Mainfunction.BuyShopItem = function(shoptype, type)
	local isArena = shoptype == "arenashop"
	local tab = isArena and Scripttable.GUI.ArenaShopTab or Scripttable.GUI.EventShopTab
	local radiobox = isArena and tab.ArenaShopRadiobox or tab.EventsShopRadiobox
	local reverseTable = isArena and Scripttable.ArenaItemid_Reverse or Scripttable.EventItemid_Reverse
	local shopData = isArena and Scripttable.ArenaShopData or Scripttable.EventShopData
	local myCurrency = isArena and GameGUITable.arenashop.ArenaData.Value or tonumber(GameGUITable.eventshop.EventData.Text)
	local remoteEvent = isArena and game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\231\171\158\230\138\128\229\156\186"):FindFirstChild("\232\180\173\228\185\176") or game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\232\138\130\230\151\165\230\180\187\229\138\168"):FindFirstChild("\232\180\173\228\185\176")
	local id = tab.Select_ID
	if id then
		local entry = reverseTable[id]
		local translatedName = Mainfunction.Translationtable(entry.name)
		local shopItems = shopData[translatedName]
		for _, item in ipairs(shopItems) do
			if tostring(item.price) == entry.price then
				if item.stock > 0 then
					if myCurrency > item.price then
						remoteEvent:FireServer(id, 1)
					else
						Msg:Error("資金不足" .. " | 價格: " .. item.price .. " | 目前: " .. myCurrency)
						if type == "Checkbox" then
							tab.Enabled = false
							radiobox:SetValue(false)
						end
					end
				else
					Msg:Error(entry.name .. " | 無庫存")
					if type == "Checkbox" then
						tab.Enabled = false
						radiobox:SetValue(false)
					end
				end
			end
		end
	else
		Msg:Error("未選擇商品")
		if type == "Checkbox" then
			tab.Enabled = false
			radiobox:SetValue(false)
		end
	end
end

Mainfunction.Buy_GuildShop_Item = function()
  local Select = Scripttable.GUI.GuildShopTab.Select
  local MyCurrency = tonumber(GameGUITable.guildshop.GuildData.Text)
  local list = GameGUITable.guildshop.GuildItemList

  for _, item in ipairs(list:GetChildren()) do
    if item.ClassName ~= "Frame" or not item.Visible then continue end
    local btn = item:FindFirstChild("按钮")
    if not btn then continue end

    local nameObj = btn:FindFirstChild("名称")
    local priceObj = btn:FindFirstChild("价格")
    local stockObj = btn:FindFirstChild("库存")
    local stock = tonumber(string.match(stockObj.Text, "(%d+)%s*Left"))
    if MyCurrency > tonumber(priceObj.Text) then
      if stock > 0 then
        local name = nameObj.Text
        if Select[name] == true then
          local translatedName = Mainfunction.Translationtable(name)
          firesignal(btn.Activated)
          -- print("購買成功: " .. translatedName .. " | 價格: " .. priceObj.Text)
        end
      end
    end
  end
  Msg:Success("購買完成", 3)
  Scripttable.GUI.GuildShopTab.GuildShopRadiobox:SetValue(false)
end

Mainfunction.Upd_Event_RefreshTime = function()
	local time_str = GameGUITable.eventshop.EventTime.Text

	-- 特別處理：如果等於 "Time Left: 23:59:59"
	if time_str == "Time Left: 23:59:59" then
		return " 未獲取"
	end

	-- 嘗試匹配完整格式："Time Left: X days, Y hours"
	local days, hours = string.match(time_str, "Time Left: (%d+) days?, (%d+) hours?")
	if days then
		days, hours = tonumber(days), tonumber(hours)
		if hours == 0 then
			return days .. " 天"
		elseif days == 0 then
			return hours .. " 小時"
		else
			return days .. " 天 " .. hours .. " 小時"
		end
	end

	-- 嘗試匹配新格式："Time Left: HH:MM:SS"
	local minutes
	hours, minutes = string.match(time_str, "Time Left: (%d+):(%d+):%d+")
	if hours then
		hours, minutes = tonumber(hours), tonumber(minutes)
		if hours == 0 then
			return minutes .. " 分鐘"
		elseif minutes == 0 then
			return hours .. " 小時"
		else
			return hours .. " 小時 " .. minutes .. " 分鐘"
		end
	end

	return " 未獲取"
end

-- 反向查表：ID → { name, price }
for name, priceMap in pairs(Scripttable.EventItemid) do
	for price, itemId in pairs(priceMap) do
		Scripttable.EventItemid_Reverse[itemId] = {
			name = name,
			price = price
		}
	end
end

-- 反向查表：ID → { name, price }
for name, priceMap in pairs(Scripttable.ArenaItemid) do
	for price, itemId in pairs(priceMap) do
		Scripttable.ArenaItemid_Reverse[itemId] = {
			name = name,
			price = price
		}
	end
end

Mainfunction.Upd_Shop_Data = function()
	Scripttable.GUI.EventShopTab.EventItem.Text = "活動物品: " .. GameGUITable.eventshop.EventData.Text
	Scripttable.GUI.ArenaShopTab.ArenaItem.Text = "紫鑽: " .. GameGUITable.arenashop.ArenaData.Value
  Scripttable.GUI.GuildShopTab.GuildData.Text = "公會幣: " .. GameGUITable.guildshop.GuildData.Text
end

Mainfunction.Upd_Select = function(shoptype)
	local tab = shoptype == "arenashop" and Scripttable.GUI.ArenaShopTab or Scripttable.GUI.EventShopTab
	local reverseTable = shoptype == "arenashop" and Scripttable.ArenaItemid_Reverse or Scripttable.EventItemid_Reverse
	local shopData = shoptype == "arenashop" and Scripttable.ArenaShopData or Scripttable.EventShopData
	local id = tab.Select_ID
	if id then
		local entry = reverseTable[id]
		if not entry then
			return
		end
		local translatedName = Mainfunction.Translationtable(entry.name)
		local shopItems = shopData[translatedName]
		if not shopItems then
			return
		end
		for _, item in ipairs(shopItems) do
			if tostring(item.price) == entry.price then
				if item.stock > 0 then
					tab.ChoosenItem_Label.Text = "當前選擇: " .. entry.name .. " | 庫存: " .. string.format("%02d", item.stock) .. " | 價格: " .. item.price
				else
					tab.ChoosenItem_Label.Text = "當前選擇: " .. entry.name .. " | 無庫存"
				end
			end
		end
	end
end

-- ========== GUI 介面創建 ==========
-- 主視窗建立
local Window = ReGui:TabsWindow({
	Title = "商品購買腳本",
	Size = UDim2.fromOffset(380, 320),
}):Center()

-- 創建頁籤
local EventShopTab = Window:CreateTab({Name = "活動商店", TextSize = 18,})
local ArenaShopTab = Window:CreateTab({Name = "競技場商店",	TextSize = 18,})
local GuildShopTab = Window:CreateTab({Name = "公會商店",	TextSize = 18,})

-- 創建頁面內容容器
local EventsShopContent = EventShopTab:ScrollingCanvas({Fill = true, UiPadding = UDim.new(0, 0),})
local ArenaShopContent = ArenaShopTab:ScrollingCanvas({Fill = true, UiPadding = UDim.new(0, 0),})
local GuildShopContent = GuildShopTab:ScrollingCanvas({Fill = true,	UiPadding = UDim.new(0, 0),})

-- 設定頁籤字體大小
spawn(function()
	task.wait(0.1)
	local tabs = {EventShopTab, ArenaShopTab, GuildShopTab}
	for _, tab in ipairs(tabs) do
		local label = tab.TabButton.Button:FindFirstChildOfClass("TextLabel")
		if label then
			label.TextSize = 18
		end
	end
end)

Scripttable.GUI.EventShopTab.RefreshTime_Label = EventsShopContent:Label({
	Text = "活動商店刷新剩餘: 未獲取",
	TextSize = 16,
})

Scripttable.GUI.EventShopTab.ChoosenItem_Label = EventsShopContent:Label({
	Text = "當前選擇商品: 未選擇",
	TextSize = 16,
})

Scripttable.GUI.EventShopTab.EventItem = EventsShopContent:Label({
	Text = "活動物品: " .. GameGUITable.eventshop.EventData.Text,
	TextSize = 16,
})

Scripttable.GUI.EventShopTab.EventsShop_Key_Combo = EventsShopContent:Combo({
	Label = "選擇購買物品(鑰匙)",
	GetItems = function()
		return Mainfunction.GetItemsByType("eventshop", "Key")
	end,
	Callback = function(selected)
		local text = selected.Value
		Scripttable.GUI.EventShopTab.ChoosenItem_Label.Text = "當前選擇: " .. text
		local name, stock, price = string.match(text, "^(.-) | 庫存: (%-*%d*) | 價格: (%d+)")
		if name and price then
			if stock == "--" then
				Scripttable.GUI.EventShopTab.ChoosenItem_Label.Text = "當前選擇: " .. name .. " | 無庫存"
			end
			local ID = Scripttable.EventItemid[name] and Scripttable.EventItemid[name][tostring(price)]
			Scripttable.GUI.EventShopTab.Select_ID = ID
		end
	end,
})

Scripttable.GUI.EventShopTab.EventsShop_Item_Combo = EventsShopContent:Combo({
	Label = "選擇購買物品(物品)",
	GetItems = function()
		return Mainfunction.GetItemsByType("eventshop", "Item")
	end,
	Callback = function(selected)
		local text = selected.Value
		Scripttable.GUI.EventShopTab.ChoosenItem_Label.Text = "當前選擇: " .. text
		local name, stock, price = string.match(text, "^(.-) | 庫存: (%-*%d*) | 價格: (%d+)")
		if name and price then
			if stock == "--" then
				Scripttable.GUI.EventShopTab.ChoosenItem_Label.Text = "當前選擇: " .. name .. " | 無庫存"
			end
			local ID = Scripttable.EventItemid[name] and Scripttable.EventItemid[name][tostring(price)]
			Scripttable.GUI.EventShopTab.Select_ID = ID
		end
	end,
})

EventsShopContent:Separator({
	Text = "● 功能選項",
})

Scripttable.GUI.EventShopTab.EventShopTab_ROW = EventsShopContent:Row()
Scripttable.GUI.EventShopTab.EventsShopRadiobox = Scripttable.GUI.EventShopTab.EventShopTab_ROW:Radiobox({
	Value = false,
	Label = "購買商品",
	Callback = function(self, Value)
		Scripttable.GUI.EventShopTab.Enabled = Value
		task.spawn(function()
			while Scripttable.GUI.EventShopTab.Enabled do
				if not Scripttable.GUI.EventShopTab.Enabled then
					return
				end
				Mainfunction.BuyShopItem("eventshop", "Checkbox")
				task.wait(Scripttable.GUI.EventShopTab.BuyInterval)
			end
		end)
	end,
})

-- 活動商店功能按鈕
EventsShopContent:SliderFloat({
	Label = "購買間隔 (秒)",
	Value = 0.1,
	Minimum = 0.1,
	Maximum = 2.0,
	Format = "%.1f 秒",
	Callback = function(_, value)
		Scripttable.GUI.EventShopTab.BuyInterval = value
	end,
})

local eventShopButtons = {
	"刷新時間",
	"購買商品"
}
for _, buttonText in ipairs(eventShopButtons) do
	Scripttable.GUI.EventShopTab.EventShopTab_ROW:Button({
		Text = buttonText,
		TextSize = 16,
		Callback = function()
			if buttonText == "刷新時間" then
				local replicatedStorage = game:GetService("ReplicatedStorage")
				local event = replicatedStorage:FindFirstChild("打开节日商店", true)
				if event then
					event:Fire("打开节日商店")
					task.wait(0.1)
					Scripttable.GUI.EventShopTab.RefreshTime_Label.Text = "活動商店刷新剩餘: " .. Mainfunction.Upd_Event_RefreshTime()
				end
			elseif buttonText == "購買商品" then
				Mainfunction.BuyShopItem("eventshop")
			end
		end,
	})
end

Scripttable.GUI.ArenaShopTab.ChoosenItem_Label = ArenaShopContent:Label({
	Text = "當前選擇商品: 未選擇",
	TextSize = 16,
})

Scripttable.GUI.ArenaShopTab.ArenaItem = ArenaShopContent:Label({
	Text = "紫鑽: " .. GameGUITable.arenashop.ArenaData.Value,
	TextSize = 16,
})

Scripttable.GUI.ArenaShopTab.EArenaShop_Key_Combo = ArenaShopContent:Combo({
	Label = "選擇購買物品(鑰匙)",
	GetItems = function()
		return Mainfunction.GetItemsByType("arenashop", "Key")
	end,
	Callback = function(selected)
		local text = selected.Value
		Scripttable.GUI.ArenaShopTab.ChoosenItem_Label.Text = "當前選擇: " .. text
		local name, stock, price = string.match(text, "^(.-) | 庫存: (%-*%d*) | 價格: (%d+)")
		if name and price then
			if stock == "--" then
				Scripttable.GUI.ArenaShopTab.ChoosenItem_Label.Text = "當前選擇: " .. name .. " | 無庫存"
			end
			local ID = Scripttable.ArenaItemid[name] and Scripttable.ArenaItemid[name][tostring(price)]
			Scripttable.GUI.ArenaShopTab.Select_ID = ID
		end
	end,
})

Scripttable.GUI.ArenaShopTab.ArenaShop_Item_Combo = ArenaShopContent:Combo({
	Label = "選擇購買物品(物品)",
	GetItems = function()
		return Mainfunction.GetItemsByType("arenashop", "Item")
	end,
	Callback = function(selected)
		local text = selected.Value
		Scripttable.GUI.ArenaShopTab.ChoosenItem_Label.Text = "當前選擇: " .. text
		local name, stock, price = string.match(text, "^(.-) | 庫存: (%-*%d*) | 價格: (%d+)")
		if name and price then
			if stock == "--" then
				Scripttable.GUI.ArenaShopTab.ChoosenItem_Label.Text = "當前選擇: " .. name .. " | 無庫存"
			end
			local ID = Scripttable.ArenaItemid[name] and Scripttable.ArenaItemid[name][tostring(price)]
			Scripttable.GUI.ArenaShopTab.Select_ID = ID
		end
	end,
})

ArenaShopContent:Separator({
	Text = "● 功能選項",
})

Scripttable.GUI.ArenaShopTab.ArenaShopTab_ROW = ArenaShopContent:Row()
Scripttable.GUI.ArenaShopTab.ArenaShopRadiobox = Scripttable.GUI.ArenaShopTab.ArenaShopTab_ROW:Radiobox({
	Value = false,
	Label = "購買商品",
	Callback = function(self, Value)
		Scripttable.GUI.ArenaShopTab.Enabled = Value
		task.spawn(function()
			while Scripttable.GUI.ArenaShopTab.Enabled do
				if not Scripttable.GUI.ArenaShopTab.Enabled then
					return
				end
				Mainfunction.BuyShopItem("arenashop", "Checkbox")
				task.wait(0.1)
			end
		end)
	end,
})

Scripttable.GUI.ArenaShopTab.ArenaShopTab_ROW:Button({
  Text = "購買商品",
  Callback  = function()
    Mainfunction.BuyShopItem("arenashop")
  end,
})

Scripttable.GUI.GuildShopTab.GuildData = GuildShopContent:Label({
  Text = "公會幣: " .. GameGUITable.guildshop.GuildData.Text,
  TextSize = 16
})

-- 創建物品選擇表格
Scripttable.GUI.GuildShopTab.GuildShopTable = GuildShopContent:CollapsingHeader({
  Title = "選擇要購買的商品(可多選)",
  Collapsed = false,
  TextSize = 16
}):Table({
  MaxColumns = 2
}):NextRow()

Scripttable.GUI.GuildShopTab.ItemComponents = {}

-- 按順序創建每個物品選項
for _, key in ipairs(Scripttable.GuildItemOrder) do
  local label = Mainfunction.Translationtable(key) or key
  local column = Scripttable.GUI.GuildShopTab.GuildShopTable:NextColumn()

  local component = column:Radiobox({
    Value = Scripttable.GUI.GuildShopTab.Select[key] or false,
    Label = label,
    Callback = function(self, newValue)
      Scripttable.GUI.GuildShopTab.Select[key] = newValue
    end
  })
  Scripttable.GUI.GuildShopTab.ItemComponents[key] = component
end

GuildShopContent:Separator({
  Text = "● 功能選項",
})

Scripttable.GUI.GuildShopTab.GuildShopTab_ROW = GuildShopContent:Row()
Scripttable.GUI.GuildShopTab.GuildShopRadiobox = Scripttable.GUI.GuildShopTab.GuildShopTab_ROW :Radiobox({
  Value = false,
  Label = "購買商品",
  Callback = function(self, Value)
    if Value == true then
      Mainfunction.Buy_GuildShop_Item()
    end
  end,
})

for _, buttonText in ipairs(Scripttable.GUI.GuildShopTab.indextext) do
  Scripttable.GUI.GuildShopTab.GuildShopTab_ROW:Button({
    Text = buttonText,
    TextSize = 16,
    Callback = function()
      if buttonText == "刷新商店" then
        game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\229\133\172\228\188\154"):FindFirstChild("\229\136\183\230\150\176\229\133\172\228\188\154\229\149\134\229\186\151"):FireServer()
      elseif buttonText == "儲存" then
        Mainfunction.SaveGuildShopconfig()
      elseif buttonText == "重新加載" then
        Mainfunction.LoadGuildShopconfig()
      elseif buttonText == "刪除配置" then
        Mainfunction.DeleteGuildShopconfig()
      end
    end,
  })
end

Mainfunction.LoadGuildShopconfig() -- 嘗試載入配置
-- ========== 主循環初始化 ==========
task.spawn(function()
	while true do
		Mainfunction.GetShopData("eventshop")
		Mainfunction.GetShopData("arenashop")
		Mainfunction.Upd_Shop_Data()
		Mainfunction.Upd_Select("eventshop")
		Mainfunction.Upd_Select("arenashop")
		task.wait(1)
	end
end)

