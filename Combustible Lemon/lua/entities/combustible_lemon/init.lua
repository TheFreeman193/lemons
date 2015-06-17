//////////////////////////////////////
///////// Combustible Lemon //////////
///// Developed By TheFreeman193 /////
//////// Model By Cold Fusion ////////
//// Released Under The GNU GPLv3 ////
//////////////////////////////////////

AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:SpawnFunction(ply, trace)
	if !trace.Hit then return end
	
	local e = ents.Create(ClassName || self.ClassName || "combustible_lemon")
	if !(e && IsValid(e)) then
		if e.Remove then e:Remove() end
		return
	end
	e:SetPos(trace.HitPos + trace.HitNormal * 16)
	e.Owner = ply
	e:Spawn()
	e:Activate()
	
	return e
end

function ENT:Initialize()
	self:SetModel"models/combustible_lemon/combustiblelemon.mdl"
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)    
	self:SetSolid(SOLID_VPHYSICS)

	local p = self:GetPhysicsObject()
	if  IsValid(p) then p:Wake() end
	p = nil
	
	self.EntHealth     = 100
	self.Active        = true
	self.Started    = false
	self.Exploding    = false
end

//Precache Ent's Audio
for _, SoundFile in pairs(ENT.Audio) do util.PrecacheSound(SoundFile) end

function ENT:OnTakeDamage(DInfo)
	if self.Started || self.Exploding then return end
	local Dam = DInfo:GetDamage()
	if Dam < 1 || self.EntHealth <= 0 then return end
	
	self.EntHealth = self.EntHealth - DInfo:GetDamage()
	if Dam >= 7 && self.EntHealth > 0 then self:EmitSound(self.Audio.Pain, 75, 210) end
	
	if self.EntHealth <= 0 then
		self:EmitSound(self.Audio.GlaDOS1, 111, 200)
		self:Explode()
	end
end

function ENT:Explode(jump)
	if self.Exploding then return else self.Exploding = true end
	
	if jump then local p = self:GetPhysicsObject(); if IsValid(p) then p:SetVelocity(Vector(0, 0, 500)) end end
	
	timer.Simple(jump&&.8||0, function()
		local explosioneffect = ents.Create "env_explosion"
		explosioneffect:SetOwner(self.Owner)
		explosioneffect:SetPos(self:GetPos())
		explosioneffect:SetKeyValue("iMagnitude", "150")
		explosioneffect:Spawn()
		explosioneffect:Activate()
		explosioneffect:Fire("Explode", "", 0)
	end)
	timer.Simple(jump&&.9||.1, function() self:Remove() end)
end

function ENT:PhysicsCollide(CInfo, obj)
	if self.Started || (self.Started && self:IsOnFire()) then return end
	local Speed = CInfo.Speed
	local Damage
	if Speed >= 100 && Speed < 400 then
		Damage = math.Round(Speed / 15,1) - 2
	elseif Speed >= 400 && Speed < 500 then
		Damage = 50
	elseif Speed >= 500 then
		Damage = 100
	end
	self:TakeDamage(Damage)
end


function ENT:Use()
	if self.Started then return else self.Started = true end
	
	timer.Simple(.3, function()
		local StartTime
		if IsValid(self) then self:EmitSound(self.Audio.Cave1, 115, 100); StartTime = RealTime() else return end
		
		timer.Create("LemonSpeechCounter"..tostring(math.random(1,50)), 0.1, 0, function()
			local CT = math.Round(RealTime() - StartTime, 1)
			if CT <= 0 then return end
			if !IsValid(self) then return end
			
			if CT >= 24 && CT < 32 then if !self:IsOnFire() then self:Ignite(8.1, 190) end elseif self:IsOnFire() then self:Extinguish() end
			
			
			if CT == 12 then		self:EmitSound(self.Audio.Cave2, 100, 100)
			elseif CT == 20.2 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 120)
			elseif CT == 23.2 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 140)
			elseif CT == 28.5 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 160)
			elseif CT == 30.2 then 	self:StopSound(self.Audio.Cave2); self:EmitSound(self.Audio.GlaDOS1, 75, 175)
			elseif CT == 30.4 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 150)
			elseif CT == 30.6 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 130)
			elseif CT == 30.7 then 	self:EmitSound(self.Audio.GlaDOS1, 75, 100)
			elseif CT == 31.2 then 	self:EmitSound(self.Audio.GlaDOS2, 100, 110); self.Active = false
			elseif CT >= 32 then
				self:Explode(true)
				timer.Destroy"LemonSpeechCounter"
			end
		end)
	end)
end

function ENT:OnRemove()
	if IsValid(self) then
		for _, SoundFile in pairs(self.Audio) do
			self:StopSound(SoundFile)
		end
	end
	if self.Started then timer.Simple(.7, function() BroadcastLua'RunConsoleCommand("stopsound")' end) end
end

function ENT:Think()
	if !self.Active then return false end
	if !IsValid(self) then return end
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		local cV = phys:GetVelocity()
		phys:SetVelocity(Vector(cV[1] + math.random(-1,1)*20, cV[2] + math.random(-1,1)*20, cV[3] + math.random(10,150)))
	end
	self:NextThink(CurTime() + math.Rand(0.5,2))
	return true
end
