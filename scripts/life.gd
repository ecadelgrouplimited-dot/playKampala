extends Node
## KAMPALA LIFE
## Turns the city from "a place you deliver in" into a place you live in:
##  - Needs: Food, Energy, Mood drain through the day and change how you move
##  - Every place has a meaning (food, bar, church, market, salon, clinic, home...)
##    and offers real activities that cost money and take time
##  - "Where to?": pick any place by type, get a real street route (road graph)
##  - Ride as a passenger: call a boda, or board a matatu whose conductor is shouting
##  - Proactive suggestions from needs, time, weekday and what's nearby
##  - Citizens with daily routines: work, lunch, market, bar, home, Sunday church

const Person = preload("res://scripts/person.gd")

const CAT_NAMES := {
	"food": "Food & Street Vendors", "tv": "Roadside TVs & Kibanda", "market": "Market & groceries",
	"bar": "Bars & nightlife", "church": "Churches", "myhome": "Your room", "health": "Clinic & pharmacy",
	"salon": "Salons", "shop": "Shops & Fundis", "fuel": "Fuel", "taxi": "Taxi park",
	"stage": "Boda stage", "leisure": "Lake & leisure", "sport": "Sport", "home": "Homes",
	"momo": "Mobile Money", "other": "Places",
}
const PICKER_CATS := ["food", "tv", "market", "bar", "church", "myhome", "health", "salon", "shop", "fuel", "taxi", "leisure"]
const WEEKDAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
# Conductor / vendor bubble lines come from scripts/voice_bank.gd (tools/audio/voice_lines.csv)
const RIDERS := ["Kato", "Musa", "Ssali", "Brian", "Okello", "Juma", "Mugisha", "Isaac", "Ronnie", "Wasswa"]

var main: Node

# ---------------------------------------------------------------- needs & life state
var hunger := 70.0     # 100 = full
var energy := 85.0
var mood := 60.0
var groceries := 0
var slept_home := false
var home := {}         # {name, pos, district, cat}
var cat_of: Array = [] # category of each main.places entry

# ---------------------------------------------------------------- navigation
var dest := {}         # the place you're heading to
var route := PackedVector3Array()
var _route_t := 0.0
var _route_mesh: MeshInstance3D
var _imesh: ImmediateMesh

# ---------------------------------------------------------------- passenger rides
var ride: Node3D = null
var ride_state := 0    # 0 none, 1 driver coming, 2 waiting for you, 3 riding
var ride_kind := "boda"
var ride_fare := 0
var ride_dest := {}
var ride_pts := PackedVector3Array()
var ride_idx := 0
var ride_driver := ""
var _ride_hidden_car: Node3D = null
var _ride_stuck := 0.0

# ---------------------------------------------------------------- activities
var act := {}
var act_place := {}
var _act_t := 0.0
const ACT_SECONDS := 2.6

# ---------------------------------------------------------------- suggestions
var _suggest_cool := 25.0
var _suggest_kind := ""
var _suggest_place := {}
var _seen_today := {}
var _last_day := 1
var _last_time := 7.0

# ---------------------------------------------------------------- citizens
var citizens: Array = []
var _bubbles := {}
var _shout_t := 0.0

# ---------------------------------------------------------------- UI
var ui: CanvasLayer
var needs_lbl: Label
var needs_rows: VBoxContainer
var needs_min_btn: Button
var needs_min := false
var bars := {}
var go_btn: Button
var card: PanelContainer
var card_lbl: Label
var card_btns: HBoxContainer
var chips: PanelContainer
var chips_title: Label
var chips_box: VBoxContainer
var chips_min_btn: Button
var chips_min := false
var _last_chip_place := ""
var picker: PanelContainer
var picker_title: Label
var picker_list: VBoxContainer
var picker_cats: GridContainer
var _picker_mode := "go"   # go | boda | taxi
var _picker_cat := "food"
var overlay: PanelContainer
var overlay_lbl: Label
var overlay_fill: ColorRect
var _chips_key := ""


# =================================================================== setup
func _ready() -> void:
	_classify_places()
	_choose_home()
	_build_ui()
	_route_mesh = MeshInstance3D.new()
	_imesh = ImmediateMesh.new()
	_route_mesh.mesh = _imesh
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(0.2, 0.85, 1.0, 0.6)
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_route_mesh.material_override = rm
	_route_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main.add_child(_route_mesh)
	_spawn_citizens()
	_last_day = main.day
	_last_time = main.time_of_day
	load_life()


func weekday() -> String:
	return WEEKDAYS[(main.day - 1) % 7]


func is_sunday() -> bool:
	return (main.day - 1) % 7 == 6


func categorize(name: String) -> String:
	var n := name.to_lower()
	if n.ends_with("'s home"):
		return "home"
	if "tv" in n or "match screen" in n or "kibanda" in n:
		return "tv"
	if "church" in n or "cathedral" in n or "mosque" in n:
		return "church"
	if "bar & lodge" in n or "bar" in n.split(" ") or "pub" in n or "club" in n:
		return "bar"
	for k in ["restaurant", "chapati", "bakery", "juice", "rolex", "muchomo", "gonja", "fruit cart", "sugarcane", "cold soda", "kitchen", "cafe", "food"]:
		if k in n:
			return "food"
	for k in ["market", "supermarket", "general merchandise", "wholesalers", "agro"]:
		if k in n:
			return "market"
	if "clinic" in n or "pharmacy" in n or "hospital" in n:
		return "health"
	if "saloon" in n or "salon" in n:
		return "salon"
	if "fuel" in n:
		return "fuel"
	if "taxi park" in n:
		return "taxi"
	if "boda stage" in n:
		return "stage"
	if "mobile money" in n or "forex" in n:
		return "momo"
	if "beach" in n or "pier" in n or "clock tower" in n:
		return "leisure"
	if "stadium" in n or "pitch" in n:
		return "sport"
	for k in ["boutique", "fashions", "shoe", "tailoring", "cosmetics", "electronics", "phone repair", "mattress", "furniture", "hardware", "stationery", "printing", "video", "spare parts", "butchery", "mechanic", "tyre fundi"]:
		if k in n:
			return "shop"
	return "other"


func _classify_places() -> void:
	cat_of.clear()
	for p in main.places:
		cat_of.append(categorize(str(p["name"])))


func _choose_home() -> void:
	# your rented room: a muzigo home 70-200 m from where you start
	var best := -1
	var best_d := 1e9
	for i in main.places.size():
		if cat_of[i] != "home":
			continue
		var d: float = (main.places[i]["pos"] as Vector3).distance_to(main.SPAWN)
		if d > 70.0 and d < best_d:
			best_d = d
			best = i
	if best == -1:
		home = {"name": "Your room", "pos": main.SPAWN + Vector3(10, 0, 10), "district": "Kampala", "cat": "myhome"}
	else:
		var p: Dictionary = main.places[best]
		home = {"name": "Your room (muzigo)", "pos": p["pos"], "district": p["district"], "cat": "myhome"}


func place_dict(i: int) -> Dictionary:
	var p: Dictionary = main.places[i]
	return {"name": p["name"], "pos": p["pos"], "district": p["district"], "cat": cat_of[i]}


## Nearest places of a category, closest first.
func nearest(cat: String, from: Vector3, count := 6) -> Array:
	if cat == "myhome":
		return [home]
	var found := []
	for i in main.places.size():
		if cat_of[i] == cat:
			var d: float = (main.places[i]["pos"] as Vector3).distance_to(from)
			found.append([d, i])
	found.sort_custom(func(x, y): return x[0] < y[0])
	var out := []
	for k in mini(count, found.size()):
		out.append(place_dict(found[k][1]))
	return out


# =================================================================== the loop
func _process(delta: float) -> void:
	if not main.built:
		return
	var p: Node3D = main.player
	# --- needs drain with game time
	var t: float = main.time_of_day
	var dh := t - _last_time
	if dh < 0.0 or dh > 3.0:
		dh = 0.0
	_last_time = t
	if dh > 0.0 and act.is_empty():
		var riding: bool = p.on_boda or ride_state == 3
		hunger = clampf(hunger - dh * (8.0 if riding else 6.5), 0.0, 100.0)
		energy = clampf(energy - dh * (6.5 if riding else 4.5), 0.0, 100.0)
		mood = clampf(mood - dh * (3.0 if main.raining else 1.6), 0.0, 100.0)
	# --- a new day began (the game's own end-of-day summary handled the money)
	if main.day != _last_day:
		_last_day = main.day
		_new_day()

	if not act.is_empty():
		_run_activity(delta)
	_update_ride(delta)
	_update_route(delta)
	_update_suggestions(delta)
	_update_chips()
	_update_citizens(delta)
	_update_shouts(delta)
	_update_needs_ui()


