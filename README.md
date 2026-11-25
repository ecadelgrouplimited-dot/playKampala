# PlayKampala

A first look at PlayKampala in the low-poly, Townscaper-style 3D we picked.
It's one Kampala crossroads, and everything in it is generated from code, so
there are no art files to manage yet.

## What's in the scene

- Shop-house rows with arcades (verandas over the pavement), painted
  signboards, rooftop water tanks, iron-sheet (mabati) roofs and balconies
  with washing
- Some buildings painted solid telecom yellow and red, but with no logos
- Matatus with the blue-and-white checked band, cars, and bodas weaving at
  the road edge, with riders in reflective vests, some without helmets
- Traffic drives on the **left**, the way it does in Uganda
- A boda stage on the pavement, a rolex stand with a glowing charcoal stove,
  a market shed with produce stalls, a taxi park, muzigo rental rows, a
  dusty football pitch with kids playing, mango, jacaranda and banana
  trees, red murram soil, potholes (some full of water), open drains,
  black-and-yellow curbs, and hills on the horizon
- People walking, some carrying jerrycans, matooke or baskets on their heads
- **Day and night**: windows, shops and street lights come on at dusk
- **Rain**: the sky turns grey, the road gets shiny, people hurry and
  umbrellas come out
- **Power cut**: the lights go off, except one building on a generator
  and the rolex stand's charcoal

## Reference-Art 3D Character, Vehicle & Arched Boulevard Overhaul (v1.2.0 / v6.0)
- **Zero-Stick Sculpted Organic Anatomy (`scripts/mesh_sculpt.gd`, `scripts/person.gd`, `scripts/main.gd`)**:
  - Added smooth revolved 3D lathe anatomy (`MeshSculpt.lathe_profile`) and `ArrayMesh` skinning in `Person._skinned_mesh()` so every rider, man, and woman has contoured athletic/curvy torsos, rounded deltoid sleeves, muscular forearms, overlapping thighs & calves (zero stick cylinders or joint gaps), sculpted jawlines, full Ugandan hairstyles, and white-soled sneakers.
  - Upgraded the default Boda Rider (`_seated()` & `apply_bike_paint()`) to match the PlayKampala cover & icon art 1-to-1: **open-face golden-yellow Kampala boda helmet** with front curved clear visor, **open high-vis yellow reflector vest with twin silver reflective stripes** layered over a charcoal short-sleeve T-shirt, two-segment bent muscular forearms gripping the handlebars, and indigo jeans.
- **5-Spoke Cast-Alloy Wheels, Detailed Bajaj Boxer & Framed Matatu Windows (`scripts/mesh_sculpt.gd`, `scripts/main.gd`)**:
  - Added `MeshSculpt.spoked_wheel_pair()` (smooth 3D torus rubber tyres + open 5-spoke cast-alloy wheels) across motorcycles, matatus, and sedans.
  - Upgraded `model_boda()` with finned cylinder block, silver crankcase, tubular chrome engine crash-guard, twin round speedometers above the chrome-rimmed headlamp, amber stalk indicators, side panels, tail cowl, and chrome rear grab-rail hoop; added individual framed side window bays & rooftop route sign on `model_taxi()` and exterior-visible framed glass on `model_car()`.
- **3D Arched Kampala Veranda Colonnades, Ringed Palms & Stylized Sunlit Shaders (`scripts/main.gd`, `scripts/endless_world.gd`)**:
  - Added `MeshSculpt.arch_spandrel()` semi-circular masonry arches, column plinths, wrought-iron upper loggia railings, classical eaves, and potted tropical plants along `shop_house()` streets, plus 7-segment ringed curved palm trunks (`model_tree(0)`) with 12 layered V-folded tropical fronds and crisp cream road edge lines across all city streets & endless highways.
  - Upgraded `mat_agent` and `mat_solid` with warm golden-sun + cool cerulean-sky hemisphere bounce and golden Fresnel rim highlights matching the official artwork.

## First-Class Realism, Endless Streaming World & Deep Kampala Life Overhaul (v1.1.0 / v5.0)
- **Grounded Ugandan Palette, Architectural AO Shader & Contact Shadows** (`scripts/main.gd`, `project.godot`):
  - Enabled 4× MSAA (`msaa_3d=2`) and crisp `4096` soft directional shadows (`soft_shadow_filter_quality=3`).
  - Upgraded `mat_solid` to a custom world-space architectural shader with triplanar plaster micro-grain, lower-wall ground-contact ambient occlusion (`0..0.52m`), and authentic Ugandan red-laterite lower-wall dust splash (`0..0.68m`).
  - Added soft under-chassis contact shadow blobs (`_attach_contact_shadow()`) under every boda, matatu, car, bus, and 40ft trailer, replaced toy-saturated wall/cloth palettes with cohesive sun-bleached Kampala earth/plaster tones, and decluttered streets with weathered concrete mid-block curbs + yellow/black safety kerbs only at junctions.
  - Slimmed the top wallet & job HUD into sleek translucent glass bars (`scripts/hud.gd`, `scripts/life.gd`) so ~90% of the viewport showcases the 3D streets, palms, and skyline.
- **Non-Ending Streaming Suburbs, Villages & Inter-District Highways** (`scripts/endless_world.gd`, `scripts/player.gd`, `scripts/main.gd`):
  - Added `EndlessWorld`, a real-time `96m × 96m` (`5×5` active grid) chunk streamer with deterministic procedural generation and clean chunk unloading + dynamic place/mud-road registration.
  - Ride infinitely along **Jinja–Mukono–Lugazi Highway** (`Bweyogerere → Kira → Seeta → Mukono → Lugazi`), **Bombo–Luweero–Gulu Highway** (`Kawempe → Matugga → Bombo → Wobulenzi`), **Masaka–Wakiso Highway** (`Nateete → Buloba → Wakiso → Mpigi`), and **Entebbe Highway** (`Kajjansi → Kisubi`), or turn onto endless red laterite murram/mud village feeder tracks.
  - Streams realistic **Walled Suburb Bungalow Estates** (perimeter walls, sliding gates, solar panels, Crest water tanks, compounds), **Developing Construction Plots** (unfinished red-brick storied houses, eucalyptus timber scaffolding, sand heaps & brick stacks), **Suburb Trading Centres** (Pork Joints, Kinyozi Salons, Hardware, MoMo & Stages), **Community Boreholes** (with yellow 20L jerrycan queues), **Primary Schools**, and **Matooke Shamba Farms**.
