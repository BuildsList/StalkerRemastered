#define DMG_TYPE_GIB 1
#define DMG_TYPE_ENERGY 2
#define DMG_TYPE_BURN 4
#define DMG_TYPE_BRAIN 8
#define DMG_TYPE_RADIATION 16
#define DMG_TYPE_IGNITION 32
#define DMG_TYPE_BIO 64
#define DMG_TYPE_LASTER 128
GLOBAL_LIST_EMPTY(anomalies)
GLOBAL_LIST_EMPTY(spawned_artifacts)

/obj/anomaly
	name = "Anomaly"
	var/damage_amount = 0 				//������� �������
	var/damage_type = DMG_TYPE_ENERGY	//��� ������
	var/activated_icon_state = null 	//������ ��� ���������
	var/cooldown = 5
	var/lasttime = 0
	var/list/mob/living/trapped = new/list()
	var/idle_luminosity = 0
	var/activated_luminosity = 0
	var/sound = null
	var/delay = 0
	var/incooldown = 0
	//var/attachedSpawner = null
	var/active_icon_state = null
	var/inactive_icon_state = null;
	var/active_invisibility = 0
	var/inactive_invisibility = 0
	var/list/loot = list()
	var/anomaly_color = null
	var/loot_count = 1
	icon = 'stalker/icons/anomalies.dmi'
	resistance_flags = UNACIDABLE
	anchored = 1
	pass_flags = PASSTABLE | PASSGRILLE

/obj/anomaly/Initialize()
	..()
	GLOB.anomalies += src
	icon_state = inactive_icon_state
	invisibility = inactive_invisibility
	set_light(idle_luminosity, l_color = anomaly_color)
	SpawnArtifact()

/obj/anomaly/proc/SpawnArtifact()
	for(var/i = 1, i <= loot_count, i++)
		if(!loot)
			return

		var/lootspawn = pickweight(loot)

		if(!lootspawn || lootspawn == /obj/nothing)
			return

		//var/obj/item/artifact/lootspawn_art = lootspawn
		var/turf/T = get_turf(src)
		var/obj/item/artifact/O = new lootspawn(T)
		O.invisibility = 100
		if (z == 1)
			if(O.level_s > 4)
				SpawnArtifact()
				return
		if (z == 2)
			switch(y)
				if(766 to 1000)
					if(O.level_s > 4)
						SpawnArtifact()
						return

				if(511 to 765)
					if(O.level_s > 3)
						SpawnArtifact()
						return

				if(256 to 510)
					if(O.level_s > 2)
						SpawnArtifact()
						return
				if(0 to 255)
					if(O.level_s > 3)
						SpawnArtifact()
						return
		RandomMove(O)
		GLOB.spawned_artifacts += O

/obj/anomaly/proc/RandomMove(spawned)
	if(!spawned || !istype(spawned, /obj))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/obj/O = spawned
	var/new_x = T.x + rand(-1, 1)
	var/new_y = T.y + rand(-1, 1)
	O.Move(locate(new_x, new_y, T.z))

	//if(istype(get_turf(O), /turf/open/stalker))
	//	RandomMove(spawned)

/obj/anomaly/Crossed(atom/A)
	..()
	if(lasttime + (cooldown * 10) > world.time)
		return

	if(istype(A,/obj/item/projectile) || istype(A,/obj/item/artifact))
		return

	if(istype(A,/obj/item))

		ApplyEffects()

		lasttime = world.time

		playsound(src.loc, src.sound, 50, 1, channel = 0)
		var/obj/item/I = A

		AffectItem(I)

		return

	if(istype(A,/mob/living))
		var/mob/living/L = A
		src.trapped.Add(L)
		if(src.trapped.len >= 1 && !incooldown)
			Think()
	return

/obj/anomaly/Uncrossed(atom/A)
	..()
	if(istype(A, /mob/living))
		var/mob/living/L = A
		src.trapped.Remove(L)
	return