func _new_day() -> void:
	_seen_today.clear()
	if slept_home:
		energy = 100.0
		mood = clampf(mood + 10.0, 0.0, 100.0)
		main.hud.toast("Good morning! You slept well in your room. %s, Day %d." % [weekday(), main.day])
	else:
		energy = maxf(energy, 55.0)
		mood = clampf(mood - 12.0, 0.0, 100.0)
		main.hud.toast("You dozed at the stage instead of going home. Tired and stiff... %s, Day %d." % [weekday(), main.day])
	hunger = clampf(hunger - 15.0, 0.0, 100.0)
	slept_home = false
	_reset_citizens_morning()
	save_life()


## Hungry, tired or miserable people are slower (used by player.gd).
func speed_mult() -> float:
	var m := 1.0
	if hunger < 15.0:
		m *= 0.82
	if energy < 15.0:
		m *= 0.78
	elif energy < 30.0:
		m *= 0.92
	if mood > 80.0:
		m *= 1.05
	return m


func modal_open() -> bool:
	return picker.visible or overlay.visible


# =================================================================== activities
func meal_word() -> String:
	var h: float = main.time_of_day
	if h < 11.0:
		return "breakfast"
	if h < 16.0:
		return "lunch"
	return "supper"


## What you can do at a place. Each: label, cost (UGX), hours, effects, text.
func activities_for(pl: Dictionary) -> Array:
	var h: float = main.time_of_day
	var c: String = pl["cat"]
	var n: String = pl["name"]
	var out := []
	match c:
		"food":
			var nl := n.to_lower()
			var meal := meal_word()
			if "muchomo" in nl or "gonja" in nl:
				out.append({"label": "Eat sizzling beef Muchomo & roasted Gonja", "cost": 3500, "hours": 0.4, "hunger": 52, "mood": 16,
					"text": "Fresh off the charcoal sigiri: smoky beef skewers, sweet golden gonja and spicy kachumbari salad!"})
				out.append({"label": "Roasted maize cob & goat skewer", "cost": 2000, "hours": 0.25, "hunger": 30, "mood": 10,
					"text": "Hot roasted maize rubbed with lemon and chili beside the glowing charcoal embers."})
			elif "fruit" in nl or "sugarcane" in nl:
				out.append({"label": "Cold sugarcane & ginger juice (ekikuba)", "cost": 1500, "hours": 0.2, "hunger": 20, "energy": 20, "mood": 10,
					"text": "Freshly crushed sugarcane juice with a kick of ginger and lime. Instant Kampala energy!"})
				out.append({"label": "Tropical fruit plate (watermelon, pineapple & mango)", "cost": 2500, "hours": 0.3, "hunger": 38, "energy": 14, "mood": 12,
					"text": "Sweet, juicy slices of Ugandan pineapple, red watermelon and mango from the pushcart."})
			elif "newspaper" in nl or "soda" in nl:
				out.append({"label": "Ice-cold soda & read Bukedde / New Vision headlines", "cost": 2000, "hours": 0.3, "hunger": 15, "energy": 12, "mood": 15,
					"text": "You pop open a cold glass bottle of soda and debate today's front-page Kampala stories with passers-by."})
			else:
				out.append({"label": "Eat %s: matooke, beans & g-nuts" % meal, "cost": 6000, "hours": 0.75, "hunger": 60, "mood": 6,
					"text": "You sit down at %s. A steaming plate of matooke, beans and groundnut sauce. 'Webale nnyo!'" % n})
				out.append({"label": "Quick rolex & African tea", "cost": 2500, "hours": 0.35, "hunger": 35, "energy": 4,
					"text": "Chapati rolled with two eggs and tomatoes, and sweet spiced tea. Fast and filling."})
				if h >= 17.0:
					out.append({"label": "Pork joint supper with friends", "cost": 9000, "hours": 1.2, "hunger": 70, "mood": 18,
						"text": "Roasted pork, cassava and kachumbari with friends. Stories and laughter till late."})
		"tv":
			out.append({"label": "Watch live football match on the Roadside TV", "cost": 1000, "hours": 0.75, "mood": 28, "energy": -2,
				"text": "You grab a spot on the wooden bench at %s. The screen glows brightly and the whole street roars when the goal goes in!" % n})
			out.append({"label": "Watch VJ Jingo Luganda-translated action movie", "cost": 1000, "hours": 0.85, "mood": 25, "energy": 4,
				"text": "Non-stop action with hilarious Luganda commentary from VJ Jingo: 'Commando tafa!!' Everyone is laughing."})
			out.append({"label": "Friendly UGX 2,000 goal prediction with fans", "cost": 2000, "hours": 0.5, "mood": 22, "special": "tv_bet",
				"text": "You back the next goalscorer with the roadside TV crowd and lean forward as the striker breaks through..."})
		"bar":
			out.append({"label": "Have a cold drink", "cost": 3500, "hours": 1.0, "mood": 18, "energy": -4,
				"text": "A cold soda (or two) at %s, loud music and catching up with the stage guys." % n})
			if h >= 18.0:
				out.append({"label": "Watch the big match", "cost": 2000, "hours": 1.5, "mood": 30, "energy": -6,
					"text": "The whole bar erupts when the goal goes in. Someone buys you a round!"})
			if h >= 20.0 or (weekday() in ["Friday", "Saturday"] and h >= 19.0):
				out.append({"label": "Dance - it's karaoke night!", "cost": 0, "hours": 1.5, "mood": 38, "energy": -18,
					"text": "Kadongo kamu, Afrobeats and a terrible karaoke version of a classic. You dance till you sweat."})
		"church":
			if is_sunday() and h >= 7.5 and h < 13.0:
				out.append({"label": "Attend Sunday service", "cost": 1000, "hours": 2.0, "mood": 40, "energy": 6, "special": "service",
					"text": "Hymns, a powerful sermon and the choir in full voice. You give UGX 1,000 offering. After service, a church member asks for your number for boda trips."})
			out.append({"label": "Sit quietly and pray", "cost": 0, "hours": 0.4, "mood": 14, "energy": 4,
				"text": "The church is cool and quiet. You pray for good customers and safe roads."})
			if weekday() == "Wednesday" and h >= 17.0:
				out.append({"label": "Join the evening fellowship", "cost": 0, "hours": 1.5, "mood": 26,
					"text": "Praise songs, testimonies and tea. You leave lighter."})
		"market":
			out.append({"label": "Buy groceries for the week", "cost": 8000, "hours": 0.6, "mood": 4, "groceries": 2,
				"text": "Tomatoes, onions, beans, rice and a tray of eggs. You bargain the price down. 'Mpa ku discount!'"})
			out.append({"label": "Buy a bunch of matooke", "cost": 6000, "hours": 0.3, "groceries": 1,
				"text": "A big green bunch of matooke. Heavy, but it'll feed you for days."})
			out.append({"label": "Buy roasted groundnuts & gonja", "cost": 2000, "hours": 0.15, "hunger": 22, "mood": 6,
				"text": "Hot salted groundnuts and sweet roasted plantain straight from the market basket."})
			out.append({"label": "Help unload a produce sack (+UGX 3,500)", "cost": 0, "hours": 0.4, "energy": -14, "mood": 4, "special": "market_earn",
				"text": "You help a market mama carry heavy matooke & tomato crates to her stall. She sends UGX 3,500 on MoMo!"})
			out.append({"label": "Stroll and window-shop", "cost": 0, "hours": 0.5, "mood": 6, "energy": -3,
				"text": "Second-hand shoes, bright kitenge, radios blaring. Kampala in full colour."})
		"myhome":
			out.append({"label": "Sleep until morning", "cost": 0, "hours": 0.0, "special": "sleep",
				"text": "You lock the door, set the alarm and fall asleep to the sound of the city."})
			out.append({"label": "Nap for an hour", "cost": 0, "hours": 1.0, "energy": 22, "mood": 4,
				"text": "A quick nap on the mattress, with the radio low."})
			if groceries > 0:
				out.append({"label": "Cook supper (uses groceries)", "cost": 0, "hours": 1.0, "hunger": 65, "mood": 10, "groceries": -1,
					"text": "Charcoal stove outside the door. Beans and rice, the neighbours' kids hovering hopefully."})
			out.append({"label": "Bathe & change clothes", "cost": 0, "hours": 0.4, "mood": 10, "energy": 6,
				"text": "A basin of water, a fresh shirt. A new person."})
		"health":
			out.append({"label": "Get a check-up", "cost": 10000, "hours": 1.0, "energy": 30, "mood": 6,
				"text": "The nurse checks your blood pressure: 'Rest more and drink water.' You feel better."})
			out.append({"label": "Buy painkillers & ORS", "cost": 3000, "hours": 0.2, "energy": 12,
				"text": "Panadol and oral rehydration salts for the long day ahead."})
		"salon":
			out.append({"label": "Get a fresh haircut", "cost": 5000, "hours": 0.8, "mood": 22,
				"text": "Clippers buzzing, a radio talk show and the latest gossip. You look sharp."})
		"shop":
			out.append_array(_shop_items(n.to_lower(), n))
			out.append({"label": "Browse and chat", "cost": 0, "hours": 0.25, "mood": 3,
				"text": "You look around, chat with the shopkeeper and promise to come back."})
		"leisure":
			out.append({"label": "Swim in Lake Victoria (Free)", "cost": 0, "hours": 0.6, "mood": 26, "energy": -6, "special": "swim",
				"text": "You wade off Ggaba Beach into cool Lake Victoria and swim along the shoreline. Walk into the water anytime on foot too!"})
			out.append({"label": "Relax by the lake", "cost": 0, "hours": 1.0, "mood": 22, "energy": 10,
				"text": "The breeze off Lake Victoria, fishing canoes coming in. Peace."})
			out.append({"label": "Fried tilapia & chips", "cost": 12000, "hours": 1.0, "hunger": 75, "mood": 15,
				"text": "Whole fried tilapia with chips and kachumbari, right by the water."})
		"sport":
			if h >= 14.0 and h < 19.0:
				out.append({"label": "Watch a local match", "cost": 5000, "hours": 2.0, "mood": 32, "energy": -5,
					"text": "Drums, vuvuzelas and a late winner. The crowd spills onto the street singing."})
		"taxi":
			out.append({"label": "Board a matatu (choose where)", "cost": 0, "hours": 0.0, "special": "taxi"})
		"stage":
			out.append({"label": "Hire a boda (choose where)", "cost": 0, "hours": 0.0, "special": "boda"})
		"home":
			if h >= 10.0 and h < 20.0:
				out.append({"label": "Greet the neighbours", "cost": 0, "hours": 0.5, "mood": 10,
					"text": "'Oli otya?' 'Bulungi!' Tea, news and a promise to visit again."})
	return out


