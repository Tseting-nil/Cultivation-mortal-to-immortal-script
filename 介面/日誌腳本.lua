--=========================================================
--   LogSystem 模組（支援公告 / 日誌分組）
--=========================================================
local LogSystem = {}

-- 創建新的日誌系統實例
function LogSystem.new(ReGui, config)
	config = config or {}
	
	local self = {}
	
	-- 創建視窗
	self.Window = ReGui:Window({
		Title = config.Title or "更新日誌",
		Size = config.Size or UDim2.fromOffset(700, 500),
		NoTabs = true,
		NoCollapse = true,
	})
	self.Window:Center()
	
	-- 設定
	self.ContentIndent = config.ContentIndent or 40
	self.LastDate = nil
	self.Visible = true
	
	
	---------------------------------------------------------
	-- 顯示 UI
	---------------------------------------------------------
	function self:Show()
		self.Window:SetVisible(true)
		self.Visible = true
		return self
	end
	
	
	---------------------------------------------------------
	-- 隱藏 UI
	---------------------------------------------------------
	function self:Hide()
		self.Window:SetVisible(false)
		self.Visible = false
		return self
	end
	
	
	---------------------------------------------------------
	-- 關閉 UI
	---------------------------------------------------------
	function self:Close()
		self.Window:Close()
		return self
	end
	
	
	---------------------------------------------------------
	-- 📢 建立公告（置中 + 分隔線 + 大字體）
	---------------------------------------------------------
	function self:AddAnnouncement(text, color, size)
		self.Window:Separator()
		self.Window:Label({
			Text = "📢 公告",
			TextSize = 24,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(255, 225, 140),
			TextXAlignment = Enum.TextXAlignment.Center
		})
		self.Window:Label({
			Text = text,
			TextSize = size or 22,
			TextColor3 = color or Color3.fromRGB(255, 150, 150),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
		})
		self.Window:Separator()
		return self
	end
	
	
	---------------------------------------------------------
	-- 📅 建立日誌（自動日期分組）
	---------------------------------------------------------
	function self:AddLog(color, size, date, version, ...)
		
		-----------------------------------------------------
		-- 日期不同 → 插入日期標題（自動分組）
		-----------------------------------------------------
		if self.LastDate ~= date then
			self.LastDate = date
			self.Window:Label({
				Text = "📅 " .. date,
				TextSize = 22,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(120, 255, 138)
			})
		end
		
		
		-----------------------------------------------------
		-- 版本標題
		-----------------------------------------------------
		self.Window:Label({
			Text = "▼ " .. version,
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			TextColor3 = color or Color3.fromRGB(19, 92, 250)
		})
		
		
		-----------------------------------------------------
		-- 顯示內容（多行）
		-----------------------------------------------------
		local contents = {...}
		local contentIndent = self.Window:Indent({
			Offset = self.ContentIndent
		})
		for _, line in ipairs(contents) do
			contentIndent:Label({
				Text = "• " .. line,
				TextWrapped = true,
				TextSize = size or 18,
				TextColor3 = Color3.fromRGB(220, 220, 220)
			})
		end
		self.Window:Separator()
		return self
	end
	
	return self
end


-- 返回模組
return LogSystem