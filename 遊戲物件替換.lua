-- ========================================================================== --
-- 遊戲物件替換
-- 功能：初始化時批量重命名 UI 物件，使其更容易被程式碼引用
-- ========================================================================== --

local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local secondscreen = playerGui.GUI:FindFirstChild("二级界面")

-- ========================================================================== --
-- 側邊通知模組
-- ========================================================================== --
if not getgenv().NotificationModule then
	loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/00001d614d928fc5dafce59133a012dd78419afd/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua"))()
end
local Msg = getgenv().NotificationModule

-- ========================================================================== --
-- ThreadManager - 多線程同步管理器
-- ========================================================================== --
local ThreadManager = {
	activeCount = 0,
	totalTasks = 0,
	completedTasks = 0,
	failedTasks = 0,
	startTime = 0
}

function ThreadManager:init()
	self.activeCount = 0
	self.totalTasks = 0
	self.completedTasks = 0
	self.failedTasks = 0
	self.startTime = tick()
end

function ThreadManager:spawn(taskName, fn)
	self.totalTasks = self.totalTasks + 1
	self.activeCount = self.activeCount + 1
	task.spawn(function()
		local success, err = pcall(fn)
		if success then
			self.completedTasks = self.completedTasks + 1
    -- 成功時不輸出
		else
			self.failedTasks = self.failedTasks + 1
			Msg:Error("物件替換", taskName .. " 失敗: " .. tostring(err))
			warn("[物件替換] " .. taskName .. " 失敗: " .. tostring(err))
		end
		self.activeCount = self.activeCount - 1
	end)
end

function ThreadManager:waitForAll()
    -- 等待中不輸出
	while self.activeCount > 0 do
		task.wait(0.1)
	end
	local elapsed = tick() - self.startTime
	if self.failedTasks > 0 then
		local msg = string.format("完成 - 成功: %d, 失敗: %d", self.completedTasks, self.failedTasks)
		Msg:Warn("物件替換", msg)
		warn("[物件替換] " .. msg)
	end
end

-- ========================================================================== --
-- NameProcessor - 統一名稱處理器
-- ========================================================================== --
local NameProcessor = {}

-- 安全的深度路徑查找
function NameProcessor.findPath(root, pathArray)
	local current = root
	for _, name in ipairs(pathArray) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

-- 模式: SIMPLE (純數字), PREFIX (前綴+數字), TEXT (從子物件取文本)
function NameProcessor.process(config)
	local parent = config.parent
	if not parent then
		return 0
	end
	local processed = 0
	local mode = config.mode or "SIMPLE"
	local target = config.target
	local prefix = config.prefix
	local maxCount = config.maxCount
	local textChild = config.textChild  -- TEXT 模式用
    
    -- 第一階段：批量處理已存在的物件
	local batch = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == target then
			table.insert(batch, child)
		end
	end
	for _, child in ipairs(batch) do
		local newName = nil
		if mode == "TEXT" and textChild then
			local nameObj = child:FindFirstChild(textChild)
			if nameObj and nameObj.Text then
				newName = string.gsub(nameObj.Text, "%s+", "")
			end
		else
			processed = processed + 1
			newName = prefix and (prefix .. processed) or tostring(processed)
		end
		if newName and newName ~= "" then
			child.Name = newName
			if mode == "TEXT" then
				processed = processed + 1
			end
		end
	end
    
    -- 第二階段：等待動態生成的物件 (如指定了 maxCount)
	if maxCount and processed < maxCount then
		local attempts, maxAttempts = 0, 50
		while processed < maxCount and attempts < maxAttempts do
			local item = parent:FindFirstChild(target)
			if item then
				processed = processed + 1
				item.Name = prefix and (prefix .. processed) or tostring(processed)
			else
				attempts = attempts + 1
				if attempts % 5 == 0 then
					RunService.Heartbeat:Wait()
				end
			end
		end
	end
	return processed
end

-- 雙層結構處理 (寵物背包專用)
function NameProcessor.processNested(config)
	local parent = config.parent
	if not parent then
		return 0, 0
	end
	local frameName = config.frameName
	local childName = config.childName
	local framePrefix = config.framePrefix or "Frame"
	local childPrefix = config.childPrefix or "Item"
	local frameCount, childCount = 0, 0
    
    -- 處理框架的輔助函數
	local function setupFrame(frame, frameIndex)
		frame.Name = framePrefix .. frameIndex
		local itemCount = 0
        
        -- 處理現有子物件
		for _, child in ipairs(frame:GetChildren()) do
			if child.Name == childName then
				itemCount = itemCount + 1
				child.Name = childPrefix .. itemCount
				childCount = childCount + 1
			end
		end
        
        -- 監聽新增子物件
		frame.ChildAdded:Connect(function(child)
			if child.Name == childName then
				itemCount = itemCount + 1
				child.Name = childPrefix .. itemCount
			end
		end)
	end
    
    -- 處理已存在的框架
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == frameName then
			frameCount = frameCount + 1
			setupFrame(child, frameCount)
		end
	end
    
    -- 監聽新框架
	parent.ChildAdded:Connect(function(child)
		if child.Name == frameName then
			frameCount = frameCount + 1
			setupFrame(child, frameCount)
		end
	end)
	return frameCount, childCount
end