## What each kind of shop actually sells you.
func _shop_items(n: String, name: String) -> Array:
	if "juice" in n:
		return [
			{"label": "Fresh mango-passion smoothie", "cost": 3000, "hours": 0.2, "hunger": 22, "energy": 18, "mood": 14,
				"text": "Blended fresh at %s with thick yellow mango, passionfruit and ice!" % name},
			{"label": "Cold sugarcane & ginger juice", "cost": 1500, "hours": 0.15, "hunger": 14, "energy": 15, "mood": 10,
				"text": "Crisp ekikuba sugarcane juice poured straight from the chilled dispenser."}
		]
	if "boutique" in n or "fashion" in n or "tailor" in n:
		return [
			{"label": "Buy a smart Kampala shirt", "cost": 15000, "hours": 0.5, "mood": 18,
				"text": "A sharp new shirt from %s. The stage guys will notice." % name},
			{"label": "Buy bright kitenge outfit", "cost": 25000, "hours": 0.6, "mood": 26,
				"text": "Tailored kitenge from %s — ready for Sunday service or evening outings!" % name}
		]
	if "shoe" in n:
		return [{"label": "Polish & repair your shoes", "cost": 2000, "hours": 0.3, "mood": 6,
			"text": "The cobbler stitches the sole and buffs them till they shine."}]
	if "cosmetic" in n:
		return [{"label": "Buy lotion & perfume", "cost": 6000, "hours": 0.3, "mood": 10,
			"text": "Shea butter lotion and a little perfume. You smell like money."}]
	if "phone repair" in n:
		return [{"label": "Fix your cracked phone screen", "cost": 20000, "hours": 1.0, "mood": 14,
			"text": "Twenty minutes, a heat gun and a new screen. Customers can reach you again!"}]
	if "electronic" in n:
		return [{"label": "Buy a power bank", "cost": 12000, "hours": 0.3, "mood": 8,
			"text": "A power bank, so your phone never dies when customers call."}]
	if "furniture" in n or "mattress" in n:
		return [{"label": "Buy a plastic chair for your room", "cost": 12000, "hours": 0.5, "mood": 10,
			"text": "A red plastic chair, tied to a boda and delivered to your room. Luxury."}]
	if "hardware" in n:
		return [{"label": "Buy a padlock for your room", "cost": 7000, "hours": 0.3, "mood": 5,
			"text": "A strong padlock. Your room - and your boda helmet - are safer now."}]
	if "stationery" in n or "printing" in n:
		return [{"label": "Print & photocopy your documents", "cost": 1000, "hours": 0.3, "mood": 3,
			"text": "Copies of your ID and permit, in case the traffic police ask."}]
	if "video" in n:
		return [{"label": "Rent a VJ-translated movie", "cost": 1000, "hours": 0.3, "mood": 14,
			"text": "An action movie with a Luganda VJ narrating over it. Tonight's entertainment!"}]
	if "butcher" in n:
		return [{"label": "Buy 1 kg of beef", "cost": 14000, "hours": 0.3, "groceries": 2, "mood": 6,
			"text": "Fresh beef wrapped in newspaper. Stew tonight!"}]
	if "spare" in n or "mechanic" in n or "tyre" in n or "fundi" in n or "garage" in n:
		return [
			{"label": "🔧 Repair & Service Boda (100%)", "cost": 4000, "hours": 0.35, "mood": 14, "special": "repair_boda",
				"text": "The mechanic repairs your engine, tightens the chain & restores your boda to 100% health!"},
			{"label": "Pump tyres, oil chain & tune boda", "cost": 2000, "hours": 0.35, "mood": 12, "energy": 5, "special": "tune_boda",
				"text": "The roadside fundi checks your tyre pressure, oils the chain and tightens the brakes. Smooth riding!"},
			{"label": "Buy a new boda side mirror", "cost": 6000, "hours": 0.4, "mood": 6,
				"text": "The fundi fits it on the spot. Safer riding in Kampala jam."},
		]
	return []


func start_activity(a: Dictionary, pl: Dictionary) -> void:
	var cost: int = int(a.get("cost", 0))
	match str(a.get("special", "")):
		"taxi":
			open_picker("taxi")
			return
		"boda":
			open_picker("boda")
			return
	if cost > 0 and main.money < cost:
		main.hud.toast("Not enough on Mobile Money for that (UGX %s)." % main.ugx(cost))
		return
	act = a
	act_place = pl
	_act_t = 0.0
	main.paused = true
	overlay.visible = true
	overlay_lbl.text = "%s\n\n%s" % [str(a["label"]).to_upper(), str(a.get("text", ""))]
	var indoor: bool = str(pl.get("cat", "")) in ["myhome", "church", "health"]
	main.player.visible = not indoor
	if not indoor and pl.has("pos"):
		var d: Vector3 = (pl["pos"] as Vector3) - main.player.position
		if Vector2(d.x, d.z).length() > 0.1:
			main.player.heading = atan2(-d.x, -d.z)
			main.player.walk_body.rotation.y = main.player.heading


