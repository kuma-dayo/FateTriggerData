if _G.BuoysConst then
    return
end
BuoysConst = {}


BuoysConst.__DistInt2TextShow = {}


--[[
    获取当前距离对应的 Text展示

    @param DistInt 距离，整型
    @return FText
]]
function BuoysConst.GetTextShowByDistInt(DistInt)
	if not BuoysConst.__DistInt2TextShow[DistInt] then
		--[[[
			进行缓存每个距离对应的文本展示
			1.避免反复Format产生性能消耗
			2.避免反复创建FText产生临存
		]]
		local TheString = StringUtil.FormatSimple("{0}m", math.tointeger(DistInt))
		BuoysConst.__DistInt2TextShow[DistInt] = StringUtil.ConvertString2FText(TheString)

    --     CWaring("BuoysConst.GetTextShowByDistInt===============New")
    -- else
    --     CWaring("BuoysConst.GetTextShowByDistInt===============Cache")
	end
	return BuoysConst.__DistInt2TextShow[DistInt]
end