- **New Authentic Kampala & Suburb Life Activities** (`scripts/life.gd`):
  - **Rural-to-City Matooke Trading Loop**: Buy wholesale Shamba Matooke & Village Eggs at suburb/village farms (`UGX 4,500`, visible on your carrier) and sell them at any City Market for `UGX 11,000` (`+UGX 6,500` trader profit), or help harvest in the shamba (`+UGX 4,500`).
  - **Community Borehole & Construction Hustles**: Pump cool fresh borehole water for free, carry 20L yellow jerrycans for suburb neighbours (`+UGX 3,000`), mix mortar & stack red clay bricks at suburb building sites (`+UGX 6,500`), or buy Tororo Cement toward your future plot.
  - **Driving School, Executive Kinyozi, Pork Joints, Yaka! & Street Football**: Earn your Official Riding Permit via the Driving School Road Test (`UGX 18,000`), get rating-boosting skin-fades or box-braids at salons, pay room Yaka! electricity tokens or Stage Data Bundles (instant VIP call) at MoMo kiosks, feast at suburb Pork Joints, and join 5-aside street football kickabouts.

## Sculpted 3D Vehicles, Palm Boulevards & Street-Level Chase Camera (v4.0)
- **Procedural 3D Mesh Sculptor** (`scripts/mesh_sculpt.gd` + `scripts/mesh_baker.gd`): Added beveled 2D-to-3D profile extrusion (`extrude_profile`), curved tropical palm/banana fronds (`curved_frond`), and faceted low-poly foliage canopies (`faceted_canopy`) baked directly into merged single-draw-call meshes.
- **Zero-Box Sculpted Vehicles**: Replaced boxy vehicle primitives with a sculpted teardrop-tank **Bajaj Boxer boda-boda** (raked chrome forks, curved fender, round headlamp, twin orange coil shocks, alloy hubs & side mirrors), sloped-windshield **Toyota HiAce Kampala matatu**, and aerodynamic **3-box sedans**.
- **Cinematic Street-Level Chase Camera & Golden Equatorial Atmosphere** (`scripts/camera_rig.gd`, `scripts/main.gd`):
  - Default camera upgraded to low street-level chase (`-13.5°`, `dist = 9.0`, `fov = 50°`) with gentle auto-align while riding (`View` cycles `street` / `cruise` / `top`).
  - Added lush curved palm trees & matooke banana groves lining Kampala boulevards, sloped colorful shop awnings, warm golden Kampala sunlight & horizon haze, and closer iconic Seven Hills with the golden-domed Gaddafi National Mosque on the horizon.

## Natural Forward Walking & Solid AI-to-AI Collisions / Accidents (v1.0.2)
- **Natural Forward Walking Controls** (`scripts/player.gd`): Replaced instant sideways velocity snapping with a clean `0.12` thumbstick deadzone, smooth walk acceleration/deceleration (`move_toward`), crisp heading alignment (`18.0 * delta`), and forward-locked walking movement so the character always walks smoothly in the direction they face.
- **Zero Vehicle Ghosting & Real AI-to-AI Road Accidents** (`scripts/car.gd`, `scripts/main.gd`):
  - Removed the `_ignore` stuck-timer ghosting hack that previously let stopped taxis drive through other vehicles after 4.2 seconds.
  - Added exact Separating-Axis OBB vehicle overlap blocking (`_find_overlap_vehicle()`) before every vehicle step, non-overlapping traffic spawning in `_spawn_car()`, and physical junction clearance verification in `request_junction()`.
  - Added real **AI-to-AI Traffic Accidents** (`on_ai_accident()`): vehicles that collide at speed halt together as real road obstacles with impact tilt, crash audio, horns, and live Kampala street subtitles while traffic queues behind them.

## Character Rig Fix & Upgraded Player, Men & Women Models (v1.0.1)
- **Fixed Duplicate Skeleton / Flashing Clothes Bug** (`scripts/person.gd`, `scripts/main.gd`): Updated `Person.build()` to reuse the existing `Skeleton3D` & `MeshInstance3D` instead of spawning stacked skeletons on every outfit/paint update, and eliminated double-building in `_spawn_player()` plus random skin/trouser re-rolls in `apply_bike_paint()` and `_seated()`.
- **Upgraded Men, Women & Rider Models** (`model_human()` & `_seated()` in `scripts/main.gd`, `Person.animate()` in `scripts/person.gd`):
  - Distinct male (broad shoulders, belt & buckle, collar, fade hair) and female (contoured waist/hips, kitenge/ankara bordered skirts, gomesi puffed shoulders, handbags, braids/locs, high afro puff, and kitenge headwraps) silhouettes.
  - Expressive faces with sclera + iris eyes, eyebrows, ears, nose, and smile lines, plus calibrated natural walking stride cadence.
  - Added a **Rider Style (`Man` / `Woman`)** toggle in `⚙️ Settings` (persisted in saves).

## Publish-Ready Release — Live-3D Title Screen, Kampala Trophies, Suburb Express & FPS Boost (v1.0.0 / v3.1)
- **Live-3D Title Screen & Release Metadata**: Renamed project to `PlayKampala` (`version/name="1.0.0"`, `version/code=31`), added a sleek live-3D **PLAY KAMPALA** launch screen (`title_panel` in `scripts/hud.gd`) displaying Rider Name, Home Stage, Day, MoMo balance & Trophies with instant `▶ HIT THE STREETS`, `⚙️ Profile & Customize`, and `🏆 Kampala Trophies` buttons.
- **8 Kampala Trophies / Achievements**: Persistent milestone rewards (`ACHIEVEMENTS`, `unlock_achievement()` in `scripts/main.gd`) covering First Hustle, Stage Regular, Murram & Mud Warrior, Upcountry Highway Rider, Sparkling Clean, Five-Star Legend, Boda Boss, and Lake Victoria Swimmer — each paying instant MoMo bonuses.
- **Inter-District / Suburb Express Missions**: Added `suburb_express` jobs in `scripts/jobs.gd` (+70% fare bonus) sending riders out to Bweyogerere/Mukono, Kawempe/Kisaasi, Nateete/Wakiso, and Kajjansi Entebbe Rd.
- **Mobile Performance & Clean Publish HUD**: Optimized shadows (`SHADOW_ORTHOGONAL`), disabled multi-pass full-screen glow while keeping textured roads/murram/water/buildings & ACES color grading, and hid the raw developer FPS/draw-call overlay by default (toggleable via `⚙️ Tools` → `📊 FPS`).

