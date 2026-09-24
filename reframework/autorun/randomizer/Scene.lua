local Scene = {}

Scene.sceneObject = nil
Scene.mainFlowManager = nil
Scene.interactManager = nil
Scene.saveDataManager = nil
Scene.recordManager = nil
Scene.itemManager = nil

--- A note for a person who has more time in the future
-- 60_LevelMaster -> CutSceneManager
--

function Scene.isNonRTX()
    local tdb = sdk.get_tdb_version()

    if tdb < 69 then return true end

    return false
end


local function getManagedSingleton(relativeName)
    local ok, obj = pcall(function()
        return sdk.get_managed_singleton(sdk.game_namespace(relativeName))
    end)
    if ok then
        return obj
    end
    return nil
end

local function mainFlowCall(methodName, defaultValue)
    local mfm = Scene.getMainFlowManager()
    if not mfm then
        return defaultValue
    end

    local ok, result = pcall(function()
        return mfm:call(methodName)
    end)
    if ok and result ~= nil then
        return result
    end
    return defaultValue
end

local function mainFlowFlag(methodName)
    return mainFlowCall(methodName, false) == true
end

function Scene.getSceneObject()
    local ok, currentScene = pcall(function()
        return sdk.call_native_func(
            sdk.get_native_singleton("via.SceneManager"),
            sdk.find_type_definition("via.SceneManager"),
            "get_CurrentScene()"
        )
    end)
    if ok and currentScene ~= nil then
        Scene.sceneObject = currentScene
        return currentScene
    end

    return Scene.sceneObject
end

-- RTX: never rely on scene:findGameObject("UIMaster").
function Scene.getGUIMaster()
    return getManagedSingleton("gui.GUIMaster")
end

function Scene.findGameObjectByName(name)
    local scene = Scene.getSceneObject()
    if scene then
        -- typed call first; :findGameObject(name) is overloaded and often returns nil on RTX
        local ok, obj = pcall(function()
            return scene:call("findGameObject(System.String)", name)
        end)
        if ok and obj ~= nil then
            return obj
        end

        ok, obj = pcall(function()
            return scene:findGameObject(name)
        end)
        if ok and obj ~= nil then
            return obj
        end
    end

    return nil
end

-- RTX: walk GUIMaster's in-game folder children (scene find often returns nil :/ ).
function Scene.findGameObjectInGuiInGameFolder(name)
    local gui = Scene.getGUIMaster()
    if not gui then
        return nil
    end

    local okFolder, folder = pcall(function()
        return gui:call("get_GuiInGameFolder")
    end)
    if not okFolder or folder == nil then
        return nil
    end

    local okChildren, children = pcall(function()
        return folder:call("get_Children")
    end)
    if not okChildren or children == nil then
        return nil
    end

    local list = children
    if children.get_elements then
        local okEls, els = pcall(function()
            return children:get_elements()
        end)
        if okEls and els then
            list = els
        end
    end

    for _, transform in pairs(list) do
        if transform ~= nil then
            local okGo, go = pcall(function()
                return transform:call("get_GameObject")
            end)
            if okGo and go ~= nil then
                local okName, goName = pcall(function()
                    return go:call("get_Name")
                end)
                if okName and goName == name then
                    return go
                end
            end
        end
    end

    return nil
end

local function getGuiObject(name)
    return Scene.findGameObjectByName(name) or Scene.findGameObjectInGuiInGameFolder(name)
end

function Scene.getGUIPurpose()
    return getGuiObject("GUI_Purpose")
end

function Scene.getGUIItemBox()
    return getGuiObject("GUI_ItemBox")
end

function Scene.getGUIInventory()
    return getGuiObject("GUI_NewInventory")
end

function Scene.getGameMaster()
    -- Prefer Masters tag (non-RTX). RTX often fails this lookup.
    return Scene.getMasterObject("30_GameMaster")
end

function Scene.getInventoryMaster()
    return Scene.getMasterObject("50_InventoryMaster")
end

function Scene.getGimmickMaster()
    return Scene.getMasterObject("70_GimmickMaster")
end

