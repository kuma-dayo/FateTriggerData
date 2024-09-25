require "UnLua"
-- 处理 WBP_PlayerNameWidget
local WBP_PlayerNameWidget = Class("Client.Mvc.UserWidgetBase")

function WBP_PlayerNameWidget:OnInit()
    print("WBP_PlayerNameWidget:OnInit")
    self.BindNodes = 
    {
		{ UDelegate = self.OnInitPlayerNameEvent,				    Func = self.InitPlayerName },
		{ UDelegate = self.GUIButton_Main.OnClicked,				    Func = self.OnClickBtn },
     
	}
    self.MsgList = {
        {Model = UserModel, MsgName = UserModel.ON_MODIFY_NAME_SUCCESS, Func = self.OnSelfModifyName},

    }
    UserWidgetBase.OnInit(self)
end

function WBP_PlayerNameWidget:InitPlayerName()
    print("===============WBP_PlayerNameWidget InitPlayerName "..self.ShowPlayerId.." "..self.ShowPlayerName.." ")
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.ShowPlayerId == MyPlayerId then
        local PlayerNameStr = StringUtil.SplitPlayerName(self.ShowPlayerName)
        self.LabelPlayerName:SetText(PlayerNameStr)
    else
        -- 他人名字需要轮询更新
        local PlayerNameParam = {
            WidgetBaseOrHandler = self,
            TextBlockName = self.LabelPlayerName,
            PlayerId = self.ShowPlayerId,
            DefaultStr = self.ShowPlayerName,
            IsHideNum = true
        }
        MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    end
end

-- 自己改名了
function WBP_PlayerNameWidget:OnSelfModifyName()
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.ShowPlayerId ~= MyPlayerId then
        return
    end
    print("===============WBP_PlayerNameWidget OnSelfModifyName ")
    self.ShowPlayerName = StringUtil.ConvertString2FText(MvcEntry:GetModel(UserModel):GetPlayerName())
    local PlayerNameStr = StringUtil.SplitPlayerName(self.ShowPlayerName)
    self.LabelPlayerName:SetText(PlayerNameStr)
end

function WBP_PlayerNameWidget:OnClickBtn()
    if not self.ShowPlayerId then
        return
    end
    local Param =  {
        PlayerId = tonumber(self.ShowPlayerId),
        IsShowOperateBtn = true,
        FocusWidget = self.GUIButton_Main,
        IsNeedReqUpdateData = true,
    }
    MvcEntry:OpenView(ViewConst.CommonPlayerInfoHoverTip,Param)
end

function WBP_PlayerNameWidget:OnDestroy()
    UserWidgetBase.OnDestroy(self)
end


return WBP_PlayerNameWidget