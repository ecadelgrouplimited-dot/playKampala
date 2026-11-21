extends CanvasLayer
## On-screen controls and info.

const JOY_RADIUS := 90.0
const FONT := 22

var main: Node
var joy := Vector2.ZERO
var job_text := ""

var info: Label
var money_lbl: Label
var day_lbl: Label
var job_lbl: Label
var job_panel: PanelContainer
var job_min_btn: Button
var job_skip_btn: Button
var job_errand_btn: Button
var job_mode_btn: Button
var job_minimized := false
var tut_panel: PanelContainer
var tut_lbl: Label
var tut_dots_lbl: Label
var tut_next_btn: Button
var toast_lbl: Label
var toast_panel: PanelContainer
var msg_btn: Button
var msg_drawer: PanelContainer
var enc_panel: PanelContainer
var enc_lbl: Label
var enc_btn_a: Button
var enc_btn_b: Button
var voice_panel: PanelContainer
var voice_lbl: Label
var _voice_time := 0.0
var map_finder_panel: PanelContainer
var map_finder_list: VBoxContainer
var map_filter := "all"
var fuel_panel: PanelContainer
var fuel_menu_lbl: Label
var fuel_menu_btns: GridContainer
var settings_panel: PanelContainer
var settings_name_edit: LineEdit
var settings_stage_btn: Button
var settings_paint_btn: Button
var settings_outfit_btn: Button
var settings_gender_btn: Button
var title_panel: PanelContainer
var title_sub_lbl: Label
var trophies_panel: PanelContainer
var trophies_lbl: Label
var show_fps := false
var msg_drawer_lbl: Label
var toast_history: Array[String] = []
var tools_box: VBoxContainer
var tools_btn: Button
var tools_open := false
var money_pop_lbl: Label
var _money_pop_t := 0.0
var fuel_fill: ColorRect
var fuel_lbl: Label
var speed_lbl: Label
var action_btn: Button
var rain_btn: Button
var power_btn: Button
var speed_btn: Button
var stick: Joystick
var summary: PanelContainer
var summary_lbl: Label
var summary_btn: Button
var police_panel: PanelContainer
var police_lbl: Label
var phone_panel: PanelContainer
var phone_lbl: Label
var phone_actions: GridContainer
var phone_tab := 0
var guide_btn: Button
var radio_btn: Button

var minimap: MapView
var bigmap: MapView
var horn_btn: Button
var boost_btn: Button
var view_btn: Button

var _joy_index := -1
var _joy_last := 0
var _toast_time := 0.0


class Joystick extends Control:
	var center := Vector2.ZERO
	var knob := Vector2.ZERO
	var active := false
	var speed_ratio := 0.0
	var boosting := false
	var key_vec := Vector2.ZERO

	func _draw() -> void:
		var pad_c := Vector2(102.0, size.y - 102.0)
		var c := center if (active and center.distance_to(pad_c) > 2.0) else pad_c
		var r := 68.0
		var disp_knob := knob if active else key_vec
		var font := get_theme_default_font()
		var moving: bool = active or disp_knob.length() > 0.05

		# Solid physical controller socket & bezel (always clearly visible)
		draw_circle(c + Vector2(0, 3), r + 4.0, Color(0.0, 0.0, 0.0, 0.45))
		draw_circle(c, r + 2.0, Color(0.10, 0.13, 0.18, 0.90))
		draw_circle(c, r - 4.0, Color(0.05, 0.07, 0.11, 0.94))
		var rim_col := Color(0.28, 0.92, 1.0, 0.95) if boosting else Color(1.0, 0.84, 0.15, 0.95 if active else 0.78)
		draw_arc(c, r + 2.0, 0, TAU, 48, rim_col, 3.0)
		draw_arc(c, r - 6.0, 0, TAU, 48, Color(1.0, 1.0, 1.0, 0.14), 1.5)

		# Recessed 4-way D-pad cross tracks & crisp directional arrows
		var track_col := Color(0.16, 0.20, 0.27, 0.92)
		draw_rect(Rect2(c.x - 13, c.y - r + 10, 26, (r - 10) * 2.0), track_col, true)
		draw_rect(Rect2(c.x - r + 10, c.y - 13, (r - 10) * 2.0, 26), track_col, true)
		var arr_col := Color(1.0, 0.94, 0.65, 0.85 if active else 0.72)
		draw_string(font, c + Vector2(-6, -r + 22), "▲", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, arr_col)
		draw_string(font, c + Vector2(-6, r - 11), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, arr_col)
		draw_string(font, c + Vector2(-r + 12, 5), "◀", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, arr_col)
		draw_string(font, c + Vector2(r - 23, 5), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, arr_col)

		# 3D-shaded physical thumbstick cap
		var kp := c + disp_knob * (r - 18.0)
		draw_circle(kp + Vector2(2, 4), 27.0, Color(0.0, 0.0, 0.0, 0.55))
		draw_circle(kp, 27.0, Color(0.16, 0.19, 0.24, 0.98))
		var cap_col := Color(0.28, 0.92, 1.0, 1.0) if boosting else Color(1.0, 0.82, 0.16, 1.0 if moving else 0.92)
		draw_circle(kp, 22.0, cap_col)
		draw_arc(kp, 15.0, 0, TAU, 28, Color(0.08, 0.09, 0.12, 0.35), 2.0)
		draw_circle(kp + Vector2(-5, -6), 6.0, Color(1.0, 1.0, 1.0, 0.38))

		# Clear steady label below the controller
		draw_string(font, c + Vector2(-42, r + 18), "STEER / MOVE", HORIZONTAL_ALIGNMENT_CENTER, 84, 10, Color(1.0, 0.92, 0.52, 0.88))