function Scene.getMasterObject(objectName)
    local scene = Scene.getSceneObject()
    if not scene then
        return nil
    end

    local ok, masters = pcall(function()
        return scene:findGameObjectsWithTag("Masters")
    end)
    if not ok or masters == nil then
        return nil
    end

    for _, master in pairs(masters) do
        if master ~= nil and master:get_Name() == objectName then
            return master
        end
    end

    return nil
end

function Scene.getMainFlowManager()
    if Scene.mainFlowManager ~= nil then
        return Scene.mainFlowManager
    end

    -- RTX: Masters-tag GameMaster lookup is flaky and makes isInGame() flicker.
    Scene.mainFlowManager = getManagedSingleton("gamemastering.MainFlowManager")
    if Scene.mainFlowManager ~= nil then
        return Scene.mainFlowManager
    end

    local gameMaster = Scene.getGameMaster()
    if gameMaster == nil then
        return nil
    end

    local ok, mfm = pcall(function()
        return gameMaster:call(
            "getComponent(System.Type)",
            sdk.typeof(sdk.game_namespace("gamemastering.MainFlowManager"))
        )
    end)
    if ok then
        Scene.mainFlowManager = mfm
    end

    return Scene.mainFlowManager
end

function Scene.getInteractManager()
    if Scene.interactManager ~= nil then
        return Scene.interactManager
    end

    Scene.interactManager = getManagedSingleton("gimmick.action.InteractManager")
    if Scene.interactManager ~= nil then
        return Scene.interactManager
    end

    local gimmickMaster = Scene.getGimmickMaster()
    if gimmickMaster == nil then
        return nil
    end

    local ok, im = pcall(function()
        return gimmickMaster:call(
            "getComponent(System.Type)",
            sdk.typeof(sdk.game_namespace("gimmick.action.InteractManager"))
        )
    end)
    if ok then
        Scene.interactManager = im
    end

    return Scene.interactManager
end

function Scene.getSaveDataManager()
    if Scene.saveDataManager ~= nil then
        return Scene.saveDataManager
    end

    Scene.saveDataManager = getManagedSingleton("gamemastering.SaveDataManager")
    if Scene.saveDataManager ~= nil then
        return Scene.saveDataManager
    end

    local gameMaster = Scene.getGameMaster()
    if gameMaster == nil then
        return nil
    end

    local ok, sdm = pcall(function()
        return gameMaster:call(
            "getComponent(System.Type)",
            sdk.typeof(sdk.game_namespace("gamemastering.SaveDataManager"))
        )
    end)
    if ok then
        Scene.saveDataManager = sdm
    end

    return Scene.saveDataManager
end

function Scene.getRecordManager()
    if Scene.recordManager ~= nil then
        return Scene.recordManager
    end

    Scene.recordManager = getManagedSingleton("gamemastering.RecordManager")
    if Scene.recordManager ~= nil then
        return Scene.recordManager
    end

    local gameMaster = Scene.getGameMaster()
    if gameMaster == nil then
        return nil
    end

    local ok, rm = pcall(function()
        return gameMaster:call(
            "getComponent(System.Type)",
            sdk.typeof(sdk.game_namespace("gamemastering.RecordManager"))
        )
    end)
    if ok then
        Scene.recordManager = rm
    end

    return Scene.recordManager
end

function Scene.getItemManager()
    if Scene.itemManager ~= nil then
        return Scene.itemManager
    end

    local inventoryMaster = Scene.getInventoryMaster()

    Scene.itemManager = inventoryMaster:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gamemastering.ItemManager")))

    return Scene.itemManager
end

function Scene.getSurvivorType()
    local survivorManager = getManagedSingleton("SurvivorManager")
    if survivorManager == nil then
        local gameMaster = Scene.getGameMaster()
        if gameMaster == nil then
            return -1
        end

        local ok, sm = pcall(function()
            return gameMaster:call(
                "getComponent(System.Type)",
                sdk.typeof(sdk.game_namespace("SurvivorManager"))
            )
        end)
        if not ok then
            return -1
        end
        survivorManager = sm
    end
    if survivorManager == nil then
        return -1
    end

    local survivors = survivorManager:get_field("ExistSurvivorInfoList")
    if survivors == nil then
        return -1
    end

    for _, survivor in pairs(survivors:get_field("mItems") or {}) do
        if survivor then
            local isActive = survivor:get_field("<IsActivePlayer>k__BackingField")
            if isActive then
                return survivor:get_field("<SurvivorType>k__BackingField")
            end
        end
    end

    return -1
