--Ty to MEW Feral Sim
-- jpganis
function druid_feral(self)

	local energy = UnitMana("player")
	local cp = GetComboPoints("player")
	local executePhase = jps.hp("target") <= 0.25
	local gcdLocked = true -- they changed this :( jps.cooldown("shred") == 0
	local energyPerSec = 10.59

	local tigersFuryCD = jps.cooldown("Tiger's Fury")

	local clearcasting = jps.buff("Clearcasting")
	local berserk = jps.buff("Berserk")
	local tigersFury = jps.buff("Tiger's fury")
	local predatorySwiftness = jps.buff("Predatory Swiftness")
	local cenarionStacks = jps.buffStacksID(108381) -- Dream of Cenarius

	local ripDuration = jps.debuffDuration("Rip")
	local rakeDuration = jps.debuffDuration("Rake")
	local savageRoarDuration = jps.buffDuration("Savage Roar")
	local thrashDuration = jps.debuffDuration("Thrash")
	local predatorySwiftnessDuration = jps.buffDuration("Predatory Swiftness")

	local maxLevel = (UnitLevel("player") == 90)

	local possibleSpells = {
		-- Bail if not in cat form.
	  { nil, 
	  	not jps.buff("Cat Form") },

	  -- Bail if not in melee range.
    { nil, 
    	IsSpellInRange("Shred", "target") == 0 },

		-- Savage Roar should be kept up at all times.
    { "Savage Roar", 
    	savageRoarDuration == 0 },

		-- Healing Touch when we have Predatory Swiftness, less than 2 cenarion stacks, and the combo points to use the damage buff.
		{ "Healing Touch", 
			predatorySwiftness
			and cenarionStacks < 2
			and cp >= 4
			and maxLevel },

		-- Healing Touch to use up Predatory Swiftness before it falls off if we have less than 2 cenarion stacks and low combo points and energy.
		{ "Healing Touch", 
			predatorySwiftness
			and predatorySwiftnessDuration <= 1
			and not clearcasting 
			and energy < 45 
			and cenarionStacks < 2 
			and cp < 4
			and maxLevel },

		-- Healing Touch whenever we have Nature's Swiftness. (talent based)
		{ "Healing Touch", 
			jps.buff("Nature's Swiftness")
			and cenarionStacks < 2
			and maxLevel },

		-- Temporary for leveling.
		{ "Healing Touch", 
			predatorySwiftness or jps.buff("Nature's Swiftness")
			and jps.hp() < .6
			and not maxLevel },

		-- Tiger's Fury when we're low on energy.
		{ "Tiger's Fury", 
			energy <= 35 
			and not clearcasting 
			and gcdLocked },

		-- Berserk when we have Tiger's Fury
		{ "Berserk", 
			jps.UseCDs
			and jps.buff("Tiger's Fury") },

		-- Nature's Vigil if Berserk buff in on.
		{ "Nature's Vigil", 
			jps.UseCDs
			and berserk },

		-- Incarnation if Berserk buff in on. (talent specific)
		{ "Incarnation", 
			jps.UseCDs
			and berserk },

		-- Treants (talent specific)
		{ "Force of Nature" },

		-- On-Use Trinkets if Berserk buff in on.
    { jps.useSlot(13), 
      jps.UseCDs
      and berserk },
    { jps.useSlot(14), 
      jps.UseCDs
      and berserk },

		-- DPS Racial if Berserk buff in on.
		{ jps.DPSRacial, 
			jps.UseCDs
			and berserk },

		-- Engineers may have synapse springs on their gloves (slot 10).
		{ jps.useSlot(10), 
      jps.UseCDs
      and berserk },

		-- Lifeblood if Berserk buff in on. (requires herbalism)
		{ "Lifeblood",
			jps.UseCDs
			and berserk },

		-- Interrupt
		{ "Skull Bash", 
			jps.shouldKick() 
			and jps.Interrupts },

		-- Faerie Fire single-target when we know it's going to be a longer fight.
		{ "Faerie Fire", 
			not jps.MultiTarget
			and energy <= 60
			and not jps.debuff("Weakened Armor")
			and UnitHealth("target") > (UnitHealth("player") * .8) },

		-- Ferocious Bite if we're in execute phase and Rip is about the fall off.
		{ "Ferocious Bite", 
			not jps.MultiTarget
			and executePhase 
			and cp > 0 
			and ripDuration <= 2 
			and ripDuration > 0 },

		-- Multi-target only: Thrash debuff should be kept up at all times.
	  { "Thrash", 
	  	jps.MultiTarget
	  	and thrashDuration < 2 },

	  -- Multi-target only: Swipe is the base AoE spell. (Assume there's a good reason to limit at 51+?)
	  { "Swipe", 
	  	jps.MultiTarget
	  	and energy > 51 },

		-- Thrash if we're clearcasting, it's debuff is about to run out, and we have no cenarion stacks.
		{ "Thrash", 
			clearcasting 
			and thrashDuration < 3 
			and cenarionStacks == 0 },

		-- Savage Roar
		{ "Savage Roar", 
			savageRoarDuration <= 1 
			or (savageRoarDuration <= 3 
				and cp > 0) 
			and executePhase },

		-- Nature's Swiftness
		{ "Nature's Swiftness",	
			cenarionStacks == 0 
			and not predatorySwiftness 
			and cp >= 5 
			and executePhase },

		-- Rip
		{ "Rip", 
			not jps.MultiTarget
			and cp >= 5 
			and cenarionStacks > 0 
			and executePhase 
			and not jps.RipBuffed }, -- stronger rip detection

		-- Ferocious Bite
		{ "Ferocious Bite", 
			not jps.MultiTarget
			and executePhase 
			and cp == 5 
			and ripDuration > 0 },

		-- Rip
		{ "Rip", 
			not jps.MultiTarget
			and cp >= 5 
			and ripDuration < 2 
			and cenarionStacks > 0 },

		-- Savage Roar
		{ "Savage Roar", 
			savageRoarDuration <= 1 
			or (savageRoarDuration <= 3 
				and cp > 0) },

		-- Nature's Swiftness
		{ "Nature's Swiftness",	
			cenarionStacks == 0 
			and not predatorySwiftness 
			and cp >= 5 
			and ripDuration < 3 
			and (berserk 
				or ripDuration <= tigersFuryCD) 
			and not executePhase
			and maxLevel },

		-- Temporary for leveling
		{ "Nature's Swiftness",	
			not predatorySwiftness
			and not maxLevel },

		-- Rip
		{ "Rip", 
			not jps.MultiTarget
			and cp >= 5 
			and ripDuration < 2 
			and (berserk 
				or ripDuration < tigersFuryCD) },

		-- Thrash
		{ "Thrash", 
			clearcasting 
			and thrashDuration < 3 },

		-- Savage Roar
		{ "Savage Roar", 
			savageRoarDuration <= 6 
			and cp >= 5 
			and ripDuration > 4 },

		-- Ferocious Bite
		{ "Ferocious Bite", 
			not jps.MultiTarget
			and cp >= 5 
			and ripDuration > 4 },

		-- Rake
		{ "Rake", 
			not jps.MultiTarget
			and cenarionStacks > 0 
			and not jps.RakeBuffed },

		-- Rake
		{ "Rake", 
			not jps.MultiTarget
			and rakeDuration < 3 
			and (berserk 
				or tigersFuryCD + .8 >= rakeDuration) },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and clearcasting },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and predatorySwiftnessDuration > 1 
			and not (energy + (energyPerSec * (predatorySwiftnessDuration - 1)) < (4 - cp) * 20) },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and ( 
				(cp < 5 
					and ripDuration < 3) 
				or (cp == 0 
					and savageRoarDuration < 2 ) 
			) },

		-- Thrash
		{ "Thrash", 
			cp >= 5 
			and thrashDuration < 6 
			and (tigersFury 
				or berserk) },

		-- Thrash
		{ "Thrash", 
			cp >= 5 
			and thrashDuration < 6 
			and tigersFuryCD <= 3 },

		-- Thrash
		{ "Thrash", 
			cp >= 5 
			and thrashDuration < 6 
			and energy >= 100 - energyPerSec },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and ( berserk 
				or jps.buff("tiger's fury")
			) },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and tigersFuryCD <= 3 },

		-- Shred
		{ "Shred", 
			not jps.MultiTarget
			and energy >= 100 - (energyPerSec * 2) },
	}

	return parseSpellTable(possibleSpells)
end
