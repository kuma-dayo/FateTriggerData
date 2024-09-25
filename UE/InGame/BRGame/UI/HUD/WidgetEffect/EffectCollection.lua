
local ParentClassName = "Common.Framework.UserWidget"
local UserWidget = require(ParentClassName)
local EffectCollection = Class(ParentClassName)

function EffectCollection:OnInit()
    print("EffectCollection:OnInit")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    self.EffectCollectionViewModel = UIManager:GetViewModelByName("TagLayout.Gameplay.EffectCollection")
    if not self.EffectCollectionViewModel then return end
    self.EffectCollectionViewModel:K2_AddFieldValueChangedDelegateSimple("ActivateEffectName", { self, self.TriggerActivateEffect })
    self.EffectCollectionViewModel:K2_AddFieldValueChangedDelegateSimple("DeactivateEffectName", { self, self.TriggerDeactivateEffect })
    self.EffectCollectionViewModel:K2_AddFieldValueChangedDelegateSimple("ChangeAndActivateEffectName", { self, self.TriggerChangeAndActivateEffect })
    self.EffectCollectionViewModel:K2_AddFieldValueChangedDelegateSimple("SetVariableEffectName", { self, self.TriggerSetEffectVariable })

    UserWidget.OnInit(self)
end

function EffectCollection:OnDestroy()
    print("EffectCollection:OnDestroy")
    if not self.EffectCollectionViewModel then return end
    self.EffectCollectionViewModel:K2_RemoveFieldValueChangedDelegateSimple("ActivateEffectName", { self, self.TriggerActivateEffect })
    self.EffectCollectionViewModel:K2_RemoveFieldValueChangedDelegateSimple("DeactivateEffectName", { self, self.TriggerDeactivateEffect })
    self.EffectCollectionViewModel:K2_RemoveFieldValueChangedDelegateSimple("ChangeAndActivateEffectName", { self, self.TriggerChangeAndActivateEffect })
    self.EffectCollectionViewModel:K2_RemoveFieldValueChangedDelegateSimple("SetVariableEffectName", { self, self.TriggerSetEffectVariable })

    UserWidget.OnDestroy(self)
end

function EffectCollection:TriggerActivateEffect(vm, fieldID)
    if not vm then return end
    print("EffectCollection:TriggerActivateEffect. EffectName = ", vm[fieldID.FieldName])
    local ActivateEffectName = vm[fieldID.FieldName]
    if ActivateEffectName and ActivateEffectName ~= "" and self[ActivateEffectName] then
        self[ActivateEffectName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self[ActivateEffectName]:ActivateSystem(true)
    end
end

function EffectCollection:TriggerDeactivateEffect(vm, fieldID)
    if not vm then return end
    print("EffectCollection:TriggerDeactivateEffect. EffectName = ", vm[fieldID.FieldName])
    local DeactivateEffectName = vm[fieldID.FieldName]
    if DeactivateEffectName and DeactivateEffectName ~= "" and self[DeactivateEffectName] then
        self[DeactivateEffectName]:SetVisibility(UE.ESlateVisibility.Collapsed)
        self[DeactivateEffectName]:DeactivateSystemImmediate()
    end
end

function EffectCollection:TriggerChangeAndActivateEffect(vm, fieldID)
    if not vm then return end
    print("EffectCollection:TriggerChangeAndActivateEffect. EffectName = ", vm[fieldID.FieldName])
    local ChangeAndActivateEffectName = vm[fieldID.FieldName]
    if ChangeAndActivateEffectName and ChangeAndActivateEffectName ~= "" and self[ChangeAndActivateEffectName] then
        local NewNiagaraSystem = vm.NewChangeNiagaraSystem
        if NewNiagaraSystem and NewNiagaraSystem:IsValid() then
            self[ChangeAndActivateEffectName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self[ChangeAndActivateEffectName]:UpdateNiagaraSystemReference(NewNiagaraSystem)
        end
    end
end

function EffectCollection:TriggerSetEffectVariable(vm, fieldID)
    if not vm then return end
    -- print("EffectCollection:TriggerSetEffectVariable. EffectName = ", vm[fieldID.FieldName])
    local SetVariableEffectName = vm[fieldID.FieldName]
    if SetVariableEffectName and SetVariableEffectName ~= "" and self[SetVariableEffectName] then
        local NiagaraComponent = self[SetVariableEffectName]:GetNiagaraComponent()
        if NiagaraComponent then
            local SetVarFunc = NiagaraComponent["SetVariable" .. vm.VarType]
            if SetVarFunc and vm.VariableName and vm.VariableName ~= "" then
                local value = vm["VariableValue" .. vm.VarType]
                if value then
                    SetVarFunc(NiagaraComponent, vm.VariableName, value)
                end
            end
        end
    end
end


return EffectCollection