func _run_activity(delta: float) -> void:
	_act_t += delta
	if main.player.visible and main.player.walk_body:
		main.player.walk_body.animate(delta, 1.35)
	overlay_fill.size.x = 420.0 * clampf(_act_t / ACT_SECONDS, 0.0, 1.0)
	if _act_t < ACT_SECONDS:
		return
	var a := act
	act = {}
	overlay.visible = false
	main.player.visible = true
	main.paused = false
	var cost: int = int(a.get("cost", 0))
	if cost > 0:
		main.add_money(-cost, "%s at %s" % [a["label"], act_place["name"]])
	hunger = clampf(hunger + float(a.get("hunger", 0)), 0.0, 100.0)
	energy = clampf(energy + float(a.get("energy", 0)), 0.0, 100.0)
	mood = clampf(mood + float(a.get("mood", 0)), 0.0, 100.0)
	groceries = maxi(0, groceries + int(a.get("groceries", 0)))
	main.sfx.play("chime", -6.0)
	if str(a.get("special", "")) == "sleep":
		slept_home = true
		main.time_of_day = main.DAY_END - 0.002   # the game's end-of-day summary takes over
		_last_time = main.time_of_day
		save_life()
		return
	var hrs: float = float(a.get("hours", 0.0))
	main.time_of_day = minf(main.DAY_END - 0.01, main.time_of_day + hrs)
	_last_time = main.time_of_day
	if str(a.get("special", "")) == "service":
		main.adjust_rating(0.05)
		main.add_sms("Church member", "Praise God! Great to meet you at service. I'll call you for boda trips this week.")
	elif str(a.get("special", "")) == "market_earn":
		main.add_money(3500, "Market produce offload")
		main.hud.toast("Earned UGX 3,500 helping offload market produce!")
		save_life()
		return
	elif str(a.get("special", "")) == "repair_boda":
		if main.player:
			main.player.repair_bike()
		main.sfx.play("bonus")
		main.hud.toast("🔧 Boda repaired to 100% Health! Ready to ride!")
		save_life()
		return
	elif str(a.get("special", "")) == "tune_boda":
		if main.player:
			main.player.bike_health = minf(100.0, main.player.bike_health + 30.0)
		main.sfx.play("chime")
		main.hud.toast("🔧 Boda tuned! Health now %d%%." % int(roundf(main.player.bike_health)))
		save_life()
		return
	elif str(a.get("special", "")) == "swim":
		main.sfx.play("splash" if main.sfx.has_method("has") else "pop")
		main.hud.toast("🏊 Refreshing swim in Lake Victoria! (+26 Mood)")
		save_life()
		return
	elif str(a.get("special", "")) == "tv_bet":
		if randf() < 0.58:
			main.add_money(5000, "Kibanda TV match goal prize")
			main.hud.toast("GOAL!! Your team scored! You won UGX 5,000 at the Roadside TV!")
			save_life()
			return
		else:
			main.hud.toast("Ooh, hit the crossbar! Close match at the Roadside TV!")
			save_life()
			return
	main.hud.toast("%s  -  Food %d  Energy %d  Mood %d" % [a["label"], int(hunger), int(energy), int(mood)])
	save_life()