## Live map of the city: roads, districts, traffic, fuel stations, the job
## target and you. Small = rotates with the camera; full screen = north up.
class MapView extends Control:
	var main: Node
	var full := false
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if is_visible_in_tree() and main and main.built:
			queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		var click_pos := Vector2(-1, -1)
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			click_pos = e.position
		elif e is InputEventScreenTouch and e.pressed:
			click_pos = e.position
		if click_pos.x >= 0.0 and main and main.built:
			var full_scale: float = minf(size.x, size.y) / (main.HALF * 2.0 + 115.0)
			var scale := full_scale if full else 0.72
			var centre: Vector3 = Vector3(0, 0, 8.0) if full else main.player.position
			var yaw: float = 0.0 if full else main.rig.yaw
			# 1. Check 1-Tap Quick-Route Pills along the top-right of the Full Map
			if full:
				var pills := [
					["fuel", Rect2(size.x - 635, 8, 120, 28)],
					["myhome", Rect2(size.x - 507, 8, 112, 28)],
					["food", Rect2(size.x - 387, 8, 122, 28)],
					["tv", Rect2(size.x - 257, 8, 120, 28)],
					["stage", Rect2(size.x - 129, 8, 116, 28)],
				]
				for pl_pill in pills:
					if (pl_pill[1] as Rect2).has_point(click_pos):
						if main.has_method("route_to_category"):
							main.route_to_category(str(pl_pill[0]), true)
						accept_event()
						return
			# 1.5 Check active Golden Street Promo [★] (clickable on both minimap & full map)
			if main.street_event and bool(main.street_event.get("active", false)):
				var eq := _w2m(main.street_event["pos"], centre, scale, yaw)
				if click_pos.distance_to(eq) <= (28.0 if full else 20.0):
					if main.has_method("route_to_event"):
						main.route_to_event(full)
					accept_event()
					return
			# 2. Check Petrol Stations [F] (clickable on both minimap & full map)
			var hit_r := 26.0 if full else 18.0
			for p in main.pumps:
				var q := _w2m(p, centre, scale, yaw)
				if click_pos.distance_to(q) <= hit_r:
					if main.has_method("route_to_pump"):
						main.route_to_pump(p, full)
					accept_event()
					return
			# 3. On Full Map, also allow clicking [TV] stands or [H] Your Room directly!
			if full:
				if main.life and not main.life.home.is_empty():
					var hq := _w2m(main.life.home["pos"], centre, scale, yaw)
					if click_pos.distance_to(hq) <= 22.0:
						main.route_to_category("myhome", true)
						accept_event()
						return
				for tvp in main.tv_stands:
					var tvq := _w2m(tvp, centre, scale, yaw)
					if click_pos.distance_to(tvq) <= 22.0:
						main.life.set_destination({"name": "Kibanda Live TV", "pos": tvp, "district": main.district_at(tvp), "cat": "tv"})
						main.hud.bigmap.visible = false
						main.sfx.play("chime", -3.0)
						accept_event()
						return
			main.hud.toggle_map()
			accept_event()

	func _w2m(p: Vector3, centre: Vector3, scale: float, yaw: float) -> Vector2:
		var d := Vector2(p.x - centre.x, p.z - centre.z)
		if full:
			return size / 2 + d * scale
		var right := Vector2(cos(yaw), -sin(yaw))
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		return size / 2 + Vector2(d.dot(right), -d.dot(fwd)) * scale

	func _draw() -> void:
		var m := main
		var full_scale: float = minf(size.x, size.y) / (m.HALF * 2.0 + 235.0)
		var scale := full_scale if full else 0.72
		var centre: Vector3 = Vector3(0, 0, 8.0) if full else m.player.position
		var yaw: float = 0.0 if full else m.rig.yaw
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.09, 0.92 if full else 0.82))
		var font := get_theme_default_font()
		if full:
			# Lake Victoria water band along southern edge of Kampala
			var lake_tl := _w2m(Vector3(-m.HALF - 90.0, 0, m.HALF + 8.0), centre, scale, yaw)
			draw_rect(Rect2(lake_tl, Vector2((m.HALF * 2.0 + 180.0) * scale, 34.0 * scale)), Color(0.08, 0.36, 0.64, 0.78))
			draw_string(font, lake_tl + Vector2(36, 20), "LAKE VICTORIA  •  Ggaba Beach & Pier", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.94, 1.0))
			# Inter-District Highways & Suburb Murram/Mud Roads outside town
			if m.get("highway_routes") != null:
				for hr in m.highway_routes:
					var pa := _w2m(hr["a"], centre, scale, yaw)
					var pb := _w2m(hr["b"], centre, scale, yaw)
					var is_m: bool = str(hr.get("kind", "")) == "murram"
					draw_line(pa, pb, Color(0.68, 0.34, 0.19, 0.92) if is_m else Color(0.42, 0.44, 0.48, 0.95), 4.0 if is_m else 7.0)
					if hr.has("label"):
						var mid := pa.lerp(pb, 0.55)
						draw_string(font, mid + Vector2(-46, -6), str(hr["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.98, 0.72))
			# district tint + names
			for key in m.district_of:
				var d: String = m.district_of[key]
				var x0: float = -m.HALF + key.x * m.BLOCK + 6.5
				var z0: float = -m.HALF + key.y * m.BLOCK + 6.5
				var a := _w2m(Vector3(x0, 0, z0), centre, scale, yaw)
				var col: Color = {"downtown": Color(0.95, 0.55, 0.2, 0.3), "market": Color(0.95, 0.82, 0.2, 0.32),
					"taxi": Color(0.3, 0.55, 0.95, 0.32), "workshops": Color(0.55, 0.55, 0.6, 0.3),
					"pitch": Color(0.28, 0.82, 0.32, 0.32), "fuel": Color(0.1, 0.75, 0.42, 0.32),
					"nakasero": Color(0.42, 0.75, 0.95, 0.32)}.get(d, Color(0.65, 0.42, 0.3, 0.2))
				var bsz: float = (m.BLOCK - 13.0) * scale
				draw_rect(Rect2(a, Vector2(bsz, bsz)), col)
				if d in ["downtown", "market", "taxi", "workshops", "pitch", "nakasero"] or (key.x + key.y) % 3 == 0:
					var short_lbl: String = {"downtown": "Kikuubo", "market": "Owino Market", "taxi": "Old Taxi Park",
						"pitch": "Nakivubo", "workshops": "Katwe", "mixed": "Wandegeya",
						"estates": "Ntinda", "fuel": "Fuel", "nakasero": "Nakasero Hill"}.get(d, m.DISTRICT_NAMES[d])
					draw_string(font, a + Vector2(4, 15), short_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.88))
		# roads
		var rw := maxf(2.2, 8.2 * scale)
		for e in m.edges:
			draw_line(_w2m(m.nodes[e[0]], centre, scale, yaw), _w2m(m.nodes[e[1]], centre, scale, yaw), Color(0.52, 0.53, 0.57), rw)
		# Real Kampala Street Names on the Full-Screen City Map
		if full and m.get("EW_STREETS") and m.get("NS_STREETS"):
			for j in m.EW_STREETS.size():
				var z_rd: float = -m.HALF + j * m.BLOCK
				var lp := _w2m(Vector3(-m.HALF - 6.0, 0, z_rd), centre, scale, yaw)
				draw_string(font, lp + Vector2(-118, 4), str(m.EW_STREETS[j]), HORIZONTAL_ALIGNMENT_RIGHT, 112, 11, Color(0.95, 0.90, 0.65, 0.92))
			for i in m.NS_STREETS.size():
				var x_rd: float = -m.HALF + i * m.BLOCK
				var tp := _w2m(Vector3(x_rd, 0, -m.HALF - 6.0), centre, scale, yaw)
				var short_ns := str(m.NS_STREETS[i]).replace(" Street", " St").replace(" Road", " Rd")
				draw_string(font, tp + Vector2(-42, -4 if i % 2 == 0 else -16), short_ns, HORIZONTAL_ALIGNMENT_CENTER, 84, 10, Color(0.78, 0.94, 1.0, 0.92))
		# roundabouts & Clock Tower
		for ri in m.roundabouts.size():
			var rq := _w2m(m.roundabouts[ri], centre, scale, yaw)
			draw_circle(rq, maxf(4.5, 5.8 * scale), Color(0.98, 0.78, 0.12))
			draw_circle(rq, maxf(2.6, 3.6 * scale), Color(0.22, 0.62, 0.24))
			if full and ri == 0:
				draw_string(font, rq + Vector2(8, 4), "Clock Tower", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.92, 0.45))
		# GPS route line to active job target
		if m.jobs and m.jobs.marker.visible:
			var p_pos: Vector3 = m.player.position
			var t_pos: Vector3 = m.jobs.target()
			var r_col := Color(0.15, 0.95, 0.45, 0.72) if m.jobs.state == 0 else Color(1.0, 0.62, 0.12, 0.78)
			var b_sz: float = m.BLOCK
			var h_sz: float = m.HALF
			var p_rx := clampf(roundf((p_pos.x + h_sz) / b_sz) * b_sz - h_sz, -h_sz, h_sz)
			var p_rz := clampf(roundf((p_pos.z + h_sz) / b_sz) * b_sz - h_sz, -h_sz, h_sz)
			var t_rx := clampf(roundf((t_pos.x + h_sz) / b_sz) * b_sz - h_sz, -h_sz, h_sz)
			var t_rz := clampf(roundf((t_pos.z + h_sz) / b_sz) * b_sz - h_sz, -h_sz, h_sz)
			var w1: Vector3
			var w2: Vector3
			if absf(p_pos.x - p_rx) < absf(p_pos.z - p_rz):
				w1 = Vector3(p_rx, 0, p_pos.z)
				w2 = Vector3(p_rx, 0, t_rz)
			else:
				w1 = Vector3(p_pos.x, 0, p_rz)
				w2 = Vector3(t_rx, 0, p_rz)
			draw_line(_w2m(p_pos, centre, scale, yaw), _w2m(w1, centre, scale, yaw), r_col, 3.0)
			draw_line(_w2m(w1, centre, scale, yaw), _w2m(w2, centre, scale, yaw), r_col, 3.0)
			draw_line(_w2m(w2, centre, scale, yaw), _w2m(t_pos, centre, scale, yaw), r_col, 3.0)
		# fuel stations (clickable on both minimap & full map to set GPS route!)
		var low_f: bool = m.player and m.player.fuel_fraction() <= 0.25
		for p in m.pumps:
			var q := _w2m(p, centre, scale, yaw)
			if low_f or full:
				var pulse_r := (14.0 if full else 11.0) + sin(_t * 6.5) * 2.5
				var ring_col := Color(1.0, 0.32, 0.18, 0.9) if low_f else Color(0.25, 0.95, 0.55, 0.75)
				draw_arc(q, pulse_r, 0, TAU, 20, ring_col, 2.2)
			var box_r := 10.0 if full else 8.0
			draw_rect(Rect2(q - Vector2(box_r, box_r), Vector2(box_r * 2.0, box_r * 2.0)), Color(0.08, 0.74, 0.38))
			draw_rect(Rect2(q - Vector2(box_r, box_r), Vector2(box_r * 2.0, box_r * 2.0)), Color(1.0, 0.92, 0.35, 0.85), false, 1.5)
			draw_string(font, q + Vector2(-4, 5), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 13 if full else 12, Color.WHITE)
			if full:
				draw_string(font, q + Vector2(13, 5), "PETROL (Tap to Route)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 1.0, 0.72))
		# traffic police checkpoints
		for cp in m.checkpoints:
			var cq := _w2m(cp, centre, scale, yaw)
			draw_rect(Rect2(cq - Vector2(6, 6), Vector2(12, 12)), Color(0.15, 0.35, 0.85))
			draw_string(font, cq + Vector2(-4, 5), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		# Highlight filtered places/roads on Full Map when a filter is active
		if full and m.hud and m.hud.map_filter != "all" and m.has_method("find_places_by_filter"):
			var f_items: Array = m.find_places_by_filter(m.hud.map_filter)
			for fi_idx in mini(8, f_items.size()):
				var fpl: Dictionary = f_items[fi_idx]
				var fq := _w2m(fpl["pos"], centre, scale, yaw)
				draw_circle(fq, 7.5, Color(1.0, 0.84, 0.14, 0.92))
				draw_arc(fq, 11.0 + sin(_t * 6.0) * 2.0, 0, TAU, 18, Color(0.25, 0.95, 1.0, 0.9), 2.0)
				if fi_idx < 3:
					draw_string(font, fq + Vector2(11, 4), str(fpl["name"]), HORIZONTAL_ALIGNMENT_LEFT, 160, 11, Color(1.0, 0.95, 0.72))
		# roadside live TVs & match screening stands
		if full:
			for tvp in m.tv_stands:
				var tvq := _w2m(tvp, centre, scale, yaw)
				draw_rect(Rect2(tvq - Vector2(8, 6), Vector2(16, 12)), Color(0.10, 0.65, 0.90))
				draw_string(font, tvq + Vector2(-6, 4), "TV", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		# Active Golden Street Promo / Lucky Drop Event [★]
		if m.street_event and bool(m.street_event.get("active", false)):
			var eq := _w2m(m.street_event["pos"], centre, scale, yaw)
			if not full:
				var mid_e := size / 2
				var off_e := eq - mid_e
				var lim_e := size.x / 2 - 12
				if absf(off_e.x) > lim_e or absf(off_e.y) > lim_e:
					eq = mid_e + off_e * (lim_e / maxf(absf(off_e.x), absf(off_e.y)))
			var er := (14.0 if full else 10.0) + sin(_t * 8.0) * 2.5
			draw_arc(eq, er, 0, TAU, 20, Color(1.0, 0.86, 0.12, 0.95), 2.4)
			draw_circle(eq, 8.5 if full else 7.0, Color(0.96, 0.72, 0.06))
			draw_string(font, eq + Vector2(-5, 4), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12 if full else 11, Color(0.1, 0.08, 0.02))
			if full:
				draw_string(font, eq + Vector2(12, 5), "%s (+UGX %s • %ds)" % [m.street_event.get("title", "Street Promo"), m.ugx(int(m.street_event.get("reward", 0))), int(m.street_event.get("timer", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.92, 0.35))
		# live traffic
		for v in m.vehicles:
			var col2 := Color(0.95, 0.95, 0.95) if v.kind == "taxi" else (Color(1.0, 0.82, 0.15) if v.kind == "boda" else Color(0.55, 0.78, 1.0))
			draw_circle(_w2m(v.global_position, centre, scale, yaw), 2.5 if full else 3.0, col2)
		# job target: pulsing ring, pinned to the edge when off the minimap
		if m.jobs and m.jobs.marker.visible:
			var tq := _w2m(m.jobs.target(), centre, scale, yaw)
			if not full:
				var mid := size / 2
				var off := tq - mid
				var lim := size.x / 2 - 10
				if absf(off.x) > lim or absf(off.y) > lim:
					tq = mid + off * (lim / maxf(absf(off.x), absf(off.y)))
			var tc := Color(0.15, 0.95, 0.45) if m.jobs.state == 0 else Color(1.0, 0.62, 0.12)
			draw_circle(tq, 6.5 + sin(_t * 6.0) * 2.0, tc)
			draw_arc(tq, 9.5 + sin(_t * 6.0) * 2.0, 0, TAU, 20, Color(1, 1, 1, 0.8), 1.5)
		# you
		var pp := _w2m(m.player.position, centre, scale, yaw)
		var h: float = m.player.heading
		var fwd3 := Vector3(-sin(h), 0, -cos(h))
		var tip := _w2m(m.player.position + fwd3 * 9.0 / scale * 0.7, centre, scale, yaw) - pp
		tip = tip.normalized() * 11.5
		var side := Vector2(-tip.y, tip.x) * 0.55
		draw_colored_polygon(PackedVector2Array([pp + tip, pp - tip * 0.6 + side, pp - tip * 0.6 - side]), Color(1.0, 0.3, 0.22))
		if m.get("life") and m.life:
			m.life.draw_on_map(self, centre, scale, yaw)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.84, 0.15, 0.45), false, 2.0)
		if full:
			draw_string(font, Vector2(16, 26), "KAMPALA CITY MAP  •  Tap any [F] Petrol, [TV], [H] Room or Quick-Route Pill:", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.84, 0.15))
			# Draw 5 Quick-Route Filter Pills along top-right of Full Map
			var pill_defs := [
				["⛽ Fuel [F]", Rect2(size.x - 635, 8, 120, 28), Color(0.08, 0.62, 0.34)],
				["🏠 My Room", Rect2(size.x - 507, 8, 112, 28), Color(0.75, 0.25, 0.58)],
				["🍳 Rolex/Food", Rect2(size.x - 387, 8, 122, 28), Color(0.82, 0.45, 0.12)],
				["📺 Kibanda TV", Rect2(size.x - 257, 8, 120, 28), Color(0.10, 0.55, 0.82)],
				["🛠️ Boda Stage", Rect2(size.x - 129, 8, 116, 28), Color(0.65, 0.52, 0.10)],
			]
			for pd in pill_defs:
				var r: Rect2 = pd[1]
				draw_rect(r, pd[2])
				draw_rect(r, Color(1, 1, 1, 0.65), false, 1.5)
				draw_string(font, r.position + Vector2(10, 19), str(pd[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
			draw_string(font, Vector2(16, size.y - 16), "You: Red Arrow   •   Job: Green/Orange   •   Petrol (Tap!): [F]   •   Live TV (Tap!): [TV]   •   Room (Tap!): [H]   •   Press M to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.88))
		else:
			draw_rect(Rect2(Vector2(0, size.y - 24), Vector2(size.x, 24)), Color(0.04, 0.04, 0.06, 0.82))
			var st_lbl: String = m.street_at(m.player.position) if m.has_method("street_at") else m.district_at(m.player.position)
			draw_string(font, Vector2(6, size.y - 7), "TRAFFIC • " + st_lbl, HORIZONTAL_ALIGNMENT_LEFT, 186, 11, Color(1.0, 0.88, 0.35))


func toggle_map() -> void:
	bigmap.visible = not bigmap.visible
	if bigmap.visible:
		if main.tutorial_step == 1:
			main.tutorial_step = 2
		_refresh_map_finder()
	main.sfx.play("pop", -6.0)


func show_title_screen() -> void:
	if title_panel == null or main == null:
		return
	var ach_n: int = main.unlocked_achievements.size()
	var ach_tot: int = main.ACHIEVEMENTS.size()
	title_sub_lbl.text = "Rider: %s  •  %s\nDay %d  •  MoMo UGX %s  •  ★ %.1f  •  🏆 %d/%d Trophies" % [
		main.rider_name, main.home_stage_name(), main.day, main.ugx(main.money), main.rating, ach_n, ach_tot]
	title_panel.visible = true


func open_trophies() -> void:
	if trophies_panel == null or main == null:
		return
	var lines := PackedStringArray()
	var got := 0
	for a in main.ACHIEVEMENTS:
		var aid: String = str(a["id"])
		var has_it: bool = main.unlocked_achievements.has(aid)
		if has_it:
			got += 1
		lines.append("%s  %s — %s (+UGX %s)" % [
			"✅" if has_it else "🔒", str(a["title"]), str(a["desc"]), main.ugx(int(a["reward"]))])
	trophies_lbl.text = "🏆 KAMPALA TROPHIES (%d / %d)\n\n%s" % [got, main.ACHIEVEMENTS.size(), "\n".join(lines)]
	trophies_panel.visible = true
	main.sfx.play("pop", -4.0)


func open_settings() -> void:
	if settings_panel == null or main == null:
		return
	settings_name_edit.text = main.rider_name
	_refresh_settings_labels()
	settings_panel.visible = true
	main.sfx.play("pop", -4.0)


func _refresh_settings_labels() -> void:
	if main == null:
		return
	settings_stage_btn.text = "Home Stage: %s" % main.home_stage_name()
	settings_paint_btn.text = "Boda Color: %s" % main.bike_paint_name()
	settings_outfit_btn.text = "Rider Clothes: %s" % main.rider_outfit_name()
	if settings_gender_btn:
		settings_gender_btn.text = "Rider Style: %s" % ("Woman" if main.rider_female else "Man")


func open_fuel_menu() -> void:
	if fuel_panel == null or main == null or main.player == null:
		return
	for c in fuel_menu_btns.get_children():
		c.queue_free()
	var p = main.player
	var need_l: float = maxf(0.0, p.max_tank() - p.fuel)
	var full_cost: int = int(ceil(need_l * main.FUEL_PRICE / 100.0) * 100)
	fuel_menu_lbl.text = "⛽ PETROL STATION PUMP\nTank: %d%% (%.1fL / %.1fL)  •  Price: UGX %s/L\nYour MoMo Balance: UGX %s" % [
		int(roundf(p.fuel_fraction() * 100.0)), p.fuel, p.max_tank(), main.ugx(main.FUEL_PRICE), main.ugx(main.money)]
	for amt in [2000, 5000, 10000, 15000]:
		var b_amt: int = amt
		var lit := float(b_amt) / float(main.FUEL_PRICE)
		var lbl := "UGX %s (%.1fL)" % [main.ugx(b_amt), lit]
		var btn := _btn(fuel_menu_btns, lbl, func():
			fuel_panel.visible = false
			main.buy_fuel_amount(b_amt), Vector2(215, 38), 13)
		btn.disabled = main.money < b_amt
	var full_lbl := "⛽ FULL TANK (UGX %s)" % main.ugx(full_cost)
	var full_btn := _btn(fuel_menu_btns, full_lbl, func():
		fuel_panel.visible = false
		main.buy_fuel_amount(-1), Vector2(215, 38), 13)
	full_btn.disabled = main.money < 500 or full_cost <= 0
	_btn(fuel_menu_btns, "✕ Cancel", func():
		fuel_panel.visible = false, Vector2(215, 38), 13)
	fuel_panel.visible = true
	main.sfx.play("pop", -4.0)


func show_voice_subtitle(speaker: String, line: String) -> void:
	if voice_lbl == null:
		return
	voice_lbl.text = "%s: \"%s\"" % [speaker, line]
	_voice_time = 3.8


func _refresh_map_finder() -> void:
	if map_finder_list == null or main == null or not main.has_method("find_places_by_filter"):
		return
	for c in map_finder_list.get_children():
		c.queue_free()
	var items: Array = main.find_places_by_filter(map_filter)
	if items.is_empty():
		var empty_l := _label(map_finder_list, 13, Color(0.8, 0.82, 0.86))
		empty_l.text = "No matching places found."
		return
	for idx in mini(6, items.size()):
		var pl: Dictionary = items[idx]
		var btn_txt := "%s (%d m)" % [str(pl["name"]), int(pl["dist"])]
		if btn_txt.length() > 36:
			btn_txt = str(pl["name"]).substr(0, 24) + "… (%d m)" % int(pl["dist"])
		var target_pl := pl
		_btn(map_finder_list, btn_txt, func():
			if main.life:
				main.life.set_destination(target_pl)
			bigmap.visible = false
			main.sfx.play("chime", -3.0)
			toast("GPS route set to %s (%d m)!" % [str(target_pl["name"]), int(target_pl["dist"])]), Vector2(268, 32), 12)


func _ready() -> void:
	stick = Joystick.new()
	stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stick)

	info = _label(self, 13, Color(1, 1, 1, 0.72))
	info.position = Vector2(14, 4)
	info.visible = false

	minimap = MapView.new()
	minimap.main = main
	minimap.position = Vector2(12, 12)
	minimap.size = Vector2(196, 196)
	minimap.clip_contents = true
	minimap.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(minimap)

	# --- top-centre wallet card: Mobile Money, day, fuel & speedometer
	var top := _panel(self, Color(0.05, 0.06, 0.08, 0.82), Color(1.0, 0.82, 0.12, 0.55))
	top.anchor_left = 0.5
	top.anchor_right = 0.5
	top.offset_left = -255
	top.offset_right = 255
	top.offset_top = 8
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 3)
	top.add_child(tv)
	money_lbl = _label(tv, FONT, Color(1.0, 0.84, 0.15))
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl = _label(tv, 15, Color(0.9, 0.9, 0.9))
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fuel_row := HBoxContainer.new()
	fuel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fuel_row.add_theme_constant_override("separation", 10)
	tv.add_child(fuel_row)
	fuel_lbl = _label(fuel_row, 15, Color(0.88, 0.88, 0.88))
	fuel_lbl.text = "Fuel"
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.16)
	bar_bg.custom_minimum_size = Vector2(180, 12)
	bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_row.add_child(bar_bg)
	fuel_fill = ColorRect.new()
	fuel_fill.color = Color(0.25, 0.92, 0.42)
	fuel_fill.size = Vector2(180, 12)
	fuel_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(fuel_fill)
	speed_lbl = _label(fuel_row, 15, Color(0.55, 0.9, 1.0))
	speed_lbl.text = "On Foot"

	# --- current job, under the wallet (minimizable!)
	job_panel = _panel(self, Color(0.05, 0.06, 0.08, 0.78), Color(0.2, 0.9, 0.45, 0.48))
	job_panel.anchor_left = 0.5
	job_panel.anchor_right = 0.5
	job_panel.offset_left = -350
	job_panel.offset_right = 350
	job_panel.offset_top = 104
	var jh := HBoxContainer.new()
	jh.add_theme_constant_override("separation", 8)
	job_panel.add_child(jh)
	job_lbl = _label(jh, 16, Color.WHITE)
	job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	job_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	job_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	job_skip_btn = _btn(jh, "✕ Skip", func(): main.jobs.reject_job(), Vector2(68, 26), 12)
	job_errand_btn = _btn(jh, "🚶 Errand", func(): main.jobs.resume_dispatch(true), Vector2(82, 26), 12)
	job_mode_btn = _btn(jh, "⏸️ Break", func(): main.jobs.toggle_dispatch(), Vector2(76, 26), 12)
	job_min_btn = _btn(jh, "—", func():
		job_minimized = not job_minimized
		job_min_btn.text = "+" if job_minimized else "—", Vector2(28, 26), 13)

	# --- interactive, auto-adapting & closable Tutorial Coach
	tut_panel = _panel(self, Color(0.06, 0.09, 0.15, 0.92), Color(1.0, 0.84, 0.15, 0.75))
	tut_panel.anchor_left = 0.5
	tut_panel.anchor_right = 0.5
	tut_panel.offset_left = -310
	tut_panel.offset_right = 310
	tut_panel.offset_top = 160
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	tut_panel.add_child(th)
	var tv2 := VBoxContainer.new()
	tv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv2.add_theme_constant_override("separation", 2)
	th.add_child(tv2)
	tut_dots_lbl = _label(tv2, 12, Color(1.0, 0.86, 0.25))
	tut_lbl = _label(tv2, 14, Color(0.96, 0.97, 1.0))
	tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_next_btn = _btn(th, "Next →", func(): main.advance_tutorial(), Vector2(78, 30), 13)
	_btn(th, "✕", func(): main.dismiss_tutorial(), Vector2(30, 30), 13)
	tut_panel.visible = false

	# --- floating +UGX celebration popup
	money_pop_lbl = _label(self, 20, Color(0.35, 1.0, 0.52))
	money_pop_lbl.anchor_left = 0.5
	money_pop_lbl.anchor_right = 0.5
	money_pop_lbl.offset_left = 90
	money_pop_lbl.offset_right = 290
	money_pop_lbl.offset_top = 16
	money_pop_lbl.visible = false

	# --- toast messages (docked at bottom-centre, with Minimize-to-Inbox & Dismiss buttons!)
	toast_panel = _panel(self, Color(0.04, 0.05, 0.07, 0.90), Color(1.0, 0.84, 0.15, 0.75))
	toast_panel.anchor_left = 0.5
	toast_panel.anchor_right = 0.5
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_left = -295
	toast_panel.offset_right = 225
	toast_panel.offset_top = -108
	toast_panel.offset_bottom = -28
	var toh := HBoxContainer.new()
	toh.add_theme_constant_override("separation", 6)
	toast_panel.add_child(toh)
	toast_lbl = _label(toh, 15, Color(1.0, 0.96, 0.85))
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(toh, "💬", func():
		_toast_time = 0.0
		toast_panel.visible = false
		toggle_messages_drawer(), Vector2(32, 28), 13)
	_btn(toh, "✕", func():
		_toast_time = 0.0
		toast_panel.visible = false, Vector2(28, 28), 13)
	toast_panel.visible = false

	# --- Interactive Kampala Street Encounter choice card (non-blocking)
	enc_panel = _panel(self, Color(0.06, 0.08, 0.14, 0.94), Color(0.25, 0.85, 1.0, 0.88))
	enc_panel.anchor_left = 0.5
	enc_panel.anchor_right = 0.5
	enc_panel.anchor_top = 1.0
	enc_panel.anchor_bottom = 1.0
	enc_panel.offset_left = -265
	enc_panel.offset_right = 265
	enc_panel.offset_top = -225
	enc_panel.offset_bottom = -118
	var env := VBoxContainer.new()
	env.add_theme_constant_override("separation", 6)
	enc_panel.add_child(env)
	enc_lbl = _label(env, 14, Color(0.95, 0.97, 1.0))
	enc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var enh := HBoxContainer.new()
	enh.alignment = BoxContainer.ALIGNMENT_CENTER
	enh.add_theme_constant_override("separation", 10)
	env.add_child(enh)
	enc_btn_a = _btn(enh, "Option A", func(): main.resolve_encounter(0), Vector2(215, 32), 13)
	enc_btn_b = _btn(enh, "Option B", func(): main.resolve_encounter(1), Vector2(215, 32), 13)
	enc_panel.visible = false

	# --- tap-to-view Recent Messages / Alerts Drawer (docked cleanly on the right under 'Where to?')
	msg_drawer = _panel(self, Color(0.05, 0.07, 0.11, 0.96), Color(1.0, 0.84, 0.15, 0.80))
	msg_drawer.anchor_left = 1.0
	msg_drawer.anchor_right = 1.0
	msg_drawer.offset_left = -380
	msg_drawer.offset_right = -10
	msg_drawer.offset_top = 234
	msg_drawer.offset_bottom = 500
	var mdv := VBoxContainer.new()
	mdv.add_theme_constant_override("separation", 6)
	msg_drawer.add_child(mdv)
	var mdh := HBoxContainer.new()
	mdv.add_child(mdh)
	var mdt := _label(mdh, 15, Color(1.0, 0.86, 0.25))
	mdt.text = "💬 RECENT MESSAGES & ALERTS"
	mdt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(mdh, "—", func(): msg_drawer.visible = false, Vector2(28, 24), 13)
	msg_drawer_lbl = _label(mdv, 13, Color(0.93, 0.95, 0.98))
	msg_drawer_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_drawer_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	msg_drawer.visible = false

	# --- top-right quick bar + collapsible Tools drawer
	var bar := VBoxContainer.new()
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.offset_left = -132
	bar.offset_right = -10
	bar.offset_top = 8
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 4)
	add_child(bar)
	_btn(bar, "Map (M)", func(): toggle_map(), Vector2(122, 30), 14)
	_btn(bar, "Phone (P)", func(): toggle_phone(), Vector2(122, 30), 14)
	radio_btn = _btn(bar, main.sfx.radio_short_label() if main.sfx else "FM", func():
		var st_name: String = main.sfx.cycle_radio()
		radio_btn.text = main.sfx.radio_short_label()
		toast("📻 Radio tuned to: %s" % st_name), Vector2(122, 30), 13)
	msg_btn = _btn(bar, "💬 Alerts", func(): toggle_messages_drawer(), Vector2(122, 30), 13)
	tools_btn = _btn(bar, "⚙️ Tools ▸", func():
		tools_open = not tools_open
		tools_box.visible = tools_open
		tools_btn.text = "⚙️ Tools ▾" if tools_open else "⚙️ Tools ▸", Vector2(122, 30), 13)
	tools_box = VBoxContainer.new()
	tools_box.add_theme_constant_override("separation", 4)
	tools_box.visible = false
	bar.add_child(tools_box)
	rain_btn = _btn(tools_box, "Rain", func(): main.toggle_rain(), Vector2(122, 28), 13)
	_btn(tools_box, "+3 hours", func(): main.skip_hours(3.0), Vector2(122, 28), 13)
	power_btn = _btn(tools_box, "Power", func(): main.toggle_power(), Vector2(122, 28), 13)
	speed_btn = _btn(tools_box, "Time", func(): main.cycle_speed(), Vector2(122, 28), 13)
	view_btn = _btn(tools_box, "View: street", func(): view_btn.text = "View: " + ["street", "cruise", "top"][main.rig.cycle_view()], Vector2(122, 28), 13)
	guide_btn = _btn(tools_box, "Guide: off", func():
		if main.jobs:
			main.jobs.show_pointer = not main.jobs.show_pointer
			guide_btn.text = "Guide: " + ("on" if main.jobs.show_pointer else "off"), Vector2(122, 28), 13)
	_btn(tools_box, "⚙️ Settings", func():
		tools_open = false
		tools_box.visible = false
		tools_btn.text = "⚙️ Tools ▸"
		open_settings(), Vector2(122, 28), 13)
	_btn(tools_box, "🏆 Trophies", func():
		tools_open = false
		tools_box.visible = false
		tools_btn.text = "⚙️ Tools ▸"
		open_trophies(), Vector2(122, 28), 13)
	var fps_btn: Button
	fps_btn = _btn(tools_box, "📊 FPS: off", func():
		show_fps = not show_fps
		info.visible = show_fps
		fps_btn.text = "📊 FPS: " + ("on" if show_fps else "off"), Vector2(122, 28), 13)
	_btn(tools_box, "⏭ Next Song", func():
		if main.sfx:
			var st_name: String = main.sfx.skip_song()
			radio_btn.text = main.sfx.radio_short_label()
			toast("📻 %s" % st_name), Vector2(122, 28), 13)
	var snd_btn: Button
	snd_btn = _btn(tools_box, "Sound: on", func():
		main.sfx.set_enabled(not main.sfx.enabled)
		snd_btn.text = "Sound: " + ("on" if main.sfx.enabled else "off"), Vector2(122, 28), 13)

	# --- big action button, bottom-right
	action_btn = Button.new()
	action_btn.anchor_left = 1.0
	action_btn.anchor_right = 1.0
	action_btn.anchor_top = 1.0
	action_btn.anchor_bottom = 1.0
	action_btn.offset_left = -252
	action_btn.offset_right = -20
	action_btn.offset_top = -126
	action_btn.offset_bottom = -34
	action_btn.add_theme_font_size_override("font_size", 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.78, 0.1, 0.94)
	sb.border_color = Color(1.0, 0.92, 0.5, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	action_btn.add_theme_stylebox_override("normal", sb)
	action_btn.add_theme_stylebox_override("hover", sb)
	var sbp := sb.duplicate()
	sbp.bg_color = Color(0.82, 0.62, 0.05, 0.96)
	action_btn.add_theme_stylebox_override("pressed", sbp)
	action_btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.04))
	action_btn.add_theme_color_override("font_hover_color", Color(0.08, 0.06, 0.04))
	action_btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.06, 0.04))
	action_btn.focus_mode = Control.FOCUS_NONE
	action_btn.pressed.connect(func(): main.player_action())
	add_child(action_btn)

	horn_btn = Button.new()
	horn_btn.anchor_left = 1.0
	horn_btn.anchor_right = 1.0
	horn_btn.anchor_top = 1.0
	horn_btn.anchor_bottom = 1.0
	horn_btn.offset_left = -362
	horn_btn.offset_right = -258
	horn_btn.offset_top = -78
	horn_btn.offset_bottom = -34
	horn_btn.text = "Hoot (H)"
	horn_btn.add_theme_font_size_override("font_size", 15)
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.15, 0.18, 0.24, 0.88)
	hsb.border_color = Color(1.0, 0.82, 0.15, 0.65)
	hsb.set_border_width_all(2)
	hsb.set_corner_radius_all(12)
	horn_btn.add_theme_stylebox_override("normal", hsb)
	horn_btn.add_theme_stylebox_override("hover", hsb)
	horn_btn.focus_mode = Control.FOCUS_NONE
	horn_btn.pressed.connect(func(): main.player_horn())
	add_child(horn_btn)

	boost_btn = Button.new()
	boost_btn.anchor_left = 1.0
	boost_btn.anchor_right = 1.0
	boost_btn.anchor_top = 1.0
	boost_btn.anchor_bottom = 1.0
	boost_btn.offset_left = -362
	boost_btn.offset_right = -258
	boost_btn.offset_top = -126
	boost_btn.offset_bottom = -82
	boost_btn.text = "⚡ Boost"
	boost_btn.add_theme_font_size_override("font_size", 14)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.14, 0.28, 0.42, 0.90)
	bsb.border_color = Color(0.35, 0.88, 1.0, 0.78)
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(12)
	boost_btn.add_theme_stylebox_override("normal", bsb)
	boost_btn.add_theme_stylebox_override("hover", bsb)
	boost_btn.focus_mode = Control.FOCUS_NONE
	boost_btn.pressed.connect(func():
		if main.player:
			main.player.boost_toggle = not main.player.boost_toggle
			main.sfx.play("pop", -2.0, 1.3 if main.player.boost_toggle else 0.9))
	add_child(boost_btn)

	# --- full-screen city map (tap the minimap or the Map button)
	bigmap = MapView.new()
	bigmap.main = main
	bigmap.full = true
	bigmap.set_anchors_preset(Control.PRESET_FULL_RECT)
	bigmap.mouse_filter = Control.MOUSE_FILTER_STOP
	bigmap.visible = false
	add_child(bigmap)

	# Interactive Place & Road Filter Finder docked on the right side of Full Map
	map_finder_panel = _panel(bigmap, Color(0.05, 0.07, 0.11, 0.94), Color(1.0, 0.84, 0.15, 0.72))
	map_finder_panel.anchor_left = 1.0
	map_finder_panel.anchor_right = 1.0
	map_finder_panel.anchor_top = 0.0
	map_finder_panel.anchor_bottom = 1.0
	map_finder_panel.offset_left = -296
	map_finder_panel.offset_right = -12
	map_finder_panel.offset_top = 46
	map_finder_panel.offset_bottom = -42
	map_finder_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var mfv := VBoxContainer.new()
	mfv.add_theme_constant_override("separation", 6)
	map_finder_panel.add_child(mfv)
	var mf_title := _label(mfv, 14, Color(1.0, 0.88, 0.25))
	mf_title.text = "FILTER & ROUTE TO PLACE"
	var mf_grid := GridContainer.new()
	mf_grid.columns = 2
	mf_grid.add_theme_constant_override("h_separation", 6)
	mf_grid.add_theme_constant_override("v_separation", 6)
	mfv.add_child(mf_grid)
	for fdef in [
		["all", "📍 All Nearest"], ["repair", "🔧 Repair / Fundi"],
		["fuel", "⛽ Petrol"], ["food", "🍔 Food / Juice"],
		["market", "🛒 Market / Shop"], ["church", "⛪ Church"],
		["health", "🏥 Clinic"], ["landmarks", "🏫 Landmarks"],
		["wash", "🫧 Wash Bays"], ["suburbs", "🏡 Suburbs & Hwys"],
		["roads", "🛣️ Streets"],
	]:
		var fkey: String = fdef[0]
		_btn(mf_grid, fdef[1], func():
			map_filter = fkey
			_refresh_map_finder()
			bigmap.queue_redraw(), Vector2(130, 28), 12)
	var mf_sub := _label(mfv, 12, Color(0.75, 0.9, 1.0))
	mf_sub.text = "Tap any result to plot GPS route:"
	map_finder_list = VBoxContainer.new()
	map_finder_list.add_theme_constant_override("separation", 5)
	mfv.add_child(map_finder_list)

	# --- Live Ugandan English Street Voice Subtitle Pill (bottom-right above Boost/Action, clear of left controller)
	voice_panel = _panel(self, Color(0.05, 0.07, 0.12, 0.90), Color(0.35, 0.92, 0.55, 0.78))
	voice_panel.anchor_left = 1.0
	voice_panel.anchor_right = 1.0
	voice_panel.anchor_top = 1.0
	voice_panel.anchor_bottom = 1.0
	voice_panel.offset_left = -362
	voice_panel.offset_right = -20
	voice_panel.offset_top = -184
	voice_panel.offset_bottom = -134
	voice_lbl = _label(voice_panel, 13, Color(0.92, 0.98, 0.94))
	voice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	voice_panel.visible = false

	# --- Rider Identity, Stage & Boda Customization Settings Modal
	settings_panel = _panel(self, Color(0.05, 0.07, 0.12, 0.96), Color(1.0, 0.84, 0.15, 0.88))
	settings_panel.anchor_left = 0.5
	settings_panel.anchor_right = 0.5
	settings_panel.anchor_top = 0.5
	settings_panel.anchor_bottom = 0.5
	settings_panel.offset_left = -255
	settings_panel.offset_right = 255
	settings_panel.offset_top = -220
	settings_panel.offset_bottom = 220
	var stv := VBoxContainer.new()
	stv.add_theme_constant_override("separation", 10)
	settings_panel.add_child(stv)
	var st_title := _label(stv, 17, Color(1.0, 0.88, 0.25))
	st_title.text = "⚙️ RIDER PROFILE, STAGE & CUSTOMIZATION"
	st_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 8)
	stv.add_child(name_row)
	var nl := _label(name_row, 14, Color(0.9, 0.92, 0.96))
	nl.text = "Rider Name:"
	settings_name_edit = LineEdit.new()
	settings_name_edit.custom_minimum_size = Vector2(240, 34)
	settings_name_edit.max_length = 18
	settings_name_edit.placeholder_text = "Enter your rider name..."
	name_row.add_child(settings_name_edit)
	settings_gender_btn = _btn(stv, "Rider Style: Man", func():
		main.set_customization(settings_name_edit.text, main.home_stage, main.bike_paint, main.rider_outfit, not main.rider_female)
		_refresh_settings_labels()
		main.sfx.play("pop", -4.0, 1.08), Vector2(450, 38), 14)
	settings_gender_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_stage_btn = _btn(stv, "Home Stage: Old Taxi Park Stage", func():
		main.set_customization(settings_name_edit.text, main.home_stage + 1, main.bike_paint, main.rider_outfit, main.rider_female)
		_refresh_settings_labels()
		main.sfx.play("pop", -4.0, 1.05), Vector2(450, 38), 14)
	settings_stage_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_paint_btn = _btn(stv, "Boda Color: Stage Red", func():
		main.set_customization(settings_name_edit.text, main.home_stage, main.bike_paint + 1, main.rider_outfit, main.rider_female)
		_refresh_settings_labels()
		main.sfx.play("pop", -4.0, 1.15), Vector2(450, 38), 14)
	settings_paint_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	settings_outfit_btn = _btn(stv, "Rider Clothes: Stage Neon", func():
		main.set_customization(settings_name_edit.text, main.home_stage, main.bike_paint, main.rider_outfit + 1, main.rider_female)
		_refresh_settings_labels()
		main.sfx.play("pop", -4.0, 1.10), Vector2(450, 38), 14)
	settings_outfit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_foot := HBoxContainer.new()
	st_foot.alignment = BoxContainer.ALIGNMENT_CENTER
	st_foot.add_theme_constant_override("separation", 12)
	stv.add_child(st_foot)
	_btn(st_foot, "✓ Save & Apply", func():
		main.set_customization(settings_name_edit.text, main.home_stage, main.bike_paint, main.rider_outfit, main.rider_female)
		settings_panel.visible = false
		main.sfx.play("chime", -4.0)
		toast("Saved profile: %s (%s) • %s" % [main.rider_name, main.home_stage_name(), main.bike_paint_name()]), Vector2(200, 38), 14)
	_btn(st_foot, "✕ Close", func():
		settings_panel.visible = false, Vector2(130, 38), 14)
	settings_panel.visible = false

	# --- Kampala Trophies / Achievements Modal
	trophies_panel = _panel(self, Color(0.05, 0.07, 0.12, 0.96), Color(1.0, 0.84, 0.15, 0.90))
	trophies_panel.anchor_left = 0.5
	trophies_panel.anchor_right = 0.5
	trophies_panel.anchor_top = 0.5
	trophies_panel.anchor_bottom = 0.5
	trophies_panel.offset_left = -285
	trophies_panel.offset_right = 285
	trophies_panel.offset_top = -205
	trophies_panel.offset_bottom = 205
	var trv := VBoxContainer.new()
	trv.add_theme_constant_override("separation", 12)
	trophies_panel.add_child(trv)
	trophies_lbl = _label(trv, 14, Color(0.95, 0.96, 0.98))
	trophies_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tr_close := _btn(trv, "✕ Close", func():
		trophies_panel.visible = false, Vector2(140, 36), 14)
	tr_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	trophies_panel.visible = false

	# --- Publish-Ready Live-3D Title Screen Overlay
	title_panel = _panel(self, Color(0.04, 0.06, 0.10, 0.92), Color(1.0, 0.84, 0.15, 0.95))
	title_panel.anchor_left = 0.5
	title_panel.anchor_right = 0.5
	title_panel.anchor_top = 0.5
	title_panel.anchor_bottom = 0.5
	title_panel.offset_left = -270
	title_panel.offset_right = 270
	title_panel.offset_top = -185
	title_panel.offset_bottom = 185
	var ttlv := VBoxContainer.new()
	ttlv.add_theme_constant_override("separation", 11)
	title_panel.add_child(ttlv)
	var ttl_head := _label(ttlv, 30, Color(1.0, 0.86, 0.18))
	ttl_head.text = "PLAY KAMPALA"
	ttl_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ttl_tag := _label(ttlv, 13, Color(0.75, 0.92, 1.0))
	ttl_tag.text = "Kampala Boda-Boda & City Life Adventure  •  v1.0"
	ttl_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_sub_lbl = _label(ttlv, 14, Color(0.94, 0.95, 0.97))
	title_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var play_btn := _btn(ttlv, "▶  HIT THE STREETS", func():
		title_panel.visible = false
		main.sfx.play("start", -3.0)
		toast("Welcome to Kampala, %s! Tap 'Ride boda' or explore the streets." % main.rider_name), Vector2(320, 48), 18)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var psty := StyleBoxFlat.new()
	psty.bg_color = Color(0.98, 0.78, 0.12)
	psty.corner_radius_top_left = 10
	psty.corner_radius_top_right = 10
	psty.corner_radius_bottom_left = 10
	psty.corner_radius_bottom_right = 10
	play_btn.add_theme_stylebox_override("normal", psty)
	play_btn.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
	var ttl_row := HBoxContainer.new()
	ttl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ttl_row.add_theme_constant_override("separation", 10)
	ttlv.add_child(ttl_row)
	_btn(ttl_row, "⚙️ Profile & Customize", func():
		title_panel.visible = false
		open_settings(), Vector2(185, 38), 13)
	_btn(ttl_row, "🏆 Kampala Trophies", func():
		title_panel.visible = false
		open_trophies(), Vector2(175, 38), 13)
	title_panel.visible = false

	# --- Flexible Petrol Station Refuel Pump Selector
	fuel_panel = _panel(self, Color(0.05, 0.08, 0.12, 0.96), Color(0.22, 0.88, 0.45, 0.85))
	fuel_panel.anchor_left = 0.5
	fuel_panel.anchor_right = 0.5
	fuel_panel.anchor_top = 0.5
	fuel_panel.anchor_bottom = 0.5
	fuel_panel.offset_left = -260
	fuel_panel.offset_right = 260
	fuel_panel.offset_top = -175
	fuel_panel.offset_bottom = 175
	var fmv := VBoxContainer.new()
	fmv.add_theme_constant_override("separation", 10)
	fuel_panel.add_child(fmv)
	fuel_menu_lbl = _label(fmv, 16, Color(0.95, 0.98, 0.96))
	fuel_menu_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fuel_menu_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fuel_menu_btns = GridContainer.new()
	fuel_menu_btns.columns = 2
	fuel_menu_btns.add_theme_constant_override("h_separation", 8)
	fuel_menu_btns.add_theme_constant_override("v_separation", 8)
	fuel_menu_btns.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fmv.add_child(fuel_menu_btns)
	fuel_panel.visible = false

	# --- end-of-day summary
	summary = _panel(self, Color(0.06, 0.06, 0.08, 0.95), Color(1.0, 0.84, 0.15, 0.7))
	summary.anchor_left = 0.5
	summary.anchor_right = 0.5
	summary.anchor_top = 0.5
	summary.anchor_bottom = 0.5
	summary.offset_left = -300
	summary.offset_right = 300
	summary.offset_top = -250
	summary.offset_bottom = 250
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 14)
	summary.add_child(sv)
	summary_lbl = _label(sv, 19, Color.WHITE)
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_btn = _btn(sv, "Start the next day", func(): main.start_next_day(), Vector2(240, 56), FONT)
	summary_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary.visible = false

	# --- Traffic Police Checkpoint interactive dialog
	police_panel = _panel(self, Color(0.05, 0.08, 0.16, 0.95), Color(0.25, 0.62, 1.0, 0.85))
	police_panel.anchor_left = 0.5
	police_panel.anchor_right = 0.5
	police_panel.anchor_top = 0.5
	police_panel.anchor_bottom = 0.5
	police_panel.offset_left = -310
	police_panel.offset_right = 310
	police_panel.offset_top = -185
	police_panel.offset_bottom = 185
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	police_panel.add_child(pv)
	police_lbl = _label(pv, 18, Color(0.95, 0.97, 1.0))
	police_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	police_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var b0 := _btn(pv, "1. Pay Official Express Penalty Receipt (UGX 10,000)", func(): main.resolve_police(0), Vector2(460, 44), 16)
	b0.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b1 := _btn(pv, "2. Settle on the spot — 'Officer's Soda' (UGX 5,000)", func(): main.resolve_police(1), Vector2(460, 44), 16)
	b1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b2 := _btn(pv, "3. Apologize politely & try to talk your way out", func(): main.resolve_police(2), Vector2(460, 44), 16)
	b2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	police_panel.visible = false

	# --- In-Game Kampala Smartphone UI (Stage App, MoMo Statement, Garage & Fleet, Messages & Saves)
	phone_panel = _panel(self, Color(0.05, 0.07, 0.11, 0.96), Color(1.0, 0.84, 0.15, 0.88))
	phone_panel.anchor_left = 0.5
	phone_panel.anchor_right = 0.5
	phone_panel.anchor_top = 0.5
	phone_panel.anchor_bottom = 0.5
	phone_panel.offset_left = -350
	phone_panel.offset_right = 350
	phone_panel.offset_top = -245
	phone_panel.offset_bottom = 245
	var phv := VBoxContainer.new()
	phv.add_theme_constant_override("separation", 8)
	phone_panel.add_child(phv)
	var tab_row := HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override("separation", 6)
	phv.add_child(tab_row)
	_btn(tab_row, "Stage & Goals", func(): phone_tab = 0; _refresh_phone(), Vector2(142, 36), 14)
	_btn(tab_row, "Mobile Money", func(): phone_tab = 1; _refresh_phone(), Vector2(138, 36), 14)
	_btn(tab_row, "Garage & Empire", func(): phone_tab = 2; _refresh_phone(), Vector2(142, 36), 14)
	_btn(tab_row, "SMS & Saves", func(): phone_tab = 3; _refresh_phone(), Vector2(132, 36), 14)
	_btn(tab_row, "Close (P)", func(): toggle_phone(), Vector2(96, 36), 14)
	phone_lbl = _label(phv, 15, Color(0.95, 0.96, 0.98))
	phone_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_actions = GridContainer.new()
	phone_actions.columns = 2
	phone_actions.add_theme_constant_override("h_separation", 8)
	phone_actions.add_theme_constant_override("v_separation", 6)
	phone_actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	phv.add_child(phone_actions)
	phone_panel.visible = false


