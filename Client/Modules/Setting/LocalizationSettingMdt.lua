--[[
    本地化设置界面
]]

local class_name = "LocalizationSettingMdt";
LocalizationSettingMdt = LocalizationSettingMdt or BaseClass(GameMediator, class_name);

function LocalizationSettingMdt:__init()
end

function LocalizationSettingMdt:OnShow(data)
end

function LocalizationSettingMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.BtnTxt_1.OnClicked,				    Func = Bind(self,self.OnClicked_IllnLanguage,1) },
		{ UDelegate = self.BtnTxt_2.OnClicked,				    Func = Bind(self,self.OnClicked_IllnLanguage,2)  },
        { UDelegate = self.BtnTxt_3.OnClicked,				    Func = Bind(self,self.OnClicked_IllnLanguage,3) },
        { UDelegate = self.BtnTxt_4.OnClicked,				    Func = Bind(self,self.OnClicked_IllnLanguage,4) },
        { UDelegate = self.BtnRadio_1.OnClicked,				Func = Bind(self,self.OnClicked_IllnAudioCulture,1) },
        { UDelegate = self.BtnRadio_2.OnClicked,				Func = Bind(self,self.OnClicked_IllnAudioCulture,2) },
        { UDelegate = self.BtnRadio_3.OnClicked,				Func = Bind(self,self.OnClicked_IllnAudioCulture,3) },

        { UDelegate = self.BtnTxt_1.OnHovered,				    Func = Bind(self,self.OnHovered_IllnLanguage, 1) },
		{ UDelegate = self.BtnTxt_2.OnHovered,				    Func = Bind(self,self.OnHovered_IllnLanguage, 2)  },
        { UDelegate = self.BtnTxt_3.OnHovered,				    Func = Bind(self,self.OnHovered_IllnLanguage, 3) },
        { UDelegate = self.BtnRadio_1.OnHovered,				Func = Bind(self,self.OnHovered_IllnAudioCulture,1) },
        { UDelegate = self.BtnRadio_2.OnHovered,				Func = Bind(self,self.OnHovered_IllnAudioCulture,2) },
        { UDelegate = self.BtnRadio_3.OnHovered,				Func = Bind(self,self.OnHovered_IllnAudioCulture,3) },

        { UDelegate = self.BtnTxt_1.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnLanguage, 1) },
		{ UDelegate = self.BtnTxt_2.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnLanguage, 2) },
        { UDelegate = self.BtnTxt_3.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnLanguage, 3) },
        { UDelegate = self.BtnRadio_1.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnAudioCulture,1) },
        { UDelegate = self.BtnRadio_2.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnAudioCulture,2) },
        { UDelegate = self.BtnRadio_3.OnUnhovered,				Func = Bind(self,self.OnUnhovered_IllnAudioCulture,3) },

        { UDelegate = self.BtnClose.OnClicked,				    Func = self.OnClicked_BtnClose },
	}

    self.MsgList = {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self,self.OnClicked_BtnClose)},
	}
    
    local NormalTxtFColor =  UE.FSlateColor()
    NormalTxtFColor.SpecifiedColor = UIHelper.LinearColor.White
    local PressedTxtFColor =  UE.FSlateColor()
    PressedTxtFColor.SpecifiedColor = UIHelper.LinearColor.Black

    self.LastSelectTxtItem = nil --记录上次所选择语言项
    self.LastSelectRadioItem = nil --记录上次所选择音频项
    self.BtnTxtColor = { --按钮文本颜色
        Normal = NormalTxtFColor,
        Pressed = PressedTxtFColor 
    }
    self.ItemImgObjData = { --按钮Normal和Pressed状态ImgObj的缓存
        Normal = nil,
        Pressed = nil
    }

    self.Index2SupportLanguage = {
        [1] = LocalizationModel.IllnLanguageSupportEnum.zhHans,
        [2] = LocalizationModel.IllnLanguageSupportEnum.enUS,
        [3] = LocalizationModel.IllnLanguageSupportEnum.jaJP,
        [4] = LocalizationModel.IllnLanguageSupportEnum.zhHant,
    }
    self.Index2SupportAudioCulture = {
        [1] = LocalizationModel.IllnAudioCultureSupportEnum.Chinese,
        [2] = LocalizationModel.IllnAudioCultureSupportEnum.English,
        [3] = LocalizationModel.IllnAudioCultureSupportEnum.Japanese,
    }
    self.SupportLanguage2Index = {}
    self.SupportAudioCulture2Index = {}
    for k,v in pairs(self.Index2SupportLanguage) do
        self.SupportLanguage2Index[v] = k
    end
    for k,v in pairs(self.Index2SupportAudioCulture) do
        self.SupportAudioCulture2Index[v] = k
    end
end