## Graphics Overhaul, Kampala Suburbs, Murram/Mud Roads & Inter-District Highways (v3.0)
- **Procedural Textured Graphics & ACES Lighting Overhaul** (`scripts/main.gd`):
  - Added synchronous seamless `FastNoiseLite` albedo & bump-to-normal maps (`_make_noise_textures()`) with triplanar mapping across asphalt roads (`mat_road`), buildings/concrete (`mat_solid`), Ugandan red laterite murram (`mat_murram`), and animated shimmering Lake Victoria water (`mat_water`).
  - Upgraded vehicles & characters (`mat_agent`) with semi-gloss automotive specular + rim lighting, switched environment lighting to `TONE_MAPPER_ACES` + `AMBIENT_SOURCE_SKY` + equatorial color grading + 2-split directional shadows, and added dynamic wet-road/wet-mud reflections during Kampala rain.
- **4 Inter-District Highways, Living Suburbs & Red Murram/Mud Roads** (`_build_suburbs_and_highways()`, `_add_murram_road()`, `_add_suburb_bungalow()`, `_add_banana_patch()`):
  - Expanded playable world bounds (`HALF + 102m` in `scripts/player.gd`) with 4 overhead-gantry Ugandan highways: **Jinja–Mukono Highway** (`Bweyogerere / Kira`), **Gulu–Bombo Highway** (`Kawempe / Kisaasi`), **Masaka–Mbarara Highway** (`Nateete / Wakiso`), and **Entebbe Airport Highway** (`Kajjansi`).
  - Added red laterite murram/mud feeder roads with wheel ruts, muddy puddles, walled suburb bungalows, matooke banana plantations, brick kilns, and suburb stages.
  - Added real mud/murram riding physics (`in_mud_road()`): dry murram rumble (`86%` speed) and slippery rainy mud (`66%` speed + mud warning).
  - Updated the Full Map (`scripts/hud.gd`) to display all 4 Inter-District Highways, Suburb Murram Roads, highway labels, and a **`🏡 Suburbs & Hwys`** Map Finder filter.

## Solid OBB Vehicle/Obstacle Collisions, Emotions & Roadside Confrontations (v2.0)
- **Solid Oriented-Box (OBB) Collisions**: Replaced the old `2.8m` circle check in `scripts/player.gd` (`_resolve_agent_collisions()` and `_check_crash()`) with exact oriented bounding-box (OBB) collision against all cars, matatus, bodas, buses, and 40ft trailers, plus added static `collide()` boxes on roadwork barriers and washing-bay obstacles so motorcycles and vehicles can no longer pass through each other or props.
- **Accidents, Emotions & Roadside Confrontations**: Collisions now drop rider Mood/Energy, damage `bike_health`, and trigger an interactive **Roadside Confrontation** (`trigger_accident_confrontation()` & `resolve_encounter()` in `scripts/main.gd`) with angry drivers, fellow boda riders, or bystanders — letting you either apologize & settle calmly (+Mood) or argue/speed off (risking heated crowd fines, -Rating, and -18 Mood).

## Real Fuel Consumption & Rider/Stage/Boda Customization (v1.9)
- **Realistic Speed- & Boost-Scaled Fuel Consumption**: Fixed `LITRES_PER_METRE` (`0.00028` in `scripts/player.gd`) and added throttle/boost load scaling (`load_mult`), so `1.0 L` (`UGX 5,000`) lasts ~3.5–4.5 minutes while a `4.0 L` full tank lasts ~15 minutes (~4x longer) and `6.5 L` Big Tank lasts ~23 minutes.
- **Rider Identity, Multi-Stage Selection & Customization (`⚙️ Settings`)**: Added a persistent Rider Profile & Customization modal (`settings_panel` in `scripts/hud.gd`, `set_customization()` in `scripts/main.gd`) accessible under `⚙️ Tools` -> `⚙️ Settings`:
  - **Rider Name & Home Stage**: Set your custom rider name and choose from 8 Kampala stages (`Old Taxi Park Stage`, `Kikuubo Arcade Stage`, `Wandegeya Stage`, `Nakasero Market Stage`, `Clock Tower Stage`, `Nakawa Junction Stage`, `Kololo Airstrip Stage`, `Ggaba Beach Stage`), displayed on the status bar and saved for multiplayer readiness.
  - **Live 3D Motorcycle & Clothes Customization**: Switch between 6 motorcycle paints and 5 rider outfits with instant 3D updates on your walking character, seated rider, and parked boda.

## Heavy Traffic (Buses & Trailers), Road Repairs & Washing Bays (v1.8)
- **Kampala Buses & Cargo Trailers**: Added regional/city coaches (`model_bus()` in Pioneer, YY, Gateway & Link liveries) and 40ft container semi-trailers (`model_trailer()`) to Kampala traffic with deep air-horns and long-vehicle following distances in `scripts/car.gd`.
- **Active Road Repairs**: Added KCCA roadwork sites (`_build_roadworks()`) with orange/white traffic cones, barriers, `"DRIVE SLOWLY • WORK AHEAD"` roadside signs, tarmac drums, and workers; traffic slows down through roadwork zones and speeding riders receive a safety warning.
- **Interactive Boda & Car Washing Bays**: Added 3 Kampala Washing Bays (`_build_wash_bays()`, `near_wash_bay()`, `_wash_boda()`) with elevated water tanks, wet concrete pads, attendants, `"BODA & CAR WASH BAY • UGX 2,000"` signs, interactive `Wash Boda (UGX 2,000)` action (+Mood & +Rating), and a `🫧 Wash Bays` quick filter in the Map Finder.

## Living Bottom-Left Controller, Inline Traffic Map & Flexible Fuel Pump (v1.7)
- **Always-Visible Living Joystick**: Added a persistent bottom-left steering/movement pad (`Joystick` in `scripts/hud.gd`) with directional ticks, live speed/boost arc, tactile thumb knob, mouse click-and-drag support alongside touch & keyboard feedback, and a `STEER / MOVE` label.
- **Inline Traffic Minimap**: Updated the top-left inline minimap footer to clearly display `TRAFFIC • <street>` alongside live traffic dots.
- **Flexible Petrol Station Pump Selector**: Replaced fixed-amount refueling with a pump menu (`fuel_panel` in `scripts/hud.gd`, `buy_fuel_amount()` in `scripts/main.gd`, and `budget_ugx` support in `Player.refuel()`) letting players choose `UGX 2,000`, `UGX 5,000`, `UGX 10,000`, `UGX 15,000`, or `FULL TANK` based on their MoMo balance.

## Map Place/Road Filter, Smart Repair Recommendations & Ugandan English Street Voices (v1.6)

