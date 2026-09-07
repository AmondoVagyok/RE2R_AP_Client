local DestroyObjects = {}
DestroyObjects.isInit = false
DestroyObjects.lastRemoval = os.time()
DestroyObjects.purposeHooksInstalled = false

function DestroyObjects.DestroyGameObject(obj)
    if obj == nil then
        return false
    end

    -- Prefer hide first: on RTX, destroy alone can fail 
    -- (it caused uncontrollable rave style flickering)
    pcall(function() obj:call("set_DrawSelf", false) end)
    pcall(function() obj:call("set_UpdateSelf", false) end)
    pcall(function() obj:call("destroy", obj) end)
    return true
end

function DestroyObjects.SetupPurposeHooks()
    if DestroyObjects.purposeHooksInstalled then
        return
    end

    local guiType = sdk.find_type_definition(sdk.game_namespace("gui.GUIMaster"))
    if guiType == nil then
        return
    end

    local function skipWhenConnected(args)
        if Archipelago.IsConnected() then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    local openPurpose = guiType:get_method("openPurpose(System.Action, System.Action)")
    if openPurpose ~= nil then
        sdk.hook(openPurpose, skipWhenConnected)
    end
    
    local openOneTime = guiType:get_method(
        "openPurposeOneTime(" .. sdk.game_namespace("gamemastering.PurposeManager.PurposeData") .. ")"
    )
    if openOneTime == nil then
        openOneTime = guiType:get_method("openPurposeOneTime")
    end
    if openOneTime ~= nil then
        sdk.hook(openOneTime, skipWhenConnected)
    end

    DestroyObjects.purposeHooksInstalled = true
end

function DestroyObjects.Init()
    DestroyObjects.SetupPurposeHooks()

    if Archipelago.IsConnected() and not DestroyObjects.isInit then
        DestroyObjects.isInit = true
        DestroyObjects.lastRemoval = os.time()
        DestroyObjects.DestroyAll()
    end

    -- Retry periodically. Purpose UI can try to respawn after the first pass on RTX.
    if os.time() - DestroyObjects.lastRemoval > 15 then
        DestroyObjects.isInit = false
        DestroyObjects.lastRemoval = os.time()
    end
end

function DestroyObjects.DestroyAll()
    -- Objectives HUD: on RTX, GUI_Purpose can't be found/destroyed via scene find
    -- (RefPurpose.get_Target is null). Use GUIMaster.closePurpose instead.
    DestroyObjects.RemovePurposeGUI()

    local destroyables = {
        DestroyObjects.GetAdasSecretWeaponLadder(),
        DestroyObjects.GetSherrysKey(),
        DestroyObjects.GetSecretRoomTBarPipe()
    }

    -- if we talked to Marvin, remove the shutter and the panel interact that lets you put a fuse in it to open the shutter
    if Storage.talkedToMarvin then
        -- if hardcore, leave the shutter because new players keep softlocking themselves by skipping marvin's cutscene after dying
        if Lookups.difficulty ~= nil and string.lower(Lookups.difficulty) ~= "hardcore" then 
            table.insert(destroyables, DestroyObjects.GetMainHallShutter())
        end
        
        table.insert(destroyables, DestroyObjects.GetMainHallShutterFusePanel())
    end

    -- if we opened the Chief door with Heart Key as Claire, remove the East Hallway 2F shutter
    if Storage.openedChiefDoor then
        table.insert(destroyables, DestroyObjects.GetEastHallway2FShutter())
    end

    for _, obj in pairs(destroyables) do
        DestroyObjects.DestroyGameObject(obj)
    end
end

function DestroyObjects.RemovePurposeGUI()
    -- 1) Official close path (works on RTX)
    if Scene.closePurposeGUI and Scene.closePurposeGUI() then
        return true
    end

    -- 2) Non-RTX fallback: destroy the scene object if find works
    local obj = DestroyObjects.GetPurposeGUI()
    if obj ~= nil then
        return DestroyObjects.DestroyGameObject(obj)
    end

    return false
end

function DestroyObjects.GetPurposeGUI()
    return Scene.getGUIPurpose()
end

-- RTX: scene:findGameObject often returns nil for streamed gimmicks (main hall shutter).
-- Item boxes already work via Gimmick tag, so fall back to that and don't require an exact
-- name match because Capcom likes to add crap to the beginning of the names.
function DestroyObjects.GetObject(obj_name)
    local scene = Scene.getSceneObject()
    if scene == nil then
        return nil
    end

    local obj = nil
    pcall(function()
        obj = scene:call("findGameObject(System.String)", obj_name)
    end)
    if obj ~= nil then
        return obj
    end

    local gimmick_objects = nil
    pcall(function()
        gimmick_objects = scene:call("findGameObjectsWithTag(System.String)", "Gimmick")
    end)
    if gimmick_objects == nil then
        return nil
    end

    -- there's occasionally an error about trying to loop an REManagedObject, so don't do that
    if type(gimmick_objects) ~= "table" then
        if gimmick_objects.get_elements then
            gimmick_objects = gimmick_objects:get_elements()
        else
            return nil
        end
    end

    for k, gimmick in pairs(gimmick_objects) do
        if gimmick ~= nil then
            local gimmickName = gimmick:call("get_Name()")
            if gimmickName == obj_name or (gimmickName and string.find(gimmickName, obj_name, 1, true)) then
                return gimmick
            end
        end
    end

    return nil
end

function DestroyObjects.GetAdasSecretWeaponLadder()
    return DestroyObjects.GetObject("ADA_PlayCF535_00_HoldHackingGun")
end

function DestroyObjects.GetSherrysKey()
    return DestroyObjects.GetObject("OrphanAsylum_PlayEvent_CF360")
end

function DestroyObjects.GetMainHallShutter()
    return DestroyObjects.GetObject("sm60_033_PipeShutter01A_gimmick")
end

function DestroyObjects.GetMainHallShutterFusePanel()
    return DestroyObjects.GetObject("sm42_167_FuseBox01A_control")
end

function DestroyObjects.GetEastHallway2FShutter()
    return DestroyObjects.GetObject("sm42_003_FireShutter01A_gimmick")
end

function DestroyObjects.GetSecretRoomTBarPipe()
    return DestroyObjects.GetObject("sm41_028_THandleHole02A_underMegami_gimmick")
end

return DestroyObjects
