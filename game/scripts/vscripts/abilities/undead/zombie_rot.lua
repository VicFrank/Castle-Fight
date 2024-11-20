zombie_rot = class({})
LinkLuaModifier("modifier_zombie_rot_aura", "abilities/undead/zombie_rot", LUA_MODIFIER_MOTION_NONE)

function zombie_rot:GetIntrinsicModifierName()
  return "modifier_zombie_rot_aura"
end

modifier_zombie_rot_aura = class({})

function modifier_zombie_rot_aura:GetTexture()
  return "pudge_rot"
end

function modifier_zombie_rot_aura:IsDebuff()
  if self:GetCaster() == self:GetParent() then
    return false
  end
  
  return true
end

function modifier_zombie_rot_aura:IsAura()
  if self:GetCaster() == self:GetParent() then
    return true
  end
  
  return false
end

function modifier_zombie_rot_aura:GetAuraDuration()
  if self:GetAbility():GetLevel() == 3 then
    return 999
  else
    return 0.5
  end
end

function modifier_zombie_rot_aura:GetModifierAura()
  return "modifier_zombie_rot_aura"
end

function modifier_zombie_rot_aura:GetAuraEntityReject(target)
  return IsCustomBuilding(target) or target:IsRealHero() or target:IsMechanical()
end

function modifier_zombie_rot_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_zombie_rot_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_zombie_rot_aura:GetAuraRadius()
  return self.radius
end

function modifier_zombie_rot_aura:OnCreated(kv)
  if IsServer() then
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.dps = self:GetAbility():GetSpecialValueFor("dps")

    self.rot_tick = 0.2

    if self:GetParent() == self:GetCaster() then
      -- EmitSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
      local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
      ParticleManager:SetParticleControl( nFXIndex, 1, Vector(self.rot_radius, 1, self.rot_radius ) )
      self:AddParticle(nFXIndex, false, false, -1, false, false)
    else
      local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
      self:AddParticle(nFXIndex, false, false, -1, false, false)
    end

    self.playerHero = self:GetCaster():GetPlayerHero()
    self.casterTeam = self:GetCaster():GetTeam()

    self:StartIntervalThink(self.rot_tick)
    self:OnIntervalThink()
  end
end

function modifier_zombie_rot_aura:OnDestroy()
  if IsServer() then
    -- StopSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
  end
end

function modifier_zombie_rot_aura:OnIntervalThink()
  if IsServer() then
    local flDamagePerTick = self.rot_tick * self.dps

    if self:GetParent():GetTeam() ~= self.casterTeam then
      ApplyDamage({
        victim = self:GetParent(),
        attacker = self.playerHero,
        damage = flDamagePerTick,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
      })
    end
  end
end