## Activities for the place you're standing at (on foot).
func _update_chips() -> void:
	var p: Node3D = main.player
	var show: bool = not p.on_boda and ride_state == 0 and act.is_empty() and not picker.visible and not main.paused
	var pl := {}
	var opts := []
	if show:
		pl = place_here(p.position)
		if not pl.is_empty():
			opts = activities_for(pl)
	# matatu waiting at the roadside with its conductor shouting
	var taxi: Node3D = _stopped_taxi_near(p.position) if show else null
	if taxi != null and pl.is_empty():
		pl = {"name": "a matatu loading passengers", "cat": "taxi", "district": "", "pos": taxi.global_position}
		opts = [{"label": "Board this matatu (UGX 1,500)", "special": "taxi", "cost": 0, "hours": 0.0}]
	if ride_state == 2 and ride and p.position.distance_to(ride.global_position) < 9.0:
		pl = {"name": "%s's %s" % [ride_driver, ride_kind], "cat": "ride", "district": "", "pos": ride.global_position}
		opts = [{"label": "Hop on - go to %s" % ride_dest["name"], "special": "board"}]
	var key := "%s|%d|%d|%d" % [pl.get("name", ""), opts.size(), int(main.time_of_day * 2), groceries]
	if key == _chips_key:
		return
	_chips_key = key
	for ch in chips_box.get_children():
		ch.queue_free()
	if opts.is_empty():
		chips.visible = false
		return
	chips.visible = true
	card.visible = false
	var pname := str(pl["name"])
	if pname != _last_chip_place:
		_last_chip_place = pname
		chips_min = false
	chips_box.visible = not chips_min
	if chips_min_btn:
		chips_min_btn.text = "+" if chips_min else "—"
	chips_title.text = "%s  -  %s" % [pname.capitalize() if pname.begins_with("the ") else pname, CAT_NAMES.get(pl["cat"], "")]
	for o in opts:
		var cost: int = int(o.get("cost", 0))
		var txt := str(o["label"]) + ("   UGX %s" % main.ugx(cost) if cost > 0 else "")
		if float(o.get("hours", 0.0)) >= 0.5:
			txt += "   (%s)" % _hours_str(float(o["hours"]))
		var b := _btn(chips_box, txt, func(): _chip_pressed(o, pl), Vector2(430, 40), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _chip_pressed(o: Dictionary, pl: Dictionary) -> void:
	if str(o.get("special", "")) == "board":
		_board_ride()
		return
	if str(o.get("special", "")) == "taxi":
		var taxi := _stopped_taxi_near(main.player.position)
		_ride_hidden_car = taxi
		open_picker("taxi")
		return
	start_activity(o, pl)


func _hours_str(h: float) -> String:
	if h < 1.0:
		return "%d min" % int(round(h * 60.0))
	return "%s h" % str(snappedf(h, 0.5))


## The named place you're standing in front of, if any.
func place_here(pos: Vector3) -> Dictionary:
	if Vector2(pos.x - home["pos"].x, pos.z - home["pos"].z).length() < 5.0:
		return home
	var best := -1
	var best_d := 4.2
	for i in main.places.size():
		var q: Vector3 = main.places[i]["pos"]
		if absf(q.x - pos.x) > 6.0 or absf(q.z - pos.z) > 6.0:
			continue
		var d := Vector2(q.x - pos.x, q.z - pos.z).length()
		if d < best_d and cat_of[i] not in ["other", "fuel", "momo"]:
			best_d = d
			best = i
	return place_dict(best) if best >= 0 else {}


# =================================================================== routes (real streets)
func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> Array:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var t := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	var q := Vector2(a.x, a.z) + ab * t
	return [q.distance_to(Vector2(p.x, p.z)), Vector3(q.x, 0, q.y)]


## The road edge closest to a point: [node_a, node_b, point on the road centre]
func nearest_edge(p: Vector3) -> Array:
	var best: Array = []
	var bd := 1e9
	for e in main.edges:
		var r := _seg_dist(p, main.nodes[e[0]], main.nodes[e[1]])
		if r[0] < bd:
			bd = r[0]
			best = [e[0], e[1], r[1]]
	return best


## Shortest path of junctions between two points, along the streets.
func path_nodes(from: Vector3, to: Vector3) -> PackedInt32Array:
	var ea := nearest_edge(from)
	var eb := nearest_edge(to)
	var n: int = main.nodes.size()
	var dist := []
	var prev := []
	dist.resize(n)
	prev.resize(n)
	var done := []
	done.resize(n)
	for i in n:
		dist[i] = 1e9
		prev[i] = -1
		done[i] = false
	for s in [ea[0], ea[1]]:
		dist[s] = (ea[2] as Vector3).distance_to(main.nodes[s])
	while true:
		var u := -1
		var ud := 1e9
		for i in n:
			if not done[i] and dist[i] < ud:
				ud = dist[i]
				u = i
		if u == -1:
			break
		done[u] = true
		for v in main.adj[u]:
			var nd: float = ud + (main.nodes[u] as Vector3).distance_to(main.nodes[v])
			if nd < dist[v]:
				dist[v] = nd
				prev[v] = u
	var goal: int = eb[0]
	var g1: float = dist[eb[0]] + (main.nodes[eb[0]] as Vector3).distance_to(eb[2])
	var g2: float = dist[eb[1]] + (main.nodes[eb[1]] as Vector3).distance_to(eb[2])
	if g2 < g1:
		goal = eb[1]
	var out := PackedInt32Array()
	var c := goal
	while c != -1:
		out.insert(0, c)
		c = prev[c]
	# both points on the same street: no junction needed
	if (ea[0] == eb[0] and ea[1] == eb[1]) or (ea[0] == eb[1] and ea[1] == eb[0]):
		return PackedInt32Array()
	return out


func route_points(from: Vector3, to: Vector3) -> PackedVector3Array:
	var pts := PackedVector3Array()
	pts.append(Vector3(from.x, 0, from.z))
	var ea := nearest_edge(from)
	pts.append(ea[2])
	for nd in path_nodes(from, to):
		pts.append(main.nodes[nd])
	var eb := nearest_edge(to)
	pts.append(eb[2])
	pts.append(Vector3(to.x, 0, to.z))
	return pts


func set_destination(pl: Dictionary) -> void:
	dest = pl
	_route_t = 0.0
	main.hud.toast("Route set to %s (%s). Follow the blue line." % [pl["name"], pl["district"]])
	main.sfx.play("pop", -4.0)


func clear_destination() -> void:
	dest = {}
	route = PackedVector3Array()
	_imesh.clear_surfaces()


func _update_route(delta: float) -> void:
	if dest.is_empty():
		return
	var p: Node3D = main.player
	var here: Vector3 = ride.global_position if ride_state == 3 and ride else p.position
	_route_t -= delta
	if _route_t <= 0.0:
		_route_t = 1.0
		route = route_points(here, dest["pos"])
		_draw_ground_route()
	if ride_state != 3 and Vector2(here.x - dest["pos"].x, here.z - dest["pos"].z).length() < 5.0:
		main.hud.toast("You've arrived at %s." % dest["name"])
		main.sfx.play("pop", -4.0)
		clear_destination()


func _draw_ground_route() -> void:
	_imesh.clear_surfaces()
	if route.size() < 2:
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var left := 160.0
	for i in route.size() - 1:
		var a: Vector3 = route[i]
		var b: Vector3 = route[i + 1]
		var seg := b - a
		var l := seg.length()
		if l < 0.01:
			continue
		var d := seg / l
		var side := Vector3(-d.z, 0, d.x) * 0.22
		# dashes, like a sat-nav line painted on the road
		var s := 0.0
		while s < l and left > 0.0:
			var e := minf(s + 1.2, l)
			var p1 := a + d * s + Vector3(0, 0.13, 0)
			var p2 := a + d * e + Vector3(0, 0.13, 0)
			_imesh.surface_add_vertex(p1 - side)
			_imesh.surface_add_vertex(p1 + side)
			_imesh.surface_add_vertex(p2 + side)
			_imesh.surface_add_vertex(p1 - side)
			_imesh.surface_add_vertex(p2 + side)
			_imesh.surface_add_vertex(p2 - side)
			s += 2.4
			left -= 2.4
	_imesh.surface_end()


## Called from the HUD map to draw the route on the minimap / full map.
func draw_on_map(map: Control, centre: Vector3, scale: float, yaw: float) -> void:
	var col := Color(0.2, 0.85, 1.0, 0.9)
	if route.size() >= 2:
		for i in route.size() - 1:
			map.draw_line(map._w2m(route[i], centre, scale, yaw), map._w2m(route[i + 1], centre, scale, yaw), col, 3.5)
	if not dest.is_empty():
		var q: Vector2 = map._w2m(dest["pos"], centre, scale, yaw)
		map.draw_circle(q, 6.0, col)
	# your room
	var hq: Vector2 = map._w2m(home["pos"], centre, scale, yaw)
	map.draw_rect(Rect2(hq - Vector2(6, 6), Vector2(12, 12)), Color(0.95, 0.4, 0.75))
	map.draw_string(map.get_theme_default_font(), hq + Vector2(-4, 5), "H", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if ride and ride_state >= 1:
		map.draw_circle(map._w2m(ride.global_position, centre, scale, yaw), 5.0, Color(1.0, 0.4, 0.9))


# =================================================================== rides as a passenger
func fare_for(kind: String, from: Vector3, to: Vector3) -> int:
	var d := absf(from.x - to.x) + absf(from.z - to.z)
	if kind == "taxi":
		return 1500 if d < 250.0 else 2000
	return int(snappedf(maxf(2000.0, 1000.0 + d * 14.0), 500.0))


func call_ride(kind: String, pl: Dictionary) -> void:
	var p: Node3D = main.player
	if p.on_boda:
		main.hud.toast("Park your own boda first, then call a ride.")
		return
	if ride_state != 0:
		main.hud.toast("You already have a ride on the way.")
		return
	var fare := fare_for(kind, p.position, pl["pos"])
	if main.money < fare:
		main.hud.toast("Not enough on Mobile Money for this ride (UGX %s)." % main.ugx(fare))
		return
	ride_kind = kind
	ride_fare = fare
	ride_dest = pl
	ride_driver = RIDERS[randi() % RIDERS.size()]
	var parts: Array = main.model_taxi() if kind == "taxi" else main.model_boda(true, false)
	var mi := MeshInstance3D.new()
	mi.mesh = main._agent_mesh(parts)
	mi.material_override = main.mat_agent
	ride = RideVehicle.new()
	ride.add_child(mi)
	ride.body = mi
	ride.length = mi.mesh.get_aabb().size.z
	main.add_child(ride)
	main.obstacles.append(ride)
	set_destination(pl)
	if kind == "taxi" and _ride_hidden_car != null and is_instance_valid(_ride_hidden_car):
		# you board the matatu that was waiting: swap it for your ride
		ride.position = _ride_hidden_car.global_position
		ride.rotation = _ride_hidden_car.rotation
		_ride_hidden_car.visible = false
		_ride_hidden_car.process_mode = Node.PROCESS_MODE_DISABLED
		ride_state = 2
		_board_ride()
		return
	# a driver comes from a junction a little way off
	var en := nearest_edge(p.position)
	var start_node: int = main.adj[en[0]][randi() % main.adj[en[0]].size()]
	ride.position = main.nodes[start_node]
	ride_pts = _drive_points(ride.position, p.position, 3.0 if kind == "boda" else 1.9)
	ride_idx = 0
	ride_state = 1
	main.hud.toast("%s is coming on his %s. Fare UGX %s to %s." % [ride_driver, "boda" if kind == "boda" else "matatu", main.ugx(fare), pl["name"]])
	main.add_sms(ride_driver, "I'm coming boss. Wait for me by the road. Fare UGX %s." % main.ugx(fare))


## Points a vehicle drives through: its lane on each street, keeping LEFT.
func _drive_points(from: Vector3, to: Vector3, lane: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var nodes_path := path_nodes(from, to)
	var ea := nearest_edge(from)
	var eb := nearest_edge(to)
	var prev: Vector3 = ea[2]
	var list := [prev]
	for nd in nodes_path:
		list.append(main.nodes[nd])
	list.append(eb[2])
	for i in list.size() - 1:
		var a: Vector3 = list[i]
		var b: Vector3 = list[i + 1]
		var d := b - a
		if d.length() < 0.5:
			continue
		d = d.normalized()
		var left := Vector3(d.z, 0, -d.x)
		var inset := 6.0 if i > 0 else 0.0
		var outset := 6.0 if i < list.size() - 2 else 0.0
		pts.append(a + d * inset + left * lane + Vector3(0, 0.04, 0))
		pts.append(b - d * outset + left * lane + Vector3(0, 0.04, 0))
	if pts.is_empty():
		pts.append(Vector3(to.x, 0.04, to.z))
	return pts


func _board_ride() -> void:
	if ride == null:
		return
	var p: Node3D = main.player
	ride_state = 3
	p.visible = false
	p.process_mode = Node.PROCESS_MODE_DISABLED
	ride.passenger_on(main, ride_kind)
	main.rig.follow = ride
	ride_pts = _drive_points(ride.global_position, ride_dest["pos"], 3.0 if ride_kind == "boda" else 1.9)
	ride_idx = 0
	main.sfx.play("start", -4.0)
	main.hud.toast("You're on your way to %s. Sit back and watch Kampala go by." % ride_dest["name"])


func _update_ride(delta: float) -> void:
	if ride == null:
		return
	var p: Node3D = main.player
	if ride_state == 2:
		# waiting by the road: board automatically when you walk up
		if p.position.distance_to(ride.global_position) < 3.5:
			_board_ride()
		return
	if ride_idx >= ride_pts.size():
		if ride_state == 1:
			ride_state = 2
			main.hud.toast("%s has arrived. Walk to the %s to hop on." % [ride_driver, ride_kind if ride_kind == "boda" else "matatu"])
			main.honk_from(ride.global_position, ride_kind)
		elif ride_state == 3:
			_finish_ride()
		return
	var target: Vector3 = ride_pts[ride_idx]
	var to := target - ride.global_position
	to.y = 0.0
	var d := to.length()
	var want: float = (10.5 if ride_kind == "boda" else 8.0) * (0.8 if main.raining else 1.0)
	want = ride.traffic_speed(main, want)
	if want < 0.2:
		_ride_stuck += delta
		if _ride_stuck > 3.0:
			want = 4.0   # squeeze past (bodas always find a way)
	else:
		_ride_stuck = 0.0
	ride.speed = move_toward(ride.speed, want, (6.0 if want > ride.speed else 14.0) * delta)
	var mv: float = ride.speed * delta
	if d <= mv + 0.05:
		ride.global_position = Vector3(target.x, target.y, target.z)
		ride_idx += 1
	elif d > 0.001:
		ride.global_position += to / d * mv
		var yaw := atan2(-to.x, -to.z)
		ride.rotation.y = lerp_angle(ride.rotation.y, yaw, clampf(delta * 7.0, 0.0, 1.0))
		ride.heading = ride.rotation.y
	main.sfx.update_engine(true, clampf(ride.speed / 16.0, 0.0, 1.0), delta)


func _finish_ride() -> void:
	var p: Node3D = main.player
	main.add_money(-ride_fare, "%s ride to %s (%s)" % ["Boda" if ride_kind == "boda" else "Matatu", ride_dest["name"], ride_driver])
	main.sfx.play("chime", -6.0)
	p.position = Vector3(ride_dest["pos"].x, main.ground_height(ride_dest["pos"]), ride_dest["pos"].z)
	p.visible = true
	p.process_mode = Node.PROCESS_MODE_INHERIT
	main.rig.follow = p
	main.hud.toast("Arrived at %s. Paid %s UGX %s on Mobile Money. 'Webale!'" % [ride_dest["name"], ride_driver, main.ugx(ride_fare)])
	main.obstacles.erase(ride)
	ride.queue_free()
	ride = null
	ride_state = 0
	if _ride_hidden_car != null and is_instance_valid(_ride_hidden_car):
		_ride_hidden_car.visible = true
		_ride_hidden_car.process_mode = Node.PROCESS_MODE_INHERIT
	_ride_hidden_car = null
	clear_destination()


func _stopped_taxi_near(pos: Vector3) -> Node3D:
	for v in main.vehicles:
		if not is_instance_valid(v) or not v.visible or v.kind != "taxi":
			continue
		if float(v.get("_stop_timer")) > 0.0 and v.global_position.distance_to(pos) < 8.0:
			return v
	return null


## Conductors leaning out of stopped matatus & roadside vendors calling to passers-by.
var _vendor_lab: Label3D
var _vendor_timer := 0.0
func _update_shouts(delta: float) -> void:
	_vendor_timer -= delta
	if _vendor_timer <= 0.0:
		_vendor_timer = 5.5
		if _vendor_lab == null:
			_vendor_lab = Label3D.new()
			_vendor_lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_vendor_lab.font_size = 40
			_vendor_lab.outline_size = 10
			_vendor_lab.pixel_size = 0.0062
			_vendor_lab.modulate = Color(1.0, 0.92, 0.35)
			_vendor_lab.visibility_range_end = 55.0
			_vendor_lab.no_depth_test = true
			_vendor_lab.visible = false
			main.add_child(_vendor_lab)
		var ppos: Vector3 = main.player.position
		var shown := false
		var groups := [
			[main.tv_stands, "tv", Vector3(0, 3.3, 0)],
			[main.muchomo_stands, "muchomo", Vector3(0, 2.7, 0)],
			[main.rolex_stands, "rolex", Vector3(0, 2.7, 0)],
			[main.fruit_carts, "fruit", Vector3(0, 2.6, 0)],
			[main.boda_fundis, "fundi", Vector3(0, 2.5, 0)],
		]
		for g in groups:
			for sp: Vector3 in g[0]:
				if ppos.distance_to(sp) < 22.0:
					_vendor_lab.text = main.sfx.line_text(g[1])
					_vendor_lab.position = sp + (g[2] as Vector3)
					_vendor_lab.visible = true
					shown = true
					break
			if shown:
				break
		if not shown:
			_vendor_lab.visible = false
	_shout_t -= delta
	if _shout_t > 0.0:
		return
	_shout_t = 0.4
	for v in main.vehicles:
		if not is_instance_valid(v) or v.kind != "taxi":
			continue
		var stopped: bool = v.visible and float(v.get("_stop_timer")) > 0.0
		var lab: Label3D = _bubbles.get(v)
		if stopped and lab == null:
			lab = Label3D.new()
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.font_size = 44
			lab.outline_size = 10
			lab.pixel_size = 0.0065
			lab.modulate = Color(1.0, 0.95, 0.4)
			lab.position = Vector3(0, 3.4, 0)
			lab.visibility_range_end = 70.0
			lab.no_depth_test = true
			v.add_child(lab)
			_bubbles[v] = lab
		if lab == null:
			continue
		if stopped and not lab.visible:
			lab.text = main.sfx.line_text("conductor")
			lab.visible = true
			if v.global_position.distance_to(main.player.position) < 30.0:
				main.honk_from(v.global_position)
		elif not stopped:
			lab.visible = false


# =================================================================== suggestions (intents)
func _update_suggestions(delta: float) -> void:
	_suggest_cool -= delta
	if card.visible or chips.visible or _suggest_cool > 0.0 or not act.is_empty() or ride_state != 0 or main.paused:
		return
	_suggest_cool = 8.0
	var p: Node3D = main.player
	var h: float = main.time_of_day
	var s := _pick_suggestion(p.position, h)
	if s.is_empty():
		return
	_suggest_cool = 70.0
	_seen_today[s["kind"]] = true
	_suggest_kind = s["kind"]
	_suggest_place = s["place"]
	card_lbl.text = s["text"]
	for ch in card_btns.get_children():
		ch.queue_free()
	var pl: Dictionary = s["place"]
	_btn(card_btns, "Go there", func():
		set_destination(pl)
		card.visible = false, Vector2(130, 42), 16)
	if not p.on_boda:
		_btn(card_btns, "Call boda  UGX %s" % main.ugx(fare_for("boda", p.position, pl["pos"])), func():
			card.visible = false
			call_ride("boda", pl), Vector2(200, 42), 16)
	_btn(card_btns, "Later", func(): card.visible = false, Vector2(90, 42), 16)
	card.visible = true
	main.sfx.play("pop", -8.0)


func _pick_suggestion(pos: Vector3, h: float) -> Dictionary:
	var meal := meal_word()
	var meal_time := (h >= 7.0 and h < 9.5) or (h >= 12.5 and h < 14.5) or (h >= 18.5 and h < 21.0)
	if (hunger < 45.0 and meal_time and not _seen_today.has(meal)) or (hunger < 20.0 and not _seen_today.has("starving")):
		var f := nearest("food", pos, 1)
		if not f.is_empty():
			var k := meal if hunger >= 20.0 else "starving"
			return {"kind": k, "place": f[0], "text": "%s! Your stomach is growling (Food %d%%).\n%s is %d m away." % [
				meal.capitalize() + " time" if k == meal else "You're starving", int(hunger), f[0]["name"], int(pos.distance_to(f[0]["pos"]))]}
	if is_sunday() and h >= 7.5 and h < 10.0 and not _seen_today.has("church"):
		var c := nearest("church", pos, 1)
		if not c.is_empty():
			return {"kind": "church", "place": c[0], "text": "It's Sunday morning. Service at %s starts soon.\nThe church members might become regular customers." % c[0]["name"]}
	if (energy < 22.0 or h >= 21.0) and not _seen_today.has("home"):
		return {"kind": "home", "place": home, "text": "You're %s (Energy %d%%).\nHead home to your room and sleep?" % ["exhausted" if energy < 22.0 else "winding down", int(energy)]}
	if h >= 19.0 and mood < 60.0 and not _seen_today.has("bar"):
		var b := nearest("bar", pos, 1)
		if not b.is_empty():
			return {"kind": "bar", "place": b[0], "text": "Long day? The match is on tonight at %s.\nMood %d%% - a cold drink would help." % [b[0]["name"], int(mood)]}
	if groceries == 0 and h >= 16.0 and h < 19.0 and not _seen_today.has("market"):
		var m := nearest("market", pos, 1)
		if not m.is_empty():
			return {"kind": "market", "place": m[0], "text": "Nothing to cook at home tonight.\nPick up groceries at %s on your way?" % m[0]["name"]}
	if mood < 30.0 and not _seen_today.has("mood"):
		var l := nearest("leisure", pos, 1)
		if not l.is_empty():
			return {"kind": "mood", "place": l[0], "text": "You're feeling low (Mood %d%%).\nTake an hour at %s?" % [int(mood), l[0]["name"]]}
	return {}


# =================================================================== citizens with routines
func _spawn_citizens() -> void:
	var homes := []
	var works := []
	for i in main.places.size():
		match cat_of[i]:
			"home": homes.append(i)
			"shop", "market", "food", "salon", "health", "momo", "other": works.append(i)
	if homes.is_empty() or works.is_empty():
		return
	for k in 40:
		var female := randf() < 0.5
		var style: String = main._person_style(female)
		var person: Node3D = Person.new()
		person.build(main.model_human(female, style, randf() < 0.12), main.mat_agent)
		person.scale = Vector3.ONE * main.PERSON_SCALE
		main.add_child(person)
		var hi: int = homes[randi() % homes.size()]
		var wi: int = works[randi() % works.size()]
		var hp: Vector3 = main.places[hi]["pos"]
		var wp: Vector3 = main.places[wi]["pos"]
		var c := {
			"node": person, "home": hp, "work": wp,
			"food": _nearest_pos("food", wp), "bar": _nearest_pos("bar", hp), "church": _nearest_pos("church", hp),
			"market": _nearest_pos("market", hp),
			"jitter": randf_range(-0.6, 0.6), "barfly": randf() < 0.4, "faithful": randf() < 0.7,
			"goal": "home", "path": PackedVector3Array(), "idx": 0, "inside": true, "speed": randf_range(1.15, 1.5),
		}
		person.position = hp
		person.visible = false
		citizens.append(c)
		main.people.append(person)
		main.obstacles.append(person)


func _nearest_pos(cat: String, from: Vector3) -> Vector3:
	var n := nearest(cat, from, 1)
	return n[0]["pos"] if not n.is_empty() else from


func _reset_citizens_morning() -> void:
	for c in citizens:
		c["goal"] = "home"
		c["inside"] = true
		c["path"] = PackedVector3Array()
		var nd: Node3D = c["node"]
		nd.position = c["home"]
		nd.visible = false


## Where this citizen wants to be right now.
func _goal_for(c: Dictionary) -> String:
	var h: float = main.time_of_day + float(c["jitter"])
	if is_sunday():
		if h >= 8.5 and h < 12.0 and c["faithful"]:
			return "church"
		if h >= 12.5 and h < 14.0:
			return "food"
		if h >= 15.0 and h < 21.0 and c["barfly"]:
			return "bar"
		return "home"
	if h < 7.6:
		return "home"
	if h < 12.5:
		return "work"
	if h < 13.6:
		return "food"
	if h < 17.2:
		return "work"
	if h < 18.6:
		return "market" if not c["barfly"] else "work"
	if h < 21.5 and c["barfly"]:
		return "bar"
	return "home"


func _update_citizens(delta: float) -> void:
	var focus: Vector3 = main.rig.target
	for c in citizens:
		var nd: Node3D = c["node"]
		var goal := _goal_for(c)
		if goal != c["goal"]:
			c["goal"] = goal
			var to: Vector3 = c[goal]
			c["path"] = _walk_points(nd.position, to)
			c["idx"] = 0
			c["inside"] = false
			nd.visible = true
		var path: PackedVector3Array = c["path"]
		if c["inside"]:
			continue
		if c["idx"] >= path.size():
			# arrived: go inside, or hang around outside bars and churches
			if goal in ["bar", "church"]:
				if not c.has("loiter"):
					c["loiter"] = true
					nd.position += Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.0, 2.0))
					nd.rotation.y = randf() * TAU
				nd.animate(delta, 0.0)
			else:
				c["inside"] = true
				nd.visible = false
			continue
		c.erase("loiter")
		var tgt: Vector3 = path[c["idx"]]
		var far := nd.position.distance_to(focus) > 85.0 and tgt.distance_to(focus) > 85.0
		var spd: float = float(c["speed"]) * (1.6 if main.raining else 1.0) * (10.0 if far else 1.0)
		var to2 := tgt - nd.position
		to2.y = 0.0
		var d := to2.length()
		var mv := spd * delta
		if d <= mv:
			nd.position = Vector3(tgt.x, main.ground_height(tgt), tgt.z)
			c["idx"] += 1
		else:
			nd.position += to2 / d * mv
			nd.position.y = main.ground_height(nd.position)
			nd.rotation.y = lerp_angle(nd.rotation.y, atan2(-to2.x, -to2.z), clampf(delta * 10.0, 0.0, 1.0))
		if not far:
			nd.animate(delta, spd)


## Walking route along the pavements (left side of each street).
func _walk_points(from: Vector3, to: Vector3) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var nodes_path := path_nodes(from, to)
	var list := [from]
	for nd in nodes_path:
		list.append(main.nodes[nd])
	list.append(to)
	for i in list.size() - 1:
		var a: Vector3 = list[i]
		var b: Vector3 = list[i + 1]
		var d := b - a
		if d.length() < 0.5:
			continue
		d = d.normalized()
		var left := Vector3(d.z, 0, -d.x)
		if i == 0:
			pts.append(a)
		else:
			pts.append(a + d * 6.0 + left * 5.3)
		if i == list.size() - 2:
			pts.append(b)
		else:
			pts.append(b - d * 6.0 + left * 5.3)
	return pts


# =================================================================== UI
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)

	# needs panel, under the minimap (minimizable!)
	var np := _panel(ui, Color(0.05, 0.06, 0.08, 0.78))
	np.position = Vector2(12, 228)
	np.custom_minimum_size = Vector2(196, 0)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 3)
	np.add_child(nv)
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 4)
	nv.add_child(nh)
	needs_lbl = _label(nh, 13, Color(1.0, 0.86, 0.35))
	needs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	needs_min_btn = _btn(nh, "—", func():
		needs_min = not needs_min
		needs_rows.visible = not needs_min
		needs_min_btn.text = "+" if needs_min else "—", Vector2(24, 22), 12)
	needs_rows = VBoxContainer.new()
	needs_rows.add_theme_constant_override("separation", 3)
	needs_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nv.add_child(needs_rows)
	for k in [["food", "Food", Color(0.95, 0.6, 0.2)], ["energy", "Energy", Color(0.3, 0.85, 1.0)], ["mood", "Mood", Color(0.95, 0.45, 0.8)]]:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		needs_rows.add_child(row)
		var l := _label(row, 12, Color(1, 1, 1, 0.85))
		l.text = k[1]
		l.custom_minimum_size = Vector2(52, 0)
		var bg := ColorRect.new()
		bg.color = Color(1, 1, 1, 0.14)
		bg.custom_minimum_size = Vector2(118, 10)
		bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bg)
		var fill := ColorRect.new()
		fill.color = k[2]
		fill.size = Vector2(118, 10)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fill)
		bars[k[0]] = fill

	# "Where to?" button, in the right-hand column under the quick bar
	go_btn = Button.new()
	go_btn.text = "Where to?"
	go_btn.anchor_left = 1.0
	go_btn.anchor_right = 1.0
	go_btn.offset_left = -132
	go_btn.offset_right = -10
	go_btn.offset_top = 186
	go_btn.offset_bottom = 226
	go_btn.add_theme_font_size_override("font_size", 16)
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color(0.1, 0.55, 0.75, 0.95)
	gsb.set_corner_radius_all(10)
	go_btn.add_theme_stylebox_override("normal", gsb)
	go_btn.add_theme_stylebox_override("hover", gsb)
	go_btn.focus_mode = Control.FOCUS_NONE
	go_btn.pressed.connect(func(): open_picker("go"))
	ui.add_child(go_btn)

	# suggestion card (bottom centre-left, clear of both the joystick zone and the right-hand Action/Hoot buttons)
	card = _panel(ui, Color(0.06, 0.07, 0.1, 0.92), Color(0.2, 0.85, 1.0, 0.6))
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = -360
	card.offset_right = 90
	card.offset_top = -185
	card.offset_bottom = -20
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)
	card_lbl = _label(cv, 15, Color.WHITE)
	card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_btns = HBoxContainer.new()
	card_btns.add_theme_constant_override("separation", 8)
	cv.add_child(card_btns)
	card.visible = false

	# activities at the place you're standing at (bottom centre-left, never overlapping Action/Hoot buttons)
	chips = _panel(ui, Color(0.06, 0.07, 0.1, 0.9), Color(1.0, 0.84, 0.15, 0.55))
	chips.anchor_left = 0.5
	chips.anchor_right = 0.5
	chips.anchor_top = 1.0
	chips.anchor_bottom = 1.0
	chips.offset_left = -360
	chips.offset_right = 95
	chips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	chips.offset_top = -36
	chips.offset_bottom = -18
	var chv := VBoxContainer.new()
	chv.add_theme_constant_override("separation", 6)
	chips.add_child(chv)
	var chh := HBoxContainer.new()
	chh.add_theme_constant_override("separation", 6)
	chv.add_child(chh)
	chips_title = _label(chh, 15, Color(1.0, 0.86, 0.35))
	chips_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips_min_btn = _btn(chh, "—", func():
		chips_min = not chips_min
		chips_box.visible = not chips_min
		chips_min_btn.text = "+" if chips_min else "—", Vector2(28, 24), 13)
	chips_box = VBoxContainer.new()
	chips_box.add_theme_constant_override("separation", 5)
	chv.add_child(chips_box)
	chips.visible = false

	# destination picker
	picker = _panel(ui, Color(0.05, 0.06, 0.08, 0.96), Color(0.2, 0.85, 1.0, 0.6))
	picker.anchor_left = 0.5
	picker.anchor_right = 0.5
	picker.anchor_top = 0.5
	picker.anchor_bottom = 0.5
	picker.offset_left = -360
	picker.offset_right = 360
	picker.offset_top = -300
	picker.offset_bottom = 300
	picker.mouse_filter = Control.MOUSE_FILTER_STOP
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	picker.add_child(pv)
	picker_title = _label(pv, 19, Color(1.0, 0.86, 0.35))
	picker_cats = GridContainer.new()
	picker_cats.columns = 4
	picker_cats.add_theme_constant_override("h_separation", 6)
	picker_cats.add_theme_constant_override("v_separation", 6)
	pv.add_child(picker_cats)
	for cat in PICKER_CATS:
		var cc: String = cat
		_btn(picker_cats, CAT_NAMES[cat], func():
			_picker_cat = cc
			_fill_picker(), Vector2(168, 40), 14)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(700, 360)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(sc)
	picker_list = VBoxContainer.new()
	picker_list.add_theme_constant_override("separation", 6)
	picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(picker_list)
	var close := _btn(pv, "Close", func(): close_picker(), Vector2(160, 44), 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picker.visible = false

	# activity overlay (docked at bottom-centre so the player remains visible performing the activity!)
	overlay = _panel(ui, Color(0.05, 0.05, 0.07, 0.94), Color(1.0, 0.84, 0.15, 0.75))
	overlay.anchor_left = 0.5
	overlay.anchor_right = 0.5
	overlay.anchor_top = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = -240
	overlay.offset_right = 240
	overlay.offset_top = -185
	overlay.offset_bottom = -24
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 14)
	overlay.add_child(ov)
	overlay_lbl = _label(ov, 17, Color.WHITE)
	overlay_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_lbl.custom_minimum_size = Vector2(440, 0)
	var obg := ColorRect.new()
	obg.color = Color(1, 1, 1, 0.12)
	obg.custom_minimum_size = Vector2(420, 10)
	ov.add_child(obg)
	overlay_fill = ColorRect.new()
	overlay_fill.color = Color(1.0, 0.84, 0.15)
	overlay_fill.size = Vector2(0, 10)
	obg.add_child(overlay_fill)
	overlay.visible = false


