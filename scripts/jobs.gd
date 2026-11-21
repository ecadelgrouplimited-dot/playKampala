extends Node3D
## Boda delivery & passenger jobs: Normal, Urgent Express (2x Pay), Fragile Cargo
## (Smooth Rider Bonus), and VIP Landmark Charters.
## Pickups and drop-offs are real named places in the generated city.
## Deliver quickly for a tip and build your Fast Streak multiplier!

const ITEMS := [
	"a passenger", "a passenger", "a passenger", "a passenger",
	"a hot rolex", "a bunch of matooke", "a hardware parcel", "airtime & MoMo float",
	"a 6kg gas cylinder", "school textbooks", "a crate of soda", "a jerrycan of water",
	"two trays of eggs", "a sack of charcoal", "fresh luwombo",
]
const URGENT_ITEMS := [
	"a passenger rushing to an interview",
	"an urgent clinic blood sample",
	"an express passport & visa envelope",
	"piping-hot wedding luwombo",
	"urgent Kikuubo shop spare parts",
]
const FRAGILE_ITEMS := [
	"three trays of fresh eggs",
	"a 3-tier wedding cake",
	"a 55-inch Kibanda flat-screen TV",
	"glass pharmacy medicine bottles",
]
const CUSTOMERS := [
	"Nakato", "Okello", "Auma", "Ssemakula", "Namubiru", "Kato", "Achieng",
	"Mugisha", "Nabirye", "Opio", "Wasswa", "Babirye", "Tumusiime", "Lubega",
]
const PASSENGER_CHAT := [
	"\"Boss, weave through the edge — this Kampala jam is serious today!\"",
	"\"Eh, I love this radio station! Turn it up a bit, boda!\"",
	"\"Watch out for the Traffic Police ahead, hope you have your helmet!\"",
	"\"Webale nnyo, your Boxer rides much smoother than the last boda!\"",
	"\"Drop me right at the front entrance, I'll send your tip on MoMo!\"",
]

var main: Node
var state := 0          # -1 = paused/offline, 0 = go to pickup, 1 = deliver
var from_i := 0
var to_i := 1
var item := ""
var customer := ""
var job_kind := "normal"   # normal | urgent | fragile | vip_tour | foot_errand
var cargo_health := 100
var fare := 0
var streak := 0
var dispatch_online := true
var pause_reason := ""
var skipped_count := 0
var _wait := 0.0
var _t := 0.0
var _job_time := 0.0
var _par_time := 0.0
var _chatter_t := 9.0

var marker: Node3D
var ring_mat: StandardMaterial3D
var beam_mat: StandardMaterial3D
var arrow: MeshInstance3D
var show_pointer := false    # Off by default so players navigate with the Minimap/Map; toggleable via Guide button


func _ready() -> void:
	marker = Node3D.new()
	add_child(marker)
	ring_mat = _glow(Color(0.15, 0.95, 0.45, 0.92))
	beam_mat = _glow(Color(0.15, 0.95, 0.45, 0.25))
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 2.0
	rm.bottom_radius = 2.0
	rm.height = 0.08
	rm.radial_segments = 24
	rm.material = ring_mat
	ring.mesh = rm
	ring.position.y = 0.25
	marker.add_child(ring)
	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.45
	bm.bottom_radius = 1.0
	bm.height = 16.0
	bm.radial_segments = 12
	bm.material = beam_mat
	beam.mesh = bm
	beam.position.y = 8.0
	marker.add_child(beam)

	arrow = MeshInstance3D.new()
	var am := PrismMesh.new()
	am.size = Vector3(0.65, 0.95, 0.08)
	am.material = ring_mat
	arrow.mesh = am
	arrow.visible = false
	add_child(arrow)
	new_job()


