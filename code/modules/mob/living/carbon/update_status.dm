/mob/living/carbon/update_stat(reason = "none given")
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= HEALTH_THRESHOLD_DEAD && check_death_method())
			death()
			create_debug_log("died of damage, trigger reason: [reason]")
			return
		if(sleeping || paralysis || (check_death_method() && getOxyLoss() > 50) || (status_flags & FAKEDEATH) || health <= HEALTH_THRESHOLD_CRIT && check_death_method())
			if(stat == CONSCIOUS)
				KnockOut(TRUE, anesthetized)
				create_debug_log("fell unconscious, trigger reason: [reason]")
		else
			if(stat == (UNCONSCIOUS | ANESTHETIZED))
				WakeUp()
				create_debug_log("woke up, trigger reason: [reason]")
	update_damage_hud()
	update_health_hud()
	med_hud_set_status()

/mob/living/carbon/update_stamina()
	var/stam = getStaminaLoss()
	if(stam > DAMAGE_PRECISION && (maxHealth - stam) <= HEALTH_THRESHOLD_CRIT && !stat)
		enter_stamcrit()
	else if(stam_paralyzed)
		stam_paralyzed = FALSE
		update_canmove()

/mob/living/carbon/can_hear()
	. = FALSE
	var/obj/item/organ/internal/ears/ears = get_int_organ(/obj/item/organ/internal/ears)
	if(istype(ears) && !ears.deaf)
		. = TRUE
