--
-- Tips
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.06.21
--

require("Common.Framework.UIHelper")


local GenericTipsHelper = _G.GenericTipsHelper or {}

local LayoutDTPath = UIHelper.LayoutDTPath.TipsPanelSubData

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Common ------------------------------------


-------------------------------------------- Function ------------------------------------


-- 获取配置数据
function GenericTipsHelper.GetDTConfigData(InKey)
    local LayoutDT = UE.UObject.Load(LayoutDTPath)
    local WidgetData = UE.UDataTableFunctionLibrary.GetRowDataStructure(LayoutDT, InKey)
	return WidgetData
end

-- 创建子对象控件
function GenericTipsHelper.CreateSubWidget(InMainWidget, InKey, InParent)
    local LayoutDT = UE.UObject.Load(LayoutDTPath)
	
	return UIHelper.CreateSubWidget(InMainWidget, LayoutDT, InKey, InParent)
end

-------------------------------------------- Debug ------------------------------------

-------------------------------------------- Debug ------------------------------------

_G.GenericTipsHelper = GenericTipsHelper

return GenericTipsHelper