/obj/anomaly/proc/Think()

	if(!src.trapped || src.trapped.len < 1)
		incooldown = 0
		return

	if(lasttime + (cooldown * 10) > world.time)
		addtimer(CALLBACK(src, .proc/Think), (lasttime + (cooldown * 10) - world.time))
		return

	incooldown = 1

	lasttime = world.time

	for(var/atom/A in src.trapped)

		ApplyEffects()

		////////////////////
		sleep(src.delay * 10)
		////////////////////

		if(!istype(A, /mob/living))
			trapped.Remove(A)
			continue

		var/mob/living/L = A

		if(L.stat == 2)
			src.trapped.Remove(L)
			continue

		DealDamage(L)

		///////////////////////
		sleep(src.cooldown * 10)
		///////////////////////

	if(!src.trapped || src.trapped.len < 1)
		incooldown = 0
		return

	Think()
	return

/obj/anomaly/proc/ApplyEffects()
	invisibility = active_invisibility
	flick(active_icon_state, src)
	update_icon()
	set_light(activated_luminosity, l_color = anomaly_color)
	playsound(src.loc, src.sound, 50, 1, channel = 0)

	spawn(10)
		invisibility = inactive_invisibility
		update_icon()
		set_light(idle_luminosity, l_color = anomaly_color)

	return

/obj/anomaly/proc/AffectItem(var/obj/item/I)
	if ((I.resistance_flags & (UNACIDABLE)))
		return

	I.throw_impact(get_turf(I))
	I.throwing = 0

	sleep(5)

	var/turf/T = get_turf(I)
	var/obj/effect/decal/cleanable/molten_object/Q = new /obj/effect/decal/cleanable/molten_object(T)
	Q.pixel_x = rand(-16,16)
	Q.pixel_y = rand(-16,16)
	Q.desc = "Looks like this was \an [I] some time ago."

	qdel(I)

/obj/anomaly/proc/DealDamage(var/mob/living/L)
	if(!(L in src.trapped))
		return

	lasttime = world.time

	switch(src.damage_type)
		if(DMG_TYPE_ENERGY)
			L.apply_damage(src.damage_amount, BURN, null, L.getarmor(null, "energy"))
		if(DMG_TYPE_BIO)
			L.apply_damage(src.damage_amount, BURN, null, L.getarmor(null, "bio"))
		if(DMG_TYPE_LASTER)
			L.apply_damage(src.damage_amount, BURN, null, L.getarmor(null, "laser"))
		if(DMG_TYPE_RADIATION)
			L.rad_act(src.damage_amount)
		if(DMG_TYPE_GIB)
			if(L.stat == DEAD)
				L.gib()
				trapped.Remove(L)
			else
				L.apply_damage(src.damage_amount, BRUTE, null, L.getarmor(null, "meele"))
		if(DMG_TYPE_IGNITION)
			if(istype(L, /mob/living/simple_animal/hostile))
				L.apply_damage(40, BURN, null, 0)
			else
				L.apply_damage(20, BURN, null, 0)
				L.fire_act()
	return

/obj/anomaly/tramplin/DealDamage(var/mob/living/L)
	if(!(L in src.trapped))
		return

	L.apply_damage(src.damage_amount, BRUTE, null, 0)

	var/target = get_turf(src)

	for(var/o=0, o<8, o++)
		target = get_step_rand(target)

	L.throw_at(target, 6, 1, spin=1, diagonals_first = 1)
	L.Stun(2)
	return


/obj/anomaly/electro
	name = "anomaly"
	damage_amount = 40
	cooldown = 2
	sound = 'stalker/sound/anomalies/electra_blast1.ogg'
	idle_luminosity = 1
	activated_luminosity = 3
	anomaly_color = "#7ac8e2"
	damage_type = DMG_TYPE_ENERGY
	inactive_icon_state = "electra0"
	active_icon_state = "electra1"
	active_invisibility = 0
	inactive_invisibility = 0
	loot = list(/obj/nothing = 90,
				/obj/item/artifact/flash = 5,
				/obj/item/artifact/moonlight = 3.5,
				/obj/item/artifact/battery = 1.5,
				/obj/item/artifact/pustishka = 0.5
				)

/obj/anomaly/electro/Initialize()
	..()
	SSobj.processing.Add(src)
	src.set_light(idle_luminosity)
	spawn(10)
		SSobj.processing.Remove(src)