end

function Scene.getScenarioType()
    return mainFlowCall("get_CurrentScenarioType", -1)
end

function Scene.getDifficulty()
    return mainFlowCall("get_CurrentDifficulty", -1)
end

function Scene.getGUIMap()
    return getGuiObject("GUI_Map")
end

function Scene.isTitleScreen()
    return mainFlowFlag("get_IsInTitle")
end

function Scene.isInGame()
    return mainFlowFlag("get_IsInGame")
end

function Scene.isInPause()
    return mainFlowFlag("get_IsInPause")
end

function Scene.isGameOver()
    return mainFlowFlag("get_IsInGameOver")
end

function Scene.goToGameOver()
    return mainFlowCall("goGameOver", nil)
end

-- RTX-safe: RefPurpose.get_Target is often null, but GUIMaster.closePurpose works.
function Scene.closePurposeGUI()
    local gui = Scene.getGUIMaster()
    if not gui then
        return false
    end

    local ok = pcall(function()
        gui:call("closePurpose(System.Boolean)", true)
    end)
    if ok then
        return true
    end

    ok = pcall(function()
        gui:call("closePurpose", true)
    end)
    return ok
end

function Scene.isUsingItemBox()
    -- RTX: DrawSelf is unreliable; use GUIMaster.
    local gui = Scene.getGUIMaster()
    if gui then
        local ok, busy = pcall(function()
            return gui:call("isBusyItemBox")
        end)
        if ok and busy ~= nil then
            return busy == true
        end
    end

    local guiBox = Scene.getGUIItemBox()
    if not guiBox then
        return false
    end

    local ok, drawn = pcall(function()
        return guiBox:get_DrawSelf()
    end)
    return ok and drawn == true
end

function Scene.isUsingInventory()
    -- RTX: DrawSelf often fails even while inventory is open.
    -- GUIMaster.get_IsOpenInventory is the reliable flag (same idea as RE3).
    local gui = Scene.getGUIMaster()
    if gui then
        local ok, open = pcall(function()
            return gui:call("get_IsOpenInventory")
        end)
        if ok and open ~= nil then
            return open == true
        end
    end

    local guiInv = Scene.getGUIInventory()
    if not guiInv then
        return false
    end

    local ok, drawn = pcall(function()
        return guiInv:get_DrawSelf()
    end)
    return ok and drawn == true
end

function Scene.isUsingMap()
    local gui = Scene.getGUIMaster()
    if gui then
        local ok, open = pcall(function()
            return gui:call("get_IsOpenMap")
        end)
        if ok and open ~= nil then
            return open == true
        end
    end

    local guiMap = Scene.getGUIMap()
    if not guiMap then
        return false
    end

    local ok, drawn = pcall(function()
        return guiMap:get_DrawSelf()
    end)
    return ok and drawn == true
end

function Scene.isCharacterLeon()
    return Scene.getSurvivorType() == 0
end

function Scene.isCharacterClaire()
    return Scene.getSurvivorType() == 1
end

function Scene.isCharacterAda()
    return Scene.getSurvivorType() == 2
end

function Scene.isCharacterSherry()
    return Scene.getSurvivorType() == 3
end

function Scene.isScenarioLeonA()
    return Scene.getScenarioType() == 0
end

function Scene.isScenarioLeonB()
    return Scene.getScenarioType() == 2
end

function Scene.isScenarioClaireA()
    return Scene.getScenarioType() == 1
end

function Scene.isScenarioClaireB()
    return Scene.getScenarioType() == 3
end

function Scene.isDifficultyAssisted()
    return Scene.getDifficulty() == 0
end

function Scene.isDifficultyStandard()
    return Scene.getDifficulty() == 1
end

function Scene.isDifficultyHardcore()
    return Scene.getDifficulty() == 2
end

function Scene.getCurrentLocation()
    return mainFlowCall("get_LoadLocation", nil)
end

function Scene.getCurrentArea()
    return mainFlowCall("get_LoadArea", nil)
end

function Scene.getGameGUID()
    return mainFlowCall("get_GameGUID", nil)
end

function Scene.getSaveGUID()
    return mainFlowCall("get_SaveGUID", nil)
end

return Scene