func open_picker(mode: String) -> void:
	_picker_mode = mode
	if mode == "taxi":
		_picker_cat = "market"
	picker.visible = true
	card.visible = false
	main.paused = true
	_fill_picker()


func close_picker() -> void:
	picker.visible = false
	main.paused = false
	if ride_state == 0:
		_ride_hidden_car = null


func _fill_picker() -> void:
	var p: Node3D = main.player
	match _picker_mode:
		"taxi": picker_title.text = "Board a matatu  -  where to?  (UGX 1,500-2,000)"
		"boda": picker_title.text = "Hire a boda  -  where to?"
		_: picker_title.text = "Where to?  %s %s, Food %d%%  Energy %d%%  Mood %d%%" % [weekday(), main.time_str(), int(hunger), int(energy), int(mood)]
	for ch in picker_list.get_children():
		ch.queue_free()
	var list := nearest(_picker_cat, p.position, 7)
	if list.is_empty():
		_label(picker_list, 15, Color(1, 1, 1, 0.7)).text = "No %s in this part of town." % CAT_NAMES[_picker_cat].to_lower()
	for pl in list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		picker_list.add_child(row)
		var d := int(p.position.distance_to(pl["pos"]))
		var l := _label(row, 15, Color.WHITE)
		l.text = "%s\n%s  -  %d m" % [pl["name"], pl["district"], d]
		l.custom_minimum_size = Vector2(270, 0)
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var plc: Dictionary = pl
		if _picker_mode == "go":
			_btn(row, "Route", func():
				close_picker()
				set_destination(plc), Vector2(80, 46), 15)
		if _picker_mode != "taxi":
			_btn(row, "Boda UGX %s" % main.ugx(fare_for("boda", p.position, pl["pos"])), func():
				close_picker()
				call_ride("boda", plc), Vector2(150, 46), 14)
		if _picker_mode != "boda":
			_btn(row, "Matatu UGX %s" % main.ugx(fare_for("taxi", p.position, pl["pos"])), func():
				close_picker()
				if _picker_mode == "taxi":
					call_ride("taxi", plc)
				else:
					_call_taxi_from_stage(plc), Vector2(150, 46), 14)


