require("Common.Utils.FTextSupportUtil")

StringUtil = StringUtil or {};

StringUtil.CacheMisc = StringUtil.CacheMisc or {}

local TablePool = require("Common.Utils.TablePool")

-- local LocalizationText2CSVKey = require("Client.Modules.Localization.LocalizationText2CSVKey")
-- local LocalizationTextSDPath = "/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
-- StringUtil.LocalizationTextSDPath = LocalizationTextSDPath
-- function GetLocalizationText(Text)
-- 	if CommonUtil.IsDedicatedServer() then
-- 		--DS环境不处理本地化
-- 		return Text
-- 	end
-- 	if not CommonUtil.g_client_main_start then
-- 		--游戏还未初始化完成时，不做操作，避免错误Cache错误信息
-- 		return Text
-- 	end
-- 	if not StringUtil.CacheMisc.LocalizationTextSDRefProxy then
-- 		--TODO 将Lua本地化SD进行强引用，避免被GC
-- 		local StrTableObject = UE.UObject.Load(LocalizationTextSDPath)
-- 		if StrTableObject then
-- 			local RefProxy = UnLua.Ref(StrTableObject)
-- 			if RefProxy then
-- 				StringUtil.CacheMisc.LocalizationTextSDRefProxy = RefProxy
-- 			else
-- 				CWaring("GetLocalizationText RefProxy failed:" .. LocalizationTextSDPath)
-- 			end
-- 		else
-- 			CWaring("GetLocalizationText StrTableObject nil:" .. LocalizationTextSDPath)
-- 		end
-- 	end
-- 	if LocalizationText2CSVKey[Text] then
-- 		local CSVKey = LocalizationText2CSVKey[Text][1]
-- 		local FixText = G_ConfigHelper:GetStrTableRow(LocalizationTextSDPath,CSVKey)
-- 		if not CommonUtil.IsShipping() then
-- 			if FixText == "<MISSING STRING TABLE ENTRY>" then
-- 				CWaring("GetLocalizationText failed,not found key:" .. LocalizationTextSDPath .. "|Key:" .. CSVKey)
-- 			end
-- 		end
-- 		return FixText
-- 	else
-- 		return Text
-- 	end
-- end

-- --[[
-- 	术语表处理
-- 	{Te.Hero.Name.01}
-- ]]
-- local function FormatTerminology(format_text)
-- 	if not CommonUtil.g_client_main_start then
-- 		--游戏还未初始化完成时，不做操作，避免错误Cache错误信息
-- 		return format_text
-- 	end
-- 	-- local replaceArg = function(n)
-- 	-- 	local TerminologyStr = "{" .. n .. "}";
-- 	-- 	local Tpl_Terminology = G_ConfigHelper:GetSingleItemById(Cfg_TerminologyCfg,TerminologyStr)
-- 	-- 	if Tpl_Terminology then
-- 	-- 		return Tpl_Terminology[Cfg_TerminologyCfg_P.Name]
-- 	-- 	end
-- 	-- 	return n
-- 	-- end
-- 	-- local formatStr = string.gsub(format_text, "{(Te.[^%}]*)}", replaceArg);
-- 	-- return formatStr

-- 	--术语处理同样存在C++接口，但跨域带来的耗时太长了，所以上面用lua实现平替

-- 	--lua平替会丢失FText特性，还是得走回C++
-- 	return UE.UGFUnluaHelper.FormatTerminology(format_text,{})
-- end



local FormatTextPluralInner = function(FixFormatText,NeedFormatTerminology,Key2Values)
	
end


--[[
	检查Str类型，如果不是FText，会进行转换

	返回 FText
	返回 原值  FText传递开关为false情况下，此接口直接返回原值
]]
function StringUtil.ConvertString2FText(Str)
	if not FTextSupportUtil.IsEnabledFText then
		return Str
	end
	local TypeName = StringUtil.GetValueType(Str)
	if TypeName == "ftext" then
		return Str
	elseif TypeName == "string" then
		return UE.FText.FromString(Str)
	elseif TypeName == "integer" or TypeName == "float" then
		return UE.FText.FromString(tostring(Str))
	end
	return UE.FText.FromString("")
end

--[[
	检查Str类型，如果不是string，会进行转换

	返回 string
	返回 原值  FText传递开关为false情况下，此接口直接返回原值
]]
function StringUtil.ConvertFText2String(Str)
	if not FTextSupportUtil.IsEnabledFText then
		return Str
	end
	local TypeName = StringUtil.GetValueType(Str)
	if TypeName == "ftext" then
		return Str:ToString()
	elseif TypeName == "integer" or TypeName == "float" then
		return tostring(Str)
	end
	return Str
end

