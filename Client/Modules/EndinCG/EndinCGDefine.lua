
---@class EndinCGDefine
EndinCGDefine = EndinCGDefine or {}

---@class ECGEndMode CG结束方式
EndinCGDefine.ECGEndMode = {
    ErrorExit = 0,  --异常结束
    Skipped = 1,   --跳过播放/不播放
    EscExit = 2,    --Esc退出播放结束
    EndOfPlay = 3   --播放完成后
}


EndinCGDefine.CacheEndinCGKey = "CacheEndinCG"