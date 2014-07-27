AddCSLuaFile()
module("momo",package.seeall)
_VERSION="0"

  ////////////////////////////////////////////////
 // MOMO COMPATIBILITY PART 1: HOOK OVERRIDES! //
////////////////////////////////////////////////

//Forces our code to run before other hooks, since many coders don't use some hooks (CalcView) correctly.
//Should work with the GM+ hook "fix"
//Fuck GM+

local momo_hooks={}
local old_hook_call=hook.Call

function hook.Call(name,gm,...)
	local a,b,c,d,e,f
	if momo_hooks[name] then
		a,b,c,d,e,f = momo_hooks[name](...)
		if a!=nil then
			return a,b,c,d,e,f
		end
	end
	a,b,c,d,e,f = old_hook_call(name,gm,...)
	return a,b,c,d,e,f
end

function momo_hooks.CalcView(ply,pos,ang,fov,nearZ,farZ)
	local ent = pk_pills.getMappedEnt(LocalPlayer())
	if (IsValid(ent)) then // and ply:GetViewEntity()==ply) then
		local startpos
		if ent.formTable.type=="phys" then
			startpos = ent:LocalToWorld(ent.formTable.camera&&ent.formTable.camera.offset||Vector(0,0,0))
		else
			startpos=pos
		end

		if pk_pills.var_thirdperson:GetBool() then
			local dist
			if ent.formTable.type=="phys"&&ent.formTable.camera&&ent.formTable.camera.distFromSize then
				dist = ent:BoundingRadius()*5
			else
				dist = ent.formTable.camera&&ent.formTable.camera.dist||100
			end

			local offset = LocalToWorld(Vector(-dist,0,dist/5),Angle(0,0,0),Vector(0,0,0),ang)
			local tr = util.TraceHull({
				start=startpos,
				endpos=startpos+offset,
				filter=ent.camTraceFilter,
				mins=Vector(-5,-5,-5),
				maxs=Vector(5,5,5),
				mask=MASK_VISIBLE
			})
			//PrintTable(ent.camTraceFilter)
			local view = {}
			view.origin = tr.HitPos
			view.angles = ang//(ent.GoodEyeTrace&&(pillEnt:GoodEyeTrace().HitPos-tr.HitPos):Angle())||angles
			view.fov = fov
			return view
		else
			local view = {}
			view.origin = startpos
			view.angles = ang
			view.fov = fov
			return view
		end
	end
end

function momo_hooks.CalcViewModelView(wep,vm,oldPos,oldAng,pos,ang)
	local ent = pk_pills.getMappedEnt(LocalPlayer())
	local ply = wep.Owner
	if (IsValid(ent) and ply:GetViewEntity()==ply and pk_pills.var_thirdperson:GetBool()) then
		return oldPos+oldAng:Forward()*-500,ang
	end
end

  /////////////////////////////////////////////////
 // MOMO COMPATIBILITY PART 2: METATABLE HACKS! //
/////////////////////////////////////////////////

//Disable a ton of functions when morphed

local blocked_functions = {
	"SetHull","SetHullDuck",
	"SetWalkSpeed","SetRunSpeed","SetCrouchedWalkSpeed",
	"SetJumpPower","SetStepSize",
	"SetViewOffset","SetViewOffsetDucked"
}

local meta_player = FindMetaTable("Player")

for _,f in pairs(blocked_functions) do
	local old_func = meta_player[f]
	meta_player[f]= function(self,...)
		local ent = pk_pills.getMappedEnt(self)
		if !IsValid(ent) then
			old_func(self,...)
		end
	end
end