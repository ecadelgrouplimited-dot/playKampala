# PlayKampala – Game Plan & Roadmap

Nov 12, 2026 · @wilson ecaat

## Vision

PlayKampala is a mobile game where you live a working life in Kampala: start as a boda rider, earn on Mobile Money, and build towards owning your bike and more. It runs on cheap Android phones and feels authentic to anyone who knows the city.

- **The test for every feature:** would someone from Kampala laugh and say "eh, that's exactly how it is"? If they would, it goes in.
- **Players:** Ugandans at home and in the diaspora first, then anyone curious about African city life.
- **Style:** low-poly, Townscaper-like 3D. Authentic in daily life and detail, not photoreal.
- **Business:** free to play, with telecom partnerships (Mobile Money, data bundles) and local business placements in the city.
- **Link to Nyumbani:** PlayKampala is the city; Nyumbani is the village. Both share one engine, avatar and economy, so players can eventually "go home upcountry".

## Where we are

v1.0 completes **Phase 1 (A living city)**, **Phase 2 (Kampala character)**, **Phase 3 (Careers and progression)**, **Phase 4 Foundation (Real Kampala Street Network & 3D Street Signposts)**, **Street Life, Roadside Vendors, TVs & Night Lights (`v0.7`)**, **Audio Overhaul, Animated PlayKampala Intro, Out-of-Fuel Boda Rolling & One-Tap Map Fuel Routing (`v0.8`)**, **4-Station Kampala FM Radio, High-Stakes Boda Missions, Daily Hustle Challenges & Kampala Business Empire (`v0.9`)**, and **Real Kampala Street Names, 3D Corner Street Signposts, Custom Boda Paint Shop, Boda Express Turbo Boost & Dynamic Golden Street Promo Events (`v1.0`)**: a full 6x6 block generated Kampala city (`384m x 384m`, 421 named places, 278 shop signboards, 293 moving vehicles & citizens) with 14 real named Kampala streets (`Kampala Road`, `Jinja Road`, `Nakasero Road`, `Bombo Road`, `Makerere Hill Rd`, `Katwe Road`, `Ggaba Road`, `Entebbe Road`, `Luwum Street`, `William Street`, `Ben Kiwanuka St`, `Kafumbe Mukasa Rd`, `Yusuf Lule Rd`, `Ntinda Road`), 3D green-and-white council street signposts at intersections, custom 3D Boda paint jobs (`Stage Red`, `Kampala Gold`, `Electric Blue`, `Emerald Viper`), rechargeable `⚡ Boost` turbo riding, and live Golden Street Promo / Lucky Drop events.

