/obj/machinery/kitchen/cooker/oven

	name = "oven"
	desc = "It appears to be out of order."
	icon = 'icons/obj/appliances.dmi'
	icon_state = "oven"
	layer = BELOW_OBJ_LAYER
	var/cook_type = "baked"
	var/food_color = "#A34719"
	var/can_burn_food = 1
	active_power_usage = 6 KILOWATTS
	//Based on a double deck electric convection oven
	idle_power_usage = 2 KILOWATTS
	//uses ~30% power to stay warm
	optimal_power = 0.2

	light_x = 2
	max_contents = 2
	container_type = /obj/item/weapon/reagent_containers/baking_sheet

	stat = POWEROFF	//Starts turned off

	var/output_options = list(
	)

/obj/machinery/appliance/cooker/oven/AltClick(var/mob/user)
	try_toggle_door(user)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

/obj/machinery/appliance/cooker/oven/proc/try_toggle_door(mob/user)
	var/open = 1
	//oven door open = 1 closed = 0
	var/resistance = 16000
	var/loss = 2
	if (!isliving(usr) || isAI(user))
		return

	if (!usr.IsAdvancedToolUser())
		usr << "You lack the dexterity to do that."
		return

	if (!Adjacent(usr))
		usr << "You can't reach the [src] from there, get closer!"
		return

	if (open)
		open = 0
		loss = (active_power_usage / resistance)*0.5
	else
		open = 1
		loss = (active_power_usage / resistance)*4
		//When the oven door is opened, heat is lost MUCH faster

	update_icon()