--[[
	对字符串进行格式化填充：格式化填充字符串,把"{0}","{1}"等填充成对应参数
	并进行单复数处理

	FixFormatText 文本
	NeedFormatTerminology 是否需要检测术语
	Key2Values 描述需要format的键值对列表
]]
function StringUtil.FormatTextPlural(FixFormatText,NeedFormatTerminology,Key2Values)
	if Key2Values then
		local ArgsTypes = TablePool.Fetch("StringUtil")
		local ArgsInt = TablePool.Fetch("StringUtil")
		local ArgsDouble = TablePool.Fetch("StringUtil")
		local ArgsText = TablePool.Fetch("StringUtil")
		local ArgsNames = TablePool.Fetch("StringUtil")

		local TypeName = nil
		local TypeNameValid = true
		for Key,Value in pairs(Key2Values) do
			TypeName = StringUtil.GetValueType(Value)
			TypeNameValid = true
			if TypeName == "string" then
				table.insert(ArgsTypes,UE.EFormatArgumentType.Text)
				table.insert(ArgsText,StringUtil.ConvertString2FText(Value))
			elseif TypeName == "ftext" then
				table.insert(ArgsTypes,UE.EFormatArgumentType.Text)
				table.insert(ArgsText,Value)
			elseif TypeName == "integer" then
				table.insert(ArgsTypes,UE.EFormatArgumentType.Int)
				table.insert(ArgsInt,Value)
			elseif TypeName == "float" then
				table.insert(ArgsTypes,UE.EFormatArgumentType.Double)
				table.insert(ArgsDouble,Value)
			else
				TypeNameValid = false
			end
			if TypeNameValid then
				table.insert(ArgsNames,Key)
			else
				CError("StringUtil.Format args error,the arg type not supported:" .. TypeName,true)
			end
		end
		local FixFormatTextTypeName = StringUtil.GetValueType(FixFormatText)
		local ResultStr =  UE.UGFUnluaHelper.FormatTextFromStirngUtil(GameInstance,StringUtil.ConvertString2FText(FixFormatText),NeedFormatTerminology,ArgsTypes,ArgsNames,ArgsInt,ArgsDouble,ArgsText)
		TablePool.Recycle("StringUtil", ArgsTypes)
		TablePool.Recycle("StringUtil", ArgsInt)
		TablePool.Recycle("StringUtil", ArgsDouble)
		TablePool.Recycle("StringUtil", ArgsText)
		TablePool.Recycle("StringUtil", ArgsNames)
		if FixFormatTextTypeName == "string" then
			ResultStr = StringUtil.ConvertFText2String(ResultStr)
		end
		return ResultStr
	else
		-- local FixFormatTextTypeName = StringUtil.GetValueType(FixFormatText)
		-- local ResultStr =  FormatTerminology(StringUtil.ConvertString2FText(FixFormatText))
		-- if FixFormatTextTypeName == "string" then
		-- 	ResultStr = ResultStr:ToString()
		-- end
		-- CWaring("FixFormatTextTypeName:" .. FixFormatTextTypeName)
		-- return ResultStr

		-- return FixFormatText
		local FixFormatTextTypeName = StringUtil.GetValueType(FixFormatText)
		local ResultStr =  UE.UGFUnluaHelper.FormatTerminology(GameInstance,StringUtil.ConvertString2FText(FixFormatText))
		if FixFormatTextTypeName == "string" then
			ResultStr = StringUtil.ConvertFText2String(ResultStr)
		end
		return ResultStr
	end
end

--[[
格式化填充字符串,把"{0}","{1}"等填充成对应参数, 相当于C#中string.Format的用法。
额外支撑了：
1.Lua手写中文本地化  (参考上面的GetLocalizationText方法)（已废弃）
2.术语处理 （参考上面的FormatTerminology方法）
3.单复数处理、序数词处理  （参考UE.UKismetTextLibrary.Format）
	举例："There {0}|plural(one=is,other=are) {0} {0}|plural(one=cat,other=cats),You came {0}{0}|ordinal(one=st,two=nd,few=rd,other=th)!"
TODO
1.对于已经gsub的结果进行cache，无需二次正则
@param format_text 被填充字符串
@param ... 参数数组
return string
]]
function StringUtil.Format(format_text, ...)
	if not format_text then
		return ""
	end
	if string.len(format_text) <= 0 then
		return format_text
	end
	local Key2Values = nil
	if ... then
		local args = table.pack(...)
		for k,v in ipairs(args) do
			Key2Values = Key2Values or {}
			Key2Values[k-1] = v
		end
	end
	return StringUtil.FormatTextPlural(format_text,true,Key2Values)
end

--[[
表意明确的变量
格式化填充字符串,把"{year}","{month}"等填充成对应参数,
举例使用：
	local TestStr = "多少{year}多少{month},花开了{flowernumber}朵"
	local FixStr = StringUtil.FormatByKey(TestStr,{year = 1,month=2,flowernumber="花的数量"})
额外支撑了：
1.Lua手写中文本地化  (参考上面的GetLocalizationText方法)（已废弃）
2.术语处理 （参考上面的FormatTerminology方法）
3.单复数处理、序数词处理  （参考UE.UKismetTextLibrary.Format）
	举例："There {0}|plural(one=is,other=are) {0} {0}|plural(one=cat,other=cats),You came {0}{0}|ordinal(one=st,two=nd,few=rd,other=th)!"
@param format_text 被填充字符串
@param Key2Values 参数键值对
return string
]]
function StringUtil.FormatByKey(format_text,Key2Values)
	if not format_text then
		return ""
	end
	if string.len(format_text) <= 0 then
		return format_text
	end
	return StringUtil.FormatTextPlural(format_text,true,Key2Values)
end

--[[
	[高效]
	格式化填充字符串,把"{0}","{1}"等填充成对应参数, 相当于C#中string.Format的用法。
	相比StringUtil.Format 没有额外的单复数、术语、本地化等功能，比较高效
	@param format_text 被填充字符串
	@param ... 参数数组
	return string
]]
function StringUtil.FormatSimple(format_text, ...)
	if not format_text then
		return ""
	end
	if string.len(format_text) <= 0 then
		return format_text
	end
	local arg = {...}
	local replaceArg = function(n)
		return tostring(arg[n+1]);
	end
	local formatStr = string.gsub(format_text, "{(%d+)}", replaceArg);
	return formatStr
end


--[[
	[高效]
	格式化填充字符串,把"%s,%d,%f"等填充成对应参数,
	相比StringUtil.Format 没有额外的单复数、术语、本地化等功能，比较高效
	@param format_text 被填充字符串
	@param ... 参数数组
	return string
]]
function StringUtil.Format2(format_text, ...)
	if not format_text then
		return ""
	end
	if string.len(format_text) <= 0 then
		return format_text
	end

	local ResultStr = string.format(format_text,...)
	return ResultStr
end

StringUtil.FormatText = StringUtil.Format;

function StringUtil.FormatNumber(number, length)
	length = length or 3;
	local  ft = "%0"..tostring(length).."d";
	return string.format(ft, number);
