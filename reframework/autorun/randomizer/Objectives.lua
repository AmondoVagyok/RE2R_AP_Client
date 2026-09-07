local Objectives = {}
Objectives.isInit = false

function Objectives.Init()
    if not Objectives.isInit then
        Objectives.isInit = true

        Objectives.Destroy()
    end
end

function Objectives.GetPurposeGUI()
    -- Non-RTX: scene find works. RTX: use GUIMaster.RefPurpose via Scene.getGUIPurpose().
    return Scene.getGUIPurpose()
end

function Objectives.Destroy()
    DestroyObjects.RemovePurposeGUI()
end

return Objectives