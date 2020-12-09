elemental_rain = class({})

LinkLuaModifier("modifier_monsoon_thinker", "abilities/elemental/elemental_rain.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meteor_shower_meteor", "abilities/elemental/elemental_rain.lua", LUA_MODIFIER_MOTION_NONE)

function elemental_rain:OnSpellStart()
  local ability = self
  local caster = self:GetCaster()

  local aoe = ability:GetSpecialValueFor("aoe")
  local monsoon_duration = ability:GetSpecialValueFor("monsoon_duration")
  local blizzard_waves = ability:GetSpecialValueFor("blizzard_waves")
  local blizzard_delay = 0.75

  local spells = {
    "monsoon",
    "blizzard",
    "meteor_shower",
  }

  local spellToCast = GetRandomTableElement(spells)

  local target = GetRandomEnemy(caster:GetTeam())
  if not target then return end

  if spellToCast == "monsoon" then
    CreateModifierThinker(
      caster,
      ability,
      "modifier_monsoon_thinker",
      {
        duration = monsoon_duration
      },
      target:GetAbsOrigin(), caster:GetTeam(),
      false
    )
  elseif spellToCast == "blizzard" then
    local position = target:GetAbsOrigin()
    local delay = 0

    for i=1,blizzard_waves do
      Timers:CreateTimer(delay, function()
        self:BlizzardWave(position)
      end)

      delay = delay + blizzard_delay
    end
  elseif spellToCast == "meteor_shower" then
    self:ChaosMeteor(target:GetAbsOrigin())
  end
end

function elemental_rain:BlizzardWave(target_position)
  local ability = self
  local caster = self:GetCaster()
  local radius = ability:GetSpecialValueFor("aoe")
  local damage = ability:GetSpecialValueFor("blizzard_damage_per_wave")
  local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"

  -- Center explosion
  local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
  ParticleManager:SetParticleControl( particle1, 0, target_position )

  Timers:CreateTimer(0.05,function()
  local particle2 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
  ParticleManager:SetParticleControl( particle2, 0, target_position+RandomVector(100) ) end)

  Timers:CreateTimer(0.1,function()
  local particle3 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
   ParticleManager:SetParticleControl( particle3, 0, target_position-RandomVector(100) ) end)

  Timers:CreateTimer(0.15,function()
  local particle4 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
   ParticleManager:SetParticleControl( particle4, 0, target_position+RandomVector(RandomInt(50,100)) ) end)

  Timers:CreateTimer(0.2,function()
  local particle5 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
   ParticleManager:SetParticleControl( particle5, 0, target_position-RandomVector(RandomInt(50,100)) ) end)

  Timers:CreateTimer(0.3, function()
    caster:EmitSound("hero_Crystal.freezingField.explosion")
    
    local enemies = FindEnemiesInRadius(caster, radius, target_position)

    for _,enemy in pairs(enemies) do
      if not IsCustomBuilding(enemy) then
        ApplyDamage({
          victim = enemy,
          attacker = caster,
          damage = damage,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = ability,
        })
      end
    end
  end)
end

function elemental_rain:OnProjectileHit(target, location)
  -- this is for the meteor
  if target and not IsCustomBuilding(target) then
    local damage = self:GetSpecialValueFor("meteor_shower_damage")

    ApplyDamage({
      victim = target,
      attacker = self:GetCaster(),
      damage = damage,
      damage_type = DAMAGE_TYPE_MAGICAL,
      ability = self,
    })
  end
end

