item_building_self_destruct = class({})

LinkLuaModifier("modifier_self_destruct", "abilities/buildings/self_destruct.lua", LUA_MODIFIER_MOTION_NONE)

function item_building_self_destruct:GetIntrinsicModifierName()
  return "modifier_self_destruct"
end

function item_building_self_destruct:OnSpellStart()
  if not IsServer() then return end
  
  local caster = self:GetCaster()
  local ability = self

  caster:EmitSound("Hero_Techies.LandMine.Detonate")
  local playerId = caster:GetPlayerOwnerID()
  local hero =  PlayerResource:GetSelectedHeroEntity(playerId)
  hero:ModifyCustomGold(caster.gold_cost * .5)
  SendOverheadEventMessage(
                        PlayerResource:GetPlayer(playerId),
                        OVERHEAD_ALERT_GOLD,
                        caster,
                        caster.gold_cost * .5,
                        PlayerResource:GetPlayer(playerId)
                    )
                    
  local explosion_range = 100

  local particleName = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
  local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 2, Vector(explosion_range, 1, 1))
  ParticleManager:ReleaseParticleIndex(particle)

  caster:AddEffects(EF_NODRAW)
  caster:ForceKill(true)
end

modifier_self_destruct = class({})
function modifier_self_destruct:IsHidden() return true end
function modifier_self_destruct:IsDebuff() return false end
function modifier_self_destruct:IsPurgable() return false end

function modifier_self_destruct:DeclareFunctions()
  return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_self_destruct:OnTakeDamage( keys )
  local ability = self:GetAbility()
  local parent = self:GetParent()
  local unit = keys.unit

  if parent == unit and keys.attacker:GetTeam() ~= parent:GetTeam() then
    ability:StartCooldown(5)
  end
end