- **Full-Map Category Filter & One-Tap GPS Route Finder (`M`)**:
  - Dedicated **`FILTER & ROUTE TO PLACE`** sidebar on the Kampala City Map lets you filter by **All Nearest**, **🔧 Repair / Fundi**, **⛽ Petrol**, **🍔 Food / Juice**, **🛒 Market / Shop**, **⛪ Church**, **🏥 Clinic**, **🏫 Landmarks**, or **🛣️ Streets**.
  - Displays the **6 nearest matching places/roads** sorted by distance and highlights them on the map—one tap plots your GPS route and closes the map.
- **Smart Status Bar Repair Recommendations**:
  - When your boda is spoiled (`0%`) or heavily damaged (`<= 35%`), the top status bar recommends the **nearest Boda Fundi / Mechanic by name and distance** (`SPOILED! Fix @ the Boda Mechanic & Tyre Fundi (15m)`).
- **Spoken Ugandan English Street Voices (`DisplayServer.tts_speak` + Subtitles)**:
  - Enabled native cross-platform Text-to-Speech in [project.godot](file:///home/sisi-labs/Projects/playKampala/project.godot) (`general/text_to_speech=true`) so nearby **Matatu Taxi Conductors** (*"Kampala! Kampala! Town! Two more, let us go!"*), **Rolex & Muchomo Vendors**, **Market Mamas**, and **Boda Fundis** call out in Ugandan English with live HUD subtitles.

## Spatial Street Music & Passing Traffic "Vuuuum" Doppler Audio (v1.5)

- **Distance-Fading Street Music (`update_spatial_audio`)**:
  - **Bars & Clubs** play booming Kampala Afrobeat bass outside their doors, **Hardware, Electronics, Saloons, Boutiques & Juice Shops** play upbeat Kadongo Kamu street speakers, **Markets** play lively Highlife, and **Churches** play warm choir/organ hymns (`_music_church_hymn`).
  - Music is loudest within `4m` of a venue, gently ducks your personal FM radio, and smoothly fades away as you ride or walk beyond `28m`.
- **Passing Taxis & Cars "Vuuuum!" Doppler Whoosh**:
  - Moving matatu taxis and cars zooming past within `9m` trigger synthesized Doppler engine/tyre whooshes (`whoosh_taxi` / `whoosh_car`) scaled by vehicle speed and distance.

## Kampala Fever, District Respect, Daily Lucky Spin & Street Encounters (v1.4)

- **🔥 Kampala Fever Mode (`3+` Fast Streak) & Turbo Wheelie**:
  - Completing **3+ fast deliveries in a row** activates **Kampala Fever (`+25%` All Fares & `+50%` Boost Recharge)**, while **⚡ Boost** lifts the front wheel for a sporty **boda wheelie**.
- **🏙️ District Respect & Fare Mastery (`Lv.1 – Lv.5`)**:
  - Every Kampala district (*Kikuubo & Arcades*, *Owino Market*, *Nakivubo Stadium*, *Nakasero*, *Wandegeya*, *Ntinda*, etc.) tracks your **Respect**. Leveling up unlocks permanent **`+10%` to `+40%` District Fare Bonuses** and `+UGX 5,000` milestone rewards.
- **🎁 Stage Chairman's Daily Lucky Spin & 🎫 VIP 2x Ticket**:
  - Open `Phone (P)` → `🎁 Daily Spin READY!` once per in-game day to win **+UGX 10,000 Cash**, a **FREE Full Tank**, **FREE 100% Bike Tune-Up**, **+0.15 ★ Rating & Mood**, or a **🎫 VIP 2x Fare Golden Ticket**.
- **🎲 Dynamic Kampala Street Encounters**:
  - Live non-blocking 2-choice street stories (*Kikuubo Jam Shortcut*, *Stage Friend's Flat Tyre*, *Sudden Kampala Rain Tip*, *Nakasero Visitor Guide*) pop up as you hustle through the city.

## Living Kampala Realism: Swimmable Lake Victoria, Live Football, Churches & Real Shop Setups (v1.3)

- **Swimmable Lake Victoria & Ggaba Beach**:
  - Walk off the sandy shoreline at **Ggaba Beach & Pier** into the blue waters of Lake Victoria to **swim** (`SWIMMING 🏊` mode with animated strokes, bobbing, and passive mood boost), alongside other swimmers, beach loungers, and lakeside tilapia stalls.
- **Live Animated Football at Nakivubo Stadium**:
  - **4v4 Red vs Blue footballers** and a referee play an active match with a **live moving football**, goal nets, corner flags, and spectators cheering on the tiered stands.
- **Petrol Station Attendants, Churches with Doors & Congregation, and Specialized Shops**:
  - **Petrol Stations**: Two uniformed **Petrol Attendants** stand ready by the fuel pumps alongside safety bucket racks.
  - **Churches**: Stone entrance steps, tall arched wooden double doors with brass handles, stained-glass windows, outdoor benches, and a **Pastor & congregation** greeting at the door.
  - **Specialized Shops**: Framed glass entrance doors on open bays; **Juice Points** feature juice counters, mango & watermelon dispenser jars, blenders, fruit piles, and attendants; **Boutiques & Fashions** feature outdoor clothing racks, display mannequins, and attendants; **Bars & Lodges** feature outdoor tables, stools, bottles, and patrons hanging out.
  - **Nakasero / Owino Market**: Varied produce crates, woven grain sacks, aproned vendors, bustling shoppers, and interactive market tasks (bargain matooke, buy roasted groundnuts, or help unload produce for **`+UGX 3,500`**).

## Smart Dispatch, Task Rejection & Boda Mechanical Health (v1.2)

- **Reject / Skip Unwanted Tasks (`✕ Skip`) & Pause Dispatch (`⏸️ Break` / `▶ Online`)**:
  - Tap **`✕ Skip`** on any incoming stage call before pickup to decline it without losing your Fast Streak, and immediately scan for a better Kampala task.
  - Tap **`⏸️ Break`** / **`▶ Online`** anytime to pause or resume incoming calls while exploring, shopping, or refueling.
- **Intelligent Context-Aware Task Generation**:
  - **Breakdown & No-Fuel Protection**: When your boda is out of fuel (`0%`) or mechanically broken down (`0%`), dispatch automatically pauses impossible cross-city motorcycle passenger calls instead of nagging you—offering **`🚶 Foot Errand`** (short `16m–95m` on-foot parcel deliveries) or guiding you to a **Boda Fundi** / **Petrol Station**.
  - **Low-Fuel Short Routes (`<= 25%`)**: Dispatch automatically prioritizes nearby pickups and short drop-offs (`< 145m`) so you can finish a fare and reach a petrol station.
- **Boda Mechanical Health & Katwe Repairs**:
  - Heavy crashes wear down `bike_health`; at `0%`, the engine breaks down and you push the boda on foot (`Push boda (Broken!)`) until repaired for **`UGX 4,000`** at any **Boda Fundi** mechanic or via `Phone (P)` → `Garage & Empire`.

## Adaptive, Minimizable UX & UI (v1.1)

- **Interactive, Auto-Adapting & Closable Quick Guide (`1/4 – 4/4`)**:
  - Dedicated tutorial coach with step progress dots (`● ● ○ ○`), **`Next →`** button, and **`✕`** close button.
  - Automatically advances based on what you've already done or viewed (riding your boda, opening the Map, opening the Phone).
- **Minimizable HUD Cards & Collapsible Tools Drawer**:
  - **Job Bar (`—` / `+`)**: Collapse active delivery details into a sleek 1-line pill (`📍 Pickup Okello... [+]`) anytime.
  - **Needs Panel (`—` / `+`) & Place Activity Card (`—` / `+`)**: Minimize Food/Energy/Mood bars or nearby shop cards out of your way with one tap.
  - **Dismissible Alerts & `💬 Alerts (N)` Drawer**: Every toast notification has **`💬`** (minimize to inbox) and **`✕`** (dismiss) buttons; tap **`💬 Alerts`** on the top-right bar anytime to view or collapse recent messages and promos.
  - **Collapsible `⚙️ Tools ▸` Drawer**: Keeps `Map (M)`, `Phone (P)`, `FM Radio`, `💬 Alerts`, and `Where to?` clean and uncluttered, with `Rain`, `+3 hours`, `Power`, `Time`, `View`, `Guide`, and `Sound` tucked neatly inside `⚙️ Tools`.
- **Floating `+UGX` Celebration Popups**: Earning fares, tips, or promo rewards pops a golden floating `+UGX ...!` animation above the wallet.

## Real Kampala Streets, Custom Boda Paint, Express Boost & Street Events (v1.0)

- **Real Kampala Street Network & 3D Intersection Signposts (`Phase 4` foundation)**:
  - Every avenue and street across the 7×7 road network carries its authentic Kampala name:
    - **East–West Streets**: *Makerere Hill Rd*, *Bombo Road*, *Nakasero Road*, *Kampala Road*, *Jinja Road*, *Katwe Road*, and *Ggaba Road*.
    - **North–South Avenues**: *Kafumbe Mukasa Rd*, *Ben Kiwanuka St*, *Luwum Street*, *Entebbe Road*, *William Street*, *Yusuf Lule Rd*, and *Ntinda Road*.
  - **Live Street Tracker**: Your current street or intersection (`Kampala Road × Entebbe Road`) is displayed live on the top HUD bar and Minimap footer, and all 14 street names are drawn along the grid on the **Full-Screen Kampala City Map (`M`)**.
  - **3D Kampala Street Signposts**: Green-and-white council street name blades stand on steel corner posts at all 25 interior intersections.
- **Katwe Custom Boda Paint Shop & Dynamic Rider Gear**:
  - Repaint both your riding 3D boda and parked 3D boda in real time via `Phone (P)` -> `🎨 Paint: ...`:
    - **`Stage Red`**, **`Kampala Gold`**, **`Electric Blue`**, and **`Emerald Viper`**.
  - Buying your **Reflector Vest** dresses your 3D boda rider in a bright yellow reflector vest.
- **⚡ Boda Express Turbo Boost (`Shift` key or `⚡ Boost` HUD Button)**:
  - Engage **⚡ Boost** while riding for a **`+34%` top speed & `+48%` acceleration surge** with a sporty front-wheel lift to overtake slow matatu taxis and beat Urgent Express timers. Recharges automatically up to `100%`.
- **Dynamic Golden Street Promo / Lucky Drop Events (`[★]` on Map & 3D Beacon)**:
  - Timed Kampala street events (*Telecom MoMo Promo Van*, *Stage Chairman Rally Bonus*, *Found VIP Merchant Briefcase*, *Kampala Wedding Convoy Tip*) spawn at named intersections with a tall 3D golden beacon and a pulsing **`[★]`** icon on the Minimap and Full Map.
  - Tap `[★]` on either map (or `★ Route to Street Promo` in your Phone) to plot an instant GPS route, and reach the beacon before the timer expires for **`+UGX 8,000 – 12,000`**, `+20 Mood`, `+0.05 ★ Rating`, or a **FREE Full Tank of Fuel**!

## Kampala FM Radio, High-Stakes Missions, Daily Challenges & Business Empire (v0.9)

- **4-Station Kampala FM Radio Tuner (`FM: 91.3 Beat` HUD button or `R` key)**:
  - Cycle live between **4 synthesized Ugandan radio stations** (plus `Radio OFF`) with FM static tuning SFX:
    1. **`91.3 Afrobeat FM`** — Bright Kalimba, nylon guitar & djembe groove
    2. **`88.8 Kadongo Kamu`** — Bouncy Ugandan acoustic storytelling bass & thumb-piano groove
    3. **`97.7 Luga-Flow Beat`** — Deep 808 Kampala hip-hop & dancehall synth bounce
    4. **`100.4 Lake Highlife`** — Warm evening Ggaba Beach guitar & marimba breeze
- **High-Stakes Boda Mission Variety, Live Passenger Chatter & Fast Streaks**:
  - Dispatch any mission type on-demand from `Phone (P)` -> `Stage & Goals` or receive them automatically on stage calls:
    - **🔥 Urgent Express (`1.85x Pay` + `+UGX 2,500` Rush Tip)** for high-priority riders and time-critical deliveries.
    - **🥚 Fragile Cargo (`+60% Pay` + `+UGX 4,000` Smooth Rider Bonus)** with a live **Cargo Integrity (`100%`)** meter that drops if you bump walls or crash into traffic.
    - **🌟 VIP Landmark Charters (`1.75x Pay` + `+UGX 3,000` VIP Tip)** taking visitors directly to Kampala's biggest landmarks (*Clock Tower*, *Ggaba Beach & Pier*, *Nakivubo Stadium*, *Owino Market*, *Old Taxi Park*).
  - **Live Passenger Chatter** from the back seat while riding through traffic, plus a **🔥 Fast Streak (`Streak x2 / x3+`)** bonus (`+UGX 1,500` per streak level) for consecutive fast deliveries.
- **Daily Kampala Hustle Challenges (Instant Mobile Money Bonuses)**:
  - Tracked live in `Phone (P)` -> `Stage & Goals` with instant Mobile Money payouts and celebration fanfare:
    - **Complete 3 Boda Trips Today** -> **`+UGX 8,000` Bonus**
    - **Work 2 On-Foot Street Hustle Shifts Today** -> **`+UGX 7,000` Bonus**
    - **Earn UGX 25,000 Today** -> **`+UGX 10,000` Bonus**
- **Kampala Business Empire & Dynamic Player Ranks**:
  - Invest your earnings in `Phone (P)` -> `Garage & Empire` to own Kampala street businesses that pay **daily passive income on Mobile Money** AND **double (`2x`) your active shift pay** when you work there yourself:
    - **Own Corner Rolex Stand (`UGX 45,000`)** -> `+UGX 6,000/day` passive + `2x` Rolex shift pay
    - **Own Kibanda Live TV Cinema (`UGX 75,000`)** -> `+UGX 10,000/day` passive + `2x` Kibanda TV shift pay
    - **Own Mobile Money Kiosk (`UGX 110,000`)** -> `+UGX 14,000/day` passive + `2x` MoMo Agent shift pay
    - **Own 14-Seater Matatu Taxi (`UGX 350,000`)** -> `+UGX 35,000/day` passive remit
  - Rise through 5 Kampala titles displayed on your HUD: **`Stage Rider` → `Smart Hustler` → `Boda Boss` → `Stage Chairman` → `Kampala Tycoon`**.
- **Interactive Horn (`Hoot (H)`) & 5 One-Tap Map Quick-Route Pills**:
  - Hooting (`H` or `Hoot` button) alerts pedestrians ahead of you to step toward the pavement and nudges stopped vehicles ahead to clear the lane.
  - The Full-Screen Map (`M`) now features **5 One-Tap Quick-Route Filter Pills** along the top header (**`[⛽ Fuel [F]]`**, **`[🏠 My Room]`**, **`[🍳 Rolex/Food]`**, **`[📺 Kibanda TV]`**, **`[🛠️ Boda Stage]`**) plus clickable `[F]`, `[TV]`, and `[H]` icons directly on the map.

## Audio, Animated Intro & Fuel Realism (v0.8)

- **Distinct Vehicle Horns, SFX & Ugandan Background Music**:
  - Removed the repetitive 4-second synthetic beep from the city ambience loop so the street soundscape is a natural urban murmur.
  - Every vehicle type now has its own authentic horn: **Boda-Bodas** play a crisp high-pitched double-pip (`horn_boda`), **Matatu Taxis** blast a deep brassy dual-tone air horn (`horn_taxi`), **Sedans/Cars** sound a warm mid-range chord horn (`horn_car`), and **Traffic Police Checkpoints** blow a realistic pea-whistle trill (`whistle`).
  - Added a synthesized 8-second looping **Ugandan Afrobeat / Kalimba & Acoustic Guitar groove** with warm sub-bass and soft djembe/shaker percussion, plus an independent **`Music: on/off`** button on the HUD.
- **Custom PlayKampala Branding & Animated Skyline Intro**:
  - Replaced the default Godot engine logo on both desktop and Android (`splash.png` and `icon.svg`) with custom PlayKampala artwork.
  - Added an **Animated PlayKampala Intro** on launch featuring a Kampala golden-hour sunset gradient, rising sun over the Seven Hills, scrolling Nakasero arcades and Queen's Way Clock Tower, moving black-and-yellow kerbs, and an animated Boda-Boda rider with spinning spoked wheels, headlight beam, and exhaust puffs (tap or press any key to skip).
- **Out-of-Fuel Boda Rolling/Pushing & Progressive Fuel Warnings**:
  - **Progressive Dashboard Alerts**: As fuel burns, the bike warns you at **25%** (`LOW FUEL (25%)!` + dashboard chime + pulsing fuel bar), at **12% Reserve** (`RESERVE FUEL (12%)!` + urgent high-pitched alert), and at **0% Empty** (`OUT OF FUEL!` + engine coughing/sputtering sound + automatic GPS routing to the nearest Petrol Station).
  - **Walk Beside & Roll/Push Only (Cannot Ride Empty)**: When `fuel <= 0.0`, you **cannot** sit on and ride the motorcycle. Instead, your character dismounts and walks alongside the motorcycle, rolling/pushing it by hand at walking pace (`1.85 m/s`, HUD status `PUSHING (0L)`, action button `Roll boda (No Fuel)` / `Park boda`) until you refuel at a Petrol Station.
- **One-Tap Clickable Petrol Stations (`[F]`) on Minimap & Full Map**:
  - Tap or click any green **`[F]` Petrol Station** icon directly on either the **top-left Minimap** or the **Full-Screen City Map (`M`)** to immediately set your blue GPS route to that Petrol Station.

## Kampala Life & Street Realism (v0.7): Roadside Vendors, TVs, Billboards & Night Lights

- **Roadside TVs & Football / VJ Movie "Bibanda" (`TV` on the full map)**:
  - 6 roadside flat-screen TV shelters with satellite dishes, live cycling broadcasts (**Live EPL**, **Nakivubo Derby**, **VJ Jingo Luganda-translated Action Movies**, and **Ugandan Music Videos**), wooden spectator benches, excited fans, and blue screen glow at night.
  - Walk up on foot to watch the live football match (`UGX 1,000`, `+28 Mood`), watch a VJ-translated action movie (`UGX 1,000`), make a friendly goal prediction with fans (`UGX 2,000` to win `UGX 5,000`), or work a shift collecting match entry fees (`+UGX 3,500`).
- **Giant Rotating Digital LED Advertising Billboards**:
  - 9 double-sided illuminated monopole LED advertising boards at major intersections with floodlights, neon trim, ground light pools, and rotating Ugandan campaigns (*MTN MoMo*, *Airtel 5G*, *Nakivubo Live Match*, *Safe Boda Stage*, *Uganda Rolex Festival*, *Kampala Nights*).
- **Authentic Roadside Vendors & 9 Playable On-Foot Side-Hustles**:
  - **Muchomo & Roasted Gonja Grills**: Half-drum charcoal `sigiri` with glowing red-orange embers, sizzling beef skewers, golden roasted plantain (`gonja`), kachumbari salad bowls, and warm firelight pools. Eat sizzling muchomo (`UGX 3,500`) or work the grill (`+UGX 4,000`).
  - **Sugarcane & Tropical Fruit Pushcarts (`Kigaali`)**: Two-wheeled wooden handcarts piled with watermelons, pineapples, mangoes, and sugarcane stalks. Drink cold sugarcane-ginger juice (`UGX 1,500`, `+20 Energy`) or press juice for customers (`+UGX 3,000`).
  - **Roadside Boda Mechanics & Tyre Pressure Fundis**: Red air compressor tank, spare tyres, and toolbox. Pump your tyres & oil your chain (`UGX 2,000`) or work a mechanic shift (`+UGX 4,500`).
  - **Newspaper (*Bukedde / New Vision*), Airtime & Cold Soda Stands**: Umbrella tables with newspapers and iceboxes. Grab a cold soda & read the headlines (`UGX 2,000`) or sell airtime & papers (`+UGX 3,500`).
  - Plus **Rolex Stand Chef (`+UGX 3,500`)**, **Mobile Money Agent (`+UGX 4,000`)**, **Owino Market Vendor (`+UGX 4,000`)**, and **Matatu Conductor (`+UGX 4,500`)**.
- **Spectacular Kampala Night Lights**:
  - **Headlight beams on all 72 traffic vehicles** (matatus, cars, and bodas) at night and in rain.
  - **Neon shop signage & pharmacy crosses**: Magenta/pink neon strips on bars, salons, and boutiques; cyan/emerald LED strips and glowing 3D medical crosses on pharmacies and clinics; under-veranda arcade tube lights.
  - **Power-cut resilient charcoal & solar lights**: Charcoal `sigiri` embers and vendor solar bulbs keep glowing warmly even during Umeme load-shedding (`Power: CUT`).
- **Needs**: Food, Energy and Mood (panel under the minimap) drain through the
  day. Hungry or exhausted, you walk and ride slower; in a great mood, a bit faster.
- **Places mean something**: walk up to a place and its options appear.
  - Restaurants and rolex stands: breakfast, lunch or supper, quick rolex and tea, or a pork joint at night.
  - Bars: a cold drink, the big match from 18:00, karaoke nights.
  - Churches: pray, Wednesday fellowship, **Sunday service**. Church members become customers.
  - Markets: groceries and matooke, which you then cook at home.
  - Your room (pink **H** on the map): sleep (ends the day, full energy), nap, cook, bathe.
  - Clinics and pharmacies, salons, and every kind of shop (furniture, phone repair, VJ movies, butchery...).
  - The lake: relax, or eat fried tilapia. The stadium: watch a match.
- **"Where to?"** (right column): choose any place by type and nearest first. Get a
  real street route (shortest path on the road network) on the minimap, the full
  map and painted on the road.
- **Ride as a passenger**: call a boda (a named rider comes to you, you hop on and
  he drives you there) or take a matatu. Matatu **conductors shout for passengers**
  ("Ntinda! Ntinda! One seat!") when they pull over: walk up and board.
- **Proactive suggestions**: lunch time with the nearest food, Sunday service,
  "head home to sleep", "the match is on tonight", "pick up groceries on your way".
- **Citizens with routines**: 40 people commute to work, go for lunch, shop,
  crowd outside bars at night and fill churches on Sunday morning.
- Weekdays: Day 1 is Monday. Life progress is saved per save slot.

## Phase 3 (v0.6): Careers, Smartphone UI & Crowd Intelligence

- **In-Game Smartphone UI (`Phone (P)`)**:
  - **Stage & Hustles tab**: Live Rider Star Rating (`★ 1.0–5.0`), Regular Customers list, active delivery details, and instant dispatch.
  - **Mobile Money tab**: Live MTN/Airtel Mobile Money statement logging every fare, tip, side-hustle shift, fuel refill, upgrade purchase, police fine, owner rent, and hired rider remit.
  - **Garage & Fleet tab**: Purchase **Crash Helmet (`UGX 15,000`)**, **Reflector Vest (`UGX 10,000`)**, **Riding Permit (`UGX 25,000`)**, **Waterproof Rain Jacket (`UGX 20,000`)**, **6.5L Long-Range Tank (`UGX 35,000`)**, **Bajaj Boxer 150cc HD Engine (`UGX 60,000`)**, **Full Boda Ownership Title (`UGX 500,000` — eliminates daily rent!)**, and **Hire Stage Riders (`UGX 120,000` each — earn `+UGX 15,000/day` passive Mobile Money remit per rider!)**.
  - **SMS & Saves tab**: Inbox messages from the Stage Chairman, regular customers, and hired riders, plus **3 Save Slots (`Slot 1 / 2 / 3`)** and a **Day 1 Tutorial** replay button.
- **4 Additional Playable Side-Hustle Careers (On Foot)**:
  - **Rolex Stand Chef**: Fry chapati & egg rolexes at downtown corners (`+UGX 3,500/shift`).
  - **Mobile Money Agent**: Process cash-in/cash-out at yellow/red MoMo kiosks (`+UGX 4,000/shift`).
  - **Owino Market Vendor**: Sell matooke & produce at Owino Central Market (`+UGX 4,000/shift`).
  - **Matatu Taxi Conductor**: Call passengers & load taxis at the Old Taxi Park (`+UGX 4,500/shift`).
- **Rating, Reputation & Regular Customers**:
  - Fast deliveries boost your `★` rating (`+15%` fare bonus at `★ 4.6+`). Serving the same customer `2+` times makes them a **Regular Customer** who pays a `+UGX 2,000` loyalty bonus and texts your phone.
- **Crowd Intelligence, True Kampala Jams & Focused Camera**:
  - **No passing through people**: Pedestrians steer around you and each other, and solid personal-space separation prevents the player or walkers from ever walking through another person.
  - **Authentic Kampala Traffic Jams**: 72 vehicles concentrated on central Kampala corridors, matatu taxis pulling over mid-street to load passengers, and junction hold cadences that create multi-vehicle queues and hooting.
  - **Map-First Navigation (`Guide: off` by default)**: Removed the overhead arrow from above the player's head so the player is never covered; navigation uses the Minimap/Full Map GPS route, with an optional road-level `Guide: off/on` toggle.
  - **Closer Camera Focus & Larger Character Scale**: `PERSON_SCALE = 1.42`, `1.18x` boda scale, and closer camera presets (`11.5m / 17.5m / 27.0m`, auto-focusing when on foot) so characters and street props look bold and detailed.

## Phase 2 (v0.5): Kampala character

- **Authentic Kampala districts**: Kikuubo & Arcades, Owino Market, Nakasero Hill (modern glass-curtain office towers & gardens), Old Taxi Park, Nakivubo Stadium, Katwe Workshops, Wandegeya, and Ntinda & Suburbs.
- **Iconic landmarks**:
  - **Queen's Way Clock Tower roundabout** at `(0, 0, 64)` plus City Square and Wandegeya roundabouts with central islands and Traffic Police officers.
  - **Nakivubo War Memorial Stadium** with tiered spectator stands and cantilevered corrugated roofs around the pitch.
  - **Lake Victoria & Ggaba Beach Pier** along the southern edge (`z > 192m`) with a wooden jetty, colourful fishing canoes, and lakeside fish stalls.
- **Traffic Police checkpoints & Rider Gear**:
  - 3 roadside Traffic Police checkpoints (`P` on the map) staffed by white-uniformed Uganda Traffic Police officers checking for **Crash Helmet**, **Reflector Vest**, and **Riding Permit**.
  - Interactive stop dialog when missing gear: pay an official **UGX 10,000** Express Penalty receipt, settle on the spot with **UGX 5,000** ("officer's soda"), or apologize and try to talk your way out.
  - Buy your **Helmet (UGX 15,000)**, **Reflector Vest (UGX 10,000)**, and **Riding Permit (UGX 25,000)** at the Downtown Boda Stage to pass all checkpoints freely.
- **Rush Hour (07:00–09:00 & 17:00–20:00)**: heavier traffic jams and a **+25% Rush Hour fare surge** on new delivery calls.
- **Street hawkers**: vendors carrying head-loads/trays patrol busy junction approaches alongside jaywalking pedestrians.

## Phase 1 (v0.4): a living city

- **A generated city of 6 x 6 blocks** (about 400 m across) with districts:
  Downtown arcades and office towers, the Central Market, the Old Taxi Park,
  a community pitch, workshops and scrap yards, two fuel stations, mixed
  shops-and-homes blocks, and residential estates with rentals and churches.
- **Over 400 named places**: about 300 shops with painted signboards (invented
  Kampala-style names, no real brands), homes, garages, churches and more. Jobs
  go between them.
- **Traffic on a road network**: 44 taxis, cars and bodas drive junction to
  junction on the left, take turns at junctions, queue, and hoot at you if
  you block the road. People walk the pavements and cross wherever they like.
- **Live minimap** (top-left) turns with the camera and shows roads, traffic,
  fuel stations and your job. Tap it, or the **Map** button, for the full city
  map with districts.
- **Sound**, all generated in code: a boda engine that revs with speed, horns,
  rain, city hum, the Mobile Money chime, fuel pump, crash.
- **Speed zoom**: the camera pulls back and looks ahead as you ride faster.
  Use the **View** button for near / mid / far.
- **Hoot** button while riding.
- **People who really walk** (v0.4.1): rounded low-poly characters on a small
  skeleton. Legs swing, knees bend and arms swing as they walk. Outfits
  include casual clothes, gomesi, kanzu (some with a kofia), school uniforms
  and vendor aprons, plus people carrying jerrycans, matooke or baskets on
  their heads. Each person is still one draw call.
- **No more getting stuck**: thin pillars and poles no longer block you,
  bumps slow you once instead of trapping you, and if you're ever pinned for
  2 seconds the game squeezes you back towards the road.

## Gameplay (v0.3): a day as a boda rider

- Your day runs from **07:00 to 22:00** (about 5 minutes of play at Time x1).
- Hop on your boda and take jobs: passengers ride on the back, and parcels,
  matooke, gas and more get delivered. Fares are paid on **Mobile Money**,
  with a **tip** if you're quick.
- **Fuel** burns as you ride. Refuel at the petrol station at the east end
  of the main road (UGX 5,000 per litre). If it runs out, you push the boda.
- **Traffic reacts**: cars, taxis and bodas slow down and queue behind you.
  If you crash into something at speed, you pay for repairs, and a passenger
  will get off.
- **Rain**: you ride slower, but fares pay 1.5x.
- At **22:00** you pay the boda owner **UGX 10,000** rent and see your day's
  summary. The long-term goal is to save **UGX 500,000** for the deposit
  to own your boda.
- Progress is saved automatically.

| | Phone | Computer |
|---|---|---|
| Walk / ride | touch the left side of the screen (floating joystick) | W A S D or arrow keys |
| Ride boda / get off | big button, bottom-right | E |
| Rotate / tilt camera | one-finger drag on the right side | left-drag |
| Zoom | pinch | mouse wheel |

The small test buttons in the top-right are **Rain**, **+3 hours**,
**Power**, and **Time speed** (x1, x4, x12 or paused).

## Open it

1. Install **Godot 4.3 or newer** (the standard build, not .NET).
2. In the Project Manager, choose **Import**, select this folder's
   `project.godot`, then press **Run** (F5).

## The test that matters: a cheap phone

The project uses the **Compatibility** renderer (OpenGL ES 3), which runs on
the most Android phones.

1. In Godot, go to **Editor → Manage Export Templates** and download them.
2. Set up the Android SDK and a debug keystore under
   **Editor Settings → Export → Android**. Godot's "Exporting for Android"
   docs walk through this.
3. Go to **Project → Export → Add… → Android**, then export the APK, or use
   one-click deploy with the phone plugged in over USB.
4. Run it on the **cheapest phone you expect players to own** (for
   example a 2 GB RAM Android), and read the numbers in the top-left corner:
   - **FPS**: aim for a steady 30 or more, including in the rain at night.
   - **Draw calls**: around 220–260 in this scene. Most of the scenery is
     merged into about 64 meshes. The rest are the 80 moving people and
     vehicles, plus their shadows.

If FPS is low, these are the dials to turn, in order:

1. Shadows are already off at night and in rain. Turn them off in daytime
   too with `sun.shadow_enabled = false` in `_apply_time()`
2. Fewer walkers and vehicles in `_spawn_pedestrians` / `_spawn_traffic`
3. `rain.amount` from 1400 down to about 600
4. Set MSAA to off in Project Settings

## Files

- `scripts/main.gd`: builds the whole street, the traffic and people, and
  handles day, night, rain and power cuts
- `scripts/mesh_baker.gd`: merges many small parts into one mesh, which is
  the main performance trick
- `scripts/mover.gd`: walking, driving and idle behaviour
- `scripts/camera_rig.gd`: Townscaper-style orbit camera
- `scripts/hud.gd`: joystick, action button, Mobile Money, job text, test buttons
- `scripts/player.gd`: walking, boda riding, getting on and off
- `scripts/jobs.gd`: delivery jobs, passengers, tips, markers and fares
- `scripts/car.gd`: traffic that drives the road graph
- `scripts/life.gd`: needs, place activities, routes, passenger rides, suggestions, citizens
- `scripts/sfx.gd`: all sounds, generated in code (with a padded tail:
  Android crashes if a looping sound is read past its end)
- `scripts/person.gd`: skinned, animated people

The full plan is in the "PlayKampala – Game Plan & Roadmap" doc.

For screenshots from the command line:
`godot --path . -- --time=19 --rain --shot=/tmp/street.png`