end

---使用逗号【,】来分割数字，每三个整数数字之间有一个逗号
---例如【整数】 123456789 会被转换为 123,456,789
---例如【小数】 1234.5678 会被转换为 1,234.57 （满足四舍五入）
---@param n number 需要被转换的数字
---@param decimalLength number 默认为2；【可选】小数部分需要保留的长度
---@return string 带逗号的字符串
function StringUtil.FormatNumberWithComma(n, decimalLength)
	decimalLength = decimalLength or 2

	if type(n) ~= "number" then
		CError("[cw] trying to format a illegal value " .. tostring(n) .. " witch type is " .. tostring(type(n)))
		return nil
	end

	--拆分成俩个部分来处理
	local integer, float = math.modf(n)
	local res = ""

	--处理整数
	local str = tostring(integer)
	for i = #str, 1, -3 do
		if i >= 1 then
			local tmp = string.sub(str, math.max(1, i - 2), i)
			if res == "" then
				res = tmp
			else
				res = tmp .. "," ..res
			end
		end
	end

	--处理小数点
	if float > 0 then
		local strFloat = string.format("%.".. decimalLength .."f", float)
		strFloat = string.sub(strFloat, 2, #strFloat)
		res = res .. strFloat
	end

	return res
end

---格式化时间显示
---@param time number 时间长度，以秒为单位
---@param format_text string 样式，默认为 "{0}:{1}:{2}" 即 时:分：秒
---@return string 格式化后的时间字符串 
function StringUtil.FormatTime(time, format_text)
	format_text = format_text or "{0}:{1}:{2}";
	time = math.floor(time)  or 0;
	local h = math.floor(time/3600);
	local m = math.floor((time % 3600)/60);
	local s = (time % 60);

	h = StringUtil.FormatNumber(h, 2);
	m = StringUtil.FormatNumber(m, 2);
	s = StringUtil.FormatNumber(s, 2);

	return StringUtil.Format(format_text, h,m,s);
end

-- 名字限定字符长度(默认8字节)显示，超出部分显示为'...'
function StringUtil.FormatName(name, limitLength)
	limitLength = limitLength or 8
	if nil == name or "" == name then return name end
    assert("string" == type(name), "not string")
	local name,isSplit = StringUtil.CutByLength(name,limitLength)
    return StringUtil.Format(isSplit and name.."..." or name)
end

-- 取指定长度下的文本，isSplit可供判断是切割过没
function StringUtil.CutByLength(str,limitLength)
	local len = 0
	local isSplit = false
    local i = 1
    while i <= #str do
        local b = string.byte(str, i)
		local charSize = StringUtil.utf8CharSize(b)
		if charSize >=3 then
			len = len + 2 --汉字占3字节，算长度2
		else
        	len = len + 1 --英文，数字占1字节，算长度1
		end
		if len > limitLength then
			isSplit = true
			break
		end
        i = i + charSize
    end
	return StringUtil.Format(isSplit and string.sub(str,1,i-1) or str) , isSplit
end

---把字符串按照某个字符转分割成数组
---@param str string 被分割的字符串
---@param splite_char string 分割符
---@return table 分割出来的列表
function StringUtil.Split(str, splite_char)  
	local start_index = 1
	local str_list = {}
	if not str or string.len(str) <= 0 then
		CWaring("StringUtil.Split str nil,Please Check!")
		print_trackback()
		return str_list
	end
	splite_char = splite_char or ",";
	while true do
		local index = string.find(str, splite_char, start_index)
		if not index then
			table.insert(str_list, string.sub(str, start_index, string.len(str)))
			break
		end
		table.insert(str_list, string.sub(str, start_index, index - 1))
		start_index = index + string.len(splite_char)
	end

	return str_list
end 
--[[
把字符串按照某个字符转分割成数字数组
@param str 被分割的字符串
@param splite_char 分割符
@param start_index 开始位置
@param end_index 终点位置
return table
]]
function StringUtil.SplitNumber(str, splite_char, start_index, end_index)
	local str_list = StringUtil.Split(str, splite_char)
	return StringUtil.ParseNumber(str_list, start_index, end_index)
end
--[[
把字符串中的数字取出来
@param str 被分割的字符串
@param splite_char 分割符
@param start_index 开始位置
@param end_index 终点位置
return table
]]
function StringUtil.ParseNumber(str_list, start_index, end_index)
	local num_list = {}
	local len = #str_list
	if start_index == nil then
		start_index = 1
	end

	if end_index == nil or len < end_index then
		end_index = len
	end
	
	for index = start_index, end_index do
		local num = tonumber(str_list[index]) 
		if num ~= nil then
			table.insert(num_list, num)
		else
			return num_list,false
		end
	end

	return num_list,true
end

--[[去除所有空格]]
function StringUtil.AllTrim(content)
	return string.gsub(content, "%s+", "")
end

--[[去除空格]]
function StringUtil.Trim(content)
	return string.gsub(content, "^%s*(.-)%s*$", "%1")
end
--[[去除左边空格]]
function StringUtil.LTrim(content)
	local _,_,no_blank_text = string.find(content,"%s*([^%s]+.*)") 
	return no_blank_text
end
--[[去除右边空格]]
function StringUtil.RTrim(content)
	local _,_,no_blank_text = string.find(content,"(.*[^%s]+)%s*") 
	return no_blank_text
end
--[[检测连续空格，若存在换为单空格]]
function StringUtil.ReplaceMultipleSpaces(content)
	return string.gsub(content,"%s+", " ")
end
--[[
	空格合法处理
	1. 检测连续空格，若存在换为单空格
	2. 去除左右空格
]]
function StringUtil.HandleTextSpacesToValid(content)
	if not content or content == "" then
		return content
	end
	content = StringUtil.ReplaceMultipleSpaces(content)
	content = StringUtil.LTrim(content)
	return StringUtil.RTrim(content)
end

--以下是HTML处理功能

--[[
 * HTML格式文本
 * @param text 				string 		需要处理的文本
 * @param color 			string	 	颜色 			默认白色
 * @param size  			string 		字体大小		默认为html默认大小
 * @param is_bold 			boolean 	是否粗体		默认不是粗体
 * @param link 				string 		超链接			默认没有超链接
 * @param has_underLine 	boolean 	是否含有下划线  默认没有下划线
 * @param align_way 		string 		对齐方式		默认没有对齐方式
 * @return  
--]]
function StringUtil.FormatHtml(text, color, size, is_bold, link, has_underLine, align)
	
	if text == "" or text == nil then
		return ""
	end

	local param_text = "";
	local result = "";

	if color ~= nil then
		param_text = string.format("%s %s", param_text, string.format("color='#%s' ", color));
	end
	

	if size ~= nil then
		param_text = string.format("%s %s", param_text, string.format("size='%s' ", size));
	end

	result = string.format("<font %s>%s</font>",param_text, text);

	if is_bold then
		result = string.format("<b>%s</b>", result);
	end

	if link ~= nil then
		result = string.format("<a href='%s'>%s</a>", link, result);
	end

	if has_underLine then
		result = string.format("<u>%s</u>", result);	
	end

	if align~=nil then
		result = StringUtil.AlignHtml(result, align);
	end

	return result
end
--[[
设置对齐 
 * @param text 文字
 * @param align_name 对齐方式:-1左对齐；０居中；１右对齐；或"left"、"center"、"right"
]]
function StringUtil.AlignHtml(text, align)
	local align_name = "center";
	if( type(align) == "number")then
		if(align==-1) then
			align_name = "left";
		elseif (align==1) then
			align_name = "right";
		end
	elseif ( type(align) == "string")then
		align_name = align;
	end

	return string.format("<p align='%s'>%s</p>", align_name, text);
end

function StringUtil.NewLine(text)
	ret = string.format("%s%s", text, "<br>")
	return ret
end

--[[
 * 过滤文本中的html标签 
 * @param text
 * @param tag 例如想过滤<font/>,只需传入 "font"
 * 
--]]
function StringUtil.FilterHtml(text, tag)
	if text then
		local function FormatText(n)
			return "";
		end
		if tag == nil then
			--无指定			
			text = string.gsub(text, "<(.-)>",	FormatText);
			text = string.gsub(text, "</(.-)>",	FormatText);
			text = string.gsub(text, "<(.-)/>",	FormatText);
			return text;
		else
			--有指定			
			text = string.gsub(text, string.format("<%s (.-)>", tag),	FormatText);
			text = string.gsub(text, string.format("</%s>", tag),		FormatText);
			text = string.gsub(text, string.format("<%s (.-)/>", tag),	FormatText);
			return text;

		end
	end
	return text;
end

function StringUtil.TraceTable(table)

	local result = StringUtil.ToLuaText(table, 1000);

	return "[table]"..result;
end

function StringUtil.ToLuaText(table, depth, record_dic)
	if depth == nil then
		depth = 0;
	end

	if table == nil then
		return "nil";
	elseif type(table) == "string" then
		return table;
	elseif type(table) == "number" then
		return table;
	end

	local result = "";
	local is_root = record_dic == nil;
	record_dic = record_dic or {__count = 0};

	for k,v in pairs(table) do	
		record_dic.__count = record_dic.__count+1;
		if depth > 0 and record_dic.__count > depth then
			break;
		end
		local kname = k;
		if type(k)=="number" then
			kname = string.format("[%d]", k);
		end
		if type(v)=="string" then
			result = string.format("%s%s = \"%s\", ", result, kname, v);
		elseif type(v)=="table" then
			if record_dic[v] == nil then
				record_dic[v] = true;
				result = string.format("%s%s = {%s}, ", result, kname, StringUtil.ToLuaText(v, depth, record_dic));
			end
		else
			result = string.format("%s%s = %s, ", result, kname, v);
		end
	end
	if is_root then
		return string.format("{%s}", result);
	end
	return result;
end

function StringUtil.AddChar(text)
	if text ~= "" then
		text = text..", ";
	end
	return text;
end

function StringUtil.JsonEncode(table, string_only, record_dic)

	if table == nil then
		return nil;
	elseif type(table) == "string" then
		return "\""..table .. "\"";
	elseif type(table) == "number" and not string_only then
		return table;
	elseif type(table) ~= "table" then
		return "\""..tostring(table).."\"";
	end

	local result = "";
	local is_root = record_dic == nil;
	local len = #table;
	local is_array = len > 1;
	record_dic = record_dic or {__count = 0};

	if is_array then
		
		local count = 0;
		for k,v in ipairs(table) do
			count = count + 1;
			if v == nil then
				break;
			end
		end
		--有空值的数组不算数组
		if count < len then
			is_array = false;
		end
		--print("is_array", is_array, count, len);		
	end

	for k,v in pairs(table) do	
		record_dic.__count = record_dic.__count+1;
		if record_dic.__count > 1000000 then
			break;
		end
		if type(v) == "string" then
			result = string.format("%s\"%s\":\"%s\"", StringUtil.AddChar(result), k, v);
		elseif type(v) == "table" then
			if record_dic[v] == nil then
				record_dic[v] = true;
				if is_array then
					result = string.format("%s%s", StringUtil.AddChar(result), StringUtil.JsonEncode(v, string_only, record_dic));
				else
					result = string.format("%s\"%s\":%s", StringUtil.AddChar(result), k, StringUtil.JsonEncode(v, string_only, record_dic));
				end	
			end
		elseif type(v) == "number" and not string_only then
			result = string.format("%s\"%s\":%s", StringUtil.AddChar(result), k, v);
		else
			result = string.format("%s\"%s\":\"%s\"", StringUtil.AddChar(result), k, tostring(v));
		end
	end

	local f = is_array and "[%s]" or "{%s}";
	return string.format(f, result);
end

function StringUtil.utf8CharSize(c)
    if not c then return 0 end
    if c > 240 then return 4 end
    if c > 225 then return 3 end
    if c > 192 then return 2 end
    return 1
end

--字符长度
function StringUtil.utf8StringLen(str)
    if nil == str or "" == str then return 0 end
	str = StringUtil.ConvertFText2String(str)
    assert("string" == type(str), "not string")

    local len = 0
    local i = 1
    while i <= #str do
        local b = string.byte(str, i)
		local charSize = StringUtil.utf8CharSize(b)
        i = i + charSize
		if charSize >=3 then
			len = len + 2 --汉字占3字节，算长度2
		else
        	len = len + 1 --英文，数字占1字节，算长度1
		end
    end
    return len
end


--[[
    时间显示处理
    - 剩余时间超过7天时：显示具体过期日期；
    - 剩余时间小于或等于7天时：显示具体天数；
    - 剩余时间小于1天时：显示具体剩余小时数分钟数；
    - 剩余时间小于1小时：显示具体分钟数秒数；

	LeftSeconds: 剩余时间（秒）
	EndDate: 截止日期 - 大于7天直接显示为截止时间
	-- LeftStr [Optional]: 默认为"剩余" -- 多语言翻译不支持此文本动态设置。暂时写死为"有效期"，后续再看怎么修改
	-- EndStr [Optional]: 默认为"过期" -- 多语言翻译不支持此文本动态设置。暂时写死为"过期"，后续再看怎么修改
]]

function StringUtil.Conv_TimeShowStr(LeftSeconds,EndDate)
	-- LeftStr = LeftStr or "剩余"
	-- EndStr = EndStr or "过期"
    local Str = LeftSeconds
	local Color = DepotConst.TimeTextColor.Normal
    if LeftSeconds <= 0 then
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Expired"))
		Color = DepotConst.TimeTextColor.Warning
        return Str,Color
    end
    local OneHourSeconds = 3600
    local OneDaySeconds = 24 * OneHourSeconds
    local SevenDaysSeconds = 7 * OneDaySeconds
    if LeftSeconds > SevenDaysSeconds then
        -- ＞7天，则显示为“过期：x月x日” 如果过期时间跨越年份，则显示为“过期：xxxx年x月x日
        local CurYear = tonumber(os.date("%Y",GetTimestamp()))
        local EndYear = tonumber(os.date("%Y",EndDate))
        local ShowTime = EndYear > CurYear and os.date(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Yyearmmonthdday"),EndDate) or os.date(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_mmonthdday"),EndDate)
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Expired"),ShowTime)
    elseif LeftSeconds >= OneDaySeconds then
        -- ＞1天，则显示为“剩余：x天”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Validitydays"), math.floor(LeftSeconds/OneDaySeconds))
    elseif LeftSeconds >= OneHourSeconds then
        -- ＞1小时，则显示为“剩余：x时x分”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Validityhoursminutes"), math.floor(LeftSeconds/OneHourSeconds),math.floor((LeftSeconds % OneHourSeconds)/60))
		Color = DepotConst.TimeTextColor.Warning
    else
        -- ＜1小时，则显示为“x分钟x秒”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Validityminutessecon"),math.floor((LeftSeconds % OneHourSeconds)/60),(LeftSeconds % 60))
		Color = DepotConst.TimeTextColor.Warning
    end
    return Str,Color
