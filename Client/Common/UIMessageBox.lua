--[[
    公用提示确认框
]]
---@class UIMessageBox
UIMessageBox = UIMessageBox or {}


--[[
    使用参考：    
    msgParam = {
        title = "",                 --【可选】标题，默认为【提示】
        describe = "",              --【必选】描述
        warningDec = "",            --【可选】警告描述
        leftBtnInfo = {             --【可选】左按钮信息，无数据则不显示
            name = "",              --【可选】按钮名称，默认为【取消】
            callback = func,        --【可选】按钮回调
            iconID = 1,             --【可选】展示的图标ID，参考【CommonConst.CT_BACK】
            actionMappingKey = nil, --【可选】需要监听的按钮，参考【ActionMappings.Escape】
        }, 
        rightBtnInfo = {            --【可选】右铵钮信息，默认是【关闭弹窗】             
            name = "",              --【可选】按钮名称，默认为【确认】
            callback = func,        --【可选】按钮回调
            iconID = 1,             --【可选】展示的图标ID，参考【CommonConst.CT_SPACE】
            actionMappingKey = nil, --【可选】需要监听的按钮，参考【ActionMappings.SpaceBar】
        }, 
        closeCallback = func        --【可选】关闭回调
        hyperlinkCallback = func    --【可选】超链接回调
        HideCloseBtn                --【可选】是否隐藏关闭按钮
        HideCloseTip                --【可选】是否隐藏空白半闭
        bRepeatShow                 --【可选】是否支持重复打开时刷新这个界面
        DelayCloseTime               --【可选】延迟关闭时间
    }
    UIMessageBox.Show(msgParam)
]]
---展示通用确认弹窗
---@param msgParam table 展示数据，数据格式参考上方注释
function UIMessageBox.Show(msgParam)
    if not msgParam or not msgParam.describe then
        CError("UIMessageBox Show msgParam Error")
        return
    end

    MvcEntry:OpenView(ViewConst.MessageBox, msgParam)
end

function UIMessageBox.Close()
    MvcEntry:CloseView(ViewConst.MessageBox)
end

---展示通用确认弹窗（系统版本）
function UIMessageBox.Show_System(msgParam)
    if not msgParam or not msgParam.describe then
        CError("UIMessageBox Show_System msgParam Error")
        return
    end

    MvcEntry:OpenView(ViewConst.MessageBoxSystem,msgParam)
end

---展示通用确认弹窗（没有标题版本）
function UIMessageBox.Show_NoTitle(msgParam)
    if not msgParam or not msgParam.describe then
        CError("UIMessageBox Show_NoTitle msgParam Error")
        return
    end
    
    MvcEntry:OpenView(ViewConst.MessageBoxNoTitle, msgParam)
end


--[[
    通用提示框Mdt类
]]
local class_name = "UIMessageBoxMdt"
UIMessageBoxMdt = UIMessageBoxMdt or BaseClass(GameMediator, class_name)

function UIMessageBoxMdt:__init()
end

function UIMessageBoxMdt:OnShow(data)

end

function UIMessageBoxMdt:OnHide()
end

--[[
    通用提示框Mdt类(无标题版本)
]]
local class_name = "UIMessageBoxNoTitle"
UIMessageBoxNoTitle = UIMessageBoxNoTitle or BaseClass(GameMediator, class_name)
function UIMessageBoxNoTitle:__init()
end
function UIMessageBoxNoTitle:OnShow(data) end
function UIMessageBoxNoTitle:OnHide() end

--[[
    通用提示框Mdt类（系统）
]]
local class_name = "UIMessageBoxSystemMdt"
UIMessageBoxSystemMdt = UIMessageBoxSystemMdt or BaseClass(GameMediator, class_name)

function UIMessageBoxSystemMdt:__init()
end

function UIMessageBoxSystemMdt:OnShow(data)

end

function UIMessageBoxSystemMdt:OnHide()
end