--由mdt触发调用
function M:OnShow(data)
    local LanSelData = MvcEntry:GetModel(LocalizationModel):GetCurSelectLanData()
    self.LastTxtSelIndex = self.SupportLanguage2Index[LanSelData.CurTxtLanguage]
    self.LastRadioSelIndex = self.SupportAudioCulture2Index[LanSelData.CurAudioCulture]
    self.CurTxtSelIndex = self.LastTxtSelIndex
    self.CurRadioSelIndex = self.LastRadioSelIndex
    self:InitItemImgObjData()
    self:SetSelectTxtItemShowByIndex(self.CurTxtSelIndex)
    self:SetSelectRadioItemShowByIndex(self.CurRadioSelIndex)
end

--获取Normal和Pressed按钮态的ResObj,并根据按钮选中状态动态切变
function M:InitItemImgObjData()
    self.ItemImgObjData.Normal = self.BtnGetResObj.WidgetStyle.Normal
    self.ItemImgObjData.Pressed = self.BtnGetResObj.WidgetStyle.Pressed
end

--设置语言文本类按钮选择项
function M:SetSelectTxtItemShowByIndex(InIndex)
    self:SetSelectBtnShow(InIndex, "BtnTxt_")
end

--设置语言音频类按钮选择项
function M:SetSelectRadioItemShowByIndex(InIndex)
    self:SetSelectBtnShow(InIndex, "BtnRadio_")
end

--按钮变化统一处理
function M:SetSelectBtnShow(InIndex, InBtnKey)
    local Btn = self[InBtnKey..InIndex]
    local LastSelect = self.LastSelectTxtItem
    if InBtnKey == "BtnRadio_" then
        LastSelect = self.LastSelectRadioItem
    end
    if LastSelect then
        LastSelect.WidgetStyle.Normal = self.ItemImgObjData.Normal
        self:SetTargetBtnTxtColor(LastSelect, true)
    end
    Btn.WidgetStyle.Normal = self.ItemImgObjData.Pressed
    self:SetTargetBtnTxtColor(Btn, false)
    if InBtnKey == "BtnRadio_" then
        self.LastSelectRadioItem = Btn
    else
        self.LastSelectTxtItem = Btn
    end
end

--设置按钮文本颜色
function M:SetTargetBtnTxtColor(InTargetBtn, InIsNormal)
    local TxtName = InTargetBtn:GetAllChildren():Get(1)
    TxtName:SetColorAndOpacity(InIsNormal and self.BtnTxtColor.Normal or self.BtnTxtColor.Pressed)
end

function M:OnHide()
end

--[[
    本地化文本切换点击
]]
function M:OnClicked_IllnLanguage(InIndex)
    if InIndex == self.CurTxtSelIndex then
        return
    end
    self.CurTxtSelIndex = InIndex
    local TheLanguage = self.Index2SupportLanguage[InIndex]
    self:SetSelectTxtItemShowByIndex(InIndex)

    MvcEntry:GetModel(LocalizationModel):SetCurSelectLanTxtLanguage(TheLanguage,true,false,true)
end

--[[
    本地化语音切换点击
]]
function M:OnClicked_IllnAudioCulture(InIndex)
    if InIndex == self.CurRadioSelIndex then
        return
    end
    self.CurRadioSelIndex = InIndex
    local TheAudioCulture = self.Index2SupportAudioCulture[InIndex]
    self:SetSelectRadioItemShowByIndex(InIndex)

    MvcEntry:GetModel(LocalizationModel):SetCurSelectLanRadioCulture(TheAudioCulture,true,false,true)
end


function M:OnHovered_IllnLanguage(InIndex)
    self:SetTargetBtnTxtColor(self["BtnTxt_"..InIndex], false)
end

function M:OnUnhovered_IllnLanguage(InIndex)
    if InIndex == self.CurTxtSelIndex then
        return
    end
    self:SetTargetBtnTxtColor(self["BtnTxt_"..InIndex], true)
end

function M:OnHovered_IllnAudioCulture(InIndex)
    self:SetTargetBtnTxtColor(self["BtnRadio_"..InIndex], false)
end

function M:OnUnhovered_IllnAudioCulture(InIndex)
    if InIndex == self.CurRadioSelIndex then
        return
    end
    self:SetTargetBtnTxtColor(self["BtnRadio_"..InIndex], true)
end


--[[
    界面关闭
]]
function M:OnClicked_BtnClose()
    if (self.LastTxtSelIndex ~= self.CurTxtSelIndex or self.LastRadioSelIndex ~= self.CurRadioSelIndex) then
        -- local msgParam = {
        --     describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Localizedcontentcant")),
        --     leftBtnInfo = {
        --         name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Restartlater"),
        --         callback = function()
        --             MvcEntry:CloseView(self.viewId)
        --         end
        --     },
        --     rightBtnInfo = {
        --         name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Setting', "Lua_LocalizationSettingMdt_Restartimmediately"),
        --         callback = function()
        --             --TODO 关闭游戏
        --             UE.UKismetSystemLibrary.QuitGame(GameInstance,CommonUtil.GetLocalPlayerC(),UE.EQuitPreference.Quit,true)
        --         end
        --     }
        -- }
        -- UIMessageBox.Show(msgParam)
        MvcEntry:CloseView(self.viewId)
    else
        MvcEntry:CloseView(self.viewId)
    end
end

return M