end

function StringUtil.Conv_TimeShowStrNew(Timestamp, Format, NullString)
    if Timestamp <= 0 then
        return StringUtil.Format(NullString)
    end
	return StringUtil.Format(Format, TimeUtils.TimestampToDateTime(Timestamp))
end

--[[
    时间显示处理
    - 剩余时间≥1天，则显示为“剩余n天”
  	- 剩余时间＜1天，则显示“剩余n小时”
    - 剩余时间≤1小时时，显示“剩余0小时”

	--暂时：邮件用到
]]
function StringUtil.FormatExpireTimeShowStr(LeftSeconds,EndDate)
	-- EndStr = EndStr or "过期"
    local Str = LeftSeconds
    if LeftSeconds <= 0 then
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Questionnaire_OutOfDate"))
        return Str
    end
    local OneHourSeconds = 3600
    local OneDaySeconds = 24 * OneHourSeconds
    local SevenDaysSeconds = 7 * OneDaySeconds
    if LeftSeconds >= OneDaySeconds then
        -- >=1天，则显示为“剩余x天”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_daysremaining"), math.floor(LeftSeconds/OneDaySeconds))
    elseif LeftSeconds > OneHourSeconds then
        -- >1小时，则显示为“剩余x时”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hoursremaining"), math.floor(LeftSeconds/OneHourSeconds))
    else
        -- <=1小时，则显示为“剩余0小时”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hoursremaining"), 0)
    end
    return Str
