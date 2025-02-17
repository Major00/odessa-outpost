//Config stuff
#define SUPPLY_DOCKZ 2          //Z-level of the Dock.
#define SUPPLY_STATIONZ 1       //Z-level of the Station.

//Supply packs are in /code/defines/obj/supplypacks.dm
//Computers are in /code/game/machinery/computer/supply.dm

var/list/mechtoys = list(
	/obj/item/toy/figure/mecha/ripley,
	/obj/item/toy/figure/mecha/fireripley,
	/obj/item/toy/figure/mecha/deathripley,
	/obj/item/toy/figure/mecha/gygax,
	/obj/item/toy/figure/mecha/durand,
	/obj/item/toy/figure/mecha/honk,
	/obj/item/toy/figure/mecha/marauder,
	/obj/item/toy/figure/mecha/seraph,
	/obj/item/toy/figure/mecha/mauler,
	/obj/item/toy/figure/mecha/odysseus,
	/obj/item/toy/figure/mecha/phazon
)

/obj/item/weapon/paper/manifest
	name = "supply manifest"
	var/is_copy = 1

/obj/structure/plasticflaps //HOW DO YOU CALL THOSE THINGS ANYWAY
	name = "\improper plastic flaps"
	desc = "Completely impassable - or are they?"
	icon = 'icons/obj/stationobjs.dmi' //Change this.
	icon_state = "plasticflaps"
	density = 0
	anchored = 1
	layer = ABOVE_MOB_LAYER
	explosion_resistance = 5
	var/list/mobs_can_pass = list(
		/mob/living/carbon/slime,
		/mob/living/simple_animal/mouse,
		/mob/living/silicon/robot/drone
		)

/obj/structure/plasticflaps/CanPass(atom/A, turf/T)
	if(istype(A) && A.checkpass(PASSGLASS))
		return prob(60)

	var/obj/structure/bed/B = A
	if (istype(A, /obj/structure/bed) && B.buckled_mob)//if it's a bed/chair and someone is buckled, it will not pass
		return 0

	if(istype(A, /obj/vehicle))	//no vehicles
		return 0

	var/mob/living/M = A
	if(istype(M))
		if(M.lying)
			return ..()
		for(var/mob_type in mobs_can_pass)
			if(istype(A, mob_type))
				return ..()
		return issmall(M)

	return ..()

/obj/structure/plasticflaps/ex_act(severity)
	switch(severity)
		if (1)
			qdel(src)
		if (2)
			if (prob(50))
				qdel(src)
		if (3)
			if (prob(5))
				qdel(src)

/obj/structure/plasticflaps/mining //A specific type for mining that doesn't allow airflow because of them damn crates
	name = "airtight plastic flaps"
	desc = "Heavy duty, airtight, plastic flaps."

/obj/structure/plasticflaps/mining/New() //set the turf below the flaps to block air
	update_turf_underneath(1)
	..()

/obj/structure/plasticflaps/mining/Destroy() //lazy hack to set the turf to allow air to pass if it's a simulated floor
	update_turf_underneath(0)
	. = ..()

/obj/structure/plasticflaps/mining/proc/update_turf_underneath(var/should_pass)
	var/turf/T = get_turf(loc)
	if(T)
		if(should_pass)
			T.blocks_air = 1
		else
			if(istype(T, /turf/simulated/floor))
				T.blocks_air = 0