/obj/anomaly/karusel
	name = "anomaly"
	damage_amount = 30
	cooldown = 2
	delay = 1
	sound = 'stalker/sound/anomalies/gravi_blowout1.ogg'
	idle_luminosity = 0
	activated_luminosity = 0
	inactive_icon_state = "tramplin0"
	active_icon_state = "tramplin1"
	damage_type = DMG_TYPE_GIB
	active_invisibility = 0
	inactive_invisibility = 101
	loot = list(/obj/nothing = 80,
				/obj/item/artifact/meduza = 12,
				/obj/item/artifact/stoneflower = 5,
				/obj/item/artifact/nightstar = 2,
				/obj/item/artifact/soul = 1
				)

/obj/anomaly/karusel/Initialize()
	..()
	SSobj.processing.Add(src)

/obj/anomaly/karusel/Destroy()
	..()
	SSobj.processing.Remove(src)

/obj/anomaly/karusel/process()
	for(var/atom/movable/A in range(2, src))
		if(!A.anchored)
			step_towards(A,src)
			//if(!(A in trapped))
			//	src.trapped.Add(A)

/obj/anomaly/tramplin
	name = "anomaly"
	damage_amount = 15
	cooldown = 2
	delay = 0.5
	sound = 'stalker/sound/anomalies/gravi_blowout1.ogg'
	idle_luminosity = 0
	activated_luminosity = 0
	inactive_icon_state = "tramplin0"
	active_icon_state = "tramplin1"
	damage_type = DMG_TYPE_GIB
	active_invisibility = 0
	inactive_invisibility = 101
	loot = list(/obj/nothing = 80,
				/obj/item/artifact/meduza = 12,
				/obj/item/artifact/stoneflower = 6,
				/obj/item/artifact/nightstar = 2
				)

/obj/anomaly/jarka
	name = "anomaly"
	cooldown = 2
	sound = 'stalker/sound/anomalies/zharka1.ogg'
	luminosity = 2
	idle_luminosity = 3
	activated_luminosity = 5
	anomaly_color = "#FFAA33"
	damage_type = DMG_TYPE_IGNITION
	icon = 'stalker/icons/anomalies.dmi'
	inactive_icon_state = "jarka0"
	active_icon_state = "jarka1"
	active_invisibility = 0
	inactive_invisibility = 0
	loot = list(/obj/nothing = 90,
				/obj/item/artifact/droplet = 5,
				/obj/item/artifact/fireball = 3,
				/obj/item/artifact/crystal = 1.5,
				/obj/item/artifact/maminibusi = 0.5
				)

/obj/anomaly/jarka/Initialize()
	..()
	SSobj.processing.Add(src)
	src.set_light(idle_luminosity)
	spawn(10)
		SSobj.processing.Remove(src)

/obj/anomaly/jarka/Uncrossed(atom/A)
	..()
	if(istype(A, /mob/living))
		var/mob/living/L = A
		src.trapped.Remove(L)
		lasttime = 0
		incooldown = 0
	return

/obj/anomaly/jarka/AffectItem(var/obj/item/I)
	incooldown = 0
	lasttime = 0

	if((I.resistance_flags & (UNACIDABLE)))
		return

	I.throw_impact(get_turf(I))
	I.throwing = 0

	sleep(5)

	var/turf/T = get_turf(I)
	var/obj/effect/decal/cleanable/molten_object/Q = new /obj/effect/decal/cleanable/molten_object(T)
	Q.pixel_x = rand(-16,16)
	Q.pixel_y = rand(-16,16)
	Q.desc = "Looks like this was \an [I] some time ago."

	qdel(I)
