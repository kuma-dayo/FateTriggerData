require "UnLua"

local ScoreboardConquest = Class("Common.Framework.UserWidget")

function ScoreboardConquest:OnInit()
    print('yyp ScoreboardConquest:OnInit')
	self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.SCOREBOARD_UPDATE_CampSharedInfoParams, Func = self.OnUpdateCampSharedInfoParams, bCppMsg = true },
	}

    -- 需要拿2队数据

	UserWidget.OnInit(self)
end

function ScoreboardConquest:OnShow()
    print('yyp ScoreboardConquest:OnShow')
end


function ScoreboardConquest:OnUpdateCampSharedInfoParams(InFCampSharedInfoParams)
    print('yyp CampId = ', InFCampSharedInfoParams.CampId)
    print('yyp CampName = ', InFCampSharedInfoParams.CampName)
    print('yyp CampScore = ', InFCampSharedInfoParams.CampScore)
end

return ScoreboardConquest