| Version | What it added | Phone result |
| --- | --- | --- |
| v1.1 | **Adaptive, Minimizable UX/UI Overhaul & Floating Rewards:** Replaced static tutorial text with an interactive, auto-adapting, closable **Quick Guide (`1/4 – 4/4`)** with progress dots, **`Next →`**, and **`✕`** buttons (auto-advances as you ride, open Map, or open Phone); made **Job Banner**, **Needs Panel**, and **Place Activity Cards** minimizable (`—` / `+`); made **Toast Alerts** dismissible (`✕`) & minimizable into a **`💬 Alerts (N)`** expandable **Recent Messages & Alerts** drawer; collapsed secondary test buttons into a clean **`⚙️ Tools ▸`** drawer; added floating **`+UGX`** celebration popups on earnings | ~0.97 s full build, 40–43 FPS, 0 errors |
| v1.0 | **Real Kampala Street Names, 3D Street Signposts, Custom Boda Paint, Express Boost & Dynamic Street Events:** Named all 14 N–S and E–W Kampala streets (`Kampala Road`, `Jinja Road`, `Entebbe Road`, `Luwum Street`, `William Street`, `Ben Kiwanuka St`, `Nakasero Road`, `Bombo Road`, `Ggaba Road`, etc.) with live street tracking (`street_at()`) on the HUD & Minimap, street labels on the Full Map, and 3D green-and-white Kampala Street Name Signposts at intersections; added **Katwe Custom Boda Paint Shop** (`Stage Red`, `Kampala Gold`, `Electric Blue`, `Emerald Viper`) + dynamic rider gear visuals on the 3D boda; added rechargeable **⚡ Boda Express Boost (`Shift` / `⚡ Boost` button)** (`+34%` speed & sporty wheelie tilt); added **Dynamic Golden Street Promo Events (`[★]` on Map & 3D golden beacon)** awarding `+UGX 8,000–12,000` MoMo bonuses & free fuel | ~1.7 s full build, 0 errors |
| v0.9 | **4-Station Kampala FM Radio, Mission Variety, Daily Hustle Challenges, Business Empire & Map Quick-Route Pills:** Added 4-station Kampala FM Radio tuner (`91.3 Afrobeat FM`, `88.8 Kadongo Kamu`, `97.7 Luga-Flow Beat`, `100.4 Lake Highlife`, `OFF` via HUD button or `R` key); added **🔥 Urgent Express (`1.85x` pay + `+UGX 2,500` tip)**, **🥚 Fragile Cargo (`+60%` pay + `+UGX 4,000` Smooth Rider bonus + live Cargo Integrity % on bumps)**, **🌟 VIP Landmark Charters (`1.75x` pay + `+UGX 3,000` VIP tip)**, **Live Passenger Chatter**, and **Fast Streak (`Streak x2/x3+`)** bonuses; added **3 Daily Hustle Challenges** (`3 Boda Trips`, `2 Foot Hustles`, `Earn UGX 25k`) with instant Mobile Money bonuses; added **Kampala Business Empire investments** (`Own Rolex Stand`, `Own Kibanda TV`, `Own MoMo Kiosk`, `Own Matatu Taxi` paying up to `+UGX 65,000/day` passive income + `2x` active shift pay) & **Player Ranks** (`Stage Rider` -> `Kampala Tycoon`); upgraded `Hoot (H)` to make pedestrians step aside and nudges traffic; added **5 1-Tap Quick-Route Filter Pills** (`Fuel [F]`, `My Room`, `Rolex/Food`, `Kibanda TV`, `Boda Stage`) on the Full Map | ~1.7 s full build, 0 errors |
| v0.8 | **Audio Overhaul, Animated Intro, Out-of-Fuel Rolling & Map Fuel Routing:** Removed repetitive 4s ambient beep; added distinct vehicle horns (`horn_boda`, brassy `horn_taxi`, chord `horn_car`), Traffic Police pea-whistle (`whistle`), low-fuel alert chime (`low_fuel`), engine dying (`sputter`), and looping 8s Ugandan Afrobeat / Kalimba & Guitar background music (`Music: on/off` HUD toggle); replaced default Godot boot logo with custom PlayKampala `splash.png` & `icon.svg` plus an **Animated PlayKampala Intro** (sunset skyline, Clock Tower, rolling boda rider); implemented **Out-of-Fuel Boda Rolling/Pushing** (when `fuel <= 0`, rider walks beside and rolls the bike on foot at `1.85 m/s` instead of riding) with progressive `25%`, `12%`, and `0%` warnings; made all Petrol Stations (`[F]`) directly clickable on both the Minimap and Full Map to set an instant GPS route | ~1.3 s full build, 0 errors |
| v0.7 | **Street Realism, Roadside Vendors, TVs & Night Lights:** 6 Roadside Live Football & VJ Movie TV "Bibanda" with live score tickers & spectator crowds, 8 giant rotating LED Advertising Billboards, new roadside vendors (Muchomo & Roasted Gonja charcoal grills, Sugarcane & Fruit pushcarts, Boda Mechanic & Tyre Pressure fundis, Newspaper & Cold Soda stands), 9 playable foot side-hustles + Kampala Life customer activities (with visible animated player), neon night signage, glowing pharmacy crosses, charcoal ember light pools (immune to power cuts), and night headlight beams on all 72 traffic vehicles | ~1.1 s full build, ~220 draw calls |
| v0.6 | **Phase 3 complete:** In-game Smartphone UI (Stage App, MoMo Statement ledger, Katwe Garage & Fleet, SMS & 3 Save Slots), 4 foot side-hustles (Rolex Stand chef, MoMo Agent, Owino Market vendor, Matatu conductor), Star Rating & Regular Customers (+UGX 2,000 bonus & SMS), full upgrades (Rain Jacket, 6.5L Tank, Boxer 150cc HD, Own Boda Title, Hire Stage Riders), solid person-to-person collision intelligence, dense central Kampala traffic jams, closer camera focus, optional road guide (off by default) | ~480 ms build on desktop, 48–50 FPS |
| v0.5 | **Phase 2 complete:** Kampala districts (Kikuubo, Owino, Nakasero Hill, Old Taxi Park, Nakivubo Stadium, Katwe, Wandegeya, Ntinda), Clock Tower & 3 roundabouts, Lake Victoria & Ggaba Pier, Traffic Police officers & checkpoints (Helmet/Vest/Permit check + receipt/soda/apologize dialog), Rush Hour jams & +25% fare surge, street hawkers at junctions | 470 ms build on desktop, ~140–200 draw calls |
| v0.4 | **Phase 1 complete:** 6x6 block city generator (`±192m`, fixed `±100m` boundary bug), graph-based left-hand traffic, live minimap & full-screen GPS route map, 270+ Kampala shop signboards, procedural synthesizer SFX (engine, horn, rain, MoMo chime, crash), speed zoom, upgraded 3D boda/matatu/car models, night headlight cone, black-and-yellow kerbs & storm drains | Built in 2,142 ms on ARM Mali-G57 MC2 phone |
| v0.3 | Fuel and petrol station, daily owner rent, end-of-day summary, passengers, tips, traffic that brakes, crashes, autosave | Verified on Android |
| v0.2 | Player, touch joystick, rideable boda, delivery jobs, Mobile Money balance, rain fare surge | HUD text broke (a stale `main.gd` was saved) |
| v0.1 | One low-poly street block, traffic on the left, people, day/night, rain, power cuts | 31 FPS day, 16 FPS night rain, 139–185 draw calls |