-- ========================================================================== --
-- TaskConfig - 任務配置表
-- ========================================================================== --
--[[
	輸入範本:
	
	fixed (固定數量任務):
	{
		name = "任務名稱",                    -- 識別名稱 (調試用)
		path = {"路徑1", "路徑2", ...},       -- UI 路徑 (從 secondscreen 開始)
		target = "目標物件名",                -- 要重命名的物件名稱
		mode = "SIMPLE",                      -- 模式: SIMPLE (純數字)
		maxCount = 12                         -- 最大等待數量
	}
	
	dynamic (動態數量任務):
	{
		name = "任務名稱",
		path = {"路徑1", "路徑2", ...},
		target = "目標物件名",
		prefix = "前綴"                       -- 命名前綴 (如 "mail" → mail1, mail2...)
	}
	
	textBased (文本模式任務):
	{
		name = "任務名稱",
		path = {"路徑1", "路徑2", ...},
		target = "目標物件名",
		textChild = "名称"                    -- 從此子物件的 .Text 取得新名稱
	}
	
	nested (雙層結構任務):
	{
		name = "任務名稱",
		path = {"路徑1", "路徑2", ...},
		frameName = "框架物件名",             -- 外層框架名稱
		childName = "子物件名",               -- 內層物件名稱
		framePrefix = "PetFrame",             -- 框架命名前綴
		childPrefix = "PetEgg"                -- 子物件命名前綴
	}
]]
local TaskConfig = {
  -- 固定數量任務
	fixed = {
		{
			name = "通行證任務",
			path = {"商店","通行证任务","背景","任务列表"},
			target = "任务项预制体",
			mode = "SIMPLE",
			maxCount = 12
		},
		{
			name = "每日任務",
			path = {"每日任务","背景","任务列表"},
			target = "任务项预制体",
			mode = "SIMPLE",
			maxCount = 7
		}
	},
    
  -- 動態數量任務
	dynamic = {
		{
			name = "通行證獎勵",
			path = {"商店","背景","右侧界面","月通行证","背景","奖励区","奖励列表"},
			target = "月通行证奖励预制体",
			prefix = "gamepassgift"
		},
		{
			name = "郵件",
			path = {"邮件","背景","邮件列表"},
			target = "邮件",
			prefix = "mail"
		},
		{
			name = "活動商品",
			path = {"节日活动商店","背景","右侧界面","兑换","列表"},
			target = "活动商品预制体",
			prefix = "eventcommodity"
		},
		{
			name = "公會商店",
			path = {"公会","背景","右侧界面","商店","列表"},
			target = "活动商品预制体",
			prefix = "Guildshopitem"
		},
		{
			name = "競技場商店",
			path = {"竞技场","背景","右侧界面","商店","列表"},
			target = "活动商品预制体",
			prefix = "Arenashopitem"
		},
		{
			name = "世界BOSS",
			path = {"关卡选择","背景","右侧界面","世界boss","列表"},
			target = "世界boss关卡预制体",
			prefix = "worldboss"
		},
		{
			name = "祝福",
			path = {"主角","背景","右侧界面","小绿瓶","祝福","列表"},
			target = "祝福预制体",
			prefix = "Blessing"
		}
	},
    
  -- 文本模式任務 (地下城)
	textBased = {
		{
			name = "地下城",
			path = {"关卡选择","背景","右侧界面","副本","列表"},
			target = "副本预制体",
			textChild = "名称"
		},
		{
			name = "活動地下城",
			path = {"关卡选择","背景","右侧界面","活动副本","列表"},
			target = "活动副本预制体",
			textChild = "名称"
		}
	},
    
  -- 雙層結構任務
	nested = {
		{
			name = "寵物背包",
			path = {"宠物","背景","右侧界面","宠物蛋","背包区域","道具栏","列表"},
			frameName = "宠物背包行框架预制体",
			childName = "背包项预制体",
			framePrefix = "PetFrame",
			childPrefix = "PetEgg"
		}
	}
}

-- ========================================================================== --
-- 初始化執行
-- ========================================================================== --
local function runInitialization()
	ThreadManager:init()
    
    -- 處理世界關卡 (特殊處理)
	ThreadManager:spawn("世界關卡", function()
		local schedule = NameProcessor.findPath(player, {"值","主线进度"})
		if schedule then
			local worldname = schedule:FindFirstChild("世界")
			local levelsname = schedule:FindFirstChild("关卡")
			if worldname then
				worldname.Name = "world"
			end
			if levelsname then
				levelsname.Name = "levels"
			end
		end
	end)
    
    -- 處理固定數量任務
	for _, cfg in ipairs(TaskConfig.fixed) do
		ThreadManager:spawn(cfg.name, function()
			NameProcessor.process({parent = NameProcessor.findPath(secondscreen, cfg.path),target = cfg.target,mode = cfg.mode or "SIMPLE",prefix = cfg.prefix,maxCount = cfg.maxCount})
		end)
	end
    
    -- 處理動態數量任務
	for _, cfg in ipairs(TaskConfig.dynamic) do
		ThreadManager:spawn(cfg.name, function()
			NameProcessor.process({parent = NameProcessor.findPath(secondscreen, cfg.path),target = cfg.target,mode = "PREFIX",prefix = cfg.prefix})
		end)
	end
    
    -- 處理文本模式任務
	for _, cfg in ipairs(TaskConfig.textBased) do
		ThreadManager:spawn(cfg.name, function()
			NameProcessor.process({parent = NameProcessor.findPath(secondscreen, cfg.path),target = cfg.target,mode = "TEXT",textChild = cfg.textChild})
		end)
	end
    
    -- 處理雙層結構任務
	for _, cfg in ipairs(TaskConfig.nested) do
		ThreadManager:spawn(cfg.name, function()
			NameProcessor.processNested({parent = NameProcessor.findPath(secondscreen, cfg.path),frameName = cfg.frameName,childName = cfg.childName,framePrefix = cfg.framePrefix,childPrefix = cfg.childPrefix})
		end)
	end
	ThreadManager:waitForAll()
end

-- 啟動
runInitialization()