end

--[[
    时间显示处理
    - 剩余时间≥1天，则显示为“n天”
	- 剩余时间<1天，则显示“n小时”
    - 剩余时间≤1小时时，显示“n分钟”
    - 剩余时间≤1分钟时，显示“n秒”
]]
function StringUtil.FormatLeftTimeShowStr(LeftSeconds,FormatStr,EndStr)
	FormatStr = FormatStr or G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam")
	EndStr = EndStr or G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Expired") 
    local Str = LeftSeconds
    if LeftSeconds <= 0 then
        -- Str = StringUtil.Format("已{0}",EndStr) -- 多语言翻译不支持动词文本动态设置。修改为整体文本由外部传入，不拼接，后续再看怎么修改
        Str = StringUtil.Format(EndStr)
        return Str
    end
    local OneMinuteSeconds = 60
    local OneHourSeconds = 60 * OneMinuteSeconds
    local OneDaySeconds = 24 * OneHourSeconds
    if LeftSeconds >= OneDaySeconds then
        -- ＞1天，则显示为“x天”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_days"), math.floor(LeftSeconds/OneDaySeconds))
    elseif LeftSeconds >= OneHourSeconds then
        -- ＞1小时，则显示为“x小时”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hours"), math.floor(LeftSeconds/OneHourSeconds))
	elseif LeftSeconds >= OneMinuteSeconds then
        -- ＞1分钟，则显示为“x分钟”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_minutes"), math.floor(LeftSeconds/OneMinuteSeconds))
    else
        -- ＜1小时，则显示为“x秒”
        Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_seconds"),LeftSeconds)
    end
	Str = StringUtil.Format(FormatStr, Str)
    return Str
