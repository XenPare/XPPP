local tag = "XPPP APG"
local cfg = XPPP.CFG

local function unFreeze(ent)
	if not SERVER then
		return
	end

	if ent:GetCollisionGroup() ~= COLLISION_GROUP_NONE then
		return
	end

	ent.LastColor = ent:GetColor()
	ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
	ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
	ent:SetColor(ColorAlpha(color_black, 200))
	ent.XPPPCanUse = false -- thirdparty
end

local blocking = cfg.CustomSpawnBlockingEntities
function XPPP.IsBlocked(ent)
	local center = ent:LocalToWorld(ent:OBBCenter())
	local bRadius = ent:BoundingRadius()
	for _, v in next, ents.FindInSphere(center, bRadius) do
		local isLivingPlayer = v:IsPlayer() and v:Alive()
		if isLivingPlayer or blocking[v:GetClass()] or XPPP.BlockingEntities[v:GetClass()] then
			local pos = v:GetPos()
			local trace = {start = pos, endpos = pos, filter = v}
			local tr = util.TraceEntity(trace, v)
			if tr.Entity == ent then
				return true
			end
		end
	end
	return false
end

hook.Add("PhysgunPickup", tag, function(pl, ent)
	local owner = ent:GetNWEntity("XPPPOwner")
	local ownerid = ent:GetNWString("XPPPOwnerID")

	if ent.PhysgunPickup then
		return ent:PhysgunPickup(pl)
	end

	if pl:IsAdmin() then
		if ent:IsPlayer() then
			return
		end
		if IsValid(owner) or ownerid ~= "" then
			if ent:GetClass():find("prop_") then
				unFreeze(ent)
			end
		elseif not IsValid(owner) and ownerid == "" then
			return false
		else
			return false
		end
	else
		if IsValid(owner) then
			if owner == pl then
				if ent:GetClass():find("prop_") then
					unFreeze(ent)
				end
			else
				return false
			end
		else
			return false
		end
	end
end)

hook.Add("PhysgunDrop", tag, function(pl, ent)
	local owner = ent:GetNWEntity("XPPPOwner")
	local ownerid = ent:GetNWString("XPPPOwnerID")
	local phys = ent:GetPhysicsObject()

	if pl:IsAdmin() then
		if ent:IsPlayer() then
			return
		end

		if IsValid(owner) or ownerid ~= "" then
			if IsValid(phys) and SERVER and ent:GetClass():find("prop_") then
				phys:EnableMotion(false)
			end
		elseif not IsValid(owner) and ownerid == "" then
			return false
		else
			return false
		end
	else
		if IsValid(owner) and owner == pl then
			if IsValid(phys) and SERVER and ent:GetClass():find("prop_") then
				phys:EnableMotion(false)
			end
		else
			return false
		end
	end
end)

hook.Add("CanTool", tag, function(pl, tr, toolname)
	if XPPP.BlockedTools[toolname] or cfg.CustomBlockedTools[toolname] then
		return false
	end

	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	if ent:GetNWString("XPPPOwnerID") == "" then
		return false
	end

	local owner = ent:GetNWEntity("XPPPOwner")
	local ownerid = ent:GetNWString("XPPPOwnerID")

	if pl:IsAdmin() then
		return IsValid(owner) or ownerid ~= ""
	else
		return IsValid(owner) and owner == pl
	end
end)

if SERVER then
	hook.Add("OnPhysgunReload", tag, function()
		return false
	end)

	hook.Add("PlayerSpawnProp", tag, function(pl, mdl)
		local pos = pl:GetEyeTrace().HitPos
		if not pl:Alive() or pos:DistToSqr(pl:GetPos()) > 592900 then
			return false
		end

		if cfg.CustomBlockedModels[mdl:lower()] or cfg.CustomBlockedModels[mdl] then
			pl:ChatPrint("This model is blocked!")
			return false
		end

		if cfg.PresetsEnabled and XPPP.BlockedModels[mdl:lower()] then
			return false
		end
	end)

	hook.Add("EntityTakeDamage", tag, function(target, dmg)
		if (dmg:IsDamageType(DMG_CRUSH) or dmg:IsDamageType(DMG_VEHICLE)) and (IsValid(target) and (target:IsPlayer() or target:GetClass():find("prop_"))) then
			return true
		end
	end)

	hook.Add("PlayerSpawnedProp", tag, function(pl, mdl, ent)
		if XPPP.IsBlocked(ent) then
			ent.LastColor = ent:GetColor()
			ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
			ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
			ent:SetColor(ColorAlpha(color_black, 200))
			ent.XPPPCanUse = false -- thirdparty
		else
			ent.XPPPCanUse = true -- thirdparty
		end

		-- disable motion
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		-- set owner
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("PlayerSpawnedRagdoll", tag, function(pl, mdl, ent)
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("PlayerSpawnedEffect", tag, function(pl, mdl, ent)
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("PlayerSpawnedSENT", tag, function(pl, ent)
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("PlayerSpawnedVehicle", tag, function(pl, ent)
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("PlayerSpawnedNPC", tag, function(pl, ent)
		ent:SetNWEntity("XPPPOwner", pl)
		ent:SetNWString("XPPPOwnerID", pl:SteamID())
	end)

	hook.Add("OnEntityCreated", tag, function(ent)
		timer.Simple(0.1, function()
			if not IsValid(ent) then
				return
			end

			local cr = ent.Founder
			local crid = ent.FounderSID
			if cr or crid then
				if cr and IsValid(cr) then
					ent:SetNWEntity("XPPPOwner", cr)
				end

				if crid then
					local sid = util.SteamIDFrom64(crid)
					ent:SetNWString("XPPPOwnerID", sid)
				end
			elseif ent.GetPlayer then
				local pl = ent:GetPlayer()
				if IsValid(pl) then
					ent:SetNWEntity("XPPPOwner", pl)
					ent:SetNWString("XPPPOwnerID", pl:SteamID())
				end
			else
				local df = ent.OnDieFunctions
				if not df then
					return
				end

				local tbl = df.undo1
				if not tbl then
					return
				end

				local args = tbl.Args
				local pl = args[2]
				if not IsValid(pl) then
					return
				end

				ent:SetNWEntity("XPPPOwner", pl)
				ent:SetNWString("XPPPOwnerID", pl:SteamID())
			end
		end)
	end)

	hook.Add("OnPhysgunFreeze", tag, function(_, phys, ent, pl)
		if IsValid(pl) and IsValid(ent) and not XPPP.IsBlocked(ent) and ent:GetClass():find("prop_") then
			ent:SetCollisionGroup(COLLISION_GROUP_NONE)
			ent:SetRenderMode(RENDERMODE_NORMAL)
			ent:SetColor(ent.LastColor or color_white)
			ent.XPPPCanUse = true -- thirdparty
		end
	end)

	hook.Add("PlayerDisconnected", tag, function(pl)
		local sid = pl:SteamID()
		timer.Create("XPPP Remove Props of " .. sid, cfg.DisconnectedRemovalTimer, 1, function()
			for _, e in ipairs(ents.GetAll()) do
				if e:GetNWString("XPPPOwnerID") == sid then
					e:Remove()
				end
			end
		end)
	end)

	hook.Add("PlayerInitialSpawn", tag, function(pl)
		local sid = pl:SteamID()

		local tname = "XPPP Remove Props of " .. sid
		if timer.Exists(tname) then
			timer.Remove(tname)
		end

		for _, e in ipairs(ents.GetAll()) do
			if e:GetNWString("XPPPOwnerID") == sid then
				e:SetNWEntity("XPPPOwner", pl)
			end
		end
	end)
end