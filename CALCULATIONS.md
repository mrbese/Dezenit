# Manor OS — Complete Calculation Reference

**App:** Manor OS (Home Energy Auditor)
**Date:** 2026-02-23
**Source:** All formulas extracted verbatim from Swift source code

This document contains every formula, constant, lookup table, parameter range, and hand-verifiable worked example used in Manor OS's energy calculation pipeline. Ten interconnected engines cover BTU loads, window heat gain, annual operating costs, efficiency grading, appliance energy, upgrade recommendations, energy profiles, envelope scoring, and recommendation triggers.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Global Constants](#2-global-constants)
3. [BTU Load Calculation](#3-btu-load-calculation)
4. [Window Heat Gain](#4-window-heat-gain)
5. [Annual Operating Cost](#5-annual-operating-cost)
6. [Efficiency Grading](#6-efficiency-grading)
7. [Appliance Energy](#7-appliance-energy)
8. [Upgrade Engine](#8-upgrade-engine)
9. [Energy Profile & Envelope](#9-energy-profile--envelope)
10. [Recommendation Thresholds](#10-recommendation-thresholds)
11. [Standard References](#11-standard-references)

---

## 1. Overview

Manor OS estimates residential energy performance from room-level LiDAR scans, HVAC equipment data, appliance inventories, and building envelope assessments. The calculation pipeline flows:

```
Room Scan → BTU Load → Equipment Efficiency → Annual Cost
                ↓                ↓                  ↓
          Window Heat Gain   Grading Engine    Upgrade Engine
                                  ↓                  ↓
                           Home Grade      Payback + Tax Credits
                                  ↓
                      Recommendations + Energy Profile
```

All arithmetic is deterministic — no ML models, no API calls, no randomness. Every output is reproducible from the inputs and the constants below.

---

## 2. Global Constants

**Source:** `ManorOS/Utils/Constants.swift`

### Core Factors

| Constant | Value | Description |
|----------|-------|-------------|
| Safety Factor | 1.10 | Applied to final BTU after insulation adjustment |
| BTU per Ton | 12,000 | Conversion from BTU/hr to tonnage |

### Climate Factors (BTU/sq ft)

| Zone | BTU/sq ft | Description |
|------|-----------|-------------|
| Hot | 30 | Desert Southwest, Gulf Coast, Florida |
| Moderate | 25 | Mid-Atlantic, Pacific Coast, Midwest |
| Cold | 35 | Northern US, Mountain West, New England |

### Ceiling Height Factors

| Height | Factor |
|--------|--------|
| 8 ft | 1.00 |
| 9 ft | 1.12 |
| 10 ft | 1.25 |
| 12 ft | 1.50 |

### Insulation Multipliers

| Quality | Multiplier |
|---------|------------|
| Poor | 1.30 |
| Average | 1.00 |
| Good | 0.85 |
| Unknown | 1.00 (falls back to Average) |

### Window BTU per Sq Ft (by direction)

| Direction | BTU/sq ft |
|-----------|-----------|
| South | 150 |
| West | 120 |
| East | 100 |
| North | 40 |

### Window Sizes

| Size | Sq Ft |
|------|-------|
| Small | 10 |
| Medium | 20 |
| Large | 35 |

### Energy Rates

| Rate | Value |
|------|-------|
| Electricity | $0.16/kWh |
| Gas | $1.20/therm |

### Phantom Load Defaults

| Setting | Value |
|---------|-------|
| Entertainment center (TV + soundbar + streaming + console) | 25 W |
| Home office (desktop + monitor + router) | 12 W |
| Kitchen (microwave + coffee maker + toaster) | 8 W |
| Smart power strip savings | 75% reduction |

### Common Bulb Wattages

| Type | Available Wattages |
|------|-------------------|
| LED | 5, 7, 9, 12, 15, 18 W |
| CFL | 9, 13, 18, 23, 26 W |
| Incandescent | 40, 60, 75, 100, 150 W |

---

## 3. BTU Load Calculation

**Source:** `ManorOS/Services/EnergyCalculator.swift`

### Formula Chain

```
baseBTU            = squareFootage × ceilingFactor × climateBTU
windowHeatGain     = Σ(each window's heatGainBTU)                    // see §4
subtotal           = baseBTU + windowHeatGain
afterInsulation    = subtotal × insulationMultiplier
insulationAdj      = afterInsulation − subtotal
finalBTU           = afterInsulation × 1.10
safetyBuffer       = finalBTU − afterInsulation
tonnage            = finalBTU / 12,000
windowHeatGain%    = windowHeatGain / finalBTU × 100
```

### Parameter Ranges

| Parameter | Valid Range |
|-----------|------------|
| squareFootage | > 0 (any positive Double) |
| ceilingHeight | {8, 9, 10, 12} ft |
| climateZone | {Hot, Moderate, Cold} |
| insulation | {Poor, Average, Good, Unknown} |
| windows | 0..N WindowInfo objects |

### Worked Example 1 — Minimal Room (no windows, average insulation)

**Inputs:** 200 sq ft, 8 ft ceiling, Moderate climate, Average insulation, 0 windows

```
baseBTU         = 200 × 1.00 × 25 = 5,000
windowHeatGain  = 0
subtotal        = 5,000 + 0 = 5,000
afterInsulation = 5,000 × 1.00 = 5,000
finalBTU        = 5,000 × 1.10 = 5,500
tonnage         = 5,500 / 12,000 = 0.4583
```

### Worked Example 2 — Large Hot Room (no windows, poor insulation)

**Inputs:** 500 sq ft, 12 ft ceiling, Hot climate, Poor insulation, 0 windows

```
baseBTU         = 500 × 1.50 × 30 = 22,500
windowHeatGain  = 0
subtotal        = 22,500 + 0 = 22,500
afterInsulation = 22,500 × 1.30 = 29,250
finalBTU        = 29,250 × 1.10 = 32,175
tonnage         = 32,175 / 12,000 = 2.6813
```

### Worked Example 3 — Room with Standard Window

**Inputs:** 300 sq ft, 9 ft ceiling, Cold climate, Good insulation, 1 south-facing medium double-pane vinyl good-condition window

```
baseBTU         = 300 × 1.12 × 35 = 11,760
windowHeatGain  = 150 × 20 × (0.30 × 0.95 × 1.00) / 0.285
                = 3,000 × (0.285 / 0.285)
                = 3,000 × 1.0 = 3,000
subtotal        = 11,760 + 3,000 = 14,760
afterInsulation = 14,760 × 0.85 = 12,546
finalBTU        = 12,546 × 1.10 = 13,800.60
tonnage         = 13,800.60 / 12,000 = 1.1501
```

### Worked Example 4 — Cold Climate Mixed Windows

**Inputs:** 400 sq ft, 10 ft ceiling, Cold climate, Average insulation, 2 windows:
- Window A: South, Large, Single pane, Aluminum frame, Poor condition
- Window B: North, Small, Triple pane, Composite frame, Good condition

```
baseBTU = 400 × 1.25 × 35 = 17,500

Window A:
  effectiveU = 1.10 × 1.30 × 1.35 = 1.9305
  heatGain   = 150 × 35 × (1.9305 / 0.285) = 5,250 × 6.7737 = 35,561.84

Window B:
  effectiveU = 0.22 × 0.90 × 1.00 = 0.198
  heatGain   = 40 × 10 × (0.198 / 0.285) = 400 × 0.6947 = 277.89

windowHeatGain = 35,561.84 + 277.89 = 35,839.73
subtotal       = 17,500 + 35,839.73 = 53,339.73
afterInsulation = 53,339.73 × 1.00 = 53,339.73
finalBTU       = 53,339.73 × 1.10 = 58,673.70
tonnage        = 58,673.70 / 12,000 = 4.8895
```

---

## 4. Window Heat Gain

**Source:** `ManorOS/Models/WindowInfo.swift`

### Formula

```
effectiveUFactor = paneU × frameThermalFactor × conditionLeakageFactor
standardUFactor  = 0.285
heatGainBTU      = directionBTU × sizeSqFt × (effectiveUFactor / standardUFactor)
```

The standard U-factor 0.285 represents a baseline double-pane vinyl window in good condition:
`0.30 (double pane) × 0.95 (vinyl) × 1.00 (good) = 0.285`

### Lookup Table: Pane Type U-Factors

| Pane Type | U-Factor | Notes |
|-----------|----------|-------|
| Not Assessed | 0.30 | Assumes double-pane for calculation |
| Single | 1.10 | Pre-1980 homes, poor insulator |
| Double | 0.30 | Standard modern window |
| Triple | 0.22 | Best insulation, cold climates |

### Lookup Table: Frame Thermal Factors

| Material | Factor | Effect |
|----------|--------|--------|
| Not Assessed | 1.00 | Neutral default |
| Aluminum | 1.30 | Worst — high conductivity |
| Wood | 1.00 | Baseline |
| Vinyl | 0.95 | Slightly better than wood |
| Fiberglass | 0.92 | Good insulator |
| Composite | 0.90 | Best thermal performance |

### Lookup Table: Condition Leakage Factors

| Condition | Factor | Effect |
|-----------|--------|--------|
| Not Assessed | 1.00 | Neutral default |
| Good | 1.00 | Seals tight, no drafts |
| Fair | 1.15 | Minor drafts, some fog |
| Poor | 1.35 | Drafty, visible gaps |

### Lookup Table: Direction BTU/sq ft

| Direction | BTU/sq ft |
|-----------|-----------|
| South | 150 |
| West | 120 |
| East | 100 |
| North | 40 |

### Lookup Table: Window Size

| Size | Sq Ft |
|------|-------|
| Small | 10 |
| Medium | 20 |
| Large | 35 |

### Worked Example 1 — Worst-Case Window

**Inputs:** South, Large, Single pane, Aluminum frame, Poor condition

```
effectiveU = 1.10 × 1.30 × 1.35 = 1.9305
heatGain   = 150 × 35 × (1.9305 / 0.285)
           = 5,250 × 6.7737
           = 35,561.84 BTU
```

### Worked Example 2 — Best-Case Window

**Inputs:** North, Small, Triple pane, Composite frame, Good condition

```
effectiveU = 0.22 × 0.90 × 1.00 = 0.198
heatGain   = 40 × 10 × (0.198 / 0.285)
           = 400 × 0.6947
           = 277.89 BTU
```

### Worked Example 3 — Standard Default (Not Assessed)

**Inputs:** South, Medium, Not Assessed pane, Not Assessed frame, Not Assessed condition

```
effectiveU = 0.30 × 1.00 × 1.00 = 0.300
heatGain   = 150 × 20 × (0.300 / 0.285)
           = 3,000 × 1.0526
           = 3,157.89 BTU
```

### Worked Example 4 — Degraded Double-Pane

**Inputs:** West, Large, Double pane, Wood frame, Fair condition

```
effectiveU = 0.30 × 1.00 × 1.15 = 0.345
heatGain   = 120 × 35 × (0.345 / 0.285)
           = 4,200 × 1.2105
           = 5,084.21 BTU
```

---

## 5. Annual Operating Cost

**Source:** `ManorOS/Services/EfficiencyDatabase.swift`

### 5.1 Cooling Cost (Central AC, Heat Pump, Window AC)

```
correctedFactor = climateBTU × fullLoadHours / 1000
annualCost      = (homeSqFt × correctedFactor) / SEER × electricityRate
```

**Corrected Factor Derivation:**

| Zone | BTU/sq ft | Full Load Hours | / 1000 | correctedFactor |
|------|-----------|-----------------|--------|-----------------|
| Hot | 30 | 1,800 | ÷1000 | 54.0 |
| Moderate | 25 | 1,100 | ÷1000 | 27.5 |
| Cold | 35 | 600 | ÷1000 | 21.0 |

### 5.2 Furnace Cost (Gas)

```
correctedFactor = climateBTU × fullLoadHours / 100,000
annualCost      = (homeSqFt × correctedFactor) / (AFUE / 100) × gasRate
```

**Corrected Factor Derivation:**

| Zone | BTU/sq ft | Full Load Hours | / 100,000 | correctedFactor |
|------|-----------|-----------------|-----------|-----------------|
| Hot | 10 | 200 | ÷100000 | 0.02 |
| Moderate | 25 | 600 | ÷100000 | 0.15 |
| Cold | 35 | 1,000 | ÷100000 | 0.35 |

Note: Furnace BTU/sq ft values differ from cooling (Hot=10, not 30) because furnaces heat, not cool.

### 5.3 Water Heater Cost

```
annualCost = 400 / UEF
```

The $400 baseline represents approximate annual water heating cost at UEF 1.0. Applies to both tank and tankless types.

### 5.4 Heat Pump Heating Cost

```
heatingFactor = climateBTU × fullLoadHours / 1000
annualCost    = (homeSqFt × heatingFactor) / HSPF × electricityRate
```

**Heating Factor Derivation:**

| Zone | BTU/sq ft | Full Load Hours | / 1000 | heatingFactor |
|------|-----------|-----------------|--------|---------------|
| Hot | 10 | 200 | ÷1000 | 2.0 |
| Moderate | 25 | 600 | ÷1000 | 15.0 |
| Cold | 35 | 1,000 | ÷1000 | 35.0 |

### 5.5 Annual Savings

```
annualSavings = max(currentCost − upgradedCost, 0)
```

Where each cost is computed via `estimateAnnualCost()` with the respective efficiency value.

### 5.6 Payback Period

```
paybackYears = upgradeCost / annualSavings    (nil if annualSavings ≤ 0)
```

### Efficiency-by-Age Tables

**Source:** `EfficiencyDatabase.swift` — each equipment type has estimated efficiency, code minimum, best-in-class, and typical upgrade cost.

#### Central AC (SEER)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 9.0 | 15.2 | 24.0 | $6,000 |
| 15-20 yr | 11.0 | 15.2 | 24.0 | $6,000 |
| 10-15 yr | 12.5 | 15.2 | 24.0 | $6,000 |
| 5-10 yr | 13.5 | 15.2 | 24.0 | $6,000 |
| 0-5 yr | 15.0 | 15.2 | 24.0 | $6,000 |

#### Heat Pump (SEER)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 9.0 | 15.2 | 25.0 | $7,500 |
| 15-20 yr | 11.5 | 15.2 | 25.0 | $7,500 |
| 10-15 yr | 14.0 | 15.2 | 25.0 | $7,500 |
| 5-10 yr | 16.5 | 15.2 | 25.0 | $7,500 |
| 0-5 yr | 18.0 | 15.2 | 25.0 | $7,500 |

#### Furnace (AFUE %)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 65 | 80 | 98.5 | $4,500 |
| 15-20 yr | 75 | 80 | 98.5 | $4,500 |
| 10-15 yr | 82 | 80 | 98.5 | $4,500 |
| 5-10 yr | 88 | 80 | 98.5 | $4,500 |
| 0-5 yr | 93 | 80 | 98.5 | $4,500 |

#### Water Heater — Tank (UEF)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 0.50 | 0.64 | 3.50 | $3,500 |
| 15-20 yr | 0.57 | 0.64 | 3.50 | $3,500 |
| 10-15 yr | 0.60 | 0.64 | 3.50 | $3,500 |
| 5-10 yr | 0.65 | 0.64 | 3.50 | $3,500 |
| 0-5 yr | 0.67 | 0.64 | 3.50 | $3,500 |

#### Water Heater — Tankless (UEF)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 0.82 | 0.87 | 0.97 | $3,000 |
| 15-20 yr | 0.85 | 0.87 | 0.97 | $3,000 |
| 10-15 yr | 0.87 | 0.87 | 0.97 | $3,000 |
| 5-10 yr | 0.90 | 0.87 | 0.97 | $3,000 |
| 0-5 yr | 0.93 | 0.87 | 0.97 | $3,000 |

#### Window AC (EER)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 8.0 | 10.0 | 15.0 | $800 |
| 15-20 yr | 9.0 | 10.0 | 15.0 | $800 |
| 10-15 yr | 9.5 | 10.0 | 15.0 | $800 |
| 5-10 yr | 10.0 | 10.0 | 15.0 | $800 |
| 0-5 yr | 11.0 | 10.0 | 15.0 | $800 |

#### Thermostat (Savings %)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 0.0 | 5.0 | 15.0 | $225 |
| 15-20 yr | 0.0 | 5.0 | 15.0 | $225 |
| 10-15 yr | 5.0 | 5.0 | 15.0 | $225 |
| 5-10 yr | 7.5 | 5.0 | 15.0 | $225 |
| 0-5 yr | 12.5 | 5.0 | 15.0 | $225 |

Mapping: 0 = manual, 5 = basic programmable, 7.5 = programmable, 12.5 = smart.

#### Insulation (R-value)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 11 | 38 | 60 | $2,200 |
| 15-20 yr | 19 | 38 | 60 | $2,200 |
| 10-15 yr | 30 | 38 | 60 | $2,200 |
| 5-10 yr | 38 | 38 | 60 | $2,200 |
| 0-5 yr | 44 | 38 | 60 | $2,200 |

#### Windows (U-factor — lower is better)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 1.10 | 0.30 | 0.15 | $800 |
| 15-20 yr | 0.55 | 0.30 | 0.15 | $800 |
| 10-15 yr | 0.40 | 0.30 | 0.15 | $800 |
| 5-10 yr | 0.30 | 0.30 | 0.15 | $800 |
| 0-5 yr | 0.27 | 0.30 | 0.15 | $800 |

#### Washer (IMEF)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 1.0 | 1.84 | 2.92 | $1,200 |
| 15-20 yr | 1.4 | 1.84 | 2.92 | $1,200 |
| 10-15 yr | 1.8 | 1.84 | 2.92 | $1,200 |
| 5-10 yr | 2.0 | 1.84 | 2.92 | $1,200 |
| 0-5 yr | 2.2 | 1.84 | 2.92 | $1,200 |

#### Dryer (CEF)

| Age | Estimated | Code Min | Best | Upgrade Cost |
|-----|-----------|----------|------|-------------|
| 20+ yr | 2.5 | 3.01 | 5.2 | $1,000 |
| 15-20 yr | 2.8 | 3.01 | 5.2 | $1,000 |
| 10-15 yr | 3.1 | 3.01 | 5.2 | $1,000 |
| 5-10 yr | 3.4 | 3.01 | 5.2 | $1,000 |
| 0-5 yr | 3.7 | 3.01 | 5.2 | $1,000 |

### Worked Example 1 — Central AC in Hot Climate

**Inputs:** 2,000 sq ft, Hot zone, SEER 9.0, $0.16/kWh

```
correctedFactor = 54.0
annualCost = (2,000 × 54.0) / 9.0 × 0.16
           = 108,000 / 9.0 × 0.16
           = 12,000 × 0.16
           = $1,920.00
```

### Worked Example 2 — Furnace in Cold Climate

**Inputs:** 2,000 sq ft, Cold zone, AFUE 65%, $1.20/therm

```
correctedFactor = 0.35
annualCost = (2,000 × 0.35) / (65 / 100) × 1.20
           = 700 / 0.65 × 1.20
           = 1,076.923 × 1.20
           = $1,292.31
```

### Worked Example 3 — Water Heater Tank

**Inputs:** UEF 0.50

```
annualCost = 400 / 0.50 = $800.00
```

### Worked Example 4 — Heat Pump Heating in Cold Climate

**Inputs:** 2,000 sq ft, Cold zone, HSPF 13.0, $0.16/kWh

```
heatingFactor = 35.0
annualCost = (2,000 × 35.0) / 13.0 × 0.16
           = 70,000 / 13.0 × 0.16
           = 5,384.615 × 0.16
           = $861.54
```

---

## 6. Efficiency Grading

**Source:** `ManorOS/Services/GradingEngine.swift`

### 6.1 Per-Equipment Efficiency Ratio

For most equipment types (higher efficiency = better):

```
range = bestInClass − worstCase
ratio = (current − worstCase) / range
clampedRatio = clamp(ratio, 0, 1)
```

For **windows** (lower U-factor = better, inverted):

```
range = worstCase − bestInClass
ratio = (worstCase − current) / range
clampedRatio = clamp(ratio, 0, 1)
```

### Worst-Case Values Table

| Equipment Type | Worst Case | Best In Class | Direction |
|---------------|------------|---------------|-----------|
| Central AC | 8.0 SEER | 24.0 | Higher = better |
| Heat Pump | 8.0 SEER | 25.0 | Higher = better |
| Furnace | 60.0 AFUE | 98.5 | Higher = better |
| Water Heater (Tank) | 0.45 UEF | 3.50 | Higher = better |
| Water Heater (Tankless) | 0.80 UEF | 0.97 | Higher = better |
| Window AC | 7.0 EER | 15.0 | Higher = better |
| Thermostat | 0.0 % | 15.0 | Higher = better |
| Insulation | 5.0 R-val | 60.0 | Higher = better |
| Windows | 1.2 U-fac | 0.15 | **Lower = better** |
| Washer | 0.8 IMEF | 2.92 | Higher = better |
| Dryer | 2.0 CEF | 5.2 | Higher = better |

### Energy Share Weights

| Equipment Type | Weight |
|---------------|--------|
| Central AC, Heat Pump, Furnace | 0.45 |
| Water Heater (Tank), Water Heater (Tankless) | 0.18 |
| Insulation, Windows | 0.25 |
| Thermostat, Window AC, Washer, Dryer | 0.12 |

### Weighted Equipment Ratio

```
weightedRatio = Σ(clampedRatio_i × weight_i) / Σ(weight_i)
```

### Grade Thresholds

| Grade | Ratio Range | Color |
|-------|-------------|-------|
| A | ≥ 0.85 | Green |
| B | 0.70 – 0.849 | Blue |
| C | 0.55 – 0.699 | Yellow |
| D | 0.40 – 0.549 | Orange |
| F | < 0.40 | Red |

### 6.2 Home Composite Grade

The home-level grade is a weighted composite of three components, with weights depending on data availability:

| Data Available | Equipment | Appliance | Envelope |
|---------------|-----------|-----------|----------|
| All three | 0.60 | 0.20 | 0.20 |
| Equipment + Appliances | 0.75 | 0.25 | 0 |
| Equipment + Envelope | 0.75 | 0 | 0.25 |
| Equipment only | 1.00 | 0 | 0 |

```
compositeRatio = (equipRatio × equipWeight + applianceRatio × appWeight + envelopeRatio × envWeight)
                 / (equipWeight + appWeight + envWeight)
homeGrade = gradeFromRatio(compositeRatio)
```

Envelope ratio = `envelopeScore.score / 100.0` (see §9 for scoring).

### 6.3 Appliance Efficiency Ratio

```
baseScore = 0.50

// LED bonus: up to +0.25
ledRatio = ledBulbQty / totalLightingQty
score += ledRatio × 0.25

// Incandescent penalty: up to −0.25
incandescentRatio = incandescentBulbQty / totalLightingQty
score −= incandescentRatio × 0.25

// Phantom load penalty: if phantom > 15% of active kWh
phantomRatio = totalPhantomKWh / totalActiveKWh
if phantomRatio > 0.15:
    score −= min((phantomRatio − 0.15) × 0.5, 0.15)

score = clamp(score, 0, 1)
```

### Worked Example 1 — Old Central AC (Grade F)

**Inputs:** Central AC, 20+ years, estimated efficiency 9.0 SEER

```
worst = 8.0, best = 24.0
range = 24.0 − 8.0 = 16.0
ratio = (9.0 − 8.0) / 16.0 = 1.0 / 16.0 = 0.0625
grade = F (0.0625 < 0.40)
```

### Worked Example 2 — New Furnace (Grade A)

**Inputs:** Furnace, 0-5 years, estimated efficiency 93.0 AFUE

```
worst = 60.0, best = 98.5
range = 98.5 − 60.0 = 38.5
ratio = (93.0 − 60.0) / 38.5 = 33.0 / 38.5 = 0.8571
grade = A (0.8571 ≥ 0.85)
```

### Worked Example 3 — Windows (Grade A, inverted)

**Inputs:** Windows, 0-5 years, estimated U-factor 0.27

```
worst = 1.2, best = 0.15
range = 1.2 − 0.15 = 1.05
ratio = (1.2 − 0.27) / 1.05 = 0.93 / 1.05 = 0.8857
grade = A (0.8857 ≥ 0.85)
```

### Worked Example 4 — Home Composite (Grade D)

**Inputs:** Home has equipment only (no appliances, no envelope)
- Central AC: 9.0 SEER → ratio 0.0625, weight 0.45
- Furnace: 75 AFUE → ratio = (75−60)/38.5 = 0.3896, weight 0.45
- Water Heater Tank: 0.50 UEF → ratio = (0.50−0.45)/3.05 = 0.0164, weight 0.18

```
Equipment only → equipWeight = 1.0

weightedSum = (0.0625 × 0.45) + (0.3896 × 0.45) + (0.0164 × 0.18)
            = 0.02813 + 0.17532 + 0.00295
            = 0.20640
totalWeight = 0.45 + 0.45 + 0.18 = 1.08

compositeRatio = 0.20640 / 1.08 = 0.1911

homeRatio = 0.1911 × 1.0 / 1.0 = 0.1911
grade = F (0.1911 < 0.40)
```

*(With such old/poor equipment, the home earns an F, not D.)*

**Alternate D example** — add a newer Insulation (5-10 yr, R-38):

```
Insulation ratio = (38 − 5) / 55 = 33/55 = 0.6000, weight 0.25

weightedSum = 0.02813 + 0.17532 + 0.00295 + (0.6000 × 0.25)
            = 0.20640 + 0.15000 = 0.35640
totalWeight = 1.08 + 0.25 = 1.33

compositeRatio = 0.35640 / 1.33 = 0.2679 → still F

Add Windows (5-10 yr, U=0.30):
  ratio = (1.2 − 0.30) / 1.05 = 0.8571, weight 0.25

weightedSum = 0.35640 + (0.8571 × 0.25) = 0.35640 + 0.21428 = 0.57068
totalWeight = 1.33 + 0.25 = 1.58

compositeRatio = 0.57068 / 1.58 = 0.3612 → F

Add Thermostat (0-5 yr, 12.5):
  ratio = (12.5 − 0) / 15 = 0.8333, weight 0.12

weightedSum = 0.57068 + (0.8333 × 0.12) = 0.57068 + 0.10000 = 0.67068
totalWeight = 1.58 + 0.12 = 1.70

compositeRatio = 0.67068 / 1.70 = 0.3945 → F (barely)

Replace furnace with 88 AFUE (5-10 yr):
  ratio = (88 − 60) / 38.5 = 28/38.5 = 0.7273, weight 0.45

weightedSum (recalc) = (0.0625×0.45) + (0.7273×0.45) + (0.0164×0.18) + 0.15 + 0.21428 + 0.10
  = 0.02813 + 0.32729 + 0.00295 + 0.15 + 0.21428 + 0.10 = 0.82265
totalWeight = 1.70

compositeRatio = 0.82265 / 1.70 = 0.4839 → D (0.40 ≤ 0.4839 < 0.55)
```

---

## 7. Appliance Energy

**Source:** `ManorOS/Models/Appliance.swift`

### Formulas

```
annualKWh        = wattage × hoursPerDay × 365 / 1000 × quantity
phantomAnnualKWh = phantomWatts × (24 − hoursPerDay) × 365 / 1000 × quantity
totalAnnualKWh   = annualKWh + phantomAnnualKWh
annualCost       = annualKWh × electricityRate
```

Phantom load is only calculated for categories where `isPhantomLoadRelevant == true`.

### Complete 25-Category Default Table

| Category | Group | Wattage (W) | Hours/Day | Phantom (W) | Phantom Relevant? |
|----------|-------|-------------|-----------|-------------|-------------------|
| Television | Entertainment | 100 | 5 | 5 | Yes |
| Gaming Console | Entertainment | 150 | 2 | 10 | Yes |
| Soundbar | Entertainment | 30 | 4 | 3 | Yes |
| Streaming Device | Entertainment | 5 | 5 | 2 | Yes |
| Desktop Computer | Computing | 200 | 6 | 5 | Yes |
| Laptop | Computing | 50 | 6 | 2 | Yes |
| Monitor | Computing | 30 | 6 | 2 | Yes |
| Router/Modem | Computing | 12 | 24 | 0 | Yes* |
| Refrigerator | Kitchen | 150 | 24 | 0 | No |
| Freezer | Kitchen | 100 | 24 | 0 | No |
| Dishwasher | Kitchen | 1,800 | 1 | 0 | No |
| Microwave | Kitchen | 1,100 | 0.3 | 3 | Yes |
| Oven/Range | Kitchen | 2,500 | 1 | 0 | No |
| Coffee Maker | Kitchen | 900 | 0.5 | 2 | Yes |
| Toaster/Toaster Oven | Kitchen | 1,200 | 0.2 | 1 | Yes |
| LED Bulb | Lighting | 9 | 5 | 0 | No |
| CFL Bulb | Lighting | 13 | 5 | 0 | No |
| Incandescent Bulb | Lighting | 60 | 5 | 0 | No |
| Floodlight | Lighting | 65 | 4 | 0 | No |
| Lamp/Fixture | Lighting | 60 | 5 | 0 | No |
| Ceiling Fan | Other | 75 | 8 | 0 | No |
| Portable Heater | Other | 1,500 | 4 | 0 | No |
| Dehumidifier | Other | 300 | 12 | 0 | No |
| Pool Pump | Other | 1,500 | 8 | 0 | No |
| EV Charger | Other | 7,200 | 3 | 0 | No |
| Other | Other | 100 | 2 | 0 | No |

*Router is `isPhantomLoadRelevant = true` but `phantomWatts = 0` because it runs 24/7 (no standby mode).

### Worked Example 1 — Television with Phantom Load

**Inputs:** 1 TV, 100 W, 5 hr/day, phantom 5 W

```
annualKWh   = 100 × 5 × 365 / 1000 × 1 = 182.50 kWh
phantomKWh  = 5 × (24 − 5) × 365 / 1000 × 1 = 5 × 19 × 365 / 1000 = 34.675 kWh
totalKWh    = 182.50 + 34.675 = 217.175 kWh
annualCost  = 182.50 × 0.16 = $29.20
```

### Worked Example 2 — LED Bulbs

**Inputs:** 20 LED bulbs, 9 W each, 5 hr/day, no phantom

```
annualKWh   = 9 × 5 × 365 / 1000 × 20 = 328.50 kWh
phantomKWh  = 0 (not phantom-relevant)
annualCost  = 328.50 × 0.16 = $52.56
```

### Worked Example 3 — Refrigerator

**Inputs:** 1 refrigerator, 150 W, 24 hr/day, no phantom

```
annualKWh   = 150 × 24 × 365 / 1000 × 1 = 1,314.00 kWh
phantomKWh  = 0 (not phantom-relevant)
annualCost  = 1,314.00 × 0.16 = $210.24
```

---

## 8. Upgrade Engine

**Source:** `ManorOS/Services/UpgradeEngine.swift`

### 8.1 Cost Scaling

Equipment install costs scale with home size using linear interpolation:

```
t         = clamp((sqFt − 2000) / 1000, 0, 1)
scaledLow = low + (high − low) × t × 0.3
scaledHigh = low + (high − low) × (0.3 + t × 0.7)
```

- Homes ≤ 2,000 sq ft: t = 0 → scaledLow = low, scaledHigh = low + range×0.3
- Homes ≥ 3,000 sq ft: t = 1 → scaledLow = low + range×0.3, scaledHigh = high

### 8.2 Payback & Tax Credit Formulas

```
avgCost           = (costLow + costHigh) / 2
paybackYears      = avgCost / annualSavings                    (nil if savings ≤ 0)
creditAmount      = min(avgCost × taxCreditPercent, taxCreditCap)
effectiveCost     = max(avgCost − creditAmount, 0)
effectivePayback  = effectiveCost / annualSavings              (nil if savings ≤ 0)
```

### 8.3 Tax Credit Programs

**IRS Section 25C — Energy Efficient Home Improvement Credit:**
- Annual cap: **$3,200/yr** (aggregate across all 25C-eligible upgrades)
- Per-item caps vary (see tier table below)
- 30% of cost up to the cap

**IRS Section 25D — Residential Clean Energy Credit:**
- **No annual cap** — 30% of full cost
- Applies to heat pumps, heat pump water heaters, solar

```
capped25C = min(sum of all 25C credits, 3200)
total     = capped25C + sum25D
```

### 8.4 Complete Tier Targets Table

| Equipment | Good | Better | Best |
|-----------|------|--------|------|
| **Central AC** | 16 SEER | 20 SEER | 24 SEER + HP (13 HSPF) |
| **Heat Pump** | 16 SEER | 20 SEER | 25 SEER / 13 HSPF |
| **Furnace** | 90% AFUE | 96% AFUE | HP replacement (22 SEER / 13 HSPF) |
| **Water Heater (Tank)** | 0.70 UEF | 0.95 UEF | 3.5 UEF (HP water heater) |
| **Water Heater (Tankless)** | 0.90 UEF | 0.95 UEF | 3.5 UEF (HP water heater) |
| **Window AC** | 12 EER | 15 EER | 22 SEER (mini-split) |
| **Thermostat** | 7-day programmable | WiFi smart | Multi-zone smart + sensors |
| **Insulation** | R-38 | R-49 | R-60 |
| **Windows** | U-0.30 | U-0.22 | U-0.15 |
| **Washer** | 2.0 IMEF | 2.5 IMEF | 2.92 IMEF |
| **Dryer** | 3.5 CEF | 4.0 CEF | 5.2 CEF |

### 8.5 Cost Ranges by Tier

| Equipment | Good (Low–High) | Better (Low–High) | Best (Low–High) | Tax Credit |
|-----------|-----|--------|------|------|
| Central AC | $4,000–6,500 | $6,000–9,000 | $8,000–14,000 | 25C: $600 / Best: 25D $2,000 |
| Heat Pump | $5,000–7,500 | $7,000–10,000 | $10,000–16,000 | 25D: $2,000 all tiers |
| Furnace | $2,500–4,500 | $3,500–6,000 | $8,000–14,000 | Better: 25C $600 / Best: 25D $2,000 |
| WH Tank | $800–1,500 | $1,500–2,500 | $2,500–4,500 | Better: 25C $600 / Best: 25D $2,000 |
| WH Tankless | $1,200–2,000 | $2,000–3,000 | $2,500–4,500 | Better: 25C $600 / Best: 25D $2,000 |
| Window AC | $300–600 | $500–900 | $3,000–5,000* | Best: 25D $2,000 |
| Thermostat | $30–80 | $120–250 | $200–350 | Better/Best: 25C $150 |
| Insulation | sqft×$1.20–1.80 | sqft×$2.00–3.00 | sqft×$3.20–4.80 | 25C: $1,200 all tiers |
| Windows | #win×$480–720 | #win×$720–1,080 | #win×$1,120–1,680 | 25C: $600 all tiers |
| Washer | $600–900 | $900–1,300 | $1,500–2,500 | None |
| Dryer | $500–800 | $800–1,200 | $1,100–1,800 | None |

*Window AC "Best" (mini-split) uses scaleCost; others are fixed.

Note: Insulation costs are `sqFt × perSqFtRate × {0.8, 1.2}` (Good: $1.50/sqft, Better: $2.50/sqft, Best: $4.00/sqft). Windows costs are `windowCount × perWindowRate × {0.8, 1.2}` where `windowCount = max(floor(sqFt/150), 5)` (Good: $600/win, Better: $900/win, Best: $1,400/win).

### 8.6 Thermostat Savings Estimate

Thermostat uses a unique approach — savings are a percentage of estimated annual HVAC cost:

```
annualHVACCost = sqFt × 2.5    (rough $/yr estimate)
goodSavings    = annualHVACCost × 0.08
betterSavings  = annualHVACCost × 0.12
bestSavings    = annualHVACCost × 0.15
```

### 8.7 Insulation Savings Estimate

```
annualHVACCost = sqFt × 2.5
currentRatio   = min(currentR / 60.0, 1.0)
targetRatio    = min(targetR / 60.0, 1.0)
savings        = max((targetRatio − currentRatio) × annualHVACCost × 0.3, 0)
```

### 8.8 Windows Savings Estimate

```
annualHVACCost    = sqFt × 2.5
windowShareOfLoss = 0.25
reduction         = max((currentU − targetU) / currentU, 0)
savings           = annualHVACCost × windowShareOfLoss × reduction
```

### Worked Example 1 — Central AC Good Tier

**Inputs:** Current 9.0 SEER, 2,000 sq ft, Hot climate

```
Cost scaling: t = clamp((2000−2000)/1000, 0, 1) = 0
scaledLow  = 4000 + 2500 × 0 × 0.3 = $4,000
scaledHigh = 4000 + 2500 × (0.3 + 0 × 0.7) = 4000 + 750 = $4,750
avgCost    = (4000 + 4750) / 2 = $4,375

Current annual cost = (2000 × 54) / 9.0 × 0.16 = $1,920
Target annual cost  = (2000 × 54) / 16.0 × 0.16 = $1,080
annualSavings = 1920 − 1080 = $840

paybackYears = 4375 / 840 = 5.21 years

Tax credit (25C, 30%, cap $600):
  creditAmount = min(4375 × 0.30, 600) = min(1312.50, 600) = $600
  effectiveCost = 4375 − 600 = $3,775
  effectivePayback = 3775 / 840 = 4.49 years
```

### Worked Example 2 — Water Heater Tank Best Tier (Heat Pump WH)

**Inputs:** Current 0.50 UEF, 2,000 sq ft

```
Cost scaling: t = 0
scaledLow  = 2500 + 2000 × 0 × 0.3 = $2,500
scaledHigh = 2500 + 2000 × 0.3 = $3,100
avgCost    = (2500 + 3100) / 2 = $2,800

currentCost = 400 / 0.50 = $800
targetCost  = 400 / 3.50 = $114.29
annualSavings = 800 − 114.29 = $685.71

paybackYears = 2800 / 685.71 = 4.08 years

Tax credit (25D, 30%, uncapped):
  creditAmount = 2800 × 0.30 = $840
  effectiveCost = 2800 − 840 = $1,960
  effectivePayback = 1960 / 685.71 = 2.86 years
```

### Worked Example 3 — Insulation Good Tier

**Inputs:** Current R-11, 2,000 sq ft

```
annualHVACCost = 2000 × 2.5 = $5,000
currentRatio   = min(11 / 60, 1) = 0.1833
goodRatio      = min(38 / 60, 1) = 0.6333
savings        = max((0.6333 − 0.1833) × 5000 × 0.3, 0)
               = 0.4500 × 5000 × 0.3
               = $675.00

costLow  = 2000 × 1.5 × 0.8 = $2,400
costHigh = 2000 × 1.5 × 1.2 = $3,600
avgCost  = (2400 + 3600) / 2 = $3,000

paybackYears = 3000 / 675 = 4.44 years

Tax credit (25C, 30%, cap $1,200):
  creditAmount = min(3000 × 0.30, 1200) = min(900, 1200) = $900
  effectiveCost = 3000 − 900 = $2,100
  effectivePayback = 2100 / 675 = 3.11 years
```

### Worked Example 4 — Thermostat Better Tier

**Inputs:** 2,000 sq ft

```
annualHVACCost = 2000 × 2.5 = $5,000
annualSavings  = 5000 × 0.12 = $600

costLow  = $120
costHigh = $250
avgCost  = (120 + 250) / 2 = $185

paybackYears = 185 / 600 = 0.31 years

Tax credit (25C, 30%, cap $150):
  creditAmount = min(185 × 0.30, 150) = min(55.50, 150) = $55.50
  effectiveCost = 185 − 55.50 = $129.50
  effectivePayback = 129.50 / 600 = 0.22 years
```

---

## 9. Energy Profile & Envelope

**Source:** `ManorOS/Services/EnergyProfileService.swift`

### 9.1 Bill Data Derivation

**Source:** `ManorOS/Models/EnergyBill.swift`, `ManorOS/Models/Home.swift`

Each uploaded energy bill stores `totalKWh`, `totalCost`, and optional `billingPeriodStart`/`billingPeriodEnd` dates.

```
billingDays      = calendar days from start to end
dailyAverageKWh  = totalKWh / billingDays
annualizedKWh    = dailyAverageKWh × 365
computedRate     = ratePerKWh (if explicit and > 0)
                 | totalCost / totalKWh (if both > 0)
                 | $0.16 default
```

At the Home level, bill data is aggregated:

```
billBasedAnnualKWh  = average of all bills' annualizedKWh
actualElectricityRate = average of all bills' computedRate (or $0.16 if no bills)
```

### 9.2 Bill Comparison

```
estimatedKWh = totalEstimatedCost / electricityRate
gap          = |billKWh − estimatedKWh| / billKWh × 100
```

**Accuracy Labels:**

| Gap % | Label |
|-------|-------|
| 0 – 9.99% | Excellent |
| 10 – 24.99% | Good |
| 25 – 39.99% | Fair |
| 40%+ | Review Needed |

### 9.3 Envelope Scoring

Five factors, each scored out of 20 points (maximum 100):

```
totalScore = atticScore + wallScore + basementScore + airSealingScore + weatherstrippingScore
```

**Insulation Scoring (Attic, Walls):**

| Quality | Score |
|---------|-------|
| Good | 20 |
| Average | 12 |
| Unknown | 12 |
| Poor | 5 |

**Basement Insulation Scoring:**

| Value | Score |
|-------|-------|
| Full | 20 |
| Partial | 12 |
| Uninsulated (default) | 5 |

**Air Sealing / Weatherstripping Scoring:**

| Value | Score |
|-------|-------|
| Good | 20 |
| Fair | 12 |
| Poor (default) | 5 |

**Envelope Grade:**

| Score Range | Grade |
|-------------|-------|
| 85 – 100 | A |
| 70 – 84 | B |
| 55 – 69 | C |
| 40 – 54 | D |
| 0 – 39 | F |

The weakest area (lowest individual score) is flagged in the report.

### 9.4 Energy Profile Breakdown

The profile aggregates costs into categories:

1. **HVAC** — Central AC, Heat Pump, Furnace, Window AC, Thermostat, Insulation, Windows
2. **Water Heating** — Water Heater (Tank), Water Heater (Tankless)
3. **Appliances** — Non-lighting appliances
4. **Lighting** — LED, CFL, Incandescent, Floodlight, Lamp/Fixture categories
5. **Standby** — Total phantom load cost (only shown if > $5/yr)

```
phantomCost = totalPhantomAnnualKWh × electricityRate
totalCost   = hvacCost + waterHeatingCost + applianceCost + lightingCost + phantomCost
percentage  = categoryCost / totalCost × 100
```

Top 5 consumers (equipment + appliances, sorted by cost) are highlighted.

### Worked Example 1 — All-Good Envelope

**Inputs:** Attic=Good, Walls=Good, Basement=Full, AirSealing=Good, Weatherstripping=Good

```
score = 20 + 20 + 20 + 20 + 20 = 100
grade = A
weakest = all tied at 20
```

### Worked Example 2 — Mixed Envelope

**Inputs:** Attic=Poor, Walls=Average, Basement=Partial, AirSealing=Fair, Weatherstripping=Good

```
score = 5 + 12 + 12 + 12 + 20 = 61
grade = C (55 ≤ 61 < 70)
weakest = Attic Insulation (score 5)
```

### Worked Example 3 — Bill Comparison

**Inputs:** billKWh = 12,000 kWh/yr, totalEstimatedCost = $2,100, rate = $0.16

```
estimatedKWh = 2100 / 0.16 = 13,125 kWh
gap          = |12000 − 13125| / 12000 × 100
             = 1125 / 12000 × 100
             = 9.375%
label        = "Excellent" (< 10%)
```

---

## 10. Recommendation Thresholds

**Source:** `ManorOS/Services/RecommendationEngine.swift`

The recommendation engine has two scopes: **room-level** (triggered from BTU scan results) and **home-level** (triggered from the full home profile).

### 10.1 Room-Level Recommendations

#### Low-E Window Film

**Trigger:** Any south or west windows AND insulation ≠ Good

```
highGainBTU = Σ heatGainBTU of south/west windows
savingsBTU  = highGainBTU × 0.275     // midpoint of 25–30% reduction
```

**Output:** "Low-E Window Film" — saves ~{savingsBTU} BTU/hr peak load

#### Attic Insulation Upgrade

**Trigger:** insulation == Poor

**Output:** "Upgrade to R-49 Attic Insulation" — 1.0–1.5 kW peak load reduction

#### Excessive Glazing

**Trigger:** totalWindowArea > squareFootage × 0.30

```
totalWindowArea = Σ(each window's size.sqFt)
threshold       = squareFootage × 0.30
```

**Output:** "Reduce Thermal Glazing Exposure" — 10–20% reduction in window-related load

#### Ceiling Fan Destratification

**Trigger:** ceilingHeight > 10 ft (i.e., 12 ft ceiling)

**Output:** "Install Ceiling Fans for Destratification" — 5–10% heating season savings

#### Duct Sealing (Always)

**Trigger:** Always included

**Context:** Industry average duct leakage is 20–30%. Target is <4% leakage rate.

**Output:** "Aerosol Duct Sealing" — 15–20% conditioned air recovered

### 10.2 Home-Level Recommendations

#### Attic Insulation (Envelope)

**Trigger:** envelope.atticInsulation == Poor

**Output:** "Upgrade Attic Insulation" — 15–25% HVAC savings

#### Air Sealing (Envelope)

**Trigger:** envelope.airSealing == "Poor"

**Output:** "Professional Air Sealing" — $150–$300/yr savings (cost: $350–$700)

#### Weatherstripping (Envelope)

**Trigger:** envelope.weatherstripping == "Poor"

**Output:** "Replace Weatherstripping" — $50–$100/yr savings (cost: $20–$50 per door)

#### LED Switch

**Trigger:** Any incandescent bulbs present (quantity > 0)

```
avgHoursPerDay = average hoursPerDay across incandescent entries
savingsPerBulb = 0.051 kW   // 60W incandescent → 9W LED = 51W delta
annualSavings  = totalIncandescentQty × 0.051 × avgHours × 365 × electricityRate
```

**Output:** "Switch {N} Incandescent Bulbs to LED" — ${annualSavings}/yr

#### Smart Power Strips

**Trigger:** totalPhantomAnnualKWh > 100 kWh/yr

```
phantomCost      = phantomKWh × electricityRate
savingsWithStrip = phantomCost × 0.75    // 75% phantom reduction
```

**Output:** "Smart Power Strips for Phantom Loads" — ${savingsWithStrip}/yr

#### Thermostat Setback (Always)

**Trigger:** Always included (behavioral recommendation)

**Output:** "Thermostat Setback Schedule" — up to 10% HVAC savings

#### Off-Peak Shift

**Trigger:** billBasedAnnualKWh > 8,000 kWh/yr

**Output:** "Shift Usage to Off-Peak Hours" — 5–15% bill reduction

---

## 11. Standard References

The following industry standards and data sources inform the constants, ranges, and methodologies used in Manor OS:

### HVAC Load Calculation
- **ACCA Manual J** — Residential Load Calculation (8th Edition). Source for BTU/sq ft factors, safety factors, and climate zone methodology.
- **ASHRAE Fundamentals** — Handbook of Fundamentals. Source for window solar heat gain coefficients and building envelope thermal properties.

### Equipment Efficiency
- **DOE ENERGY STAR** — Federal minimum efficiency standards and ENERGY STAR certification thresholds for HVAC, water heating, and appliance equipment.
- **AHRI (Air-Conditioning, Heating, and Refrigeration Institute)** — Certified ratings directory for SEER, HSPF, AFUE, and UEF values.

### Windows & Envelope
- **NFRC (National Fenestration Rating Council)** — U-factor certification and testing standards for windows, doors, and skylights.
- **IECC (International Energy Conservation Code)** — Building code requirements for insulation R-values and window U-factors by climate zone.

### Tax Credits
- **IRS Section 25C** — Energy Efficient Home Improvement Credit. 30% of cost, annual cap $3,200. Covers: central AC (≥16 SEER, cap $600), furnace (≥97% AFUE, cap $600), insulation (cap $1,200), windows (ENERGY STAR, cap $600), smart thermostat (cap $150), water heater (cap $600).
- **IRS Section 25D** — Residential Clean Energy Credit. 30% of cost, no annual cap. Covers: heat pumps, heat pump water heaters, solar panels, geothermal, battery storage.

### Appliance Data
- **DOE Appliance Standards** — Federal energy conservation standards for residential appliances.
- **Lawrence Berkeley National Laboratory** — Standby power (phantom load) measurements for consumer electronics and appliances.

---

*End of document. All formulas are deterministic and reproducible from the source code listed in each section header.*
