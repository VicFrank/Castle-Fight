item_custom_blink = class({})

function item_custom_blink:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local target = self:GetCursorPosition()
  local origin = caster:GetOrigin()

  local max_range = 1000

  local direction = (target - origin)
  if direction:Length2D() > max_range then
    direction = direction:Normalized() * max_range
  end

  FindClearSpaceForUnit(caster, origin + direction, true)

  local particle_cast_a = "particles/units/heroes/hero_antimage/antimage_blink_start.vpcf"
  local sound_cast_a = "Hero_Antimage.Blink_out"

  local particle_cast_b = "particles/units/heroes/hero_antimage/antimage_blink_end.vpcf"
  local sound_cast_b = "Hero_Antimage.Blink_in"

  -- At original position
  local effect_cast_a = ParticleManager:CreateParticle( particle_cast_a, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
  ParticleManager:SetParticleControl( effect_cast_a, 0, origin )
  ParticleManager:SetParticleControlForward( effect_cast_a, 0, direction:Normalized() )
  ParticleManager:ReleaseParticleIndex( effect_cast_a )
  EmitSoundOnLocationWithCaster( origin, sound_cast_a, self:GetCaster() )

  -- At original position
  local effect_cast_b = ParticleManager:CreateParticle( particle_cast_b, PATTACH_ABSORIGIN, self:GetCaster() )
  ParticleManager:SetParticleControl( effect_cast_b, 0, self:GetCaster():GetOrigin() )
  ParticleManager:SetParticleControlForward( effect_cast_b, 0, direction:Normalized() )
  ParticleManager:ReleaseParticleIndex( effect_cast_b )
  EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast_b, self:GetCaster() )
end

