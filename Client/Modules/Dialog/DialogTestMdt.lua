--[[
    剧情表现测试界面
]]

local class_name = "DialogTestMdt";
DialogTestMdt = DialogTestMdt or BaseClass(GameMediator, class_name);

function DialogTestMdt:__init()
end

function DialogTestMdt:OnShow(data)
end

function DialogTestMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = 
    {
    }

    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_Start.OnClicked,				    Func = self.GUIButton_Start_Func },
		{ UDelegate = self.GUIButton_End.OnClicked,				    Func = self.DoClose },
		{ UDelegate = self.WBP_ReuseList_Dir.OnUpdateItem,				    Func = self.OnUpdateDir },
		{ UDelegate = self.WBP_ReuseList_File.OnUpdateItem,				    Func = self.OnUpdateFile },
	}
    self.RootPath = 'BluePrints/Abilities/GADialogue/Favorability'
    self.SelectDirPath = ''
    self.DirWidget = nil
    self.FileWidget = nil
end

function M:OnShow()
    local DirList = UE.UGameHelper.GetAllFilesNameInDir(self.RootPath, false, true)
    self.DirListTable = {}
    for i = 1, DirList:Length() do
        self.DirListTable[#self.DirListTable+1] = DirList:GetRef(i)
    end
    self.WBP_ReuseList_Dir:Reload(#self.DirListTable)
end

function M:OnUpdateDir(Widget,Index)
    local FixIndex = Index + 1
    local DirPath = self.DirListTable[FixIndex]
    Widget.Text:SetText(DirPath)
    Widget.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    CommonUtil.SetTextColorFromeHex(Widget.Text,"#FFFFFF")
    Widget.Button_Item.OnClicked:Clear()
    Widget.Button_Item.OnClicked:Add(self,Bind(self,self.OnClickDir,Widget,DirPath))
end

function M:OnClickDir(Widget,DirPath)
    if self.DirWidget then
        self.DirWidget.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        CommonUtil.SetTextColorFromeHex(self.DirWidget.Text,"#FFFFFF")
    end
    Widget.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetTextColorFromeHex(Widget.Text,"#000000")
    self.DirWidget = Widget
    self.SelectDirPath = DirPath
    self.FileWidget = nil
    self.TargetFilePath = nil
    self.TextFile:SetText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3022"))
    self.FileListTable = {}
    local SubDirPath = self.RootPath.."/"..DirPath
    local FileList = UE.UGameHelper.GetAllFilesNameInDir(SubDirPath,true,false)
    for i = 1, FileList:Length() do
        self.FileListTable[#self.FileListTable+1] = FileList:GetRef(i)
    end
    self.WBP_ReuseList_File:Reload(#self.FileListTable)
end

function M:OnUpdateFile(Widget,Index)
    local FixIndex = Index + 1
    local FilePath = self.FileListTable[FixIndex]
    Widget.Text:SetText(FilePath)
    CommonUtil.SetTextColorFromeHex(Widget.Text,"#FFFFFF")
    Widget.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    Widget.Button_Item.OnClicked:Clear()
    Widget.Button_Item.OnClicked:Add(self,Bind(self,self.OnClickFile,Widget,FilePath))
end

function M:OnClickFile(Widget,FilePath)
    if self.FileWidget then
        self.FileWidget.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
        CommonUtil.SetTextColorFromeHex(self.FileWidget.Text,"#FFFFFF")
    end
    Widget.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetTextColorFromeHex(Widget.Text,"#000000")
    self.FileWidget = Widget
    local FileName = string.gsub(FilePath,".uasset","")
    self.TargetFilePath = StringUtil.Format("/Game/{0}/{1}/{2}.{3}",self.RootPath,self.SelectDirPath,FileName,FileName)
    self.TextFile:SetText(self.TargetFilePath)
end

function M:GUIButton_Start_Func()
    if not self.TargetFilePath then
        UIAlert.Show(G_ConfigHelper:GetStrFromSpecialStaticST("SD_TestText","3025"))
        return
    end
    MvcEntry:GetCtrl(DialogSystemCtrl):ActiveDialog(self.TargetFilePath,true)
end

function M:DoClose()
    MvcEntry:CloseView(self.viewId)    
end


return M
