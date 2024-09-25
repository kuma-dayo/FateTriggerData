UIDebug = UIDebug or {}
UIDebug.Instance = UIDebug.Instance or nil

function UIDebug.Show()
    if not CommonUtil.IsValid(UIDebug.Instance) then
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(DebugUMGPath))
        UIDebug.Instance = NewObject(WidgetClass, GameInstance, nil, "Client.Common.UIDebug")
        UIRoot.AddChildToLayer(UIDebug.Instance,UIRoot.UILayerType.Tips, 99)
    end
    UIDebug.Instance:Show()
    print("==========================UIDebug")
end

function UIDebug.Close()
    if CommonUtil.IsValid(UIDebug.Instance) then
        UIDebug.Instance:Hide()
    end
end
-------------------------------------------------------------------------------

local M = Class()

function M:OnInit()
    
end

function M:Show()
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleDebug()
    self:UpdateWaterMark()
end

function M:Hide()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function M:OnShow(data)
    
end

function M:OnHide()
    self:CleanDebugTimer()
end

function M:Construct()
    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = "Setting.Renderer.RenderingQuality",Func = Bind(self,self.UpdateWaterMark), bCppMsg = true, WatchedObject = nil },
    }
    if self.MsgListGMP then
        MsgHelper:RegisterList(self, self.MsgListGMP)
    end
    self.GUITextBlock_2:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:Destruct()
    if self.MsgListGMP then
        MsgHelper:UnregisterList(self, self.MsgListGMP)
    end
    self:CleanDebugTimer()
end

function M:UpdateWaterMark()
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    if CommonUtil.IsValid(UIDebug.Instance) and Uid and  Uid > 0 then
        self.GUITextBlock_2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local RenderingQualityIndex = UE.UGenericSettingSubsystem.Get(self):GetSettingValue_int32ByTagName("Setting.Renderer.RenderingQuality")
        -- 定义渲染质量对应的key
        local QualityKey = {
            [0] = "low",
            [1] = "med",
            [2] = "high",
            [3] = "superhigh",
            [4] = "Film",
        }
        local Key = QualityKey[RenderingQualityIndex] and QualityKey[RenderingQualityIndex] or QualityKey[0]
        local Str1 = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIDebug_RenderingQuality")
        local Str2 = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIDebug_Test")
		local ClientCL,ClientStream = MvcEntry:GetModel(UserModel):GetP4ChangeList()
        self.GUITextBlock_2:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIDebug_String_Key"), tostring(Uid), Str1, G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', Key), Str2, ClientCL))
        
        --满屏UID
        local Index = 1
        local MaxLoop = 50
        repeat
            if not CommonUtil.IsValid(self["UID_" .. Index]) then
                break
            end
            if self["UID_" .. Index] then self["UID_" .. Index]:SetText(Uid) end
            Index = Index + 1
        until Index > MaxLoop
    end
end

function M:ScheduleDebug()
    self:CleanDebugTimer()
    self.DebugTimer = Timer.InsertTimer(1,function()
        local TimeStr = TimeUtils.GetDateTimeStrFromTimeStamp(GetTimestamp(), "%04d-%02d-%02d %02d:%02d:%02d", true)
        self.GUITextBlock:SetText(StringUtil.FormatSimple("{0}(UTC+0)", TimeStr))
	end, true)   
end

function M:CleanDebugTimer()
    if self.DebugTimer then
        Timer.RemoveTimer(self.DebugTimer)
    end
    self.DebugTimer = nil
end


return M