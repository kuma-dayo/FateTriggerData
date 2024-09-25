--[[
    http请求管理器
]]


require("Client.Modules.Http.HttpModel")
local class_name = "HttpCtrl"
---@class HttpCtrl : UserGameController
HttpCtrl = HttpCtrl or BaseClass(UserGameController,class_name)


function HttpCtrl:__init()
    CWaring("==HttpCtrl init")
    --- http请求列表
    self.HttpImageUrlReqList = {}
end

function HttpCtrl:Initialize()
    ---@type HttpModel
    self.HttpModel = MvcEntry:GetModel(HttpModel)
end

--[[
    玩家登入
]]
function HttpCtrl:OnLogin(data)
    CWaring("HttpCtrl OnLogin")
    self.HttpImageUrlReqList = {}
end

function HttpCtrl:OnLogout()
    self.HttpImageUrlReqList = {}
end

function HttpCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = HttpModel,    MsgName = HttpModel.ON_REMOVE_TEXTURE_CACHE_EVENT,	Func = self.RemoveTexture2DFromCacheList },  -- 旧的自定义头像失效 移除缓存 
    }
end

------------------------------------请求相关----------------------------

--[[
    请求示例
    self.HttpCtrl:SendImageUrlReq(self.PortraitUrl, function(Texture)
        if CommonUtil.IsValid(self.View) and Texture then 
            self.View.GUIImage_HeadIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.GUIImage_HeadIcon:SetBrushFromTexture(Texture)
        end
    end)
]]

-- 图片URL Http请求 返回Texture2D
---@param ImageUrl string 图片URL
---@param CallBack function 图片赋值回调
function HttpCtrl:SendImageUrlReq(ImageUrl, CallBack)
    if ImageUrl and ImageUrl ~= "" and CallBack then
        -- 检测url链接合法性
        ImageUrl = self:CheckImageUrlLegitimate(ImageUrl)
        -- 先判断缓存里的图片
        local CacheTexTure2D = self.HttpModel:GetCacheTexture2DByImageUrl(ImageUrl)
        if CacheTexTure2D then
            CallBack(CacheTexTure2D)
            CLog("[hz] HttpCtrl:SendImageUrlReq 使用缓存资源 ".. tostring(ImageUrl))
        else
            -- 判断本地有没有保存此图片
            local LocalTexture = self.HttpModel:GetLocalTextureByImageUrl(ImageUrl)
            if LocalTexture then
                CallBack(LocalTexture)
                self.HttpModel:AddTexture2DToCacheList(ImageUrl, LocalTexture)
                CLog("[hz] HttpCtrl:SendImageUrlReq 使用本地保存图片 ".. tostring(ImageUrl))
            else
                -- http请求图片
                self.HttpImageUrlReqList[ImageUrl] = self.HttpImageUrlReqList[ImageUrl] or {} 
                self.HttpImageUrlReqList[ImageUrl][#self.HttpImageUrlReqList[ImageUrl] + 1] = CallBack
    
                -- 防止同一时间重复请求  
                if #self.HttpImageUrlReqList[ImageUrl] == 1 then
                    UE.UGFUnluaHelper.ReqUTextureFromHttp(ImageUrl, function(bValidHttp, bRespSucc, InCode, Texture)
                        if (not bValidHttp) or (not bRespSucc) or (InCode ~= 200) then
                            GameLog.Error("[hz] HttpCtrl:SendImageUrlReq, Error!!! InUrl:", ImageUrl, bValidHttp, bRespSucc, InCode)
                        end
                        if Texture then 
                            self.HttpModel:AddTexture2DToCacheList(ImageUrl, Texture)
                            self.HttpModel:SaveTextureToLocalDir(ImageUrl, Texture)
                            if self.HttpImageUrlReqList[ImageUrl] then
                                for _, ImageCallBack in ipairs(self.HttpImageUrlReqList[ImageUrl]) do
                                    if ImageCallBack then
                                        ImageCallBack(Texture) 
                                    end
                                end
                            end
                        end
                        self.HttpImageUrlReqList[ImageUrl] = {}
                    end)
                end     
            end
        end
    else
        CError("[hz] HttpCtrl:SendImageUrlReq Param is nil, please check ")
    end
end

-- 检测url链接合法性  某些平台会返回一大串的后缀 需要把后缀删除
function HttpCtrl:CheckImageUrlLegitimate(ImageUrl)
    local CheckImageUrl = ImageUrl
    local CheckImageUrlArray = StringUtil.StringTruncationByChar(ImageUrl, "?")
    if CheckImageUrlArray and CheckImageUrlArray[1] then
        CheckImageUrl = CheckImageUrlArray[1]
    end
    return CheckImageUrl
end

-- 移除Texture2D缓存并释放
---@param ImageUrl string 图片URL
function HttpCtrl:RemoveTexture2DFromCacheList(ImageUrl)
    if ImageUrl and ImageUrl ~= "" then
        self.HttpModel:RemoveTexture2DFromCacheList(ImageUrl)
    end
end


---------------------------------------------------