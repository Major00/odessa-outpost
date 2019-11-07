/obj/machinery/kitchen/cooker
	var/temperature = T20C
	var/min_temp = 80 + T0C	//Minimum temperature to do any cooking
	var/optimal_temp = 200 + T0C	//Temperature at which we have 100% efficiency. efficiency is lowered on either side of this
	var/optimal_power = 0.1//cooking power at 100%

	var/loss = 1	//Temp lost per proc when equalising
	var/resistance = 320000	//Resistance to heating. combines with active power usage to determine how long heating takes

	var/light_x = 0
	var/light_y = 0
	var/cooking_power = 0
	var/max_contents = 2
	var/container_type = 0
/obj/machinery/kitchen/cooker/examine(var/mob/user)
	. = ..()
	if (.)	//no need to duplicate adjacency check
		if (!stat)
			if (temperature < min_temp)
				to_chat(user, span("warning", "\The [src] is still heating up and is too cold to cook anything yet."))
			else
				to_chat(user, span("notice", "It is running at [round(get_efficiency(), 0.1)]% efficiency!"))
			to_chat(user, "Temperature: [round(temperature - T0C, 0.1)]C / [round(optimal_temp - T0C, 0.1)]C")
		else
			to_chat(user, span("warning", "It is switched off."))

/obj/machinery/kitchen/cooker/proc/get_efficiency()
	//RefreshParts()
	return (cooking_power / optimal_power) * 100

/obj/machinery/kitchen/cooker/New()
	. = ..()
	loss = (active_power_usage / resistance)*0.5
	var/list/cooking_objs = list()
	for (var/i = 0, i < max_contents, i++)
		cooking_objs.Add(new container_type(src))

	update_icon() // this probably won't cause issues, but Aurora used SSIcons and queue_icon_update() instead

/obj/machinery/kitchen/cooker/update_icon()
	cut_overlays()
	var/image/light
	if (use_power == 2 && !stat)
		light = image(icon, "light_on")
	else
		light = image(icon, "light_off")
	light.pixel_x = light_x
	light.pixel_y = light_y
	add_overlay(light)

/obj/machinery/kitchen/cooker/proc/process()
	if (!stat)
		heat_up()
	else
		var/turf/T = get_turf(src)
		if (temperature > T.temperature)
			equalize_temperature()
	..()

/obj/machinery/kitchen/cooker/power_change()
	. = ..()
	update_icon() // this probably won't cause issues, but Aurora used SSIcons and queue_icon_update() instead

/obj/machinery/kitchen/cooker/proc/update_cooking_power()
	var/temp_scale = 0
	if(temperature > min_temp)

		temp_scale = (temperature - min_temp) / (optimal_temp - min_temp)
		//If we're between min and optimal this will yield a value in the range 0-1

		if (temp_scale > 1)
			//We're above optimal, efficiency goes down as we pass too much over it
			if (temp_scale >= 2)
				temp_scale = 0
			else
				temp_scale = 1 - (temp_scale - 1)


	cooking_power = optimal_power * temp_scale
	//RefreshParts()

/obj/machinery/kitchen/cooker/proc/heat_up()
	if (temperature < optimal_temp)
		if (use_power == 1 && ((optimal_temp - temperature) > 5))
			playsound(src, 'sound/machines/click.ogg', 20, 1)
			use_power = 2.//If we're heating we use the active power
			update_icon()
		temperature += active_power_usage / resistance
		update_cooking_power()
		return 1
	else
		if (use_power == 2)
			use_power = 1
			playsound(src, 'sound/machines/click.ogg', 20, 1)
			update_icon()
		//We're holding steady. temperature falls more slowly
		if (prob(25))
			equalize_temperature()
			return -1

/obj/machinery/kitchen/cooker/proc/equalize_temperature()
	temperature -= loss//Temperature will fall somewhat slowly
	update_cooking_power()