/*
/obj/effect/marker/supplymarker
	icon_state = "X"
	icon = 'icons/misc/mark.dmi'
	name = "X"
	invisibility = 101
	anchored = 1
	opacity = 0
*/
/*
/datum/supply_order
	var/ordernum
	var/datum/supply_packs/object = null
	var/orderedby = null
	var/comment = null

/datum/controller/supply
	//supply points
	var/points = 50
	var/points_per_process = 1
	var/points_per_slip = 2
	var/points_per_crate = 5
	var/points_per_platinum = 5 // 5 points per sheet
	var/points_per_plasma = 5
	//control
	var/ordernum
	var/list/shoppinglist = list()
	var/list/requestlist = list()
	var/list/supply_packs = list()
	//shuttle movement
	var/movetime = 1200
	var/datum/shuttle/ferry/supply/shuttle

	New()
		ordernum = rand(1,9000)

		for(var/typepath in (typesof(/datum/supply_packs) - /datum/supply_packs))
			var/datum/supply_packs/P = new typepath()
			supply_packs[P.name] = P

	// Supply shuttle ticker - handles supply point regeneration
	// This is called by the process scheduler every thirty seconds
	Process()
		points += points_per_process

	//To stop things being sent to centcomm which should not be sent to centcomm. Recursively checks for these types.
	proc/forbidden_atoms_check(atom/A)
		if(isliving(A))
			return 1
		if(istype(A,/obj/item/weapon/disk/nuclear))
			return 1
		if(istype(A,/obj/machinery/nuclearbomb))
			return 1
		if(istype(A,/obj/item/device/radio/beacon))
			return 1

		for(var/i=1, i<=A.contents.len, i++)
			var/atom/B = A.contents[i]
			if(.(B))
				return 1

	//Sellin
	proc/sell()
		var/area/area_shuttle = shuttle.get_location_area()
		if(!area_shuttle)	return

		var/plasma_count = 0
		var/plat_count = 0

		for(var/atom/movable/MA in area_shuttle)
			if(MA.anchored)	continue

			// Must be in a crate!
			if(istype(MA,/obj/structure/closet/crate))
				callHook("sell_crate", list(MA, area_shuttle))

				points += points_per_crate
				var/find_slip = 1

				for(var/atom in MA)
					// Sell manifests
					var/atom/A = atom
					if(find_slip && istype(A,/obj/item/weapon/paper/manifest))
						var/obj/item/weapon/paper/manifest/slip = A
						if(!slip.is_copy && slip.stamped && slip.stamped.len) //yes, the clown stamp will work. clown is the highest authority on the station, it makes sense
							points += points_per_slip
							find_slip = 0
						continue

					// Sell plasma and platinum
					if(istype(A, /obj/item/stack))
						var/obj/item/stack/P = A
						switch(P.get_material_name())
							if("plasma") plasma_count += P.get_amount()
							if("platinum") plat_count += P.get_amount()
			qdel(MA)

		if(plasma_count)
			points += plasma_count * points_per_plasma

		if(plat_count)
			points += plat_count * points_per_platinum

	//Buyin
	proc/buy()
		if(!shoppinglist.len) return

		var/area/area_shuttle = shuttle.get_location_area()
		if(!area_shuttle)	return

		var/list/clear_turfs = list()

		for(var/turf/T in area_shuttle)
			if(T.density)	continue
			var/contcount
			for(var/atom/A in T.contents)
				if(!A.simulated)
					continue
				contcount++
			if(contcount)
				continue
			clear_turfs += T

		for(var/S in shoppinglist)
			if(!clear_turfs.len)	break
			var/i = rand(1,clear_turfs.len)
			var/turf/pickedloc = clear_turfs[i]
			clear_turfs.Cut(i,i+1)

			var/datum/supply_order/SO = S
			var/datum/supply_packs/SP = SO.object

			var/obj/A = new SP.containertype(pickedloc)
			A.name = "[SP.containername][SO.comment ? " ([SO.comment])":"" ]"

			//supply manifest generation begin

			var/obj/item/weapon/paper/manifest/slip
			if(!SP.contraband)
				slip = new /obj/item/weapon/paper/manifest(A)
				slip.is_copy = 0
				slip.info = "<h3>[command_name()] Shipping Manifest</h3><hr><br>"
				slip.info +="Order #[SO.ordernum]<br>"
				slip.info +="Destination: [station_name]<br>"
				slip.info +="[shoppinglist.len] PACKAGES IN THIS SHIPMENT<br>"
				slip.info +="CONTENTS:<br><ul>"

			//spawn the stuff, finish generating the manifest while you're at it
			if(SP.access)
				if(isnum(SP.access))
					A.req_access = list(SP.access)
				else if(islist(SP.access))
					var/list/L = SP.access // access var is a plain var, we need a list
					A.req_access = L.Copy()
				else
					world << SPAN_DANGER("Supply pack with invalid access restriction [SP.access] encountered!")

			var/list/contains
			if(istype(SP,/datum/supply_packs/randomised))
				var/datum/supply_packs/randomised/SPR = SP
				contains = list()
				if(SPR.contains.len)
					for(var/j=1,j<=SPR.num_contained,j++)
						contains += pick(SPR.contains)
			else
				contains = SP.contains

			for(var/typepath in contains)
				if(!typepath)	continue
				var/atom/B2 = new typepath(A)
				if(SP.amount && B2:amount) B2:amount = SP.amount
				if(slip) slip.info += "<li>[B2.name]</li>" //add the item to the manifest

			//manifest finalisation
			if(slip)
				slip.info += "</ul><br>"
				slip.info += "CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"

		shoppinglist.Cut()
		return
*/
