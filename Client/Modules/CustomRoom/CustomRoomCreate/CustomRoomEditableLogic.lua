--[[
   自建房输入控件逻辑
]] 
local class_name = "CustomRoomEditableLogic"
local CustomRoomEditableLogic = BaseClass(UIHandlerViewBase, class_name)
---@class CustomRoomEditableLogicParam
---@field OnTextChangedFunc function OnTextChanged 时执行的回调
---@field OnTextCommittedEnterFunc function OnTextCommitted 且 InCommitMethod为 UE.ETextCommit.OnEnter 时执行的回调 时执行的回调

function CustomRoomEditableLogic:OnInit()
    self.InputHandler = nil
end

function CustomRoomEditableLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function CustomRoomEditableLogic:OnHide()
end

function CustomRoomEditableLogic:UpdateUI(Param)
    if not Param then
        return
    end
    -- 注册输入控件处理
    if not self.InputHandler then
        self.InputHandler = UIHandler.New(self,self.View,CommonTextBoxInput,{
           InputWigetName = "EditableText",
           FoucsViewId = ViewConst.CustomRoomCreate,
           OnTextChangedFunc = Bind(self,Param.OnTextChangedFunc),
           OnTextCommittedEnterFunc = Bind(self,Param.OnTextCommittedEnterFunc),
       }).ViewInstance
    end
end

return CustomRoomEditableLogic
