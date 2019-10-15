mine_layer_lay_mine = class({})
LinkLuaModifier("modifier_mine", "abilities/mech/lay_mine.lua", LUA_MODIFIER_MOTION_NONE)

function mine_layer_lay_mine:OnSpellStart()
  local caster = self:GetCaster()

  local position = caster:GetAbsOrigin() + RandomVector(200)

  EmitSoundOn("Hero_Techies.LandMine.Plant", caster)
  local mine = CreateUnitByName("npc_dota_techies_land_mine", position, true, caster, caster, caster:GetTeam())
  mine:AddNewModifier(caster, self, "modifier_mine", {})
end

modifier_mine = ({})

function modifier_mine:IsHidden() return true end

function modifier_mine:OnCreated(table)
  if IsServer() then
    Timers:CreateTimer(1, function()
      self:StartIntervalThink(FrameTime())
    end)

    self.playerHero = self:GetCaster():GetPlayerHero()

    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.close_radius = self:GetAbility():GetSpecialValueFor("close_radius")
    self.far_radius = self:GetAbility():GetSpecialValueFor("far_radius")
  end
end

function modifier_mine:OnIntervalThink()
  if not IsServer() then return end

  local enemies = FindEnemiesInRadius(self:GetParent(), self.close_radius)
  local foundEnemy = false
  for _,enemy in pairs(enemies) do
    if not enemy:HasFlyMovementCapability() and not IsCustomBuilding(enemy) then
      StopSoundOn("Hero_Techies.LandMine.Plant", self:GetCaster())
      EmitSoundOn("Hero_Techies.LandMine.Detonate", self:GetParent())

      local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_POINT, self:GetCaster())
      ParticleManager:SetParticleControl(nfx, 0, self:GetParent():GetAbsOrigin())
      ParticleManager:SetParticleControl(nfx, 1, self:GetParent():GetAbsOrigin())
      ParticleManager:SetParticleControl(nfx, 2, Vector(self.far_radius, self.far_radius, self.far_radius))
      ParticleManager:ReleaseParticleIndex(nfx)

      ApplyDamage({
        victim = enemy,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        attacker = self.playerHero,
        ability = self:GetAbility()
      })

      foundEnemy = true
    end    
  end

  if foundEnemy then
    local close_enemies = FindEnemiesInRadius(self:GetParent(), self.far_radius)
    for _,enemy in pairs(close_enemies) do
      if not enemy:HasFlyMovementCapability() and not IsCustomBuilding(enemy) then
        ApplyDamage({
          victim = enemy,
          damage = self.damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          attacker = self.playerHero,
          ability = self:GetAbility()
        })
      end
    end
  
    self:GetParent():ForceKill(false)
    self:Destroy()
  end
end

function modifier_mine:CheckState()
  return { 
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVISIBLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNTARGETABLE] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true
  }
end