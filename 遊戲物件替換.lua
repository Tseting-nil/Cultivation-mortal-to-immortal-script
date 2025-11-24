local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local secondscreen = playerGui.GUI:FindFirstChild("二级界面")

-- ========================================================================== --
-- 多線程同步管理器
local ThreadManager = {}
ThreadManager.activeCount = 0
ThreadManager.totalTasks = 0
ThreadManager.startTime = 0

function ThreadManager:init()
	self.activeCount = 0
	self.totalTasks = 0
	self.startTime = tick()
end

function ThreadManager:addTask()
	self.totalTasks = self.totalTasks + 1
	self.activeCount = self.activeCount + 1
end

function ThreadManager:completeTask()
	self.activeCount = self.activeCount - 1
end

function ThreadManager:waitForAll()
	print(string.format("等待 %d 個並行任務完成...", self.totalTasks))
	while self.activeCount > 0 do
		task.wait(0.1)
	end
	local elapsed = tick() - self.startTime
	print(string.format("所有任務完成！耗時: %.2f 秒", elapsed))
end

-- ========================================================================== --
-- (父物件：任務列表容器,目標名稱：要找的物件名稱,新名稱前綴,最大數量,完成訊息)
-- 支持多線程版本
local function initializationNameChange(parent, targetName, newNamePrefix, maxCount, completedMessage)
	if not parent then
		return
	end

	local processed = 0
	local children = parent:GetChildren()
	
	-- 第一階段：快速處理已存在的物件（批量處理）
	local batch = {}
	for _, child in ipairs(children) do
		if child.Name == targetName then
			table.insert(batch, child)
		end
	end
	
	-- 並行處理批量物件
	for i, child in ipairs(batch) do
		processed = processed + 1
		if newNamePrefix then
			child.Name = newNamePrefix .. tostring(processed)
		else
			child.Name = tostring(processed)
		end
	end

	-- 第二階段：等待剩餘物件（如果指定了最大數量）
	if maxCount and processed < maxCount then
		local attempts = 0
		local maxAttempts = 50
		local checkInterval = 0
		
		while processed < maxCount and attempts < maxAttempts do
			local item = parent:FindFirstChild(targetName)
			if item then
				processed = processed + 1
				if newNamePrefix then
					item.Name = newNamePrefix .. tostring(processed)
				else
					item.Name = tostring(processed)
				end
				checkInterval = 0
			else
				attempts = attempts + 1
				checkInterval = checkInterval + 1
				if checkInterval >= 5 then
					RunService.Heartbeat:Wait()
					checkInterval = 0
				end
			end
		end
	end
	print(completedMessage .. " (處理了 " .. processed .. " 個物件)")
end

-- 地下城專用的名稱處理函數（多線程優化版）
local function initializationDungeonNameChange(parent, targetName, completedMessage)
	if not parent then
		return
	end
	
	local processed = 0
	local children = parent:GetChildren()
	
	-- 第一階段：並行處理已存在的物件
	local batch = {}
	for _, child in ipairs(children) do
		if child.Name == targetName then
			table.insert(batch, child)
		end
	end
	
	-- 批量處理文本轉換
	for _, child in ipairs(batch) do
		local nameText = child:FindFirstChild("名称")
		if nameText and nameText.Text then
			local cleanName = string.gsub(nameText.Text, "%s+", "")
			if cleanName ~= "" then
				child.Name = cleanName
				processed = processed + 1
			end
		end
	end

	-- 第二階段：等待動態生成的物件
	if processed == 0 then
		local attempts = 0
		local maxAttempts = 100
		local checkInterval = 0
		
		while attempts < maxAttempts do
			local item = parent:FindFirstChild(targetName)
			if item then
				local nameText = item:FindFirstChild("名称")
				if nameText and nameText.Text then
					local cleanName = string.gsub(nameText.Text, "%s+", "")
					if cleanName ~= "" then
						item.Name = cleanName
						processed = processed + 1
					end
				end
			end
			
			attempts = attempts + 1
			checkInterval = checkInterval + 1
			if checkInterval >= 3 then
				RunService.Heartbeat:Wait()
				checkInterval = 0
			end
		end
	end
	print(completedMessage .. " (處理了 " .. processed .. " 個物件)")
end