func _glow(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func is_passenger() -> bool:
	return item.begins_with("a passenger") or job_kind == "vip_tour"


func _place(i: int) -> Dictionary:
	return main.places[i]


func on_cargo_bump() -> void:
	if state == 1 and job_kind == "fragile" and cargo_health > 0:
		cargo_health = maxi(0, cargo_health - 35)
		if cargo_health > 0:
			main.hud.toast("Careful! Fragile cargo bumped — Integrity now %d%%!" % cargo_health)
		else:
			cancel("CRASH! You smashed the fragile %s! Customer refused delivery." % item)


func _is_boda_ready() -> bool:
	return main != null and main.player != null and not main.player.is_broken() and main.player.fuel > 0.0


func pause_dispatch(reason := "") -> void:
	if main and main.player:
		main.player.show_passenger(false)
		main.player.show_cargo(false)
	state = -1
	_wait = 0.0
	pause_reason = reason if reason != "" else "⏸️ Dispatch paused — enjoy free roam or take a break."
	if marker:
		marker.visible = false
	if arrow:
		arrow.visible = false
	_update_job_text()
	if reason != "" and main and main.hud:
		main.hud.toast(reason)


func toggle_dispatch() -> void:
	if dispatch_online:
		dispatch_online = false
		pause_dispatch("⏸️ Dispatch paused — tap ▶ Go Online when ready for calls.")
	else:
		dispatch_online = true
		resume_dispatch(false)


func resume_dispatch(allow_foot_errand := false) -> void:
	dispatch_online = true
	if not _is_boda_ready():
		if allow_foot_errand:
			new_job("foot_errand")
			return
		var issue := "needs repair" if main.player.is_broken() else "is out of fuel"
		pause_dispatch("Boda %s! Tap '🚶 Foot Errand' or fix/refuel first." % issue)
		return
	pause_reason = ""
	new_job()


func reject_job() -> void:
	if state != 0:
		return
	skipped_count += 1
	main.sfx.play("pop")
	if not _is_boda_ready():
		var issue := "repair" if main.player.is_broken() else "fuel"
		pause_dispatch("Skipped %s's call — boda needs %s. Tap '🚶 Foot Errand' or fix/refuel." % [customer, issue])
		return
	main.hud.toast("Skipped %s's call — finding a better Kampala task..." % customer)
	state = -1
	pause_reason = "📡 Scanning Kampala stages for a better task..."
	_update_job_text()
	_wait = 1.35


func new_job(forced_kind := "") -> void:
	if forced_kind != "foot_errand":
		if not dispatch_online:
			pause_dispatch("⏸️ Dispatch paused — tap ▶ Go Online when ready.")
			return
		if main.player.is_broken():
			pause_dispatch("🔧 Boda broken down! Repair at Boda Fundi or Phone → Garage, or take a 🚶 Foot Errand.")
			return
		if main.player.fuel <= 0.0:
			pause_dispatch("⛽ Out of fuel! Push boda to a Petrol Station (tap Map) or take a 🚶 Foot Errand.")
			return

	pause_reason = ""
	var places: Array = main.places
	var here: Vector3 = main.player.position
	var low_fuel: bool = main.player.fuel_fraction() <= 0.25
	var is_foot := (forced_kind == "foot_errand")
	var min_pick := 16.0 if is_foot else 28.0
	var max_pick := 75.0 if is_foot else (95.0 if low_fuel else 220.0)
	var min_drop := 32.0 if is_foot else (45.0 if low_fuel else 95.0)
	var max_drop := 95.0 if is_foot else (145.0 if low_fuel else 380.0)

	var near := []
	for i in places.size():
		var d: float = (places[i]["pos"] as Vector3).distance_to(here)
		if d > min_pick and d < max_pick:
			near.append(i)
	if near.is_empty():
		for i in places.size():
			var d_fb: float = (places[i]["pos"] as Vector3).distance_to(here)
			if d_fb > 14.0 and d_fb < max_pick * 1.65:
				near.append(i)
	from_i = near[randi() % near.size()] if not near.is_empty() else randi() % places.size()

	var far := []
	var pick_pos: Vector3 = places[from_i]["pos"]
	for i in places.size():
		var d2: float = (places[i]["pos"] as Vector3).distance_to(pick_pos)
		if d2 > min_drop and d2 < max_drop:
			far.append(i)
	if far.is_empty():
		for i in places.size():
			var d2_fb: float = (places[i]["pos"] as Vector3).distance_to(pick_pos)
			if d2_fb > 25.0 and i != from_i:
				far.append(i)
	to_i = far[randi() % far.size()] if not far.is_empty() else (from_i + 7) % places.size()

	# Roll for exciting mission variety (after tutorial step 2)
	var roll := randf()
	if forced_kind != "":
		job_kind = forced_kind
	elif main.day == 1 and main.tutorial_step < 3:
		job_kind = "normal"
	elif roll < 0.22:
		job_kind = "urgent"
	elif roll < 0.40:
		job_kind = "fragile"
	elif roll < 0.54:
		job_kind = "vip_tour"
	elif not low_fuel and roll < 0.70:
		job_kind = "suburb_express"
	else:
		job_kind = "normal"

	cargo_health = 100
	customer = CUSTOMERS[randi() % CUSTOMERS.size()]
	match job_kind:
		"urgent":
			item = URGENT_ITEMS[randi() % URGENT_ITEMS.size()]
		"fragile":
			item = FRAGILE_ITEMS[randi() % FRAGILE_ITEMS.size()]
		"foot_errand":
			const FOOT_ITEMS := [
				"a hot rolex & chai",
				"an urgent MoMo receipt",
				"a spare spark plug",
				"a small parcel of matooke",
			]
			item = FOOT_ITEMS[randi() % FOOT_ITEMS.size()]
		"vip_tour":
			# Pick a famous Kampala landmark as destination if available
			for li in places.size():
				var nm: String = str(places[li]["name"])
				if nm in ["the Clock Tower", "Ggaba Beach & Pier", "Nakivubo Stadium", "Owino Market", "the Old Taxi Park"] and li != from_i:
					if (places[li]["pos"] as Vector3).distance_to(pick_pos) > 75.0:
						to_i = li
						break
			item = "a VIP Landmark Charter passenger"
		"suburb_express":
			var sub_opts := []
			for si in places.size():
				var dlow := str(places[si].get("district", "")).to_lower()
				if ("mukono" in dlow or "kawempe" in dlow or "nateete" in dlow or "kajjansi" in dlow) and si != from_i:
					sub_opts.append(si)
			if not sub_opts.is_empty():
				to_i = sub_opts[randi() % sub_opts.size()]
			var sub_items := ["a Highway Express passenger", "bags of construction cement", "a fresh matooke order", "upcountry stage luggage"]
			item = sub_items[randi() % sub_items.size()]
		_:
			item = ITEMS[randi() % ITEMS.size()]

	var a: Vector3 = places[from_i]["pos"]
	var b: Vector3 = places[to_i]["pos"]
	var road_dist := absf(a.x - b.x) + absf(a.z - b.z)
	fare = int(snappedf(maxf(2500.0, 1500.0 + road_dist * 26.0), 500.0))
	if job_kind == "urgent":
		fare = int(snappedf(fare * 1.85, 500.0))
	elif job_kind == "fragile":
		fare = int(snappedf(fare * 1.60, 500.0))
	elif job_kind == "vip_tour":
		fare = int(snappedf(fare * 1.75 + 2000.0, 500.0))
	elif job_kind == "suburb_express":
		fare = int(snappedf(fare * 1.70 + 3500.0, 500.0))
	elif job_kind == "foot_errand":
		fare = int(snappedf(maxf(2000.0, 1200.0 + road_dist * 22.0), 500.0))

	var rush: bool = main.is_rush_hour()
	if rush:
		fare = int(snappedf(fare * 1.25, 500.0))
	if main.raining:
		fare = int(snappedf(fare * 1.5, 500.0))
	if main.rating >= 4.6:
		fare = int(snappedf(fare * 1.15, 500.0))
	if streak >= 3:
		fare = int(snappedf(fare * 1.25, 500.0))
	var dist_mult: float = main.district_bonus_mult(str(places[to_i]["district"]))
	if dist_mult > 1.0:
		fare = int(snappedf(fare * dist_mult, 500.0))
	var is_reg: bool = int(main.regulars.get(customer, 0)) >= 2
	if is_reg:
		fare += 2000

	if job_kind == "foot_errand":
		_par_time = road_dist / 4.2 + 35.0
	else:
		_par_time = (road_dist / 12.0 + 19.0) if job_kind == "urgent" else (road_dist / 10.5 + 27.0)
	_job_time = 0.0
	_chatter_t = randf_range(7.0, 12.0)
	state = 0
	_set_colour(Color(0.25, 0.9, 1.0) if job_kind == "foot_errand" else Color(0.15, 0.95, 0.45))

	var prefix := ""
	match job_kind:
		"urgent": prefix = "🔥 [URGENT EXPRESS 1.85x!] "
		"fragile": prefix = "🥚 [FRAGILE CARGO +60%!] "
		"vip_tour": prefix = "🌟 [VIP CHARTER!] "
		"suburb_express": prefix = "🛣️ [HIGHWAY / SUBURB EXPRESS +70%!] "
		"foot_errand": prefix = "🚶 [ON-FOOT ERRAND] "
		_: prefix = "New stage call: "
	var what := "%s wants a boda ride" % customer if is_passenger() else "%s needs %s delivered" % [customer, item]
	var surge_note := ("  (Rain 1.5x!)" if main.raining else "") + ("  (Rush +25%!)" if rush else "") + ("  (★ Regular +2k!)" if is_reg else "") + ("  (⛽ Short low-fuel route)" if (low_fuel and job_kind != "foot_errand") else "")
	_update_job_text()
	main.hud.toast("%s%s from %s (%s).\nFare UGX %s%s" % [prefix, what, places[from_i]["name"], places[from_i]["district"], main.ugx(fare), surge_note])


func _update_job_text() -> void:
	if not main or not main.player or not main.hud:
		return
	if state == -1:
		main.hud.job_text = pause_reason if pause_reason != "" else "⏸️ Dispatch paused — enjoy free roam"
		return
	var p: Node3D = main.player
	var tgt := target()
	var dist := Vector3(tgt.x - p.position.x, 0, tgt.z - p.position.z).length()
	var badge := ""
	match job_kind:
		"urgent": badge = "🔥 [URGENT] "
		"fragile": badge = "🥚 [FRAGILE %d%%] " % cargo_health
		"vip_tour": badge = "🌟 [VIP CHARTER] "
		"foot_errand": badge = "🚶 [FOOT ERRAND] "
	var reg_tag: String = " [★ Regular]" if int(main.regulars.get(customer, 0)) >= 2 else ""
	var who := ("%s%s (passenger)" % [customer, reg_tag]) if is_passenger() else ("%s for %s%s" % [item, customer, reg_tag])
	var streak_badge := ("  •  🔥 FEVER x%d (+25%%)" % streak) if streak >= 3 else (("  •  🔥 Streak x%d" % streak) if streak >= 2 else "")
	if state == 0:
		main.hud.job_text = "%sPICKUP: %s at %s  •  %d m  (UGX %s)%s" % [badge, who, target_name(), int(dist), main.ugx(fare), streak_badge]
	else:
		var left := int(maxf(0.0, _par_time - _job_time))
		main.hud.job_text = "%sDROP-OFF: %s → %s  •  %d m   UGX %s%s%s" % [
			badge, who, target_name(), int(dist), main.ugx(fare),
			("   (Bonus: %ds)" % left) if left > 0 else "", streak_badge]


func cancel(msg: String) -> void:
	main.hud.toast(msg)
	main.player.show_passenger(false)
	main.player.show_cargo(false)
	streak = 0
	main.hud.job_text = ""
	_wait = 3.0


func _set_colour(c: Color) -> void:
	ring_mat.albedo_color = Color(c, 0.92)
	beam_mat.albedo_color = Color(c, 0.26)


func target() -> Vector3:
	return _place(from_i)["pos"] if state == 0 else _place(to_i)["pos"]


func target_name() -> String:
	var pl := _place(from_i) if state == 0 else _place(to_i)
	return "%s (%s)" % [pl["name"], pl["district"]]


func _process(delta: float) -> void:
	_t += delta
	var p: Node3D = main.player
	if main.paused:
		return
	if _wait > 0.0:
		_wait -= delta
		marker.visible = false
		arrow.visible = false
		if _wait <= 0.0:
			new_job()
		return
	if state == -1:
		marker.visible = false
		arrow.visible = false
		_update_job_text()
		return
	marker.visible = true
	_job_time += delta

	# Live passenger chatter while riding
	if state == 1 and is_passenger() and p.on_boda and p.speed > 3.5:
		_chatter_t -= delta
		if _chatter_t <= 0.0:
			_chatter_t = randf_range(14.0, 22.0)
			if main.hud._toast_time <= 0.2:
				main.hud.toast("%s: %s" % [customer, PASSENGER_CHAT[randi() % PASSENGER_CHAT.size()]])

	var tgt := target()
	marker.position = tgt
	marker.scale = Vector3.ONE * (1.0 + sin(_t * 4.5) * 0.07)

	var d := Vector3(tgt.x - p.position.x, 0, tgt.z - p.position.z)
	var dist := d.length()
	if show_pointer and dist > 5.0:
		var dir_norm := d / dist
		arrow.position = p.position + dir_norm * 2.5 + Vector3(0, 0.16, 0)
		arrow.basis = Basis(Vector3.UP, atan2(-d.x, -d.z)) * Basis(Vector3.RIGHT, -PI / 2)
		arrow.visible = true
	else:
		arrow.visible = false

	_update_job_text()

	if dist < 2.8:
		if state == 0:
			if is_passenger() and not p.on_boda:
				if p.is_broken() or p.fuel <= 0.0:
					main.hud.job_text = "%s can't ride — boda needs %s! Tap '✕ Skip' or repair/refuel." % [customer, "repair" if p.is_broken() else "fuel"]
				else:
					main.hud.job_text = "%s is waiting — hop on your boda to pick them up!" % customer
				return
			state = 1
			if main.tutorial_step == 1:
				main.tutorial_step = 2
			var drop_col := Color(1.0, 0.25, 0.45) if job_kind == "urgent" else (Color(0.25, 0.85, 1.0) if job_kind == "vip_tour" else Color(1.0, 0.62, 0.12))
			_set_colour(drop_col)
			if is_passenger():
				p.show_passenger(true)
				main.hud.toast("%s hopped on the back! \"Boss, twende to %s!\"" % [customer, target_name()])
			else:
				p.show_cargo(true)
				main.hud.toast("Strapped %s onto the carrier.%s\nDeliver to %s." % [
					item, " Drive carefully (Fragile 100%)!" if job_kind == "fragile" else "", target_name()])
			main.sfx.play("pop")
		else:
			var tip := 0
			if _job_time < _par_time:
				streak += 1
				tip = (1500 if fare < 5000 else 2500) + min(streak - 1, 4) * 500
				if job_kind == "urgent":
					tip += 2500
				main.adjust_rating(0.06)
			else:
				streak = 0
				main.adjust_rating(0.02)
			if job_kind == "fragile" and cargo_health == 100:
				tip += 4000
			elif job_kind == "vip_tour":
				tip += 3000
			var prev_trips: int = int(main.regulars.get(customer, 0))
			main.regulars[customer] = prev_trips + 1
			if prev_trips + 1 == 2:
				main.add_sms(customer, "Webale nnyo! You delivered fast. I've saved your number as my regular boda rider!")
			var ticket_bonus := 0
			if main.vip_ticket:
				main.vip_ticket = false
				ticket_bonus = fare
			main.add_money(fare + tip + ticket_bonus, "Boda fare from %s" % customer)
			main.add_district_rep(str(_place(to_i)["district"]), 20)
			main.sfx.play("bonus" if (streak >= 2 or job_kind != "normal" or ticket_bonus > 0) else "chime")
			main.day_stats["fares"] += fare + ticket_bonus
			main.day_stats["tips"] += tip
			main.day_stats["jobs"] += 1
			if main.has_method("on_trip_completed"):
				main.on_trip_completed()
			if main.tutorial_step == 2:
				main.tutorial_step = 3
			p.show_passenger(false)
			p.show_cargo(false)
			var streak_txt := (" (%dx Fever Streak!)" % streak) if streak >= 3 else ((" (%dx Fast Streak!)" % streak) if streak > 1 else "")
			var kind_bonus := " (100% Intact Fragile Bonus!)" if (job_kind == "fragile" and cargo_health == 100) else (" (VIP Charter Bonus!)" if job_kind == "vip_tour" else "")
			var vip_txt := (" + 🎫 2x VIP Ticket!") if ticket_bonus > 0 else ""
			main.hud.toast("Mobile Money: Received UGX %s from %s.%s" % [
				main.ugx(fare + tip + ticket_bonus), customer.to_upper(),
				("\nIncludes UGX %s tip%s%s%s!" % [main.ugx(tip), streak_txt, kind_bonus, vip_txt]) if (tip > 0 or ticket_bonus > 0) else ""])
			main.hud.job_text = ""
			if main.has_method("on_job_completed"):
				main.on_job_completed(job_kind, fare + tip + ticket_bonus, streak)
			main.save_game()
			_wait = 2.0
