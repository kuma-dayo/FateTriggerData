--[[
    Http请求缓存数据模型
]]

local super = GameEventDispatcher;
local class_name = "HttpModel";

---@class HttpModel : GameEventDispatcher
---@field private super GameEventDispatcher
HttpModel = BaseClass(super, class_name)
HttpModel.ON_REMOVE_TEXTURE_CACHE_EVENT = "ON_REMOVE_TEXTURE_CACHE_EVENT" -- 清除缓存图片事件 - 携带缓存图片url

-- 图片int类型
HttpModel.Const_PictureIntType = {
    -- 对应C++层的枚举
    PNG = 0,
}

-- 图片字符串类型  用于上传图片时服务器确定类型
HttpModel.Const_PictureStringTypeList = {
    [HttpModel.Const_PictureIntType.PNG] = "png",
}

function HttpModel:__init()
    self:_dataInit()
end

function HttpModel:_dataInit()
    -- 缓存的图片列表 key为http请求的Url value为缓存资源信息
    self.Texture2DCacheList = {}
end

function HttpModel:OnLogin(data)

end

--[[
    玩家登出时调用
]]
function HttpModel:OnLogout(data)
    HttpModel.super.OnLogout(self)
    self:RemoveAllTexture2DCacheList()
    self:_dataInit()
end

-------- 对外接口 -----------
-- 添加Texture2D 到缓存列表
function HttpModel:AddTexture2DToCacheList(ImageUrl, Texture2D)
    local RefProxy = UnLua.Ref(Texture2D)
    self.Texture2DCacheList[ImageUrl] = {
        RefProxy = RefProxy,
        Object = Texture2D,
    }
    CLog("[hz] HttpModel:AddTexture2DToCacheList 缓存图片 " .. tostring(ImageUrl))
end

-- 移除Texture2D缓存并释放
function HttpModel:RemoveTexture2DFromCacheList(ImageUrl)
    local RefDes = self.Texture2DCacheList[ImageUrl]
    if RefDes then
        if CommonUtil.IsValid(RefDes.Object) then
            UnLua.Unref(RefDes.Object)
            RefDes.Object = nil
        end
        RefDes.RefProxy = nil
    end
    self.Texture2DCacheList[ImageUrl] = nil
    CLog("[hz] HttpModel:RemoveTexture2DFromCacheList 移除Texture2D " .. tostring(ImageUrl))
end

-- 移除所有Texture2D缓存并释放
function HttpModel:RemoveAllTexture2DCacheList()
    for ImageUrl, _ in pairs(self.Texture2DCacheList) do
        self:RemoveTexture2DFromCacheList(ImageUrl) 
    end
    self.Texture2DCacheList = {}
end

-- 通过图片的URL链接获取缓存的Texture2D
function HttpModel:GetCacheTexture2DByImageUrl(ImageUrl)
    local CacheTexture2D = nil
    local RefDes = self.Texture2DCacheList[ImageUrl]
    if RefDes and CommonUtil.IsValid(RefDes.Object) then
        CacheTexture2D = RefDes.Object
    end
    return CacheTexture2D
end

-- 获取本地保存的图片通过ImageUrl 返回texture2d 返回空即本地没有此图片
function HttpModel:GetLocalTextureByImageUrl(ImageUrl)
    local SaveDir = self:GetTextureSaveDir(ImageUrl)
    local LocalTexture = nil
    if SaveDir then
        LocalTexture = CommonUtil.GetTextureByFile(SaveDir)
    end
    return LocalTexture
end

-- 保存图片到本地目录
function HttpModel:SaveTextureToLocalDir(ImageUrl, Texture2D)
    local SaveDir, PictureIntType = self:GetTextureSaveDir(ImageUrl)
    if SaveDir and Texture2D then
        CommonUtil.SaveTextureToFile(Texture2D, SaveDir, PictureIntType)
    end
end

-- 获取图片的本地保存路径
---@return string|nil 本地保存路径 number|nil 图片保存类型
function HttpModel:GetTextureSaveDir(ImageUrl)
    local StartSymbol = "/"
    local EndSymbol = ".png"
    local SaveDir = nil
    -- 保存的图片名称
    local PictureName = nil
    -- 保存的图片类型 int类型
    local PictureIntType = nil
    for PictureType, PictureStringType in pairs(HttpModel.Const_PictureStringTypeList) do
        EndSymbol = "." .. PictureStringType
        local CheckStr = ".*" .. StartSymbol .. "(.-)%" .. EndSymbol
        local StartPos, EndPos, CapturedStr = string.find(ImageUrl, CheckStr)
        if StartPos and EndPos then
            -- 中间的名字作为图片名称
            PictureName = CapturedStr
            PictureIntType = PictureType
            break
        end
    end
    if PictureName then
        SaveDir = "PlayerCustomHead/" .. PictureName .. EndSymbol
    end
    return SaveDir, PictureIntType
end

-- 通过图片int类型获取对应的string类型  用于与服务器通信
---@param PictureIntType number 图片int类型 HttpModel.Const_PictureIntType
function HttpModel:GetPictureStringTypeByIntType(PictureIntType)
    local PictureStringType = HttpModel.Const_PictureStringTypeList[PictureIntType]
    return PictureStringType
end
