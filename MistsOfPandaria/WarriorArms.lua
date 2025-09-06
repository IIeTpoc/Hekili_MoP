# Arms Warrior – MoP Classic
# (2025-09-06) 
# Only ICD-based trinket heuristics are still omitted.
# ------------------------------------------------------------------------------

### PRE-PULL ###
actions.precombat+=/battle_shout,if=!buff.battle_shout.up
actions.precombat+=/battle_stance,if=!stance.battle
actions.precombat+=/potion,name=mogu_power_potion,seconds_precombat=1
actions.precombat+=/shattering_throw,seconds_precombat=0.5

### BASE ###

actions+=/charge,if=time=0|target.range>8
actions+=/run_action_list,name=movement,if=movement.distance>5
actions+=/call_action_list,name=cooldowns
actions+=/run_action_list,name=execute,if=target.health.pct<20
actions+=/run_action_list,name=aoe,if=active_enemies>=2
actions+=/run_action_list,name=st,if=active_enemies=1
actions+=/call_action_list,name=defensives
actions+=/call_action_list,name=utility

### COOLDOWNS ###                            
# Use offensive cooldowns either inside an active CS window or when CS is about to be applied.
actions.cooldowns+=/colossus_smash,if=debuff.colossus_smash.remains<1
actions.cooldowns+=/avatar,if=talent.avatar.enabled&(debuff.colossus_smash.up|cooldown.colossus_smash.remains<4|target.time_to_die<25)
actions.cooldowns+=/bloodbath,if=talent.bloodbath.enabled&(debuff.colossus_smash.up|cooldown.colossus_smash.remains<4|target.time_to_die<25)
actions.cooldowns+=/recklessness,if=debuff.colossus_smash.up|target.time_to_die<30
actions.cooldowns+=/deadly_calm,if=talent.deadly_calm.enabled&debuff.colossus_smash.up&rage>=60
actions.cooldowns+=/berserker_rage,if=(buff.enrage.down|buff.enrage.remains<0.3)&(debuff.colossus_smash.up|cooldown.colossus_smash.remains<3|is_execute_phase)
actions.cooldowns+=/skull_banner,if=rage>=20&(buff.recklessness.up|cooldown.recklessness.remains<2)
actions.cooldowns+=/storm_bolt,if=talent.storm_bolt.enabled&debuff.colossus_smash.up
actions.cooldowns+=/dragon_roar,if=talent.dragon_roar.enabled&(debuff.colossus_smash.up|cooldown.colossus_smash.remains>6)&active_enemies<=4
actions.cooldowns+=/bladestorm,interrupt_if=cooldown.mortal_strike.ready&cooldown.colossus_smash.ready&debuff.colossus_smash.remains<=1.5&gcd.ready&!cooldown.battle_shout.ready,if=(active_enemies=1&!(debuff.colossus_smash.up&is_execute_phase&rage>=30)&((buff.bloodbath.up&is_execute_phase)|(!cooldown.colossus_smash.ready&debuff.colossus_smash.remains>=3))&buff.enrage.down)|active_enemies>1

# Trinkets / Racials / Potion TODO: Engi gloves
actions.cooldowns+=/use_item,slot=trinket1,if=debuff.colossus_smash.up|target.time_to_die<25
actions.cooldowns+=/use_item,slot=trinket2,if=debuff.colossus_smash.up|target.time_to_die<25
actions.cooldowns+=/potion,name=mogu_power_potion,if=buff.recklessness.up|target.time_to_die<25
actions.cooldowns+=/blood_fury,if=debuff.colossus_smash.up
actions.cooldowns+=/berserking,if=debuff.colossus_smash.up
actions.cooldowns+=/arcane_torrent,if=rage.deficit>=40

### EXECUTE (<20 %) ###
actions.execute+=/colossus_smash,if=debuff.colossus_smash.remains<1
actions.execute+=/mortal_strike,if=!debuff.mortal_wounds.up|debuff.mortal_wounds.remains<3
actions.execute+=/execute,if=debuff.colossus_smash.up&rage>=30
actions.execute+=/execute,if=buff.sudden_death.up&buff.sudden_death.remains<3
actions.execute+=/execute,if=rage>=100
actions.execute+=/slam,if=debuff.colossus_smash.up&rage>=25&rage<100
actions.execute+=/overpower,if=buff.taste_for_blood.stack>=2|rage<80
actions.execute+=/execute,if=rage>=30
actions.execute+=/slam,if=rage>=50
actions.execute+=/heroic_strike,use_off_gcd=1,if=(rage>=rage.max-35&auto_time_to_next>=1.5)|buff.deadly_calm.up
actions.execute+=/battle_shout,if=rage<40

### SINGLE-TARGET ###
actions.st+=/colossus_smash,if=debuff.colossus_smash.remains<1
actions.st+=/mortal_strike,if=!debuff.mortal_wounds.up|debuff.mortal_wounds.remains<4
actions.st+=/overpower,if=debuff.colossus_smash.up|buff.taste_for_blood.stack>=2
actions.st+=/slam,if=debuff.colossus_smash.up&rage>=25
actions.st+=/slam,if=rage>=60&debuff.colossus_smash.down
actions.st+=/execute,if=buff.sudden_death.up&buff.sudden_death.remains<3
actions.st+=/storm_bolt,if=talent.storm_bolt.enabled&debuff.colossus_smash.up
actions.st+=/dragon_roar,if=talent.dragon_roar.enabled&debuff.colossus_smash.up
actions.st+=/shockwave,if=talent.shockwave.enabled&debuff.colossus_smash.up
actions.st+=/slam,if=rage>=50
actions.st+=/heroic_strike,use_off_gcd=1,if=(rage>=rage.max-35&auto_time_to_next>=1.5&debuff.colossus_smash.down)|buff.deadly_calm.up
actions.st+=/overpower,if=rage<70
actions.st+=/heroic_leap,if=debuff.colossus_smash.up&auto_time_to_next>=1.5
actions.st+=/battle_shout,if=rage<50&!buff.battle_shout.up
actions.st+=/heroic_throw,if=rage>90

