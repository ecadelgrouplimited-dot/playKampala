# PlayKampala — Google Play Store Listing & Console Setup Guide

Everything you need to finish **every single task** in Google Play Console for **`PlayKampala`** (`com.sisilabs.playkampala`, v1.0.0).

---

## 1. Ready-to-Upload Graphic Assets (Exact Play Store Specs)

All files are generated and verified in `play_store_assets/`:

| Play Console Field | File Path | Verified Spec |
|---|---|---|
| **App icon** | `play_store_assets/app_icon_512x512.png` | `512 × 512 px`, 32-bit PNG |
| **Feature graphic** | `play_store_assets/feature_graphic_1024x500.png` | `1024 × 500 px`, PNG |
| **Phone screenshots** (6×) | `play_store_assets/screenshots/01_*.png` – `06_*.png` | `1280 × 720 px` (16:9 PNG) |
| **7" & 10" Tablet screenshots** (6×) | `play_store_assets/screenshots_tablet/01_*.png` – `06_*.png` | `1920 × 1080 px` (16:9 PNG) |

---

## 2. Main Store Listing Copy (Copy & Paste)

### App Name (11 / 30 chars)
```
PlayKampala
```

### Short Description (78 / 80 chars)
```
Ride your boda across real Kampala streets, suburbs, murram roads & highways!
```

### Full Description (1,920 / 4,000 chars)
```
Welcome to PlayKampala — the authentic 3D Kampala boda-boda & city life adventure!

Start your hustle on Entebbe Road with UGX 5,000 in Mobile Money float and work your way up from a rented stage boda to owning your own Bajaj Boxer, businesses, and fleet across Uganda's bustling capital.

🏍️ REAL KAMPALA STREETS, SUBURBS & HIGHWAYS
• Ride through downtown Kikuubo & Arcades, Old Taxi Park, Owino Market, Nakasero Hill, Wandegeya, Katwe Workshops, Nakivubo Stadium, and Ggaba Beach & Lake Victoria Pier.
• Head outside town along 4 Inter-District Highways — Jinja–Mukono, Gulu–Bombo, Masaka–Mbarara, and Entebbe Airport Rd — and tackle dusty red Ugandan murram & slippery rainy-season mud roads through Bweyogerere, Kawempe, Kisaasi, Nateete, and Wakiso!

🚦 LIVING TRAFFIC, ROADWORKS & REAL CONSEQUENCES
• Navigate left-hand Ugandan traffic packed with blue-and-white checkered matatu taxis, cars, fellow bodas, regional buses (Pioneer/YY/Gateway styles), and 40ft cargo trailers.
• Watch out for KCCA roadwork crews ("DRIVE SLOWLY • WORK AHEAD"), traffic police stops, potholes, and real roadside confrontations if you clip a vehicle.
• Visit Boda Fundi mechanics to repair damage, flexible Petrol Station pumps to choose exact fuel amounts (UGX 2,000 to Full Tank), and Kampala Washing Bays to keep your bike sparkling clean.

📻 106.5 PLAYKAMPALA FM & STREET VIBES
• Cruise with original PlayKampala songs & instrumentals on 106.5 PlayKampala FM plus 4 Kampala radio stations, spatial street music outside bars, hardware shops, markets & churches, and lively Ugandan street voices.

🎨 CUSTOMIZE YOUR RIDER & GROW YOUR HUSTLE
• Customize your Rider Name, Man/Woman style, Home Stage (8 Kampala stages), motorcycle color, and clothes.
• Take passenger rides, urgent expresses, fragile deliveries, VIP landmark charters, suburb highway runs, or on-foot hustles (frying rolex, roasting muchomo, serving MoMo, swimming at Ggaba Beach, and watching football at Nakivubo).
• Unlock 8 Kampala Trophies for bonus MoMo rewards — 100% playable offline!
```