end

--[[
    timeTable.year(4位)，
    timeTable.month(1-12)，
    timeTable.day (1-31)，
    timeTable.hour (0-23)，
    timeTable.min (0-59)，
    timeTable.sec (0-61)，
    timeTable.wday (星期几， 星期天为1)
    timeTable.yday (年内天数)
    timeTable.isdst (是否为日光节约时间true/false)

	--暂时：邮件用到
]]--

function StringUtil.FormatTimeShow(TimeTable)
	if TimeTable == nil or TimeTable == "" then
		return ""
	end
	return StringUtil.Format("{0}/{1}/{2}", 
		TimeTable.year,  
		TimeTable.month,
		TimeTable.day)
end

--- 获取富文本的临时写法
---@param ID number
---@param Size number
function StringUtil.GetRichTextImgForId(ID, Size)
	Size = Size or 70
	return StringUtil.Format('<img src="Item_{0}" size="{1}"></>', tostring(ID), Size)
end


-- 按首字母比较两串字符
--[[
	1. 单字符比较，数量少 -> 数量多
	2. 数字、符号、字母（按ASCII） -> 中文 -> 日文
	3. 字母： 大写 -> 小写
	4. 中文： 转为拼音 —> 取首字母 -> 按字母顺序排
	5. 日文： 按五十音图排序
]]
function StringUtil.CompareFirstWord(WordA,WordB)
    assert("string" == type(WordA), "CompareFirstWord WordA not string")
    assert("string" == type(WordB), "CompareFirstWord WordB not string")
    if not WordA or WordA == "" then
		return false
	elseif not WordB or WordB == "" then
		return true
	end
	-- 判断为中文字符
	local function isChinese(Char)
		if not utf8.len(Char) then
			return false
		end
		local unicode_byte = utf8.codepoint(Char)
		return unicode_byte >= 0x4E00 and unicode_byte <= 0x9FA5
  	end
  
	-- 判是否为日文字符
	local function isJapanese(Char)
		if not utf8.len(Char) then
			return false
		end
		local unicode_byte = utf8.codepoint(Char)
		return  (unicode_byte >= 0x3040 and unicode_byte <= 0x309F) or (unicode_byte >= 0x30A0 and unicode_byte <= 0x30FF) or (unicode_byte >= 0x31F0 and unicode_byte <= 0x31FF)
	end
	
	-- 判断是否小写字母
	local function IsLower(Char)
		return Char >= "a" and Char <= "z" 
	end

	local ConvertChineseToPinyin = UE.UGameHelper.ConvertChineseToPinyin
	local LengthA,LengthB = #WordA,#WordB
    local i,j = 1,1
    while i <= LengthA or j <=LengthB do
		local ByteA,ByteB =  string.byte(WordA, i),string.byte(WordB, j)
		local CharSizeA,CharSizeB = StringUtil.utf8CharSize(ByteA),StringUtil.utf8CharSize(ByteB)
		local CharA = string.sub(WordA, i, i + CharSizeA - 1)
		local CharB = string.sub(WordB, j, j + CharSizeB - 1)
		-- 1. 单个字符比，字符一样比较下一个字符，直到数量短的在前面
		if CharSizeA == 0 and CharSizeB > 0 then
			return true
		elseif CharSizeA > 0 and CharSizeB == 0 then
			return false
		elseif CharSizeA ~= CharSizeB then
			-- 2. 英文数字符号 > 中文日文
			return CharSizeA < CharSizeB
		else
			-- 3. 都是英文数字符号 / 都不是英文数字符号
			local isJapaneseA,isJapaneseB = isJapanese(CharA) , isJapanese(CharB)
			if isJapaneseA and isJapaneseB then
				-- 3.1 都是日文，按五十音图排序
				local JapanOrder = {
					["あ"]=1,["い"]=2,["う"]=3,["え"]=4,["お"]=5,["か"]=6,["き"]=7,["く"]=8,["け"]=9,["こ"]=10,["さ"]=11,["し"]=12,["す"]=13,["せ"]=14,["そ"]=15,["た"]=16,["ち"]=17,["つ"]=18,["て"]=19,["と"]=20,["な"]=21,["に"]=22,["ぬ"]=23,["ね"]=24,["の"]=25,["は"]=26,["ひ"]=27,["ふ"]=28,["へ"]=29,["ほ"]=30,["ま"]=31,["み"]=32,["む"]=33,["め"]=34,["も"]=35,["や"]=36,["ゆ"]=37,["よ"]=38,["ら"]=39,["り"]=40,["る"]=41,["れ"]=42,["ろ"]=43,["わ"]=44,["を"]=45,["ん"]=46
				}
				if not JapanOrder[CharA] or not JapanOrder[CharB] then
					return false
				end
				if JapanOrder[CharA] ~= JapanOrder[CharB] then
					return JapanOrder[CharA] < JapanOrder[CharB]
				end
			elseif isJapaneseA ~= isJapaneseB then
				-- 3.2 非日文 -> 日文
				return isJapaneseB 
			else
				-- 3.3 都非日文
				local isChineseA,isChineseB = isChinese(CharA) , isChinese(CharB)
				if isChineseA ~= isChineseB then
					-- 3.3.1 非中文 -> 中文
					return isChineseB
				else
					-- 3.5 都是中文/ 都是英文
					--中文 转为拼音首字母
					if isChineseA or isChineseB then
						-- 都是中文 转换为拼音首字母
						local CharAList = ConvertChineseToPinyin(CharA)
						local CharBList = ConvertChineseToPinyin(CharB)
						CharA = CharAList:Length() >= 1 and string.sub(CharAList:Get(1), 1, 1) or "*"
						CharB = CharBList:Length() >= 1 and string.sub(CharBList:Get(1), 1, 1) or "*"
					end
					local IsALower,IsBLower = IsLower(CharA),IsLower(CharB)
					local LowerA,LowerB = string.lower(CharA) ,string.lower(CharB)
					if IsALower ~= IsBLower and LowerA ~= LowerB then
						-- 有大小写区分 且 不是互为大小写
						if (IsALower and CharA > LowerB) or
							(IsBLower and LowerA > CharB) then
							-- 'f' > 'A' 但 'a' < 'f' 应该逆序 A -> f
							-- 'F' < 'a' 但 'f' > 'a' 应该逆序 a -> F
							return false
						else
							return true
						end
					elseif CharA ~= CharB then
						-- 同为大写或小写，按Ascii比较
						-- 互为大小写，大写在前面 按Ascii比较
						return  CharA < CharB
					end
				end
			end
		end
        i = i + CharSizeA
        j = j + CharSizeB
    end
