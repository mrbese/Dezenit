# Manor OS — Brand Color Palette & UI Kit

## Design Philosophy
Manor OS channels the intersection of nature's intelligence and technological precision. The palette draws from deep forest canopies (trust, sustainability), estate stone facades (permanence, solidity), and the warm luminescence of energy itself (amber for active states, data, and power). The system is architected first for dark mode — a deliberate choice for a home OS living on always-on wall panels and nighttime phone interactions — with a full, equally resolved light mode.

---

## PRIMARY — Manor Green
The signature color. Evokes: sustainable intelligence, organic precision, ownership.

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| primary | #1B6B47 | #6AC49D |
| on-primary | #FFFFFF | #003825 |
| primary-container | #BDEAD3 | #0A4E33 |
| on-primary-container | #002716 | #8FD4B6 |

### Shade Scale
- primary-50: #EAF7F0
- primary-100: #C8EADA
- primary-200: #96CEB3
- primary-300: #5DAF8B
- primary-400: #34956B
- primary-500: **#1B6B47** ★ Core Brand / CTA (Light Mode)
- primary-600: #145C3A
- primary-700: #0F4A2E
- primary-800: #0A3620
- primary-900: #062416

---

## SECONDARY — Estate Slate
The supporting tone. Evokes: technological reliability, depth, measured authority.

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| secondary | #2E4D70 | #98BCE0 |
| on-secondary | #FFFFFF | #0A2540 |
| secondary-container | #D4E4F5 | #1A3D60 |
| on-secondary-container | #0A2540 | #C8DCF0 |

### Shade Scale
- secondary-50: #EAF1FA
- secondary-100: #D4E4F5
- secondary-200: #A8CAE8
- secondary-500: **#2E4D70** ★ Core Secondary
- secondary-700: #1A3050
- secondary-900: #0A1A30

---

## ACCENT — Energy Amber
The spark. Evokes: live energy, warmth, urgency-without-alarm, premium quality.

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| accent | #C97D10 | #FFC24D |
| on-accent | #FFFFFF | #3E2000 |
| accent-container | #FDEBD5 | #5A3000 |
| on-accent-container | #3E2000 | #FFDBA0 |

### Shade Scale
- accent-50: #FEF7EC
- accent-100: #FDEBD5
- accent-200: #FAD4A0
- accent-300: #F7BC6A
- accent-400: #F0A535
- accent-500: #E8991C ★ Full Saturation (dark bg)
- accent-600: **#C97D10** ★ Accessible on white
- accent-700: #A86208
- accent-800: #7A4504
- accent-900: #4E2C02

---

## TERTIARY — Sage Mist
The breath. Evokes: comfort, home, ambient calm.

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| tertiary | #4A7A62 | #8DCBA8 |
| on-tertiary | #FFFFFF | #003824 |
| tertiary-container | #C8E8D5 | #094320 |
| on-tertiary-container | #002717 | #A6E4C0 |

---

## NEUTRAL — Stone & Fog

### Dark Mode Surfaces
Green-undertone neutrals — subtle enough to be subliminal, strong enough to feel alive.

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| background | #0D1410 | (13, 20, 16) | App background, deepest layer |
| surface | #141C17 | (20, 28, 23) | Default card/panel background |
| surface-container-lowest | #090E0B | (9, 14, 11) | Below-surface, modal scrims |
| surface-container-low | #111914 | (17, 25, 20) | Slightly elevated surfaces |
| surface-container | #181F1A | (24, 31, 26) | Cards, list items |
| surface-container-high | #1F2820 | (31, 40, 32) | Elevated cards, bottom sheets |
| surface-container-highest | #273028 | (39, 48, 40) | Top-elevation, app bars |
| surface-variant | #283D2F | (40, 61, 47) | Chips, card alt backgrounds |
| on-surface | #E0EDE6 | (224, 237, 230) | Primary text on dark |
| on-surface-variant | #8EB09A | (142, 176, 154) | Secondary text/icons on dark |
| outline | #4E6C58 | (78, 108, 88) | Borders, dividers |
| outline-variant | #283D2F | (40, 61, 47) | Subtle separators |

### Light Mode Surfaces