### AOE (>=2 targets) ###
actions.aoe+=/sweeping_strikes,if=!buff.sweeping_strikes.up
# Thunder Clap & Deep Wounds 
actions.aoe+=/thunder_clap,if=(active_enemies==1&!dot.deep_wounds.ticking)|(active_enemies==2&cooldown.bladestorm.ready&dot.deep_wounds.remains<=2)|(active_enemies==3&(dot.deep_wounds.percent_gain>10|talent.resonating_power.enabled&dot.deep_wounds.percent_gain>0))|(active_enemies>=4&dot.deep_wounds.percent_gain>10)
actions.aoe+=/colossus_smash,if=debuff.colossus_smash.remains<1&active_enemies<=6
actions.aoe+=/mortal_strike,if=buff.sweeping_strikes.up&active_enemies<=4
actions.aoe+=/bladestorm,if=talent.bladestorm.enabled&rage>=20
actions.aoe+=/thunder_clap,if=(talent.blood_and_thunder.enabled&active_enemies>=5|active_enemies>=7)&(dot.deep_wounds.percent_gain>-20)
actions.aoe+=/dragon_roar,if=talent.dragon_roar.enabled&active_enemies>=3
actions.aoe+=/shockwave,if=talent.shockwave.enabled&active_enemies>=3
actions.aoe+=/thunder_clap,if=active_enemies>=6  # unconditional large-pack snap
actions.aoe+=/cleave,if=active_enemies<=4&(rage>=rage.max-35)&auto_time_to_next>=1.5
actions.aoe+=/slam,if=buff.sweeping_strikes.up&rage>=25
actions.aoe+=/slam,if=debuff.colossus_smash.up&rage>=25&active_enemies>=3
actions.aoe+=/thunder_clap,if=(talent.blood_and_thunder.enabled&active_enemies>=3|active_enemies>=4)&(dot.deep_wounds.percent_gain>-20)
actions.aoe+=/heroic_strike,use_off_gcd=1,if=buff.sweeping_strikes.up&(rage>=rage.max-35)&auto_time_to_next>=1.5
actions.aoe+=/execute,if=buff.sudden_death.up&active_enemies<=3
actions.aoe+=/overpower,if=active_enemies<=4&rage<80
actions.aoe+=/whirlwind,if=active_enemies>=5&rage>=30
actions.aoe+=/battle_shout,if=buff.bladestorm.up
actions.aoe+=/battle_shout,if=rage<rage.max-30&active_enemies>=3

### MOVEMENT ###
actions.movement+=/charge,if=auto_time_to_next>=1.5&rage.deficit>=35&target.range>6&target.range<=25
actions.movement+=/heroic_leap,if=target.distance>12|debuff.colossus_smash.up
actions.movement+=/charge,if=auto_time_to_next>=1.5&rage<20&!buff.charge.up
actions.movement+=/charge,if=target.distance>8
actions.movement+=/intervene,if=group&!solo&target.distance>10
actions.movement+=/storm_bolt,if=talent.storm_bolt.enabled&target.distance>8
actions.movement+=/heroic_throw,if=target.distance>5

### DEFENSIVES ###
actions.defensives+=/die_by_the_sword,if=health.pct<60&incoming_damage_5s>health.max*0.25
actions.defensives+=/shield_wall,if=health.pct<50&incoming_damage_4s>health.max*0.4
actions.defensives+=/last_stand,if=health.pct<30&incoming_damage_3s>health.max*0.2
actions.defensives+=/rallying_cry,if=group&!solo&health.pct<25
actions.defensives+=/demoralizing_shout,if=active_enemies>=2&incoming_damage_5s>health.max*0.15
actions.defensives+=/intimidating_shout,if=active_enemies>=2&health.pct<40&!target.debuff.fear.up
actions.defensives+=/enraged_regeneration,if=health.pct<35&buff.enraged_regeneration.down
actions.defensives+=/vigilance,if=talent.vigilance.enabled&group&!solo&tank.health.pct<50
actions.defensives+=/healthstone,if=health.pct<30
actions.defensives+=/victory_rush,if=health.pct<70&buff.victory_rush.up

### UTILITY ###
actions.utility+=/sunder_armor,if=!debuff.sunder_armor.up&!debuff.expose_armor.up&target.time_to_die>15
actions.utility+=/demoralizing_shout,if=!debuff.demoralizing_shout.up&active_enemies>=2
actions.utility+=/commanding_shout,if=group&!buff.commanding_shout.up&!buff.blood_pact.up
actions.utility+=/battle_shout,if=group&!buff.battle_shout.up&!buff.horn_of_winter.up

### FALLBACK ###
actions+=/battle_shout,if=rage<20
actions+=/slam,if=rage>=25
actions+=/overpower
actions+=/heroic_throw