end

--[[
	获取值的类型
	string
	integer
	float
	table
	userdata
	ftext
]]
function StringUtil.GetValueType(Value)
	local TypeName = type(Value)
	if TypeName == "number" then
		return math.type(Value)
	end
	if FTextSupportUtil.IsEnabledFText then
		if FTextSupportUtil.CheckStrIsText(Value) then
			TypeName = 'ftext'
		end
	end
	return TypeName
end

--[[
	将数字转为带单位字母 K，M，B的
	precision: 保留的小数位数, 默认保留1位 （四舍五入）
]]
function StringUtil.FormatNumberStr(number, precision)
	precision = precision or 1
	local formatStr = string.format("%%.%df", precision)
	local function transform(divisor, unitWord)
		local base = 10^precision
		local num = math.floor((number/divisor + 5/(base*10)) * base) / base
		return StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"),string.format(formatStr, num), unitWord)
	end
	if number >= 999999995 then
		-- 十亿
		return transform(1000000000, "B")
	elseif number >= 999995 then
		-- 百万
		return transform(1000000, "M")
	elseif number>= 1000 then
		return transform(1000, "K")
	else
		return number
	end

	
end

--[[
	字符串根据特定子串(或字符)进行截取，返回table
	InIsHold: InChar是否在子串中保留 
]]
function StringUtil.StringTruncationByChar(InString, InChar, InIsHold)
	InIsHold = InIsHold or false --默认不保留
	--return string.match(inString, "(.-)" .. char)
	local result = {}
	for subStr in string.gmatch(InString, "([^"..InChar.."]+)") do --将字符串按某个字符切割一次存放进table
		if InIsHold and #result > 0 then
			subStr = InChar .. subStr
		end
		table.insert(result, subStr)
	end
	if #result < 1 then --若字符串不存在该符号, 则原样放进第一个元素
		table.insert(result, InString)
	end
	--print("StringUtil.StringTruncationByChar>>>>>>>>>>>>>>", inString, result[1], result[2])
	return result
end

--[[
	拆分玩家名字 ，返回玩家名字+数字ID
	InIsHold: 数字ID前是否保留'#'
]]
---@return string 玩家名字 string 数字ID
function StringUtil.SplitPlayerName(InString, InIsHold)
	local PlayerName = ""
	local PlayerDigitalId = ""
	if InString then
		local PlayerNameArray = StringUtil.StringTruncationByChar(InString, "#", InIsHold)
		if PlayerNameArray then
			PlayerName = PlayerNameArray[1] or ""
			PlayerDigitalId = PlayerNameArray[2] or ""
		end
	end
	return PlayerName, PlayerDigitalId
end


---最多保留n(默认2)位小数，舍弃后续小数版本
---0.0      ->    0
---1.0		->    1
---1.00		->    1
---1.1      ->    1.1
---2.22     ->    2.22
---3.333    ->    3.33
---8.888    ->    8.88
---9.999    ->    9.99
---@param Float	number 需要处理的小数
---@param MaxRemainFloatNum nil|number 需要保留的最大位数，默认为2
---@return number 处理完成的小数
function StringUtil.FormatFloat(Float, MaxRemainFloatNum)
	if Float == 0 then return 0 end
	MaxRemainFloatNum = MaxRemainFloatNum or 2
	--转为整数计算
	local res = math.floor(Float * (10 ^ (MaxRemainFloatNum)))
	local remain = MaxRemainFloatNum
	--去除末尾0
	while res % 10 == 0 and remain > 0 do
		res = math.floor(res / 10)
		remain = remain - 1
	end
	--保留小数
	if remain > 0 then
		res = res / (math.floor((10 ^ remain)))
	end
	return res
end

---最多保留两位小数，四舍五入版本
---0.0      ->  0
---1.1	    ->	1.1
---2.22		->	2.22
---3.333	->	3.33
---8.888	->	8.89
---9.999	->	10
---@param Float	number 需要处理的小数
---@return number 处理完成的小数
function StringUtil.FormatFloat_Reamain2Float(Float)
	local res = string.format("%.2f", Float)
	if res%1 == 0 then
		res = string.format("%.0f", res)
	elseif res*10%1 == 0 then
		res = string.format("%.1f", res)
	end
	return res
end