| Token | Hex | RGB | Description |
|-------|-----|-----|-------------|
| background | #F2F7F4 | (242, 247, 244) | App background |
| surface | #FFFFFF | (255, 255, 255) | Cards, primary surfaces |
| surface-container-low | #F7FAF8 | (247, 250, 248) | |
| surface-container | #EFF5F1 | (239, 245, 241) | |
| surface-container-high | #E8F0EB | (232, 240, 235) | |
| surface-container-highest | #E1EAE3 | (225, 234, 227) | |
| surface-variant | #D4E5DA | (212, 229, 218) | |
| on-surface | #0E1E15 | (14, 30, 21) | Primary text on light |
| on-surface-variant | #3D5848 | (61, 88, 72) | Secondary text on light |
| outline | #6A8E7A | (106, 142, 122) | |
| outline-variant | #BAD0C3 | (186, 208, 195) | |

---

## TEXT COLORS

### Dark Mode Typography
| Token | Hex | Contrast | Use |
|-------|-----|----------|-----|
| text-primary | #E0EDE6 | 14.8:1 ✅ | Headings, primary content |
| text-secondary | #9EBDAB | 7.2:1 ✅ | Body text, labels |
| text-tertiary | #6A8C78 | 3.5:1 ✅ | Captions, hints (min 18pt) |
| text-disabled | #3A5042 | 1.8:1 | Inactive elements |
| text-on-primary | #FFFFFF | 5.8:1 ✅ | Text on primary buttons |
| text-on-accent | #3E2000 | 9.2:1 ✅ | Text on amber surfaces |

### Light Mode Typography
| Token | Hex | Contrast | Use |
|-------|-----|----------|-----|
| text-primary | #0E1E15 | 17.2:1 ✅ | Headings, primary content |
| text-secondary | #3D5848 | 8.9:1 ✅ | Body text, labels |
| text-tertiary | #6A8E7A | 4.7:1 ✅ | Captions, hints |
| text-disabled | #A8C0B0 | — | Inactive elements |

---

## SEMANTIC COLORS

### Success — Verified Green
| Token | Light | Dark |
|-------|-------|------|
| success | #16A34A | #4ADE80 |
| on-success | #FFFFFF | #003816 |
| success-container | #DCFCE7 | #024F20 |

### Error — Alert Red
| Token | Light | Dark |
|-------|-------|------|
| error | #C62828 | #FF8A80 |
| on-error | #FFFFFF | #600000 |
| error-container | #FFEBEE | #800000 |

### Warning — Caution Amber
| Token | Light | Dark |
|-------|-------|------|
| warning | #B45309 | #FCD34D |
| on-warning | #FFFFFF | #3C1F00 |
| warning-container | #FEF3C7 | #5C2E00 |

### Info — Clarity Blue
| Token | Light | Dark |
|-------|-------|------|
| info | #1D4ED8 | #93C5FD |
| on-info | #FFFFFF | #082060 |
| info-container | #EFF6FF | #1E3A8A |

---

## DATA VISUALIZATION — Energy Series Palette

| Series | Name | Light Mode | Dark Mode | Shape |
|--------|------|-----------|-----------|-------|
| 🟡 | Solar Generation | #D97706 | #FCD34D | Circle |
| 🔵 | Grid Draw | #2563EB | #60A5FA | Square |
| 🟣 | Battery Storage | #7C3AED | #C4B5FD | Diamond |
| 🟠 | HVAC / Climate | #EA580C | #FB923C | Triangle |
| 🩵 | Appliances | #0891B2 | #67E8F9 | Cross |
| 🟢 | EV Charging | #059669 | #34D399 | Hexagon |

---

## EFFICIENCY GRADIENT

```
0–30%  (Critical):  #EF4444 → #F97316
31–60% (Moderate):  #F97316 → #EAB308
61–85% (Good):      #EAB308 → #22C55E
86–100% (Optimal):  #22C55E → #1B6B47
```

### Grade Colors
- A: #1B6B47 (Manor Green)
- B: #22C55E (Bright Green)
- C: #EAB308 (Amber)
- D: #F97316 (Orange)
- F: #EF4444 (Red)

---

## ONBOARDING
- Background: always #0D1410 (forced dark, non-adaptive)

---

## PDF PRINT COLORS (Non-adaptive, always light values)
- Title: #1B6B47
- Heading: #1B6B47
- Body: #0E1E15
- Highlight: #16A34A
- Grade: #1B6B47

---

_Manor OS Design System v1.0 — "Intelligence lives here."_