func _call_taxi_from_stage(pl: Dictionary) -> void:
	# on the street: a matatu pulls over for you
	call_ride("taxi", pl)


func _update_needs_ui() -> void:
	var hud_modal: bool = main.hud != null and (main.hud.bigmap.visible or main.hud.phone_panel.visible or main.hud.summary.visible or main.hud.police_panel.visible)
	ui.visible = not hud_modal
	needs_lbl.text = "%s  %s%s" % [weekday(), main.time_str(), ("   Groceries x%d" % groceries) if groceries > 0 else ""]
	var vals := {"food": hunger, "energy": energy, "mood": mood}
	for k in bars:
		var f: ColorRect = bars[k]
		f.size.x = 118.0 * float(vals[k]) / 100.0
		f.modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 250.0)) if float(vals[k]) < 20.0 else 1.0
	var tools_h: float = 420.0 if (main.hud != null and main.hud.get("tools_open")) else 186.0
	go_btn.offset_top = tools_h
	go_btn.offset_bottom = tools_h + 40.0
	go_btn.visible = (not main.paused or picker.visible) and not hud_modal


func _panel(parent: Node, col: Color, border := Color(1, 1, 1, 0.12)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _label(parent: Node, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _btn(parent: Control, text: String, cb: Callable, size: Vector2, font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", font)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# =================================================================== save
func _save_path() -> String:
	return "user://playkampala_life_%d.json" % int(main.get("save_slot") if main.get("save_slot") != null else 1)


func save_life() -> void:
	if "--no-save" in OS.get_cmdline_user_args():
		return
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"hunger": hunger, "energy": energy, "mood": mood, "groceries": groceries}))


