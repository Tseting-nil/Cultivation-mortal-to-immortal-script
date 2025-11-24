-- 外部庫載入
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local Msg = loadstring(game:HttpGet('https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/1cb8f4efec92cb1735e85bb7d1d0761ec2dab685/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua'))()

-- 遊戲服務和GUI元素
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local secondGUI = PlayerGui.GUI:WaitForChild("二级界面")
local HttpService = game:GetService("HttpService")

-- 遊戲GUI元素引用表
local GameGUITable = {
  eventshop = {
    EventTitle = secondGUI:waitForChild("节日活动商店"):waitForChild("背景"):waitForChild("标题"),
    EventData = secondGUI:waitForChild("节日活动商店"):waitForChild("背景"):waitForChild("标题"):waitForChild("活动物品"):waitForChild("按钮"):waitForChild("值"),
    EventTime = secondGUI:waitForChild("节日活动商店"):waitForChild("背景"):waitForChild("倒计时"):waitForChild("文本"),
    EventList = secondGUI:waitForChild("节日活动商店"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("兑换"):waitForChild("列表")
  },
  arenashop = {
    ArenaListData = LocalPlayer:WaitForChild("值"):WaitForChild("货币"):WaitForChild("紫钻"),
    ArenaList = secondGUI:waitForChild("竞技场"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("列表"),
    ArenaTime = secondGUI:waitForChild("竞技场"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("竞技场"):waitForChild("标题"):waitForChild("倒计时"):waitForChild("名称"),
    ArenaTime2 = secondGUI:waitForChild("竞技场"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("奖励介绍"):waitForChild("倒计时"):waitForChild("文本")
  }
}

-- ========== 全域變數 ==========
local ItemSelection = {
  eventshop = {
    selectedItemKey = 0
  },
  arenashop = {
    selectedItemKey = 0
  }
}

local GUI = {
  IsLoading = true,
  EventsShop = {
    IS_EventsShopRadiobox = false,
  },
  ArenaShop = {},
  GuildShop = {
    IS_AutoBuying = false
  }
}

-- 物品映射表
local ItemMappings = {
  -- 活動商店物品名稱對照表 (遊戲內英文名稱 → 中文顯示名稱)
  nameMapping = {
    ["Ore Dungeon Keys"] = "Ore Dungeon",
    ["Gem Dungeon Keys"] = "Gem Dungeon",
    ["Rune Dungeon Keys"] = "Rune Dungeon",
    ["Relic Dungeon Keys"] = "Relic Dungeon",
    ["Gold Dungeon Keys"] = "Gold Dungeon",
    ["Hover Dungeon Keys"] = "Hover Dungeon",
    ["Gold"] = "Gold",
    ["Ore"] = "Ore",
    ["Gem"] = "Gem",
    ["Talisman Summon Ticket"] = "Weapon Ticket",
    ["Skill Summon Ticket"] = "Skill Ticket",
    ["Egg"] = "PetEgg",
    ["Soul"] = "Soul"
  },
  
  -- 活動商店商品代號映射表 (名稱 + 價格 → 對應代號)
  itemCodeMap = {
    ["Ore Dungeon"] = {["400"] = 4, ["600"] = 17},
    ["Gem Dungeon"] = {["600"] = 5, ["800"] = 18},
    ["Rune Dungeon"] = {["400"] = 6, ["600"] = 19},
    ["Relic Dungeon"] = {["400"] = 7, ["600"] = 20},
    ["Gold Dungeon"] = {["400"] = 8, ["600"] = 21},
    ["Hover Dungeon"] = {["500"] = 9, ["800"] = 22},
    ["Gold"] = {["400"] = 1, ["1200"] = 12},
    ["Ore"] = {["400"] = 2, ["900"] = 13},
    ["Gem"] = {["400"] = 3, ["800"] = 14},
    ["Weapon Ticket"] = {["400"] = 10, ["800"] = 15},
    ["Skill Ticket"] = {["400"] = 11, ["800"] = 16},
    ["PetEgg"] = {["2000"] = 23},
    ["Soul"] = {["1000"] = 24}
  },
  
  -- 活動商店物品類型範圍映射
  typeRanges = {
    Key = {{4, 9}, {17, 22}},
    Item = {{1, 3}, {10, 16}, {23, 24}}
  },
  
  -- 競技場商店物品名稱對照表
  arenaNameMapping = {
    ["OreDungeonkey"] = "OreDungeon",
    ["GemDungeonkey"] = "GemDungeon",
    ["RuneDungeonkey"] = "RuneDungeon",
    ["RelicDungeonkey"] = "RelicDungeon",
    ["GoldDungeonkey"] = "GoldDungeon",
    ["HoverDungeonkey"] = "HoverDungeon",
    ["Gold"] = "Gold",
    ["Event Item"] = "EventItem",
    ["Random World Tree Decorations"] = "WorldTreeItem",
    ["Water of Life"] = "WaterOfLife",
    ["Soul"] = "Soul"
  },
  
  -- 競技場商店商品映射 (名稱 + 價格 → 對應代號)
  arenaItemCodeMap = {
    ["OreDungeon"] = {["300"] = 5},
    ["GemDungeon"] = {["300"] = 6},
    ["RuneDungeon"] = {["300"] = 7},
    ["RelicDungeon"] = {["300"] = 8},
    ["GoldDungeon"] = {["300"] = 9},
    ["HoverDungeon"] = {["300"] = 10},
    ["Soul"] = {["500"] = 11},
    ["Gold"] = {["200"] = 1},
    ["EventItem"] = {["300"] = 2},
    ["WorldTreeItem"] = {["400"] = 3},
    ["WaterOfLife"] = {["300"] = 4}
  },
  
  -- 競技場商店物品類型範圍
  arenaTypeRanges = {
    Key = {{5, 10}},
    Item = {{1, 4}, {11, 11}}
  }
}

-- 輔助函數
-- 轉換縮寫數字 (K/M/B/T)
local function ConvertAbbreviatedNumber(str)
  local num, suffix = string.match(str, "(%d+%.?%d*)(%a*)")
  num = tonumber(num)
  if not num then return 0 end
  
  suffix = suffix:upper()
  if suffix == "K" then
    num = num * 1e3
  elseif suffix == "M" then
    num = num * 1e6
  elseif suffix == "B" then
    num = num * 1e9
  elseif suffix == "T" then
    num = num * 1e12
  end
  return num
end

-- 安全執行函數，避免錯誤中斷程式
local function SafeExecute(func, ...)
  local success, result = pcall(func, ...)
  if not success then
    warn("Function execution error: " .. tostring(result))
    return false
  end
  return true, result
end

-- 活動商店功能模組
local EventShopModule = {}

-- 購買活動商店物品
function EventShopModule.BuyItem()
  local selectedKey = ItemSelection.eventshop.selectedItemKey
  local eventdata = ConvertAbbreviatedNumber(GameGUITable.eventshop.EventData.Text)
  
  -- 檢查是否選擇商品
  if selectedKey == 0 then
    Msg:Error("No item selected", 2)
    print("No item selected".. selectedKey)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  -- 獲取選中商品的詳細資訊
  local eventList = GameGUITable.eventshop.EventList
  local itemElement = eventList:FindFirstChild("eventcommodity" .. tostring(selectedKey))
  
  if not itemElement then
    Msg:Error("Item information not found", 2)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  local button = itemElement:FindFirstChild("按钮")
  if not button then
    Msg:Error("Item button does not exist", 2)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  -- 檢查庫存
  local stockText = button:WaitForChild("库存").Text
  local stock = string.gsub(stockText, "Left", "")
  stock = tonumber(stock)
  if not stock or stock <= 0 then
    Msg:Error("Item out of stock", 2)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  -- 檢查金額
  local priceText = button:WaitForChild("价格").Text
  local price = ConvertAbbreviatedNumber(priceText)
  
  if not price or price <= 0 then
    Msg:Error("Unable to get item price", 2)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  if not eventdata or eventdata < price then
    Msg:Error("Insufficient event items (Required: " .. priceText .. " | Owned: " .. GameGUITable.eventshop.EventData.Text .. ")", 3)
    GUI.EventsShop.EventsShopRadiobox:SetValue(false)
    GUI.EventsShop.IS_EventsShopRadiobox = false
    return
  end
  
  -- 執行購買
  local args = {[1] = selectedKey}
  game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\232\138\130\230\151\165\230\180\187\229\138\168"):FindFirstChild("\232\180\173\228\185\176"):FireServer(unpack(args))
end

-- 更新活動商店標籤
function EventShopModule.UpdateLabel()
  local selectedKey = ItemSelection.eventshop.selectedItemKey
  
  if selectedKey ~= 0 then
    local itemNames = {
      [1] = "Gold", [12] = "Gold",
      [2] = "Ore", [13] = "Ore", 
      [3] = "Gem", [14] = "Gem",
      [4] = "Ore Dungeon", [17] = "Ore Dungeon",
      [5] = "Gem Dungeon", [18] = "Gem Dungeon",
      [6] = "Rune Dungeon", [19] = "Rune Dungeon",
      [7] = "Relic Dungeon", [20] = "Relic Dungeon",
      [8] = "Gold Dungeon", [21] = "Gold Dungeon",
      [9] = "Hover Dungeon", [22] = "Hover Dungeon",
      [10] = "Weapon Ticket", [15] = "Weapon Ticket",
      [11] = "Skill Ticket", [16] = "Skill Ticket",
      [23] = "PetEgg",
      [24] = "Soul"
    }
    
    local name = itemNames[selectedKey] or "Unknown Item"
    local eventList = GameGUITable.eventshop.EventList
    local itemElement = eventList:waitForChild("eventcommodity" .. tostring(selectedKey))
    
    if itemElement then
      local button = itemElement:waitForChild("按钮")
      local stock = string.gsub(button:WaitForChild("库存").Text, "%D", "")
      stock = string.gsub(stock, "Left", "")
      
      local price = button:waitForChild("价格").Text
      EventShopModule.SelectItem(name, stock, price)
    end
  end
end

-- 更新活動物品顯示
function EventShopModule.UpdateCurrency()
  local items = GameGUITable.eventshop.EventData.Text
  GUI.EventsShop.EventItem.Text = "Event Items: " .. items
end

-- 選擇商品
function EventShopModule.SelectItem(name, stock, price)
  if stock == "0" or stock == "00" then
    GUI.EventsShop.ChoosenItem_Label.Text = "Item: " .. name .. " | Out of Stock"
    ItemSelection.eventshop.selectedItemKey = 0
    return
  end

  GUI.EventsShop.ChoosenItem_Label.Text = "Item: " .. name .. " | Stock:" .. stock .. " | Price:" .. price
  --name = string.gsub(name, "%s+", "")
    
  -- 使用映射表查找商品代號
  local itemCodeMap = ItemMappings.itemCodeMap
  if itemCodeMap[name] and itemCodeMap[name][price] then
    ItemSelection.eventshop.selectedItemKey = itemCodeMap[name][price]
  else
    print("無法識別的物品:", name, price)
    ItemSelection.eventshop.selectedItemKey = 0
  end
end

-- 更新所有活動商店物品資訊
function EventShopModule.UpdateItems()
  local items = {}
  local eventList = GameGUITable.eventshop.EventList
  local counter = 1
  
  for _, item in pairs(eventList:GetChildren()) do
    if item:IsA("Frame") then
      local button = item:FindFirstChild("按钮")
      if button then
        local stockText = string.gsub(button:WaitForChild("库存").Text, "%D", "")
        local priceText = string.gsub(button:WaitForChild("价格").Text, "[^%d.]", "")
        local name = button:WaitForChild("名称").Text
        
        items["eventcommodity" .. counter] = {
          Name = name,
          Stock = tonumber(stockText) or 0,
          Price = priceText
        }
        counter = counter + 1
      end
    end
  end
  return items
end

-- 獲取指定類型的商品列表
function EventShopModule.GetItemsByType(itemtype)
  local items = EventShopModule.UpdateItems()
  local selected_items = {}
  
  local ranges = ItemMappings.typeRanges[itemtype]
  if ranges then
    for _, range in ipairs(ranges) do
      for i = range[1], range[2] do
        local item = items["eventcommodity" .. i]
        if item then
          local displayName = ItemMappings.nameMapping[item.Name] or item.Name
          local display = string.format("%s | Stock:%02d | Cost:%s", displayName, item.Stock, item.Price)
          table.insert(selected_items, display)
        end
      end
    end
  end
  return selected_items
end

-- 刷新活動商店時間顯示
function EventShopModule.RefreshTime()
  local time_str = GameGUITable.eventshop.EventTime.Text
  
  -- 特別處理：如果等於 "Time Left: 23:59:59"
  if time_str == "Time Left: 23:59:59" then
    return " Not Retrieved"
  end
  
  -- 嘗試匹配完整格式："Time Left: X days, Y hours"
  local days, hours = string.match(time_str, "Time Left: (%d+) days?, (%d+) hours?")
  if days then
    days, hours = tonumber(days), tonumber(hours)
    if hours == 0 then
      return days .. " Days"
    elseif days == 0 then
      return hours .. " Hours"
    else
      return days .. " Days " .. hours .. " Hours"
    end
  end
  
  -- 嘗試匹配新格式："Time Left: HH:MM:SS"
  local minutes
  hours, minutes = string.match(time_str, "Time Left: (%d+):(%d+):%d+")
  if hours then
    hours, minutes = tonumber(hours), tonumber(minutes)
    if hours == 0 then
      return minutes .. " Minutes"
    elseif minutes == 0 then
      return hours .. " Hours"
    else
      return hours .. " Hours " .. minutes .. " Minutes"
    end
  end
  
  return " Not Retrieved"
end

-- 競技場商店功能模組
local ArenaShopModule = {}

-- 購買競技場商店物品
function ArenaShopModule.BuyItem()
  local selectedKey = ItemSelection.arenashop.selectedItemKey
  
  if selectedKey == 0 then
    Msg:Error("No item selected", 2)
    return
  end
  
  print("Executing purchase - Item code:", selectedKey)
  local args = {[1] = selectedKey}
  
  game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\231\171\158\230\138\128\229\156\186"):FindFirstChild("\232\180\173\228\185\176"):FireServer(unpack(args))
  
  Msg:Success("Purchase command sent", 2)
end

-- 更新競技場商店標籤顯示
function ArenaShopModule.UpdateLabel()
  local selectedKey = ItemSelection.arenashop.selectedItemKey
  
  if selectedKey ~= 0 then
    local itemNames = {
      [1] = "Gold",
      [2] = "Event Item", 
      [3] = "World Tree Item",
      [4] = "Water of Life",
      [5] = "Ore Dungeon",
      [6] = "Gem Dungeon",
      [7] = "Rune Dungeon",
      [8] = "Relic Dungeon",
      [9] = "Gold Dungeon",
      [10] = "Hover Dungeon",
      [11] = "Soul"
    }
    
    local name = itemNames[selectedKey] or "Unknown Item"
    local arenaList = GameGUITable.arenashop.ArenaList
    
    -- 需要遍歷競技場商店找到對應的商品元素
    local foundItem = false
    for _, item in pairs(arenaList:GetChildren()) do
      if item:IsA("Frame") then
        local button = item:FindFirstChild("按钮")
        if button then
          local itemName = button:FindFirstChild("名称")
          if itemName then
            local displayName = ItemMappings.arenaNameMapping[itemName.Text] or ItemMappings.nameMapping[itemName.Text] or itemName.Text
            
            -- 檢查是否為當前選中的商品
            if displayName == name then
              local stockText = button:WaitForChild("库存").Text
              -- 處理庫存文字，移除 "Left" 等文字，只保留數字
              local cleanStock = string.gsub(stockText, "Left", "")
              local stock = string.gsub(cleanStock, "%D", "")
              local price = button:waitForChild("价格").Text
              ArenaShopModule.SelectItem(displayName, stock, price)
              foundItem = true
              break
            end
          end
        end
      end
    end
    
    if not foundItem then
      GUI.ArenaShop.ChoosenItem_Label.Text = "Item: " .. name .. " | Item not found"
    end
  else
    GUI.ArenaShop.ChoosenItem_Label.Text = "Item: None Selected"
  end
end

-- 更新競技場貨幣顯示
function ArenaShopModule.UpdateCurrency()
  local currency = GameGUITable.arenashop.ArenaListData.Value
  GUI.ArenaShop.ArenaItem.Text = "Purple Diamonds: " .. currency
end

-- 選擇競技場商品
function ArenaShopModule.SelectItem(name, stock, price)
  if stock == "0" or stock == "00" then
    GUI.ArenaShop.ChoosenItem_Label.Text = "Item: " .. name .. " | Out of Stock"
    ItemSelection.arenashop.selectedItemKey = 0
    return
  end

  GUI.ArenaShop.ChoosenItem_Label.Text = "Item: " .. name .. " | Stock:" .. stock .. " | Price:" .. price
  
  -- 轉換名稱
  local chineseName = ItemMappings.arenaNameMapping[name] or ItemMappings.nameMapping[name] or name
  local itemCodeMap = ItemMappings.arenaItemCodeMap
  
  -- 根據名稱和價格查找商品代號
  if itemCodeMap[chineseName] and itemCodeMap[chineseName][price] then
    ItemSelection.arenashop.selectedItemKey = itemCodeMap[chineseName][price]
    print(string.format("Match success (display name): %s → code:%d", chineseName, ItemSelection.arenashop.selectedItemKey))
  elseif itemCodeMap[name] and itemCodeMap[name][price] then
    ItemSelection.arenashop.selectedItemKey = itemCodeMap[name][price]
    print(string.format("Match success (original name): %s → code:%d", name, ItemSelection.arenashop.selectedItemKey))
  else
    print("Unrecognized item:", name, "Display name:", chineseName, "Price:", price)
    ItemSelection.arenashop.selectedItemKey = 0
  end
end

-- 更新所有競技場商店物品資訊
function ArenaShopModule.UpdateItems()
  local items = {}
  local arenaList = GameGUITable.arenashop.ArenaList
  local counter = 1
  
  for _, item in pairs(arenaList:GetChildren()) do
    if item:IsA("Frame") then
      local button = item:FindFirstChild("按钮")
      if button then
        local stockText = button:WaitForChild("库存").Text
        local priceText = button:WaitForChild("价格").Text
        local name = button:WaitForChild("名称").Text
        
        -- 處理庫存文字，移除 "Left" 等文字，只保留數字
        local cleanStock = string.gsub(stockText, "Left", "")
        cleanStock = string.gsub(cleanStock, "%D", "")
        
        items["item" .. counter] = {
          Name = name,
          Stock = tonumber(cleanStock) or 0,
          Price = priceText
        }
        counter = counter + 1
      end
    end
  end
  return items
end

-- 獲取競技場商店指定類型物品
function ArenaShopModule.GetItemsByType(itemtype)
  local items = ArenaShopModule.UpdateItems()
  local selected_items = {}
  
  local ranges = ItemMappings.arenaTypeRanges[itemtype]
  if ranges then
    for _, range in ipairs(ranges) do
      for i = range[1], range[2] do
        local item = items["item" .. i]
        if item then
          local displayName = ItemMappings.arenaNameMapping[item.Name] or ItemMappings.nameMapping[item.Name] or item.Name
          local display = string.format("%s | Stock:%02d | Cost:%s", displayName, item.Stock, item.Price)
          table.insert(selected_items, display)
        end
      end
    end
  end
  return selected_items
end

-- 刷新競技場商店時間顯示
function ArenaShopModule.RefreshTime()
  local dailyTime = GameGUITable.arenashop.ArenaTime.Text or "Not Retrieved"
  local weeklyTime = GameGUITable.arenashop.ArenaTime2.Text or "Not Retrieved"
  return "Daily: " .. dailyTime .. " | Weekly: " .. weeklyTime
end

-- ========== GUI 介面創建 ==========
-- 主視窗建立
local Window = ReGui:TabsWindow({
  Title = "Item Purchase Script",
  Size = UDim2.fromOffset(430, 320)
})

-- 創建頁籤
local EventShopTab = Window:CreateTab({
  Name = "Event Shop",
  TextSize = 18
})
local ArenaShopTab = Window:CreateTab({
  Name = "Arena Shop", 
  TextSize = 18
})
local GuildShopTab = Window:CreateTab({
  Name = "Guild Shop",
  TextSize = 18
})

-- 創建頁面內容容器
local EventsShopContent = EventShopTab:ScrollingCanvas({
  Fill = true,
  UiPadding = UDim.new(0, 0)
})
local ArenaShopContent = ArenaShopTab:ScrollingCanvas({
  Fill = true,
  UiPadding = UDim.new(0, 0)
})
local GuildShopContent = GuildShopTab:ScrollingCanvas({
  Fill = true,
  UiPadding = UDim.new(0, 0)
})

-- 設定頁籤字體大小
spawn(function()
  task.wait(0.1)
  local tabs = {EventShopTab, ArenaShopTab, GuildShopTab}
  for _, tab in ipairs(tabs) do
    local label = tab.TabButton.Button:FindFirstChildOfClass("TextLabel")
    if label then label.TextSize = 18 end
  end
end)

-- ========== 活動商店頁面 UI 元件 ==========
GUI.EventsShop.RefreshTime_Label = EventsShopContent:Label({
  Text = "Time Left: Not Retrieved",
  TextColor3 = ReGui.Accent.Yellow,
  TextSize = 16
})

GUI.EventsShop.ChoosenItem_Label = EventsShopContent:Label({
  Text = "Item: None Selected",
  TextSize = 16
})

GUI.EventsShop.EventItem = EventsShopContent:Label({
  Text = "Event Items: " .. GameGUITable.eventshop.EventData.Text,
  TextSize = 16
})

GUI.EventsShop.EventsShop_Key_Combo = EventsShopContent:Combo({
  Label = "(Keys)",
  GetItems = function()
    return EventShopModule.GetItemsByType("Key")
  end,
  Callback = function(selected)
    if GUI.IsLoading then return end
    local text = tostring(type(selected) == "table" and (selected.Value or selected.Label) or selected)
    GUI.EventsShop.ChoosenItem_Label.Text = "Item: " .. text
    local name, stock, price = string.match(text, "^(.-) | Stock:(%d+) | Cost:(%d+)")
    if name and price then
      EventShopModule.SelectItem(name, stock, price)
    end
  end
})

GUI.EventsShop.EventsShop_Item_Combo = EventsShopContent:Combo({
  Label = "(Items)",
  GetItems = function()
    return EventShopModule.GetItemsByType("Item")
  end,
  Callback = function(selected)
    if GUI.IsLoading then return end
    local text = tostring(type(selected) == "table" and (selected.Value or selected.Label) or selected)
    GUI.EventsShop.ChoosenItem_Label.Text = "Item: " .. text
    local name, stock, price = string.match(text, "^(.-) | Stock:(%d+) | Cost:(%d+)")
    if name and price then
      EventShopModule.SelectItem(name, stock, price)
    end
  end
})

EventsShopContent:Separator({
  Text = "● Functions"
})

GUI.EventsShop.EventsShopContent = EventsShopContent:Row()
GUI.EventsShop.EventsShopRadiobox = GUI.EventsShop.EventsShopContent:Radiobox({
  Value = false,
  Label = "Buy Items",
  Callback = function(self, Value)
    if GUI.IsLoading then return end
    GUI.EventsShop.IS_EventsShopRadiobox = Value
    
    if Value then
      while GUI.EventsShop.IS_EventsShopRadiobox do
        EventShopModule.BuyItem()
        task.wait(0.3)
      end
    end
  end
})
-- 活動商店功能按鈕
local eventShopButtons = {"Refresh Time", "Buy Item"}
for _, buttonText in ipairs(eventShopButtons) do
  GUI.EventsShop.EventsShopContent:Button({
    Text = buttonText,
    TextSize = 16,
    Callback = function()
      if GUI.IsLoading then return end
      
      if buttonText == "Refresh Time" then
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local event = replicatedStorage:FindFirstChild("打开节日商店", true)
        if event then
          event:Fire("打开节日商店")
          task.wait(0.1)
          GUI.EventsShop.RefreshTime_Label.Text = "Time Left: " .. EventShopModule.RefreshTime()
        end
      elseif buttonText == "Buy Item" then
        EventShopModule.BuyItem()
      end
    end
  })
end

-- ========== 競技場商店頁面 UI 元件 ==========
GUI.ArenaShop.ChoosenItem_Label = ArenaShopContent:Label({
  Text = "Item: None Selected",
  TextSize = 16
})

GUI.ArenaShop.ArenaItem = ArenaShopContent:Label({
  Text = "Arena Currency: " .. GameGUITable.arenashop.ArenaListData.Value,
  TextSize = 16
})

GUI.ArenaShop.ArenaShop_Key_Combo = ArenaShopContent:Combo({
  Label = "(Keys)",
  GetItems = function()
    return ArenaShopModule.GetItemsByType("Key")
  end,
  Callback = function(selected)
    if GUI.IsLoading then return end
    
    local text = tostring(type(selected) == "table" and (selected.Value or selected.Label) or selected)
    GUI.ArenaShop.ChoosenItem_Label.Text = "Item: " .. text
    
    local name, stock, price = string.match(text, "^(.-) | Stock:(%d+) | Cost:(%d+)")
    if name and price then
      ArenaShopModule.SelectItem(name, stock, price)
    end
  end
})

GUI.ArenaShop.ArenaShop_Item_Combo = ArenaShopContent:Combo({
  Label = "(Items)",
  GetItems = function()
    return ArenaShopModule.GetItemsByType("Item")
  end,
  Callback = function(selected)
    if GUI.IsLoading then return end
    
    local text = tostring(type(selected) == "table" and (selected.Value or selected.Label) or selected)
    GUI.ArenaShop.ChoosenItem_Label.Text = "Item: " .. text
    
    local name, stock, price = string.match(text, "^(.-) | Stock:(%d+) | Cost:(%d+)")
    if name and price then
      ArenaShopModule.SelectItem(name, stock, price)
    end
  end
})

-- 競技場商店購買按鈕
GUI.ArenaShop.ArenaShopBuyButton = ArenaShopContent:Button({
  Name = "ArenaBuyButton",
  Text = "Buy Item",
  TextSize = 16,
  Callback = function()
    ArenaShopModule.BuyItem()
  end
})

-- 公會商店功能模組
local GuildShopModule = {}

-- 公會商店設定檔案名稱
local guildShopSaveFilename = "Tsetingnil_script/Cultivation/Shop_cfg.json"

-- 擴展遊戲GUI元素引用表，添加公會商店
GameGUITable.guildshop = {
  GuildCurrency = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("公会币"):waitForChild("按钮"):waitForChild("值"),
  GuildItemList = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("列表"),
  GuildShopRefining = secondGUI:waitForChild("公会"):waitForChild("背景"):waitForChild("右侧界面"):waitForChild("商店"):waitForChild("刷新"):waitForChild("按钮"):waitForChild("值")
}

-- 公會商店選擇狀態
local GuildShopSelection = {
  Weaponscroll = false,
  Skillscroll = false,
  Drug = false,
  Herbs = false,
  Gem = false,
  Gold = false,
  GemDungeonkey = false,
  OreDungeonkey = false,
  GoldDungeonkey = false,
  HoverDungeonkey = false
}

-- 提前載入公會商店設定（在UI創建之前）
local function PreLoadGuildShopSettings()
  if isfile(guildShopSaveFilename) then
    local success, result = pcall(function()
      local json = readfile(guildShopSaveFilename)
      local loaded = HttpService:JSONDecode(json)
      
      -- 檢查版本兼容性
      local settings = loaded.settings or loaded -- 向下兼容舊版本
      
      -- 載入每個設定項目
      for key, value in pairs(settings) do
        if GuildShopSelection[key] ~= nil then
          GuildShopSelection[key] = value
        end
      end
      
      print("[Pre-load Success] Guild shop settings loaded：" .. guildShopSaveFilename)
      return true
    end)
    
    if not success then
      warn("[Pre-load Failed] Error：", result)
    end
    return success
  else
    print("[Pre-load] Settings file does not exist, using default settings")
    return false
  end
end

-- 執行提前載入
PreLoadGuildShopSettings()

-- 公會商店物品名稱映射
local GuildItemNameMap = {
  Weaponscroll = "Weapon Scroll",
  Skillscroll = "Skill Scroll",
  Drug = "Elixir",
  Herbs = "Herbs",
  Gem = "Gems",
  Gold = "Gold",
  GemDungeonkey = "Gem Dungeon Key",
  OreDungeonkey = "Ore Dungeon Key",
  GoldDungeonkey = "Gold Dungeon Key",
  HoverDungeonkey = "Hover Dungeon Key"
}

-- 公會商店物品順序
local GuildItemOrder = {
  "Weaponscroll", "Skillscroll", "Drug", "Herbs", "Gem", "Gold",
  "GemDungeonkey", "OreDungeonkey", "GoldDungeonkey", "HoverDungeonkey"
}

-- 公會商店設定儲存功能
function GuildShopModule.SaveSettings()
  local toSave = {
    settings = GuildShopSelection,
  }
  
  local success, result = pcall(function()
    local json = HttpService:JSONEncode(toSave)
    writefile(guildShopSaveFilename, json)
  end)
  
  if success then
    print("[Save Success] Guild shop settings saved to：" .. guildShopSaveFilename)
    return true
  else
    warn("[Save Failed] Error：", result)
    return false
  end
end

function GuildShopModule.CreateDefaultSettings()
  print("[Initialize] Guild shop settings file not found, creating default settings...")
  
  -- 重置為預設值
  for key, _ in pairs(GuildShopSelection) do
    GuildShopSelection[key] = false
  end
  
  -- 儲存預設設定
  if GuildShopModule.SaveSettings() then
    print("[Initialize Success] Default guild shop settings file created")
    return true
  else
    warn("[Initialize Failed] Unable to create default guild shop settings file")
    return false
  end
end

function GuildShopModule.LoadSettings()
  -- 如果檔案存在，載入設定
  if isfile(guildShopSaveFilename) then
    local success, result = pcall(function()
      local json = readfile(guildShopSaveFilename)
      local loaded = HttpService:JSONDecode(json)
      
      -- 檢查版本兼容性
      local settings = loaded.settings or loaded -- 向下兼容舊版本
      
      -- 載入每個設定項目
      for key, value in pairs(settings) do
        if GuildShopSelection[key] ~= nil then
          GuildShopSelection[key] = value
        end
      end
      
      -- 確保所有鍵都存在（防止新增項目時出錯）
      for key, _ in pairs(GuildShopSelection) do
        if settings[key] == nil then
          GuildShopSelection[key] = false
        end
      end
    end)
    
    if success then
      print("[Load Success] Guild shop settings file loaded：" .. guildShopSaveFilename)
      return true
    else
      warn("[Load Failed] Error：", result)
      -- 載入失敗時創建默認設定
      return GuildShopModule.CreateDefaultSettings()
    end
  else
    -- 檔案不存在，創建默認設定
    return GuildShopModule.CreateDefaultSettings()
  end
end

-- 更新UI狀態（同步儲存的設定到UI）
function GuildShopModule.UpdateUIFromSettings()
  -- 增加延遲確保UI元件完全創建
  task.wait(0.2)
  
  for key, component in pairs(GUI.GuildShop.ItemComponents) do
    if component and GuildShopSelection[key] ~= nil then
      component.Value = GuildShopSelection[key]
      print(string.format("[UI Sync] %s = %s", key, tostring(GuildShopSelection[key])))
    else
      warn(string.format("[UI Sync Failed] Component not found: %s", key))
    end
  end
  
  print("[UI Sync Complete] All guild shop settings synced to UI")
end

-- 購買公會商店物品
function GuildShopModule.BuyItems(itemIndex)
  if itemIndex == "Refining" then
    game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\229\133\172\228\188\154"):FindFirstChild("\229\136\183\230\150\176\229\133\172\228\188\154\229\149\134\229\186\151"):FireServer()
    return
  end
  
  local args = {[1] = itemIndex}
  game:GetService("ReplicatedStorage"):FindFirstChild("\228\186\139\228\187\182"):FindFirstChild("\229\133\172\231\148\168"):FindFirstChild("\229\133\172\228\188\154"):FindFirstChild("\229\133\145\230\141\162"):FireServer(unpack(args))
end

-- 自動購買邏輯
function GuildShopModule.AutoBuy()
  -- 檢查是否有公會
  if LocalPlayer:FindFirstChild("值"):FindFirstChild("信息"):FindFirstChild("公会战斗力").Value == 0 then
    Msg:Error("No Guild", 2)
    GUI.GuildShop.IS_AutoBuying = false
    GUI.GuildShop.AutoBuyToggle:SetValue(false)
    return
  end
  local guildItemList = GameGUITable.guildshop.GuildItemList
  local guildCurrency = tonumber(GameGUITable.guildshop.GuildCurrency.Text) or 0
  
  for i = 1, 25 do
    local item = guildItemList:FindFirstChild("Guildshopitem" .. i)
    if not item or not item.Visible then
      break
    end
    
    local button = item:FindFirstChild("按钮")
    if button then
      local itemName = button:FindFirstChild("名称").Text
      local purchaseConfirmation = button:FindFirstChild("蒙版")
      local itemPrice = tonumber(button:FindFirstChild("价格").Text) or 0
      
      if not purchaseConfirmation.Visible and guildCurrency >= itemPrice then
        local function canBuy(condition, logMessage)
          if condition then
            print(logMessage)
            GuildShopModule.BuyItems(i)
            task.wait(0.1)
            return true
          end
          return false
        end
        
        canBuy(itemName == "Gold Dungeon Keys" and GuildShopSelection.GoldDungeonkey, "Buying Gold Dungeon Keys")
        canBuy(itemName == "Ore Dungeon Keys" and GuildShopSelection.OreDungeonkey, "Buying Ore Dungeon Keys")
        canBuy(itemName == "Gem Dungeon Keys" and GuildShopSelection.GemDungeonkey, "Buying Gem Dungeon Keys")
        canBuy(itemName == "Hover Dungeon Keys" and GuildShopSelection.HoverDungeonkey, "Buying Hover Dungeon Keys")
        canBuy(itemName == "Gold" and GuildShopSelection.Gold, "Buying Gold")
        canBuy(itemName == "Gem" and GuildShopSelection.Gem, "Buying Gems")
        canBuy(itemName == "Herb" and GuildShopSelection.Herbs, "Buying Herbs")
        canBuy(itemName == "Elixir" and GuildShopSelection.Drug, "Buying Elixir")
        canBuy(itemName == "Skill Scroll" and GuildShopSelection.Skillscroll, "Buying Skill Scroll")
        canBuy(itemName == "Weapon Scroll" and GuildShopSelection.Weaponscroll, "Buying Weapon Scroll")
      end
    end
  end
end

-- 更新公會貨幣顯示
function GuildShopModule.UpdateCurrency()
  local currency = GameGUITable.guildshop.GuildCurrency.Text
  GUI.GuildShop.GuildCurrency.Text = "Guild Coins: " .. currency
end

-- ========== 公會商店頁面 UI 元件 ==========
GUI.GuildShop.GuildCurrency = GuildShopContent:Label({
  Text = "Guild Coins: " .. GameGUITable.guildshop.GuildCurrency.Text,
  TextSize = 16
})

-- 創建物品選擇表格
local GuildShopTable = GuildShopContent:CollapsingHeader({
  Title = "Select Items to Purchase (Multiple Selection)",
  TextSize = 16
}):Table({
  MaxColumns = 2
}):NextRow()

-- 儲存UI元件引用
GUI.GuildShop.ItemComponents = {}

-- 按順序創建每個物品選項
for _, key in ipairs(GuildItemOrder) do
  local label = GuildItemNameMap[key] or key
  local column = GuildShopTable:NextColumn()
  
  local component = column:Radiobox({
    Value = GuildShopSelection[key],
    Label = label,
    Callback = function(self, newValue)
      GuildShopSelection[key] = newValue
      print(string.format("[State Change] %s = %s", label, tostring(newValue)))
      -- 自動儲存設定（可選）
      -- GuildShopModule.SaveSettings()
    end
  })
  
  GUI.GuildShop.ItemComponents[key] = component
end

GuildShopContent:Separator({
  Text = "● Functions"
})

-- 自動購買開關
GUI.GuildShop.AutoBuyToggle = GuildShopContent:Radiobox({
  Value = false,
  Label = "Start Auto Purchase",
  Callback = function(self, Value)
    if GUI.IsLoading then return end
    GUI.GuildShop.IS_AutoBuying = Value
    
    if Value then
      spawn(function()
        while GUI.GuildShop.IS_AutoBuying do
          SafeExecute(GuildShopModule.AutoBuy)
          task.wait(0.5)
        end
      end)
    end
  end
})

-- 功能按鈕
GUI.GuildShop.ButtonRow = GuildShopContent:Row()

for i, buttonText in ipairs({"Refresh Shop", "Save Settings" , "Reload Settings"}) do
  GUI.GuildShop.ButtonRow:Button({
    Text = buttonText,
    TextSize = 14,
    Callback = function()
      if buttonText == "Refresh Shop" then
        GuildShopModule.BuyItems("Refining")
        Msg:Success("Shop Refreshed", 2)
      elseif buttonText == "Save Settings" then
        GuildShopModule.SaveSettings()
      elseif buttonText == "Reload Settings" then
        GuildShopModule.LoadSettings()
      end
    end
  })
end

-- ========== 主循環初始化 ==========
spawn(function()
  task.wait(0.1)
  
  -- 顯示載入完成通知
  Msg:Success("Script Loaded", 2)
  GUI.IsLoading = false
  
  -- 等待UI完全創建後再同步設定
  task.wait(0.5)
  
  -- 同步載入的設定到UI
  spawn(function()
    GuildShopModule.UpdateUIFromSettings()
  end)
  
  -- 主更新循環
  while true do
    -- 活動商店更新
    SafeExecute(EventShopModule.UpdateLabel)
    SafeExecute(EventShopModule.UpdateCurrency)
    
    -- 競技場商店更新
    SafeExecute(ArenaShopModule.UpdateLabel)
    SafeExecute(ArenaShopModule.UpdateCurrency)
    
    -- 公會商店更新
    SafeExecute(GuildShopModule.UpdateCurrency)
    
    wait(0.5)
  end
end)