function elemental_rain:ChaosMeteor(target_point)
  local caster = self:GetCaster()
  local ability = self

  local caster_point = caster:GetAbsOrigin()

  local travel_speed = 300
  local land_time = 1.3

  local duration = ability:GetSpecialValueFor("meteor_shower_duration")
  local damage = ability:GetSpecialValueFor("meteor_shower_damage")
  local radius = ability:GetSpecialValueFor("aoe")
  
  local caster_point_temp = Vector(caster_point.x, caster_point.y, 0)
  local target_point_temp = Vector(target_point.x, target_point.y, 0)
  
  local point_difference_normalized = (target_point_temp - caster_point_temp):Normalized()
  local velocity_per_second = point_difference_normalized * travel_speed

  caster:EmitSound("Hero_Invoker.ChaosMeteor.Loop")

  --Create a particle effect consisting of the meteor falling from the sky and landing at the target point.
  local meteor_fly_original_point = (target_point - (velocity_per_second * land_time)) + Vector (0, 0, 1000)  --Start the meteor in the air in a place where it'll be moving the same speed when flying and when rolling.
  local chaos_meteor_fly_particle_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 0, meteor_fly_original_point)
  ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 1, target_point)
  ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 2, Vector(1.3, 0, 0))
    
  travel_distance = 465
  
  --Spawn the rolling meteor after the delay.
  Timers:CreateTimer({
    endTime = land_time,
    callback = function()
      local enemies = FindEnemiesInRadius(caster, radius, target_point)

      -- Initial damage
      for _,enemy in pairs(enemies) do
        if not IsCustomBuilding(enemy) then
          ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability,
          })
        end
      end

      --Create a dummy unit will follow the path of the meteor, providing flying vision, sound, damage, etc.      
      local chaos_meteor_dummy_unit = CreateUnitByName("dummy_unit", target_point, false, nil, nil, caster:GetTeam())
      chaos_meteor_dummy_unit:AddNewModifier(caster, ability, "modifier_meteor_shower_meteor", {})

      caster:StopSound("Hero_Invoker.ChaosMeteor.Loop")
      chaos_meteor_dummy_unit:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
      chaos_meteor_dummy_unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")  --Emit a sound that will follow the meteor.
    
      -- local chaos_meteor_duration = travel_distance / travel_speed
      local chaos_meteor_duration = duration
      local chaos_meteor_velocity_per_frame = velocity_per_second * .03
      
      local projectile_information =  
      {
        EffectName = "particles/units/heroes/hero_invoker/invoker_chaos_meteor.vpcf",
        Ability = ability,
        vSpawnOrigin = target_point,
        fDistance = travel_distance,
        fStartRadius = 0,
        fEndRadius = 0,
        Source = chaos_meteor_dummy_unit,
        bHasFrontalCone = false,
        iMoveSpeed = travel_speed,
        bReplaceExisting = false,
        bProvidesVision = true,
        iVisionTeamNumber = caster:GetTeam(),
        iVisionRadius = 500,
        bDrawsOnMinimap = false,
        bVisibleToEnemies = true, 
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_NONE,
        fExpireTime = GameRules:GetGameTime() + chaos_meteor_duration,
        vVelocity = velocity_per_second,
      }
      
      local chaos_meteor_projectile = ProjectileManager:CreateLinearProjectile(projectile_information)
      
      --Adjust the dummy unit's position every frame.
      local endTime = GameRules:GetGameTime() + chaos_meteor_duration
      Timers:CreateTimer({
        callback = function()
          chaos_meteor_dummy_unit:SetAbsOrigin(chaos_meteor_dummy_unit:GetAbsOrigin() + chaos_meteor_velocity_per_frame)
          if GameRules:GetGameTime() > endTime then
            --Stop the sound, particle, and damage when the meteor disappears.
            chaos_meteor_dummy_unit:StopSound("Hero_Invoker.ChaosMeteor.Loop")
            chaos_meteor_dummy_unit:StopSound("Hero_Invoker.ChaosMeteor.Destroy")
            chaos_meteor_dummy_unit:RemoveSelf()
            return 
          else 
            return .03
          end
        end
      })
    end
  })
end

modifier_monsoon_thinker = class({})

function modifier_monsoon_thinker:OnCreated()
  self.ability = self:GetAbility()
  self.caster = self:GetCaster()
  self.parent = self:GetParent()

  self.radius = self.ability:GetSpecialValueFor("aoe")
  self.dps = self.ability:GetSpecialValueFor("monsoon_dps")
  self.lightning_delay = 0.1

  if not IsServer() then return end

  self.playerHero = self:GetCaster():GetPlayerHero()

  self:StartIntervalThink(1)
  self:MonsoonDamage()
end

function modifier_monsoon_thinker:OnIntervalThink()
  self:MonsoonDamage()
end

function modifier_monsoon_thinker:MonsoonDamage()
  if not IsServer() then return end

  local enemies = FindEnemiesInRadius(self.parent, self.radius)

  local delay = 0
  local particle_bolt = "particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf"

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) then
      Timers:CreateTimer(delay, function()
        local particle_bolt_fx = ParticleManager:CreateParticle(particle_bolt, PATTACH_ABSORIGIN, enemy)
        ParticleManager:SetParticleControlEnt(particle_bolt_fx, 0, enemy, PATTACH_ABSORIGIN, "attach_hitloc", enemy:GetAbsOrigin(), true)
        ParticleManager:SetParticleControl(particle_bolt_fx, 1, enemy:GetAbsOrigin() + Vector(0,0,1000))
        ParticleManager:SetParticleControl(particle_bolt_fx, 2, enemy:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle_bolt_fx, 5, enemy:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(particle_bolt_fx)

        -- enemy:EmitSound("Hero_Leshrac.Lightning_Storm")

        ApplyDamage({
          victim = enemy,
          attacker = self.playerHero,
          damage = self.dps,
          damage_type = DAMAGE_TYPE_MAGICAL,
          ability = self.ability,
        })
      end)

      delay = delay + self.lightning_delay
    end
  end
end

modifier_meteor_shower_meteor = class({})

function modifier_meteor_shower_meteor:OnCreated()
  self.ability = self:GetAbility()
  self.caster = self:GetCaster()
  self.parent = self:GetParent()

  self.radius = self.ability:GetSpecialValueFor("aoe")
  self.dps = self.ability:GetSpecialValueFor("meteor_shower_dps")
  self.tick_rate = 0.25
  
  if not IsServer() then return end

  self.playerHero = self:GetCaster():GetPlayerHero()
  self:StartIntervalThink(self.tick_rate)
end

function modifier_meteor_shower_meteor:OnIntervalThink()
  if not IsServer() then return end

  local enemies = FindEnemiesInRadius(self.parent, self.radius)

  for _,enemy in pairs(enemies) do
    if not IsCustomBuilding(enemy) then
      ApplyDamage({
        victim = enemy,
        attacker = self.playerHero,
        damage = self.dps * self.tick_rate,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability,
      })
    end
  end
end