-- 處理固定數量的物件
local function initializePhaseOne()
	-- 預緩存常用路徑
	local shop = secondscreen:FindFirstChild("商店")
	local dailyMission = secondscreen:FindFirstChild("每日任务")
	
    -- 通行證任務 (固定12個)
	if shop then
		ThreadManager:addTask()
		task.spawn(function()
			local gamepassmissionnamelist = shop:FindFirstChild("通行证任务")
			if gamepassmissionnamelist then
				gamepassmissionnamelist = gamepassmissionnamelist:FindFirstChild("背景")
				if gamepassmissionnamelist then
					gamepassmissionnamelist = gamepassmissionnamelist:FindFirstChild("任务列表")
					initializationNameChange(gamepassmissionnamelist, "任务项预制体", nil, 12, "通行證任務--名稱--已全部更改")
				end
			end
			ThreadManager:completeTask()
		end)
	end

    -- 每日任務 (固定7個)
	if dailyMission then
		ThreadManager:addTask()
		task.spawn(function()
			local everydaymissionnamelist = dailyMission:FindFirstChild("背景")
			if everydaymissionnamelist then
				everydaymissionnamelist = everydaymissionnamelist:FindFirstChild("任务列表")
				initializationNameChange(everydaymissionnamelist, "任务项预制体", nil, 7, "每日任務--名稱--已全部更改")
			end
			ThreadManager:completeTask()
		end)
	end

    -- 世界關卡 (立即處理)
	ThreadManager:addTask()
	task.spawn(function()
		local schedule = player:FindFirstChild("值")
		if schedule then
			schedule = schedule:FindFirstChild("主线进度")
			if schedule then
				local worldname = schedule:FindFirstChild("世界")
				local worldlevelsname = schedule:FindFirstChild("关卡")
				if worldname and worldlevelsname then
					worldname.Name = "world"
					worldlevelsname.Name = "levels"
					print("世界關卡--名稱--已全部更改")
				end
			end
		end
		ThreadManager:completeTask()
	end)
end

-- 輔助函數：安全的深度查找（全局使用）
local function safeFindPath(root, ...)
	local current = root
	for _, name in ipairs({...}) do
		if not current then return nil end
		current = current:FindFirstChild(name)
	end
	return current
end

-- 處理動態數量的物件
local function initializePhaseTwo()
	-- 所有任務配置
	local tasks = {
		{safeFindPath(secondscreen, "商店", "背景", "右侧界面", "月通行证", "背景", "奖励区", "奖励列表"), "月通行证奖励预制体", "gamepassgift", nil, "通行證獎勵--名稱--已全部更改"},
		{safeFindPath(secondscreen, "邮件", "背景", "邮件列表"), "邮件", "mail", nil, "郵件--名稱--已全部更改"},
		{safeFindPath(secondscreen, "节日活动商店", "背景", "右侧界面", "兑换", "列表"), "活动商品预制体", "eventcommodity", nil, "活動商品--名稱--已全部更改"},
		{safeFindPath(secondscreen, "公会", "背景", "右侧界面", "商店", "列表"), "活动商品预制体", "Guildshopitem", nil, "公會商店--名稱--已全部更改"},
		{safeFindPath(secondscreen, "竞技场", "背景", "右侧界面", "商店", "列表"), "活动商品预制体", "Arenashopitem", nil, "競技場商店--名稱--已全部更改"},
		{safeFindPath(secondscreen, "关卡选择", "背景", "右侧界面", "世界boss", "列表"), "世界boss关卡预制体", "worldboss", nil, "世界BOSS--名稱--已全部更改"},
		{safeFindPath(secondscreen, "主角", "背景", "右侧界面", "小绿瓶", "祝福", "列表"), "祝福预制体", "Blessing", nil, "祝福--名稱--已全部更改"},
		{safeFindPath(secondscreen, "宠物", "背景", "右侧界面", "宠物蛋", "背包区域", "道具栏", "列表"), "背包项预制体", "PetEgg", nil, "寵物蛋背包--名稱--已全部更改"}
	}
	-- 使用 task.spawn 並行執行所有任務
	for _, taskData in ipairs(tasks) do
		ThreadManager:addTask()
		task.spawn(function()
			initializationNameChange(taskData[1], taskData[2], taskData[3], taskData[4], taskData[5])
			ThreadManager:completeTask()
		end)
	end
end

-- 處理需要文本處理的物件
local function initializePhaseThree()
	-- 預緩存關卡選擇路徑
	local levelSelection = secondscreen:FindFirstChild("关卡选择")
	if not levelSelection then return end
	
	local background = levelSelection:FindFirstChild("背景")
	if not background then return end
	
	local rightInterface = background:FindFirstChild("右侧界面")
	if not rightInterface then return end

    -- 地下城
	local Dungeonslist = rightInterface:FindFirstChild("副本")
	if Dungeonslist then
		Dungeonslist = Dungeonslist:FindFirstChild("列表")
		if Dungeonslist then
			ThreadManager:addTask()
			task.spawn(function()
				initializationDungeonNameChange(Dungeonslist, "副本预制体", "地下城--名稱--已全部更改")
				ThreadManager:completeTask()
			end)
		end
	end

    -- 活動地下城
	local Dungeonseventlist = rightInterface:FindFirstChild("活动副本")
	if Dungeonseventlist then
		Dungeonseventlist = Dungeonseventlist:FindFirstChild("列表")
		if Dungeonseventlist then
			ThreadManager:addTask()
			task.spawn(function()
				initializationDungeonNameChange(Dungeonseventlist, "活动副本预制体", "活動地下城--名稱--已全部更改")
				ThreadManager:completeTask()
			end)
		end
	end
end

local function runInitialization()
	print("=== 開始遊戲初始化命名程序 ===")
	
	-- 初始化線程管理器
	ThreadManager:init()
	
	-- 所有階段使用 task.spawn 並行執行
	initializePhaseOne()
	initializePhaseTwo()
	initializePhaseThree()
	
	-- 等待所有任務完成
	ThreadManager:waitForAll()
	
	print("=== 初始化完成！===")
end

-- 啟動
runInitialization()