Tooling is settled: official Godot 4.7.2 (not the Snap), Compatibility renderer, Java 17, APK export working.

## Roadmap

Six phases, each ending in a phone test. A phase is done only when its checks pass on the cheapest target phone.

&#91;embedded content: roadmap · 6 phases\]

### Phase 1: A living city (completed)

- [x] City generator: a grid of streets about 10x larger than v0.3, with districts (downtown arcades, market, residential, taxi park, industrial edge)
- [x] Road network that traffic drives on: vehicles turn at junctions, keep left, queue and give way
- [x] Live minimap with roads, your position, the job target and moving traffic; tap for a full-screen map
- [x] Shop names on signboards (generated Kampala-style names, no real brands)
- [x] Sound: engine that revs with speed, horn button, rain, Mobile Money chime, crash
- [x] Speed zoom: the camera pulls back as you go faster, plus smooth pinch zoom

Done when: a delivery can take 60–90 seconds of riding, and the phone holds 30 FPS in the day.

### Phase 2: Kampala character (completed)

- [x] District identity: dense downtown (Kikuubo feel), a big open market (Owino feel), hilly office streets (Nakasero feel), suburbs with muzigo and churches
- [x] Landmarks: clock-tower roundabout, big taxi park, stadium, a lake edge
- [x] Roundabouts and traffic police; jams at rush hour (07:00–09:00, 17:00–20:00)
- [x] Police checkpoints: helmet, permit, reflector; fines or a bribe choice
- [x] Pedestrians crossing anywhere, street hawkers at junctions

Done when: testers name the districts without being told.

### Phase 3: Careers and progression (completed)

- [x] Phone UI inside the game: ride-hailing app, Mobile Money statements, messages
- [x] More jobs: market vendor, Mobile Money agent, rolex stand, taxi conductor
- [x] Rating and reputation; regular customers who remember you
- [x] Upgrades: helmet, rain jacket, bigger tank, a better bike; own your boda, then hire riders
- [x] Save slots and a tutorial day

Done when: a new player plays a full in-game week without being told what to do.

### Phase 4: The real Kampala map (building next)

- [ ] Import OpenStreetMap roads and building outlines for central Kampala (ODbL licence, credit shown)
- [ ] Real neighbourhood and street names; real landmark shapes (no logos without permission)
- [ ] Streaming: load the city in tiles around the player so phones cope

Done when: a Kampala resident can find their own street.

### Phase 5: Partners and multiplayer

- [ ] Shared city: see other riders, help each other, rider stages as social hubs
- [ ] Telecom tie-ins: real Mobile Money / Airtel Money top-ups for in-game items, sponsored data bundles
- [ ] Licensed business placements (real shops pay to appear)
- [ ] Link to Nyumbani: travel upcountry to your village