/*
/obj/anomaly/jarka/comet
	name = "comet"
	inactive_icon_state = "jarka1"
	active_icon_state = "jarka1"
	loot = list(/obj/item/artifact/droplet = 45,
				/obj/item/artifact/fireball = 40,
				/obj/item/artifact/crystal = 10,
				/obj/item/artifact/maminibusi = 5
				)
	loot_count = 2
	var/stage = 0
	var/radius = 3
	var/list/turf/traectory = null

/obj/anomaly/jarka/comet/New()
	..()
	SSobj.processing.Add(src)
	traectory = circlerangeturfs(src, 4)

/obj/anomaly/jarka/comet/Destroy()
	..()
	SSobj.processing.Remove(src)

/obj/anomaly/jarka/comet/process()
	stage++
	//world << stage //fuck you - valtos
	forceMove(traectory[stage])
	if(stage == traectory.len)
		stage = 0
*/ //NEED REWORK
/obj/anomaly/holodec
	name = "anomaly"
	cooldown = 2
	luminosity = 3
	idle_luminosity = 3
	activated_luminosity = 5
	anomaly_color = "#70cc33"
	sound = 'stalker/sound/anomalies/buzz_hit.ogg'
	damage_type = DMG_TYPE_LASTER
	damage_amount = 60
	icon = 'stalker/icons/anomalies.dmi'
	inactive_icon_state = "holodec"
	active_icon_state = "holodec" //needs activation icon
	active_invisibility = 0
	inactive_invisibility = 0
	loot = list(/obj/nothing = 80,
				/obj/item/artifact/stone_blood = 10,
				/obj/item/artifact/bubble = 5.5,
				/obj/item/artifact/mica = 3,
				/obj/item/artifact/firefly = 1.5
				)

/obj/anomaly/holodec/Initialize()
	..()
	SSobj.processing.Add(src)

/obj/anomaly/holodec/Destroy()
	..()
	SSobj.processing.Remove(src)

/obj/anomaly/holodec/Uncrossed(atom/A)
	..()
	if(istype(A, /mob/living))
		var/mob/living/L = A
		src.trapped.Remove(L)
		lasttime = 0
		incooldown = 0
	return

/obj/anomaly/holodec/AffectItem(var/obj/item/I)
	incooldown = 0
	lasttime = 0

	if((I.resistance_flags & (UNACIDABLE)))
		return

	I.throw_impact(get_turf(I))
	I.throwing = 0

	sleep(5)

	var/turf/T = get_turf(I)
	var/obj/effect/decal/cleanable/molten_object/Q = new /obj/effect/decal/cleanable/molten_object(T)
	Q.pixel_x = rand(-16,16)
	Q.pixel_y = rand(-16,16)
	Q.desc = "Looks like this was \an [I] some time ago."

	qdel(I)

/obj/anomaly/holodec/process()
	var/new_dir = rand(1, 10)

	if(!istype(get_step(src, new_dir), /turf/open/stalker/floor))
		return

	if(locate(/obj/anomaly/holodec) in get_step(src, new_dir))
		return

	if(locate(/obj/structure) in get_step(src, new_dir))
		return

	var/obj/anomaly/holodec/splash/son = new /obj/anomaly/holodec/splash(get_step(src, new_dir))
	src.do_attack_animation(son, 0)

/obj/anomaly/holodec/splash
	cooldown = 2
	luminosity = 2
	idle_luminosity = 2
	activated_luminosity = 4
	damage_amount = 33
	inactive_icon_state = null
	active_icon_state = null
	//inactive_icon_state = "holodec_splash"
	//active_icon_state = "holodec_splash" //needs activation icon
	icon_state = "holodec_splash"
	active_invisibility = 0
	inactive_invisibility = 0
	loot = list()
	var/spawn_time = 0

/obj/anomaly/holodec/splash/ApplyEffects()
	playsound(src.loc, src.sound, 50, 1, channel = 0)
	return

/obj/anomaly/holodec/splash/Initialize()
	//..()
	spawn_time = world.time
	SSobj.processing.Add(src)
	flick("holodec_splash_creation", src)
	invisibility = inactive_invisibility
	damage_amount = 0
	sleep(8)
	damage_amount = initial(damage_amount)
	//if(src && get_turf(src))
		//for(var/mob/living/L in get_turf(src).contents)
			//Crossed(L)
/*
/obj/anomaly/holodec/splash/Destroy()
	//..()
	SSobj.processing.Remove(src)
*/
/obj/anomaly/holodec/splash/process()
	if(spawn_time + 15 <= world.time)
		flick("holodec_splash_destruction", src)
		damage_amount = 0

	if(spawn_time + 25 <= world.time)
		invisibility = 101
		src.trapped = list()