### Category, Tags & Contact
- **App or game**: `Game`
- **Category**: `Simulation`
- **Tags** (pick up to 5): `Simulation`, `Open World`, `Motorcycle`, `Driving`, `Offline`
- **Release Notes (v1.0.0)**:
```
Welcome to PlayKampala v1.0.0!
• Open-world 3D Kampala city, Lake Victoria Ggaba Beach, 4 Inter-District Highways & red murram suburb roads
• Living traffic with matatus, buses, 40ft trailers, KCCA roadworks & real collisions/confrontations
• Flexible petrol station pumps, Boda Fundi repairs & Kampala Washing Bays
• 106.5 PlayKampala FM with original songs, instrumentals & spatial street music
• Rider Profile customization (name, man/woman style, 8 Kampala stages, bike paints & outfits) + 8 Kampala Trophies
```

---

## 3. Google Play Console "App Content" Checklist Answers

Exact answers for every task shown on your **Finish setting up your game** dashboard:

1. **Set privacy policy**
   - Public GitHub Pages Privacy Policy URL (once GitHub Pages is enabled on `main` → `/docs`):
     `https://ecadelgrouplimited-dot.github.io/playKampala/privacy-policy.html`
   - Public Terms & Conditions URL:
     `https://ecadelgrouplimited-dot.github.io/playKampala/terms.html`
   - Public Support & Website URL:
     `https://ecadelgrouplimited-dot.github.io/playKampala/`
     `https://ecadelgrouplimited-dot.github.io/playKampala/support.html`
2. **App access / Sign in details**
   - Select: **"All functionality in my app is available without any access restrictions"** (offline single-player game, no login required).
3. **Ads**
   - Select: **"No, my app does not contain ads"**.
4. **Content rating (IARC Questionnaire)**
   - Category: **Game**
   - Violence: **Mild / Cartoon or implied non-graphic vehicle bumps** (no blood, no weapons, no realistic human injury)
   - Sexuality / Drugs / Gambling / Horror: **No**
   - User-to-user interaction / Chat / Sharing location / Real-money purchases: **No**
   - Expected rating: **Everyone / PEGI 3–7 / IARC 3+**.
5. **Target audience**
   - Recommended age group: **13–15, 16–17, 18 and over** (avoids the strict Families Policy review required for Under-13 apps unless you specifically want to target young children).
6. **Data safety**
   - "Does your app collect or share any of the required user data types?" -> **No** (all saves are local on-device only; no external servers, no ads, no analytics).
7. **Government apps**
   - Select: **No**.
8. **Financial features**
   - Select: **"My app doesn't provide any financial features"** (note: in-game "MoMo UGX" is 100% fictional game points, never real money).
9. **Health**
   - Select: **"My app does not have any health features"**.

---

## 4. Building Your Play Store Release `.aab` (Android App Bundle)

Google Play Console requires an **`.aab` (Android App Bundle)** signed with your own **Release Upload Keystore** (debug APKs are only for direct sideload testing).

### One-Time Keystore Creation (Keep `playkampala-release.keystore` safe & NEVER commit it to public git!)
```bash
keytool -genkey -v -keystore ~/playkampala-release.keystore \
  -alias playkampala -keyalg RSA -keysize 2048 -validity 10000
```

### Exporting the Signed `.aab` for Google Play Upload
1. Open **Godot → Project → Export → Android**:
   - Set **Export Format** to **`Export AAB`** (`export_format=1`)
   - Under **Keystore → Release**, select `~/playkampala-release.keystore`, set Release User = `playkampala`, and enter your keystore password.
   - Set **Launcher Icons** to the generated `play_store_assets/icon_192x192.png` and `play_store_assets/adaptive_fg_432x432.png` (already configured in `export_presets.cfg`!).
2. Click **Export Project…** (or run `godot --headless --export-release "Android" "PlayKampala-v1.0.0.aab"`) and upload `PlayKampala-v1.0.0.aab` to **Closed Testing / Production** in Google Play Console!
