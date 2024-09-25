---
--- Ctrl 模块，主要用于处理协议
--- Description: 举报
--- Created At: 2023/08/30 15:35
--- Created By: 朝文
---

require("Client.Modules.Report.ReportModel")

local class_name = "ReportCtrl"
---@class ReportCtrl : UserGameController
---@field private model ReportModel
ReportCtrl = ReportCtrl or BaseClass(UserGameController, class_name)

function ReportCtrl:__init()
    CWaring("[cw] ReportCtrl init")
    self.Model = nil
end

function ReportCtrl:Initialize()
    self.Model = self:GetModel(ReportModel)
end

function ReportCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerReportInfoRsp, Func = self.OnPlayerReportInfoRsp},
    }
end

---封装一个获取内部字段的函数
---@param Data any 需要查找的数据
---@vararg any 每一层级中的key
---@return any 查找出来的数据，如果不存在则为nil
local function _InnerGet(Data, ...)    
    --当...没有了，直接返回
    local Param = table.pack(...)
    if Param.n == 0 then return Data end    --不能用 not next(Param) 判断，因为table.pack会生成一个n字段来记录长度
    
    local nextSerchFiled = Param[1]
    --CLog("[cw] trying to find " .. tostring(nextSerchFiled) .. " in " .. tostring(Data))
    --当还存在需要获取的变量层级时，如果Data为空或者不是table的话，则说明不存在
    if Data == nil then
        CWaring("[cw] Data is nil, but search(" .. tostring(nextSerchFiled) .. ") is not end yet, return nil.")
        return nil 
    end
    if type(Data) ~= "table" then
        CWaring("[cw] Data(" .. tostring(type(Data)) .. ") is not a table, cannot get filed from it.")
        return nil 
    end
    
    return _InnerGet(Data[nextSerchFiled], table.unpack(Param, 2, #Param))
end

---封装一个查找并报错的函数
---@param Data any 需要查找的数据
---@vararg any 每一层级中的key
---@return any 查找出来的数据，如果不存在则为nil
local function _InnerCheckLog(Data, ...)
    if _InnerGet(Data, ...) == nil then
        print(...)
        local t = table.pack(...)
        local lastVal = t[#t]
        CError("[cw] Cannot find " .. tostring(lastVal) .. " in " .. tostring(Data))
        return false
    end
    
    return true
end

---内部使用整理数据
---@param Param table 检查里面的 ReportTextContent|ReportAudioContent|ReportImgContent|ReportVideoContent|ReportImgTextContent|ReportRichTextContent 字段是否存在
---@return number&table ReportConst.Enum_ReportContentCombineType类型 & 举报内容数据
local function _InnerFormat(Param)
    local ContentCombineType
    local ContentDetail = {
        TextContent = nil,
        ContentType = nil,
        UrlContent = nil
    }
    
    --1.文本类型
    local ReportConst = require("Client.Modules.Report.ReportConst")
    if _InnerGet(Param, "ReportTextContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.Text
        ContentDetail = {
            TextContent = Param.ReportTextContent.content,
            ContentType = Param.ReportTextContent.contentType
        }

    --2.音频类型
    elseif _InnerGet(Param, "ReportAudioContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.Audio
        ContentDetail = {
            UrlContent = Param.ReportTextContent.audioUrl,
        }

    --3.图片类型
    elseif _InnerGet(Param, "ReportImgContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.Image
        ContentDetail = {
            UrlContent = Param.ReportTextContent.imgUrl,
        }

    --4.视频类型
    elseif _InnerGet(Param, "ReportVideoContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.Image
        ContentDetail = {
            UrlContent = Param.ReportTextContent.videoUrl,
        }

    --5.图文类型
    elseif _InnerGet(Param, "ReportImgTextContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.ImgText
        ContentDetail = {
            TextContent = Param.ReportTextContent.content,
            ContentType = Param.ReportTextContent.contentType,
            UrlContent = Param.ReportTextContent.imgUrl
        }

    --6.富文本类型
    elseif _InnerGet(Param, "ReportRichTextContent") ~= nil then
        ContentCombineType = ReportConst.Enum_ReportContentCombineType.RichText
        ContentDetail = {
            UrlContent = Param.ReportTextContent.content,
            ContentType = Param.ReportTextContent.contentType,
        }
    end
    
    return ContentCombineType, ContentDetail
end

--[[
    local ReportConst = require("Client.Modules.Report.ReportConst")
    local Param = {
        ReportScene                     = ReportConst.Enum_ReportScene.Chat,        --【必填】举报的场景(用来展示可以显示的举报类型页签)，参考 ReportConst.Enum_ReportScene.InGame|Settlemnet|PersonInfo|Chat
        GameInfo                        = {                                         --【必填】用来(1)生成ReportDetailScene与(2)设置ReportSceneId
            GameId      = 123456,                                                   --【必填】当前游戏的GameId
            LevelId     = 1011001,                                                  --【必填】当前游戏的LevelId
            View        = 1|3,                                                      --【必填】当前游戏的视角(fpp, tpp)
            TeamType    = 1|2|4                                                     --【必填】当前游戏的队伍模式(solo, due, squad)
        },
        ReportLocation                  = {1, 2, 3},                                --【必填】举报地点(Avatar/Avatar盒子 所处的位置) {x,y,z}
        
        DefaultSelectReportPlayerIndex  = 1,                                        --【可选】默认选中的举报玩家索引，默认为1
        ReportPlayers = {                                                           --【必填】可供举报的玩家列表，至少有一名玩家
            [1] = {
                PlayerId = 1,                                                       --【必填】被举报的玩家ID
                PlayerName = "PlayerName"                                           --【必填】被举报的玩家名字
            }
        },
        
        --下列的信息只有在当ReportType为2时才有效，下列类型中最多填写一项(1|2|3|4|5|6)
        --如需要举报一个玩家在世界频道上的发言【"xx可乐就是洁厕灵"】有问题，则需要填写 ReportTextContent 里面的内容，例如
            ReportTextContent = {
                contentType = ReportConst.Enum_MsgType.WoldwideChannal,
                content = "xx可乐就是洁厕灵"
            },
        
        --1.文本类型
        ReportTextContent               = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的文字
        },
        --2.【暂无】音频类型
        ReportAudioContent              = {
            audioUrl   = "www.audiourl.com",                                        --需要被举报的音频路径
        },
        --3.【暂无】图片类型
        ReportImgContent                = {
            imgUrl     = "www.imgurl.com",                                          --需要被举报的图片路径
        },
        --4.【暂无】视频类型
        ReportVideoContent              = {
            videoUrl    = "www.videourl.com",                                       --需要被举报的视频路径
        },
        --5.【暂无】图文类型
        ReportImgTextContent            = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的文字
            imgUrl     = "www.imgurl.com",                                          --需要被举报的图片路径
        },
        --6.【暂无】富文本类型
        ReportRichTextContent           = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的富文本文字
        },
    }
    ---@type ReportCtrl
	local ReportCtrl = MvcEntry:GetCtrl(ReportCtrl)
	ReportCtrl:InGameReport(Param)
--]]
---局内使用的举报接口
function ReportCtrl:InGameReport(Param)
    if not Param or type(Param) ~= "table" or not next(Param) then
        CError("[cw][InGameReport] Cannot Handle a nil Param value", true)
        return
    end
    local MdtParam = {}
    
    --检查举报场景
    if not _InnerCheckLog(Param, "ReportScene") then return end
    MdtParam.ReportScene = Param.ReportScene
    
    --检查对局信息，组合ReportDetail中的Scene
    if not _InnerCheckLog(Param, "GameInfo", "GameId") then return end
    if not _InnerCheckLog(Param, "GameInfo", "LevelId") then return end
    if not _InnerCheckLog(Param, "GameInfo", "View") then return end
    if not _InnerCheckLog(Param, "GameInfo", "TeamType") then return end
    MdtParam.ReportSceneId = Param.GameInfo.GameId
    MdtParam.ReportDetailScene = "InGame_" .. Param.GameInfo.GameId .. "_" .. Param.GameInfo.LevelId .. "_" .. Param.GameInfo.View .. "_" .. Param.GameInfo.TeamType
    
    --检查举报位置
    --TODO: 后续看一下允许传入 FVector3D，然后函数内处理数据格式
    if not _InnerCheckLog(Param, "ReportLocation", 1) then return end
    if not _InnerCheckLog(Param, "ReportLocation", 2) then return end
    if not _InnerCheckLog(Param, "ReportLocation", 3) then return end
    MdtParam.ReportLocation = Param.ReportLocation
    
    --检查举报玩家（至少有一个）
    if not _InnerCheckLog(Param, "ReportPlayers", 1, "PlayerId") then return end
    if not _InnerCheckLog(Param, "ReportPlayers", 1, "PlayerName") then return end
    MdtParam.ReportPlayers = Param.ReportPlayers
    
    --确定被举报的内容类型
    MdtParam.ContentCombineType, MdtParam.ContentDetail = _InnerFormat(Param)    
    
    MvcEntry:OpenView(ViewConst.Report, MdtParam)

end

--[[
    local ReportConst = require("Client.Modules.Report.ReportConst")
    local Param = {
        ReportScene                     = ReportConst.Enum_ReportScene.Chat,        --【必填】举报的场景(用来展示可以显示的举报类型页签)，参考 ReportConst.Enum_ReportScene.InGame|Settlemnet|PersonInfo|Chat
        ReportSceneId                   = ReportConst.Enum_HallReportSceneId.PersonalZone, --【必填】举报的举报场景，参考 ReportConst.Enum_HallReportSceneId。PersonalZone|HallSettlement|...
        
        DefaultSelectReportPlayerIndex  = 1,                                        --【可选】默认选中的举报玩家索引，默认为1
        ReportPlayers = {                                                           --【必填】可供举报的玩家列表，至少有一名玩家
            [1] = {
                PlayerId = 1,                                                       --【必填】被举报的玩家ID
                PlayerName = "PlayerName"                                           --【必填】被举报的玩家名字
            }
        },
        
        --下列的信息只有在当ReportType为2时才有效，下列类型中最多填写一项(1|2|3|4|5|6)
        --如需要举报一个玩家在世界频道上的发言【"xx可乐就是洁厕灵"】有问题，则需要填写 ReportTextContent 里面的内容，例如
            ReportTextContent = {
                contentType = ReportConst.Enum_MsgType.WoldwideChannal,
                content = "xx可乐就是洁厕灵"
            },
        
        --1.文本类型
        ReportTextContent               = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的文字
        },
        --2.【暂无】音频类型
        ReportAudioContent              = {
            audioUrl   = "www.audiourl.com",                                        --需要被举报的音频路径
        },
        --3.【暂无】图片类型
        ReportImgContent                = {
            imgUrl     = "www.imgurl.com",                                          --需要被举报的图片路径
        },
        --4.【暂无】视频类型
        ReportVideoContent              = {
            videoUrl    = "www.videourl.com",                                       --需要被举报的视频路径
        },
        --5.【暂无】图文类型
        ReportImgTextContent            = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的文字
            imgUrl     = "www.imgurl.com",                                          --需要被举报的图片路径
        },
        --6.【暂无】富文本类型
        ReportRichTextContent           = {
            contentType = ReportConst.Enum_MsgType.UserNickName,                    --被举报的内容类型 ReportConst.Enum_MsgType.UserNickName|WoldwideChannal|PrivateChannal
            content     = "need to be reported text",                               --需要被举报的富文本文字
        },
    }
    ---@type ReportCtrl
	local ReportCtrl = MvcEntry:GetCtrl(ReportCtrl)
	ReportCtrl:HallReport(Param)
--]]
---局外使用的举报接口
function ReportCtrl:HallReport(Param)
    if not Param or type(Param) ~= "table" or not next(Param) then
        CError("[cw][HallReport] Cannot Handle a nil Param value", true)
        return
    end
    local MdtParam = {}

    --检查举报场景类型，用于控制显示的举报类型有哪些
    if not _InnerCheckLog(Param, "ReportScene") then return end
    MdtParam.ReportScene = Param.ReportScene    
    
    --设置举报场景信息，用于上报
    if not _InnerCheckLog(Param, "ReportSceneId") then return end
    MdtParam.ReportDetailScene = "Hall_" .. tostring(Param.ReportSceneId)

    --检查举报玩家（至少有一个）
    if not _InnerCheckLog(Param, "ReportPlayers", 1, "PlayerId") then return end
    if not _InnerCheckLog(Param, "ReportPlayers", 1, "PlayerName") then return end
    MdtParam.ReportPlayers = Param.ReportPlayers

    --确定被举报的内容类型
    MdtParam.ContentCombineType, MdtParam.ContentDetail = _InnerFormat(Param)

    MvcEntry:OpenView(ViewConst.Report, MdtParam)
end

-----------------------------------------请求相关------------------------------

--[[
    RePlayerId          = 123456;       --【必填】 被举报用户角色id
    RePlayerName        = "PlayerName"; --【必填】 被举报用户昵称
    ReportType          = 1;            --【必填】 举报选项对应的安全分类。举报选项与映射的安全分类由BP提供
    ReportLabelList     = 2;            --【必填】 举报选项对应的安全详细标签，根据不同的安全分类代表不同意思
    ReportText          = "Comments";   --【可选】 举报人在举报中提供的描述信息    
    ReUserId            = 9;            --【自动获取】 被举报用户user_unique_id，对应游戏的openid
    
    ReportDetail        = {             --【必填】 举报事件的详细信息,"json的详细格式见下列举报事件参数，详见下文不同场景的不同选项有不同的数据要求"
		scene           = "pvp",        --【局内】 LevelID_FPP|TPP_1|2|4  字符串拼接               这一部分主要是让使用者能快速知道举报场景
		                                  【局外】 Chat|PersonalZone      维护一个不同场景的枚举
		scene_id        = "12345",      --【局内√】 当前对局的id
		                                  【局外×】 不需要		
		location        = {             --【局内√】 举报用户所在坐标。没有坐标系可不传。数组内坐标系为float
		                                  【局外×】 不需要
			580.6,                      --【局内√】 x
			27.74,                      --【局内√】 y
			520.24,                     --【局内√】 z
		},
		report_content  = {             --【局内√】 被举报的内容信息，直接用于审核。字段内容见内容信息参数
		                                  【局内√】 被举报的内容信息，直接用于审核。字段内容见内容信息参数
			[1] = {
				type        = 1,               --【必填】对应 Report_label
				--content_id  = "29318491721", --【服务器补全】表示当前内容的唯一ID。以内容安全的标准进行上传
				content     = "你好..."         --【可选】具体内容。文本类型传对应文字, 音频和视频传对应url, 富文本传内容安全要求的富文本格式字符串
				                                  当 Report_type 类型为外挂|恶意行为|(等其他非文本信息)的时候，不需要这个
			},
		    --...
		},
		msg_type = 2,                   --【文本必选】 内容场景类型。枚举值联系安全BP获取。
		                                   私聊频道3，世界聊天频道4，用户昵称11
		                                   参考：https://bytedance.feishu.cn/docx/XevJdupRboBreexgdCcc4ZE5n2f		 
		content_combine_type = 6,       --【必选】 被举报的内容类型，富文本类举报必填 
		                                   1文本、2音频、3图片、4视频、5图文、6富文本
		--cc_id = "24241414",           --【服务器补全】被举报内容聚合的id，常用在富文本，目前不需要
		content_url = "xxxx.com"        --【文本可选】 富文本类举报需要提供富文本本身的url
	}
    
    --暂时不处理
    ReGuildId           = 13;           --【暂无】被举报公会id
    ReportVideo         = 6;            --【暂无】举报人在举报中提供的视频信息。用分号(;)分隔多个url
    ReportPicture       = 5;            --【暂无】举报人在举报中提供的图片信息。用分号(;)分隔多个url
    Ip                  = 1.2.3.4;      --【暂无】客户端公网ip
    ReDeviceId          = 12;           --【暂无】被举报用户设备id
    ReporterDeviceId    = 8;            --【暂无】举报用户设备id
--]]
---发送协议，请求举报某个玩家
---@param Msg table 
function ReportCtrl:SendPlayerReportInfoReq(Msg)
    if not Msg then return end
    if not Msg.ReportType then return end
    if not Msg.RePlayerId then return end
    if not Msg.RePlayerName then return end
    if not Msg.ReportLabelList then return end
    
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)    
    
    local ReportData = {
        --依赖传参
        RePlayerId      = Msg.RePlayerId,
        RePlayerName    = Msg.RePlayerName,
        ReportType      = Msg.ReportType,
        ReportLabelList = Msg.ReportLabelList,
        ReportText      = Msg.ReportText and tostring(Msg.ReportText) or "",
        ReUserId        = UserModel.SdkOpenId,
        ReportDetail    = JSON:encode(Msg.ReportDetail),
        
        --暂时不处理
        ReGuildId       = Msg.ReGuildId     or "",  --无工会
        ReportPicture   = Msg.ReportPicture or "",  --无图片功能
        ReportVideo     = Msg.ReportVideo   or "",  --无视频功能
        ReporterDeviceId = Msg.ReporterDeviceId or "", --客户端获取不到，需要服务器支持，被举报用户设备id
        Ip              = "",                       --客户端公网ip
        ReDeviceId      = "",                       --举报用户设备id
        Scene           = Msg.Scene
    }
    
    print_r(ReportData, "[cw] ====ReportData")
    self:SendProto(Pb_Message.PlayerReportInfoReq, ReportData)
end

--[[
Msg = {
    RePlayerId = 123
}
--]]
---接收举报协议回报
---@param Msg any 请说明数据类型及用途
function ReportCtrl:OnPlayerReportInfoRsp(Msg)
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    ReportModel:DispatchType(ReportModel.ON_PLAYER_REPORTED, Msg.RePlayerId)
end