function StringUtil.NumToChinese(num)
	local chinese_num = ""
    local num_map = {
        G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_zero"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_one"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_two"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_three"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_four"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_five"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_six"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_seven"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_eight"), G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_nine")
    }
    local unit_map = {
        [0] = '',
        [1] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_ten"),
        [2] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hundred"),
        [3] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_thousand"),
        [4] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_tenthousand"),
        [8] = G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_ahundredmillion"),
    }
	local function convert(num)
        local str = tostring(num)
        local len = string.len(str)
        local result = ''
        local zero_flag = false
        for i = 1, len do
            local n = tonumber(string.sub(str, i, i))
            if n == 0 then
                zero_flag = true
            else
                if zero_flag then
                    result = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), result, num_map[1])
                    zero_flag = false
                end
				if not (n == 1 and (len-i) == 1 and i == 1) then  -- 避免出现"一十"
                    result = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), result, num_map[n+1])
                end
                result = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), result, unit_map[len-i])
            end
        end
        return result
    end

    local str = tostring(num)
    local len = string.len(str)
    for i = 1, len do
        local n = tonumber(string.sub(str, i, i))
        if n == 0 then
            if len-i == 4 or len-i == 8 then
                chinese_num = chinese_num .. unit_map[len-i]
            end
        else
            chinese_num = chinese_num .. convert(tonumber(string.sub(str, i, len)))
            break
        end
    end

    return chinese_num
end

--[[
	大于等于25小时，显示“XX天XX小时”
	大于等于24小时，小于25小时, 显示“XX小时”
	大于等于1小时，小于24小时，显示“XX小时”
	小于1小时展示“1小时”
	剩余XX小时退位显示，不满X小时统一展示为X小时
]]
function StringUtil.FormatLeftTimeShowStrRuleOne(LeftSeconds)
    local Str
	local OneMinuteSeconds = 60
    local OneHourSeconds = 60 * OneMinuteSeconds
    local OneDaySeconds = 24 * OneHourSeconds
	local t25HourSeconds = 25 * OneHourSeconds

	if LeftSeconds >= t25HourSeconds then
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Days_Hour"), math.floor(LeftSeconds / OneDaySeconds), math.floor(LeftSeconds % OneDaySeconds / OneHourSeconds))
	elseif LeftSeconds >= OneDaySeconds then
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hours"), math.floor(LeftSeconds/OneHourSeconds))
	elseif LeftSeconds >= OneHourSeconds then
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hours"), math.floor(LeftSeconds/OneHourSeconds))
	else
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_hours"), 1)
	end
    return Str
end
--[[
	大于等于24小时，显示“XX天XX小时”
	小于24小时，大于等于1分钟, 显示“XX小时XX分”
	小于1分钟展示“0小时1分”
]]
function StringUtil.FormatLeftTimeShowStrRuleTwo(LeftSeconds)
    local Str
	local OneMinuteSeconds = 60
    local OneHourSeconds = 60 * OneMinuteSeconds
    local OneDaySeconds = 24 * OneHourSeconds

	if LeftSeconds >= OneDaySeconds then
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Days_Hour"), math.floor(LeftSeconds / OneDaySeconds), math.floor(LeftSeconds % OneDaySeconds / OneHourSeconds))
	elseif LeftSeconds >= OneMinuteSeconds then
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Hours_Minute"), math.floor(LeftSeconds/OneHourSeconds), math.floor(LeftSeconds % OneHourSeconds / OneMinuteSeconds))
	else
		Str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Hours_Minute"), 0, 1)
	end
    return Str
end

--- 分割段落和标题
--- 适用于分割如下文本
--- {Title}XXXXXX{Content}XXXXXX{Title}XXXXXX{Content}XXXXXX
---@param InString string
function StringUtil.SplitTitleAndContentStrings(InString)
	local Pattern1 = "{{0}}(.-){"
	local Pattern2 = "{{0}}(.-)$"
	local GetPattern = function(InStr)
		local Str = string.match(InString, StringUtil.FormatSimple(Pattern1, InStr))
		if not Str then
			Str = string.match(InString, StringUtil.FormatSimple(Pattern2, InStr))
		else
			InString = string.gsub(InString,StringUtil.FormatSimple(Pattern1, InStr),"{", 1)
		end
		if Str then
			Str = string.gsub(string.gsub(Str,"^%s*\n+", ""),"%s*\n+$", "")
		end
		return Str
	end

	local MainTitle = GetPattern("MainTitle")
	local StrTable = {}
	local MaxDepth = 30
	local CurDepth = 0
	while true do
		if CurDepth > MaxDepth then
			return
		end
		CurDepth = CurDepth + 1

		local Title = GetPattern("Title")
		if not Title then
			break
		end
		local Content = GetPattern("Content")
		if not Content then
			break
		end
		table.insert(StrTable, {
			Title = Title,
			Content = Content
		})
	end
	return MainTitle, StrTable
end

--根据时间戳获取日期
---@return string 1.选择中文时返回"年月日" 例如"1970.2.1" 2.选择其他语言时返回"日月年",例如"1.2.1970"
function StringUtil.FormatDateByLanguage(TimeStamp)
	local TimeTable = TimeUtils.TableTime_FromTimeStamp(TimeStamp)
	if not TimeTable then
		return ""
	end
	local DateStr = StringUtil.FormatSimple("{0}.{1}.{2}", TimeTable.Local.Year, TimeTable.Local.Month, TimeTable.Local.Day)
	local LocalLanuage = MvcEntry:GetModel(LocalizationModel):GetCurSelectLanguage()
	if LocalLanuage ~= LocalizationModel.IllnLanguageSupportEnum.zhHans and LocalLanuage ~= LocalizationModel.IllnLanguageSupportEnum.zhHant then
		DateStr = StringUtil.FormatSimple("{0}.{1}.{2}", TimeTable.Local.Day, TimeTable.Local.Month, TimeTable.Local.Year)
	end
	return DateStr
end

return StringUtil;