func toggle_phone() -> void:
	phone_panel.visible = not phone_panel.visible
	if phone_panel.visible:
		if main.tutorial_step == 3:
			main.tutorial_step = 4
			main.save_game()
		_refresh_phone()
	main.sfx.play("pop", -5.0)


func _refresh_phone() -> void:
	for c in phone_actions.get_children():
		c.queue_free()
	var reg_names := PackedStringArray()
	for k in main.regulars:
		if int(main.regulars[k]) >= 2:
			reg_names.append("%s (%d trips)" % [k, int(main.regulars[k])])
	var regs_str := ", ".join(reg_names) if reg_names.size() > 0 else "Complete 2+ trips for a customer to make them a Regular (+UGX 2,000 bonus!)"
	match phone_tab:
		0:
			var g_trips := int(main.day_stats.get("boda_trips", 0))
			var g_hustles := int(main.day_stats.get("hustles", 0))
			var g_earn := int(main.day_stats.get("fares", 0))
			var c1 := "✓" if int(main.day_stats.get("goal_trips", 0)) > 0 else ("%d/3" % mini(g_trips, 3))
			var c2 := "✓" if int(main.day_stats.get("goal_hustles", 0)) > 0 else ("%d/2" % mini(g_hustles, 2))
			var c3 := "✓" if int(main.day_stats.get("goal_earn", 0)) > 0 else ("%dk/25k" % mini(int(g_earn / 1000), 25))
			var cur_dist: String = main.district_at(main.player.position)
			var d_lv: int = main.district_level(cur_dist)
			var spin_txt := "🎁 Daily Spin READY!" if main.daily_spin_day < main.day else "✓ Spun Today"
			var vip_s := "   •   🎫 2x VIP Ticket ACTIVE!" if main.vip_ticket else ""
			phone_lbl.text = "KAMPALA STAGE APP  •  %s (★ %.1f / 5.0)%s\n" % [main.player_rank(), main.rating, vip_s] + \
				"• %s Respect: Lv.%d (+%d%% Fares)   •   Active Job: %s\n" % [cur_dist, d_lv, (d_lv - 1) * 10, job_text if job_text != "" else "Waiting..."] + \
				"• Regular Customers: %s\n\n" % regs_str + \
				"🏆 TODAY'S HUSTLE CHALLENGES (Instant Mobile Money Bonus!):\n" + \
				"  [%s] 3 Boda Trips (+UGX 8,000)   •   [%s] 2 Foot Hustles (+UGX 7,000)   •   [%s] Earn 25k (+UGX 10,000)\n\n" % [c1, c2, c3] + \
				"9 ON-FOOT SIDE HUSTLES: Rolex Stand • Muchomo Grill • MoMo Kiosk • Fruit Cart • Boda Fundi • Airtime Table • Kibanda TV • Owino Market • Taxi Park"
			_btn(phone_actions, spin_txt, func():
				main.spin_daily_wheel()
				_refresh_phone(), Vector2(210, 36), 14)
			_btn(phone_actions, "Dispatch Normal Call", func():
				if main.jobs:
					main.jobs.new_job()
					_refresh_phone(), Vector2(210, 36), 14)
			_btn(phone_actions, "🔥 Urgent Express (1.85x!)", func():
				if main.jobs:
					main.jobs.new_job("urgent")
					toggle_phone(), Vector2(210, 36), 14)
			_btn(phone_actions, "🌟 VIP Landmark Charter", func():
				if main.jobs:
					main.jobs.new_job("vip_tour")
					toggle_phone(), Vector2(210, 34), 14)
			_btn(phone_actions, "🥚 Fragile Cargo (+60%!)", func():
				if main.jobs:
					main.jobs.new_job("fragile")
					toggle_phone(), Vector2(210, 34), 14)
			_btn(phone_actions, "🎨 Paint: %s" % main.bike_paint_name(), func():
				main.cycle_bike_paint()
				_refresh_phone(), Vector2(210, 34), 14)
			_btn(phone_actions, "★ Route to Street Promo", func():
				main.route_to_event(false)
				toggle_phone(), Vector2(210, 34), 14)
		1:
			var log_str := "\n".join(main.momo_log.slice(0, 8)) if not main.momo_log.is_empty() else "No transactions yet today."
			phone_lbl.text = "MTN / AIRTEL MOBILE MONEY STATEMENT  •  Rank: %s\n" % main.player_rank() + \
				"Balance: UGX %s   •   Today's Fares: UGX %s   •   Tips & Bonuses: UGX %s\n" % [
					main.ugx(main.money), main.ugx(main.day_stats.get("fares", 0)), main.ugx(main.day_stats.get("tips", 0))] + \
				"Boda Status: %s   •   Passive Empire Income: +UGX %s/day (%d Riders & Stalls)\n\n" % [
					"OWNED (0 Rent!)" if main.owns_boda else ("Rented (-UGX 10,000/day)"),
					main.ugx(main.daily_passive_income()), main.hired_riders] + \
				"RECENT TRANSACTIONS:\n" + log_str
		2:
			phone_lbl.text = "KATWE GARAGE & KAMPALA BUSINESS EMPIRE  (Balance: UGX %s  •  Passive: +UGX %s/day)\n" % [
				main.ugx(main.money), main.ugx(main.daily_passive_income())] + \
				"Buy rider gear, upgrade your bike, or invest in Kampala street businesses for daily passive income:"
			var items := [
				["repair", "Repair Boda (4k • %d%%)" % int(roundf(main.player.bike_health)), main.player.bike_health >= 99.0],
				["helmet", "Helmet (15k)", main.has_helmet],
				["vest", "Reflector Vest (10k)", main.has_vest],
				["permit", "Riding Permit (25k)", main.has_permit],
				["jacket", "Rain Jacket (20k)", main.has_rain_jacket],
				["tank", "6.5L Fuel Tank (35k)", main.has_big_tank],
				["engine", "Boxer 150cc HD (60k)", main.bike_level >= 1],
				["rolex_biz", "Own Rolex Stand (45k • +6k/d)", main.owns_rolex_stand],
				["tv_biz", "Own Kibanda TV (75k • +10k/d)", main.owns_kibanda_tv],
				["momo_biz", "Own MoMo Kiosk (110k • +14k/d)", main.owns_momo_kiosk],
				["hire_rider", "Hire Rider #%d (120k • +15k/d)" % (main.hired_riders + 1), main.hired_riders >= 5],
				["matatu_biz", "Own Matatu Taxi (350k • +35k/d)", main.owns_matatu],
				["own_boda", "Own Boda Title (500k • 0 Rent)", main.owns_boda],
			]
			for it in items:
				var k: String = it[0]
				var label_s: String = ("✓ " + str(it[1])) if bool(it[2]) else ("Buy " + str(it[1]))
				_btn(phone_actions, label_s, func():
					main.buy_upgrade(k)
					_refresh_phone(), Vector2(295, 28), 13)
		3:
			var sms_str := "\n\n".join(main.sms_list.slice(0, 5)) if not main.sms_list.is_empty() else "No messages."
			phone_lbl.text = "INBOX MESSAGES & SAVE SLOTS  (Active: Slot %d)\n\n%s" % [main.save_slot, sms_str]
			for s: int in [1, 2, 3]:
				var sl: int = s
				_btn(phone_actions, ("✓ Save Slot %d (Active)" % sl) if main.save_slot == sl else ("Switch to Save Slot %d" % sl), func():
					main.switch_save_slot(sl)
					_refresh_phone(), Vector2(210, 36), 14)
			_btn(phone_actions, "Replay Day 1 Tutorial", func():
				main.tutorial_step = 0
				toggle_phone(), Vector2(210, 36), 14)