Done when: one telecom pilot is live with real payments.

### Phase 6: Launch

- [ ] Device test matrix (2 GB, 3 GB and 4 GB Android phones), crash reporting, analytics
- [ ] Play Store listing, age rating, privacy policy
- [ ] Download under 100 MB, no first-launch download

Done when: public release on Google Play.

## Technical architecture

The whole city comes from one seeded generator, so it is identical on every phone and costs no download. The road graph it produces is the backbone: traffic drives on it, the minimap draws it, and jobs and shops are placed along it.

&#91;embedded content: city architecture · 7 parts\]

- **Engine:** Godot 4.7, GDScript only, Compatibility renderer (OpenGL ES 3) for the widest Android support.
- **Art:** shapes built in code and merged per area into a few big meshes with vertex colours, so there are no texture files.
- **Traffic:** each vehicle follows the road graph, picks a turn at every junction, keeps left, and brakes for whatever is ahead in its lane.
- **Sound:** generated in code (engine hum, horn, rain, chime), so there are no audio files yet; recorded Kampala sounds come later.
- **Saves:** a small JSON file on the phone. A server comes only with multiplayer in Phase 5.
- **Phase 4 swap:** the generator's road graph is replaced by OpenStreetMap data, and everything downstream stays the same.

## Performance budget

Target: a steady 30 FPS on a 2 GB RAM Android phone in the worst case (night, rain, busy junction). Every new feature is checked against these limits before it ships.

| Budget item | Limit | Why |
| --- | --- | --- |
| Draw calls | 150 | Each one costs CPU time on cheap phones; v0.3 sits at 74–92 |
| Moving vehicles near the player | 30 | Each is one draw call plus its shadow |
| People near the player | 40 | Same as vehicles |
| Real lights | 1 (the sun) | Street lights are faked with glowing ground circles |
| Shadows | Daytime, clear weather only | Shadow maps double the scene cost |
| Rain drops | 700 | Transparent overdraw is expensive on phone GPUs |
| APK size | 100 MB | Data costs matter for players |
| Load time | 5 seconds | The city is generated, not downloaded |

Test phones: the cheapest Android phone we can buy in Kampala, a mid-range phone (3–4 GB), and the developer's phone. Record FPS in four conditions: day, night, rain, and night with rain.

## Risks and open decisions

The biggest risk is phone performance as the city grows; the generator and the budget above exist to contain it.

- **Phone performance:** a bigger city means more to draw. Mitigation: merged meshes, only nearby traffic simulated, the budget above.
- **Real names and brands:** showing real businesses, telecom logos or landmarks may need permission. Until then, signboards use invented names. Check with a lawyer before Phase 4 and 5.
- **Sensitive themes:** police bribes, crime and politics can offend players or partners. Keep them light, optional and never glorified.
- **OpenStreetMap licence:** the map data is free but must be credited (ODbL), and changes to the data itself must be shared back.
- **Scope creep:** every phase ends with a phone test before the next starts.

Open decisions:

- [ ] Target the cheapest phone model to buy for testing
- [x] **v1.2 Smart Dispatch & Boda Health**: Added task rejection (`✕ Skip`), dispatch pause (`⏸️ Break` / `▶ Online`), `bike_health` breakdowns & Fundi/Garage repairs, low-fuel short routes, and on-foot errands (`🚶 Foot Errand`) when the bike is broken or out of fuel.
- [x] **v1.3 Living Kampala Realism**: Added swimmable Lake Victoria at Ggaba Beach, live 4v4 animated football at Nakivubo Stadium with spectators, uniformed petrol station attendants, churches with arched double doors & congregation, and specialized 3D setups + staff for Juice Shops, Boutiques, Bars, and Markets.
- [x] **v1.4 Endless Replayability & Magic**: Added Kampala Fever (`3+` fast streak `+25%` fares & `+50%` boost regen), Turbo Wheelie, District Respect (`Lv.1–5` fare mastery), Stage Chairman's Daily Lucky Spin & VIP 2x Ticket, and dynamic 2-choice Kampala Street Encounters.
- [ ] Which telecom to approach first, and when
- [ ] Languages: English first, then Luganda; others later?
- [ ] Does PlayKampala launch before Nyumbani, or together?