func load_life() -> void:
	if "--no-save" in OS.get_cmdline_user_args() or not FileAccess.file_exists(_save_path()):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
	if typeof(d) == TYPE_DICTIONARY:
		hunger = float(d.get("hunger", hunger))
		energy = float(d.get("energy", energy))
		mood = float(d.get("mood", mood))
		groceries = int(d.get("groceries", 0))


# =================================================================== the hired vehicle
class RideVehicle extends Node3D:
	var body: Node3D
	var speed := 0.0
	var heading := 0.0
	var length := 2.0
	var on_boda := true       # makes the camera pull back with speed, like your own boda
	var kind := "ride"
	var _passenger: Node3D

	func passenger_on(m: Node, k: String) -> void:
		if k == "boda":
			var mi := MeshInstance3D.new()
			mi.mesh = m._agent_mesh(m._seated(0.62, Color(0.6, 1.0, 0.1), false))
			mi.material_override = m.mat_agent
			add_child(mi)
			_passenger = mi

	func traffic_speed(m: Node, want: float) -> float:
		var fwd := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		var side := Vector3(-fwd.z, 0, fwd.x)
		var result := want
		for o in m.vehicles:
			if not is_instance_valid(o) or not o.visible:
				continue
			var dp: Vector3 = o.global_position - global_position
			if absf(dp.x) > 12.0 or absf(dp.z) > 12.0:
				continue
			var ahead := dp.dot(fwd)
			if ahead <= 0.0 or ahead > 10.0 or absf(dp.dot(side)) > 1.6:
				continue
			var gap := ahead - length * 0.5 - 1.5
			if gap < 1.2:
				return 0.0
			result = minf(result, want * clampf(gap / 7.0, 0.25, 1.0))
		return result