/obj/anomaly/puh
	name = "anomaly"
	cooldown = 2
	sound = 'stalker/sound/anomalies/buzz_hit.ogg'
	damage_type = DMG_TYPE_BIO
	damage_amount = 65
	icon = 'stalker/icons/anomalies.dmi'
	inactive_icon_state = "puh"
	active_icon_state = "puh" //needs activation icon
	active_invisibility = 0
	inactive_invisibility = 0

/obj/anomaly/puh/Uncrossed(atom/A)
	..()
	if(istype(A, /mob/living))
		var/mob/living/L = A
		src.trapped.Remove(L)
		lasttime = 0
		incooldown = 0
	return

/obj/anomaly/puh/AffectItem(var/obj/item/I)
	incooldown = 0
	lasttime = 0

	if((I.resistance_flags & (UNACIDABLE)))
		return

	I.throw_impact(get_turf(I))
	I.throwing = 0

	sleep(5)

	var/turf/T = get_turf(I)
	var/obj/effect/decal/cleanable/molten_object/Q = new /obj/effect/decal/cleanable/molten_object(T)
	Q.pixel_x = rand(-16,16)
	Q.pixel_y = rand(-16,16)
	Q.desc = "Looks like this was \an [I] some time ago."

	qdel(I)

/obj/anomaly/puh/Initialize()
	..()
	inactive_icon_state = pick("puh","puh2")
	icon_state = inactive_icon_state
	if(inactive_icon_state == "puh2")
		active_icon_state = "puh2"

/obj/rad 	//�� ������� �����
	name = "Anomaly"
	icon = 'stalker/icons/anomalies.dmi'
	icon_state = "rad_low"
	var/damage_amount = 0 				//������� �������
	var/damage_type = DMG_TYPE_RADIATION	//��� ������
	var/activated_icon_state = null 	//������ ��� ���������
	var/cooldown = 2.5					//�������
	var/lasttime = 0
	var/list/mob/living/carbon/human/trapped = new/list()
	var/idle_luminosity = 0
	var/activated_luminosity = 0
	var/sound = null
	var/delay = 0
	var/attachedSpawner = null
	var/active_icon_state = null
	var/inactive_icon_state = null
	invisibility = 101
	icon = 'stalker/icons/anomalies.dmi'
	resistance_flags = UNACIDABLE
	anchored = 1
	pass_flags = PASSTABLE | PASSGRILLE

/obj/rad/rad_low
	damage_amount = 25
	sound = 'stalker/sound/pda/geiger_1.ogg'
	icon_state = "rad_low"

/obj/rad/rad_medium
	damage_amount = 50
	sound = 'stalker/sound/pda/geiger_4.ogg'
	icon_state = "rad_medium"

/obj/rad/rad_high
	damage_amount = 75
	sound = 'stalker/sound/pda/geiger_6.ogg'
	icon_state = "rad_high"

/obj/rad/Initialize()
	..()
	SSobj.processing += (src)

/obj/rad/Destroy()
	..()
	SSobj.processing -= (src)

/obj/rad/Crossed(atom/A)
	..()

	if(istype(A,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = A
		src.trapped += H

		if(lasttime + cooldown < world.time)
			H.rad_act(src.damage_amount)

		if(istype(H.wear_id,/obj/item/stalker_pda))
			H << sound(src.sound, repeat = 0, wait = 0, volume = 50, channel = 3)

		//if(src.trapped.len >= 1)
		//	SSobj.processing |= src

/obj/rad/Uncrossed(atom/A)
	..()
	if (istype(A,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = A
		src.trapped -= H
		//SSobj.processing.Remove(src)

/obj/rad/process()
	if(src.trapped.len < 1)
		//SSobj.processing.Remove(src)
		return

	if(lasttime + cooldown > world.time)
		return

	for(var/atom/A in src.trapped)

		if(!istype(A, /mob/living/carbon/human))
			trapped -= A
			continue

		var/mob/living/carbon/human/H = A

		if(H.stat == 2)
			trapped -= H
			continue

		H.rad_act(src.damage_amount)

		if(istype(H.wear_id,/obj/item/stalker_pda))
			H << sound(src.sound, repeat = 0, wait = 0, volume = 50, channel = 3)

	src.lasttime = world.time
