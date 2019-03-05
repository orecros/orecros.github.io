/*
 * Andrew Tollett, 2019
 * This is some compiled snippets of code from my Zombie Survival overhaul.
 * These are for auto-generating descriptions to zombie classes. using the
 * translation module, these auto-generated descriptions are available in
 * both english and russian.
 *
 * All of the code on this page was written by me for use in this project.
 */

function CLASS:Describe()
	//input.LookupBinding()
	/*
		so you have this table description that gets returned. each entry in this
		table gets added as its own richly formatted section. $ is the escape char
		and can hold the following values:
			$stats: gets put at the very start of the description with no header.
			$attack1/$attack2/$reload/$sprint: the header name gets replaced by the name
				of the key the player has bound to attack1/attack2/reload/sprint.
		all other entires get added with text of the same key added
	*/


	local description = {}

  --at the top, describe the stats of the class
	description["$stats"] = self:DescribeStats()


  --describe the class's attacks and SPRINT ability if it has one
  --get a copy of the class's weapon.
	local wep = weapons.Get(self.SWEP)
	--don't need to check if these exist, will set to nil if it doesn't
	description["$attack1"] = wep:DescribeAttack(wep.Attack1)
	description["$attack2"] = wep:DescribeAttack(wep.Attack2)
	description["$reload"] = wep:DescribeAttack(wep.Attack3)
	description["$sprint"] = wep:DescribeAlt()

	return description
end

function CLASS:DescribeStats()
  --using table.concat here because large amounts of .. concatenation is slow in Lua
	txt = table.concat({
		translate.Format("health_x",self:CalcMaxHealth()), "\n",
		translate.Format("speed_x", self.Speed) , "\n",
		((wep.CanClimb) and (translate.Get("can_climb") .. "\n") or (""))
	})

	return txt
end

--auto-generate a description of the attack based on its type and stats
function SWEP:DescribeAttack(Attack)
  --if the attack is invalid, ignore it
	if not Attack or Attack.Type == ZATTACK_NONE then return end

	if Attack.DoOverrideDescriptor then
    --this particular attack is set to use custom text instead of the auto-generated one
		return Attack:GetDescriptorText()
	end

	local txttab = {}

	if Attack.Type == ZATTACK_MELEE then
    --"claws for %d damage"
		table.insert(txttab, translate.GetFormatted("attack_claw",Attack.MeleeDamage))
		table.insert(txttab, "\n")
	elseif Attack.Type == ZATTACK_LEAP then
		local adj

    --"leaps [a long distance |a short distance |] for %d damage"
		if Attack.LeapSpeed > 750 then
			table.insert(txttab, translate.GetFormatted("attack_leap_long", Attack.LeapDamage or 0))
		elseif Attack.LeapSpeed < 450 then
			table.insert(txttab, translate.GetFormatted("attack_leap_short", Attack.LeapDamage or 0))
		else
			table.insert(txttab, translate.GetFormatted("attack_leap", Attack.LeapDamage or 0))
		end
		table.insert(txttab, "\n")

		if Attack.LeapCanAirControl then
      --"can change direction in midair"
			table.insert(txttab, translate.Get("can_change_direction"))
			table.insert(txttab, "\n")
		end

		if Attack.LeapCanInterrupt then
      --"can interrupt to attack"
			table.insert(txttab, translate.Get("can_attack_leaping"))
			table.insert(txttab, "\n")
		end
	elseif Attack.Type == ZATTACK_RANGED then
    --get the translation name of this ranged attack's projectile
		local projName = translate.Get(Attack.RangedProjectile, Attack.RangedProjectile)
      --"fires %s" ["a spray of poison","a glob of pus","a spray of tar"]
			table.insert(txttab, translate.GetFormatted("attack_ranged", projName))
			table.insert(txttab, "\n")
	else
    --"this is a special attack"
		table.insert(txttab, translate.Get("attack_special"))
		table.insert(txttab, "\n")
	end

	if Attack.GetDescriptorText then
    --this attack has additional text to add to the bottom
		table.insert(txttab, Attack:GetDescriptorText())
	end

	return table.concat(txttab)
end
function SWEP:DescribeAlt()
	if not self.Alt then return end

	if self.Alt.DoOverrideDescriptor then
    --this particular alt ability is set to use custom text instead of the auto-generated one
		return self.Alt.GetDescriptorText()
	end

	local txttab = {}

	--Speed Mul
  --"Moves (very)? fast","Moves (very)? slow"
	local SpeedMul = self.Alt.SpeedMul
	if SpeedMul and SpeedMul ~= 1 then
		if SpeedMul > 1.5 then
			table.insert(txttab, translate.Get("speed_very_fast"))
		elseif SpeedMul > 1 then
			table.insert(txttab, translate.Get("speed_fast"))
		elseif SpeedMul < 0.5 then
			table.insert(txttab, translate.Get("speed_very_slow"))
		else --if SpeedMul 0.5 < x < 1
			table.insert(txttab, translate.Get("speed_slow"))
		end
		table.insert(txttab, "\n")
	end

	--Regen
  --"Regenerates %d Health per second"
	local regen = self.Alt.Regen
	if regen and regen > 0 then
		table.insert(txttab, translate.GetFormatted("regenerates",regen))
		table.insert(txttab, "\n")
	end

	--DamageTaken
  --"(Greatly)? [Increases|Reduces] Damage Taken"
	local DamageTakenMul = self.Alt.DamageTakenMul
	if DamageTakenMul and DamageTakenMul ~= 1 then
		if DamageTakenMul > 1.5 then
			table.insert(txttab, translate.Get("damage_taken_much_more"))
		elseif DamageTakenMul > 1 then
			table.insert(txttab, translate.Get("damage_taken_more"))
		elseif DamageTakenMul < 0.5 then
			table.insert(txttab, translate.Get("damage_taken_much_less"))
		else
			table.insert(txttab, translate.Get("damage_taken_less"))
		end
		table.insert(txttab, "\n")
	end

	--DamageDealt
  --"(Greatly)? [Increases|Reduces] Damage Dealt"
	local DamageDealtMul = self.Alt.DamageDealtMul
	if DamageDealtMul and DamageDealtMul ~= 1 then
		if DamageDealtMul > 1.5 then
			table.insert(txttab, translate.Get("damage_dealt_much_more"))
		elseif DamageDealtMul > 1 then
			table.insert(txttab, translate.Get("damage_dealt_more"))
		elseif DamageDealtMul < 0.5 then
			table.insert(txttab, translate.Get("damage_dealt_much_less"))
		else
			table.insert(txttab, translate.Get("damage_dealt_less"))
		end
		table.insert(txttab, "\n")
	end

  --can the player attack while SPRINTing?
	if self.Alt.CanAttack and #txttab > 0 then
		table.insert(txttab, translate.Get("can_attack"))
		table.insert(txttab, "\n")
	end

	if self.Alt.GetDescriptorText then
    --add additional text as needed
		table.insert(txttab, self.Alt.GetDescriptorText())
	end

	return table.concat(txttab)
end
