local SelectMarkItemProxy = Class()

local AdvanceMarkName = 
{
	"MapMarkPoint",
    "MapMarkEnemy",
	"DefenseMark",
	"SomeOneCome"
}

-- -------------------------------------------- Init/ ------------------------------------
function SelectMarkItemProxy:Init(InOwner)
	self.WidgetOwner = InOwner
end

function SelectMarkItemProxy.GetTexture2D(WidgetOwner,Index)
	return WidgetOwner.TexturesIcons:Find(Index)
end

function SelectMarkItemProxy.UpdateSelectName(WidgetOwner,Index)
	return WidgetOwner.ItemNames:Find(Index)
end
function SelectMarkItemProxy.UpdateSelectDescribe(WidgetOwner,Index)
	return WidgetOwner.ItemDescribes:Find(Index)
end

function SelectMarkItemProxy.TriggerOperation(WidgetOwner,ItemId)
	local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(WidgetOwner)
	if AdvanceMarkBussinessComponent and AdvanceMarkName[ItemId] then
		AdvanceMarkBussinessComponent:HitTraceMarkByType(AdvanceMarkName[ItemId])
	end
end



function SelectMarkItemProxy.GetNameDetail(InOwner, ItemId)
	return InOwner.ItemNames:Find(ItemId),UIHelper.ToSlateColor_LC(UIHelper.LinearColor.White)
end

function SelectMarkItemProxy.GetNumDetail(InOwner, ItemId)
	return nil,nil
end

function SelectMarkItemProxy.GetInfiniteDetail(InOwner, ItemId)
	return false
end

function SelectMarkItemProxy.GetLayoutVisibility(InOwner, ItemId)
	local NameVis,DescribeVis,LVis,MVis,RVis
	RVis = UE.ESlateVisibility.HitTestInvisible
	LVis = UE.ESlateVisibility.Collapsed
	if ItemId then
		NameVis = UE.ESlateVisibility.HitTestInvisible
		DescribeVis = UE.ESlateVisibility.HitTestInvisible
		MVis = UE.ESlateVisibility.HitTestInvisible
	else
		NameVis = UE.ESlateVisibility.Collapsed
		DescribeVis = UE.ESlateVisibility.Collapsed
		MVis = UE.ESlateVisibility.Collapsed
	end
	return  NameVis,DescribeVis,LVis,MVis,RVis
end

function SelectMarkItemProxy.ShouldClose(InOwner, MouseKey, IsMouseDown)
	return true
end

--return res1：是否Trigger res2：是否Handled
function SelectMarkItemProxy.ShouldTriggerOperation(InOwner, MouseKey, IsMouseDown)
	print("ShouldTriggerOperation",MouseKey)
	if MouseKey == "MiddleMouseButton" and not IsMouseDown then
		return true,false
	end
	return false,true
end

function SelectMarkItemProxy.TriggerClose(InOwner, ItemId)
end

return SelectMarkItemProxy