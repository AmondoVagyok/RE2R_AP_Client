local Helpers = {}

function Helpers.gameObject(obj_name)
    return Scene.getSceneObject():findGameObject(obj_name)
end

function Helpers.component(obj, component_namespace)
    local comp_name = component_namespace

    if not string.find(comp_name, "via.") and not string.find(comp_name, sdk.game_namespace("")) then
        comp_name = sdk.game_namespace(comp_name)
    end

    return obj:call("getComponent(System.Type)", sdk.typeof(comp_name))
end

-- getting transform children is kinda annoying, so here's a helper for it
function Helpers.get_children(xform)
	local children = {}
	local child = xform:call("get_Child")
	while child do 
		table.insert(children, child)
		child = child:call("get_Next")
	end
	return children[1] and children
end

function Helpers.wait(seconds) 
    local start = os.time() 
    repeat until os.time() > start + seconds 
end

return Helpers
