local CutsceneObjects = {}
CutsceneObjects.hooksInstalled = false

-- The machine GameObject that grants the empty dispersal cartridge
local DISPERSAL_MACHINE = "sm42_222_SprayingMachine01A_control"

function CutsceneObjects.Init()
    if CutsceneObjects.hooksInstalled then
        return
    end

    local settingsType = sdk.find_type_definition(
        sdk.game_namespace("gimmick.option.AddItemToInventorySettings")
    )
    if not settingsType then
        return
    end

    -- Block the vanilla item grant. Scene find is unreliable on RTX, so hook
    -- the grant itself instead of trying to find/disable the object up front.
    local addStock = settingsType:get_method("AddSelectedStock")
    if not addStock then
        return
    end

    sdk.hook(addStock, function(args)
        if not Archipelago.IsConnected() then
            return
        end

        local settings = sdk.to_managed_object(args[2])
        if not settings then
            return
        end

        local gameObject = settings:call("get_GameObject")
        if not gameObject then
            return
        end

        if gameObject:call("get_Name") == DISPERSAL_MACHINE then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end)

    CutsceneObjects.hooksInstalled = true
end

return CutsceneObjects