func _panel(parent: Node, col: Color, border := Color(1, 1, 1, 0.12)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _label(parent: Node, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
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


func toast(text: String) -> void:
	toast_lbl.text = text
	_toast_time = 4.2
	toast_history.push_front("[%s] %s" % [main.time_str() if main else "07:00", text.replace("\n", " ")])
	if toast_history.size() > 10:
		toast_history.resize(10)
	if msg_btn:
		msg_btn.text = "💬 Alerts (%d)" % toast_history.size()
	if msg_drawer and msg_drawer.visible:
		_refresh_messages_drawer()


func _refresh_messages_drawer() -> void:
	if not msg_drawer_lbl:
		return
	if toast_history.is_empty():
		msg_drawer_lbl.text = "No alerts or messages yet. Ride around Kampala to receive stage calls & promos!"
	else:
		msg_drawer_lbl.text = "\n\n".join(toast_history.slice(0, 6))


func toggle_messages_drawer() -> void:
	if not msg_drawer:
		return
	msg_drawer.visible = not msg_drawer.visible
	if msg_drawer.visible:
		_refresh_messages_drawer()
	if main and main.sfx:
		main.sfx.play("pop", -5.0)


func spawn_money_pop(amount: int) -> void:
	if amount <= 0 or not money_pop_lbl:
		return
	money_pop_lbl.text = "+UGX %s!" % main.ugx(amount)
	money_pop_lbl.offset_top = 42.0
	money_pop_lbl.modulate.a = 1.0
	money_pop_lbl.visible = true
	_money_pop_t = 1.65


func show_summary(text: String, button_text: String) -> void:
	summary_lbl.text = text
	summary_btn.text = button_text
	summary.visible = true


func hide_summary() -> void:
	summary.visible = false


func show_police(missing_str: String) -> void:
	police_lbl.text = "TRAFFIC POLICE CHECKPOINT\n\n\"Oli otya, boda! Pull over!\"\nThe officer checks your bike and points out you are missing: %s.\n(Tip: Buy Helmet, Reflector Vest & Permit at the Downtown Boda Stage)" % missing_str
	police_panel.visible = true


func hide_police() -> void:
	police_panel.visible = false


## Floating joystick: the first finger that lands on the left 40% of the
## screen becomes the stick. Other fingers still rotate/zoom the camera.
func _input(e: InputEvent) -> void:
	if summary.visible or police_panel.visible:
		return
	if e is InputEventScreenTouch:
		var vs := get_viewport().get_visible_rect().size
		# a finger-lift the phone never reported must not lock the stick forever
		if e.pressed and _joy_index != -1 and Time.get_ticks_msec() - _joy_last > 600:
			_joy_index = -1
		if e.pressed and _joy_index == -1 and not bigmap.visible and not phone_panel.visible and not fuel_panel.visible and not settings_panel.visible and not title_panel.visible and not trophies_panel.visible and not (main.life and main.life.modal_open()) and e.position.x < vs.x * 0.45 and e.position.y > vs.y * 0.32:
			_joy_last = Time.get_ticks_msec()
			_joy_index = e.index
			var pad_t := Vector2(102.0, vs.y - 102.0)
			stick.center = pad_t if e.position.distance_to(pad_t) <= 125.0 else e.position
			var vt: Vector2 = ((e.position - stick.center) / JOY_RADIUS).limit_length(1.0)
			stick.knob = vt
			joy = Vector2(vt.x, -vt.y)
			stick.active = true
			stick.queue_redraw()
			get_viewport().set_input_as_handled()
		elif not e.pressed and e.index == _joy_index:
			_joy_index = -1
			joy = Vector2.ZERO
			stick.knob = Vector2.ZERO
			stick.active = false
			stick.queue_redraw()
			get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag and e.index == _joy_index:
		_joy_last = Time.get_ticks_msec()
		var v: Vector2 = (e.position - stick.center) / JOY_RADIUS
		v = v.limit_length(1.0)
		stick.knob = v
		joy = Vector2(v.x, -v.y)
		stick.queue_redraw()
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var vs2 := get_viewport().get_visible_rect().size
		var pad_c := Vector2(102.0, vs2.y - 102.0)
		if e.pressed and _joy_index == -1 and not bigmap.visible and not phone_panel.visible and not fuel_panel.visible and not settings_panel.visible and not title_panel.visible and not trophies_panel.visible and not (main.life and main.life.modal_open()) and e.position.distance_to(pad_c) <= 92.0:
			_joy_index = 999
			_joy_last = Time.get_ticks_msec()
			stick.center = pad_c
			var vm: Vector2 = ((e.position - stick.center) / 68.0).limit_length(1.0)
			stick.knob = vm
			joy = Vector2(vm.x, -vm.y)
			stick.active = true
			stick.queue_redraw()
			get_viewport().set_input_as_handled()
		elif not e.pressed and _joy_index == 999:
			_joy_index = -1
			joy = Vector2.ZERO
			stick.knob = Vector2.ZERO
			stick.active = false
			stick.queue_redraw()
	elif e is InputEventMouseMotion and _joy_index == 999:
		_joy_last = Time.get_ticks_msec()
		var vm2: Vector2 = (e.position - stick.center) / 68.0
		vm2 = vm2.limit_length(1.0)
		stick.knob = vm2
		joy = Vector2(vm2.x, -vm2.y)
		stick.queue_redraw()
		get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_E or e.keycode == KEY_SPACE:
			main.player_action()
		elif e.keycode == KEY_H:
			if main.player.on_boda:
				main.player_horn()
		elif e.keycode == KEY_M:
			toggle_map()
		elif e.keycode == KEY_P:
			toggle_phone()
		elif e.keycode == KEY_R:
			if main.sfx:
				var st_name: String = main.sfx.cycle_radio()
				radio_btn.text = main.sfx.radio_short_label()
				toast("📻 Radio tuned to: %s" % st_name)
		elif e.keycode == KEY_N:
			if main.sfx:
				var st_name2: String = main.sfx.skip_song()
				radio_btn.text = main.sfx.radio_short_label()
				toast("📻 %s" % st_name2)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_joy_index = -1
		joy = Vector2.ZERO
		if stick:
			stick.active = false
			stick.queue_redraw()


func _process(delta: float) -> void:
	rain_btn.text = "Rain: " + ("on" if main.raining else "off")
	power_btn.text = "Power: " + ("on" if main.power_on else "CUT")
	speed_btn.text = "Time x%d" % main.time_speed

	var t: float = main.time_of_day
	var h := int(t)
	var m := int((t - h) * 60.0)
	info.text = "FPS %d   draw calls %d" % [
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
	var gear := PackedStringArray()
	if main.has_helmet:
		gear.append("Helmet")
	if main.has_vest:
		gear.append("Vest")
	if main.has_permit:
		gear.append("Permit")
	if main.bike_level >= 1:
		gear.append("150cc")
	var gear_str := ("  •  [" + "/".join(gear) + "]") if gear.size() > 0 else ""
	money_lbl.text = "MoMo UGX %s  •  %s (%s • ★ %.1f)%s" % [main.ugx(main.money), main.rider_name, main.home_stage_name(), main.rating, gear_str]
	var own_str: String = ("OWNED (%d Riders)" % main.hired_riders) if main.owns_boda else ("Own Boda: %d%%" % int(clampf(float(main.money) / main.GOAL * 100.0, 0.0, 100.0)))
	var st_here: String = main.street_at(main.player.position) if main.has_method("street_at") else ""
	var loc_str: String = ("%s (%s)" % [st_here, main.district_at(main.player.position)]) if st_here != "" else main.district_at(main.player.position)
	day_lbl.text = "Day %d  •  %02d:%02d  •  %s%s%s%s  •  %s" % [
		main.day, h, m,
		loc_str,
		"  •  RUSH HOUR" if main.is_rush_hour() else "",
		"  •  Rain" if main.raining else "",
		"  •  Power Cut" if not main.power_on else "",
		own_str]
	var f: float = main.player.fuel_fraction()
	fuel_fill.size.x = maxf(4.0 if f <= 0.0 else 0.0, 180.0 * f)
	var pulse_warn := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
	if f <= 0.0:
		fuel_fill.color = Color(1.0, 0.18, 0.15).lerp(Color(1.0, 0.75, 0.1), pulse_warn)
		fuel_lbl.text = "EMPTY! [Tap F]"
		fuel_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	elif f <= 0.25:
		fuel_fill.color = Color(1.0, 0.25, 0.18).lerp(Color(1.0, 0.82, 0.15), pulse_warn)
		fuel_lbl.text = "LOW FUEL (%d%%)" % int(roundf(f * 100.0))
		fuel_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
	else:
		fuel_fill.color = Color(0.25, 0.92, 0.42)
		fuel_lbl.text = "Fuel"
		fuel_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	if main.player.is_broken():
		var fi: Dictionary = main.nearest_fundi_info() if main.has_method("nearest_fundi_info") else {}
		speed_lbl.text = ("SPOILED! Fix @ %s (%dm)" % [fi.get("name", "Fundi"), int(fi.get("dist", 0))]) if not fi.is_empty() else "BROKEN (0%) — Repair!"
		speed_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.22))
	elif main.player.is_pushing_boda():
		speed_lbl.text = "PUSHING (0L)"
		speed_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.22))
	elif main.player.is_swimming:
		speed_lbl.text = "SWIMMING 🏊"
		speed_lbl.add_theme_color_override("font_color", Color(0.28, 0.92, 1.0))
	elif main.player.on_boda:
		var hp_warn := ""
		if main.player.bike_health <= 35.0:
			var fi2: Dictionary = main.nearest_fundi_info() if main.has_method("nearest_fundi_info") else {}
			hp_warn = (" • 🔧%d%% (Fundi %dm)" % [int(roundf(main.player.bike_health)), int(fi2.get("dist", 0))]) if not fi2.is_empty() else (" • 🔧%d%%" % int(roundf(main.player.bike_health)))
		speed_lbl.text = "%d km/h%s" % [int(roundf(main.player.speed * 3.2)), hp_warn]
		speed_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.25) if main.player.bike_health <= 35.0 else Color(0.55, 0.9, 1.0))
	else:
		speed_lbl.text = "On Foot"
		speed_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))

	var modal_up: bool = phone_panel.visible or bigmap.visible or summary.visible or police_panel.visible or fuel_panel.visible or settings_panel.visible or title_panel.visible or trophies_panel.visible
	if stick:
		stick.visible = not modal_up
		if main.player:
			stick.speed_ratio = clampf(main.player.speed / main.player.BODA_MAX, 0.0, 1.0) if main.player.on_boda else clampf(main.player.speed / main.player.WALK_SPEED, 0.0, 1.0)
			stick.boosting = main.player.boosting
			var kv := Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
			if Input.is_key_pressed(KEY_D): kv.x += 1.0
			if Input.is_key_pressed(KEY_A): kv.x -= 1.0
			if Input.is_key_pressed(KEY_S): kv.y += 1.0
			if Input.is_key_pressed(KEY_W): kv.y -= 1.0
			stick.key_vec = kv.limit_length(1.0)
		stick.queue_redraw()
	# Interactive Street Encounter card
	if not modal_up and not main.active_encounter.is_empty():
		enc_lbl.text = "%s\n%s" % [str(main.active_encounter.get("title", "")), str(main.active_encounter.get("body", ""))]
		enc_btn_a.text = str(main.active_encounter.get("a", "Yes"))
		enc_btn_b.text = str(main.active_encounter.get("b", "No"))
		enc_panel.visible = true
	else:
		enc_panel.visible = false
	# 1. Minimizable Job Panel (with smart Skip / Break / On-Foot Errand controls)
	if (job_text != "" or main.jobs.state == -1) and not modal_up:
		if job_minimized:
			var short_j := job_text.split("\n")[0]
			if short_j.length() > 42:
				short_j = short_j.substr(0, 40) + "…"
			job_lbl.text = "📍 " + short_j
			job_panel.offset_left = -260
			job_panel.offset_right = 260
		else:
			job_lbl.text = job_text
			job_panel.offset_left = -380
			job_panel.offset_right = 380
		job_skip_btn.visible = (not job_minimized) and main.jobs.state == 0
		job_errand_btn.visible = (not job_minimized) and main.jobs.state == -1 and (main.player.is_broken() or main.player.fuel <= 0.0)
		job_mode_btn.visible = not job_minimized
		job_mode_btn.text = "⏸️ Break" if main.jobs.dispatch_online else "▶ Online"
		job_panel.visible = true
	else:
		job_panel.visible = false

	# 2. Interactive, Auto-Adapting & Closable Tutorial Coach
	var tut: String = main.tutorial_text()
	if tut != "" and not modal_up:
		var s_idx := clampi(main.tutorial_step, 0, 3)
		var dots := ""
		for di in 4:
			dots += "● " if di <= s_idx else "○ "
		tut_dots_lbl.text = "QUICK GUIDE %d/4   %s" % [s_idx + 1, dots.strip_edges()]
		tut_lbl.text = tut
		tut_next_btn.text = "Done ✓" if s_idx >= 3 else "Next →"
		tut_panel.offset_top = 152 if not job_panel.visible else (146 if job_minimized else 166)
		tut_panel.visible = true
	else:
		tut_panel.visible = false

	# 3. Floating +UGX Celebration Popup
	if _money_pop_t > 0.0:
		_money_pop_t -= delta
		money_pop_lbl.offset_top -= delta * 26.0
		money_pop_lbl.modulate.a = clampf(_money_pop_t * 1.4, 0.0, 1.0)
		if _money_pop_t <= 0.0:
			money_pop_lbl.visible = false

	if modal_up and msg_drawer.visible:
		msg_drawer.visible = false

	var label: String = main.action_label()
	action_btn.visible = label != "" and not summary.visible and not police_panel.visible and not phone_panel.visible and not bigmap.visible
	var show_boda_btns: bool = main.player.on_boda and not main.player.is_pushing_boda() and not bigmap.visible and not police_panel.visible and not phone_panel.visible
	horn_btn.visible = show_boda_btns
	boost_btn.visible = show_boda_btns
	if show_boda_btns:
		var bpct := int(roundf(main.player.boost_energy * 100.0))
		boost_btn.text = ("⚡ BOOST! %d%%" % bpct) if main.player.boosting else ("⚡ Boost %d%%" % bpct)
	action_btn.text = label

	if _voice_time > 0.0:
		_voice_time -= delta
		voice_panel.visible = not modal_up
		voice_panel.modulate.a = clampf(_voice_time * 1.3, 0.0, 1.0)
	else:
		voice_panel.visible = false
	if _toast_time > 0.0:
		_toast_time -= delta
		var life_btm: bool = main.life != null and ((main.life.chips.visible and not main.life.chips_min) or main.life.card.visible or main.life.overlay.visible)
		toast_panel.offset_top = -268 if life_btm else -108
		toast_panel.offset_bottom = -188 if life_btm else -28
		toast_panel.visible = not modal_up
		toast_panel.modulate.a = clampf(_toast_time * 1.2, 0.0, 1.0)
	else:
		toast_panel.visible = false

