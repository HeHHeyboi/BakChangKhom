# BakChangKhom — Asset Prompt Commands

ชุดคำสั่งนี้ทำตาม `Docs/ASSET_GUIDE.md` และ `Docs/ASSET_TODO.md` แยกเป็นชุดเล็ก ๆ เพื่อสร้างและตรวจได้ง่าย

## Shared prompt

```text
2D hand-drawn game asset, Don't Starve inspired but brighter, clean imperfect dark-brown outline #2C1810, warm vivid palette, flat two-tone shading, centered object, no cast shadow, transparent background, PNG-ready, consistent scale and angle with the same asset set.
Negative: photorealistic, 3D render, perspective distortion, gradient, background scene, watermark, signature, Thai text, logo, extra objects, cropped object.
```

## Batch 1 — RAM cleaning tools

Output: `Assets/MiniGame/PartRam/`, each `200x200 PNG`, transparent, side view, centered.

```text
ram_tool_brush.png — soft anti-static cleaning brush with wooden handle
ram_tool_blower.png — rubber air blower bulb for electronics, nozzle pointing left
ram_tool_cloth.png — folded blue microfiber cloth
ram_tool_ipa_swab.png — small IPA bottle with droplet icon and cotton swab
ram_tool_eraser_red.png — hard red-and-blue ink eraser
ram_tool_sandpaper.png — folded sheet of sandpaper with rough texture
ram_tool_wet_cloth.png — dripping wet cloth with a few water droplets
ram_tool_hairdryer.png — cartoon hair dryer with subtle heat-wave lines
ram_tool_vacuum.png — small household vacuum nozzle with tiny static sparks
```

`ram_eraser.png` มีอยู่แล้ว จึงไม่ต้องสร้างซ้ำ

## Batch 2 — RAM tool UI

```text
ram_tray.png — front-facing wooden tool tray with ten empty tool slots, 900x220 PNG
ui_tool_card.png — blank paper-like property card frame, 320x200 PNG, no text
ui_meter_pip_on.png — single filled hardness meter pip icon, 24x24 PNG
ui_meter_pip_off.png — single empty hardness meter pip icon, 24x24 PNG
ram_icon_moisture.png — simple water droplet icon, 48x48 PNG
ram_icon_esd.png — simple static-electricity lightning icon, 48x48 PNG
ram_icon_residue.png — simple falling-powder residue icon, 48x48 PNG
ram_icon_narrow.png — simple narrow-gap icon, 48x48 PNG
```

## Batch 3 — Shared ToolBelt

Output: `Assets/MiniGame/PartCommon/`, each `200x200 PNG`, transparent, centered.

```text
tool_screwdriver_flat.png — flathead screwdriver, side view
tool_hex_driver.png — 5mm hex nut driver with visible socket
tool_pliers.png — needle-nose pliers, side view
tool_esd_strap.png — anti-static wrist strap with coiled cord
tool_esd_mat.png — grey anti-static mat, top view
tool_flashlight.png — small desk flashlight with a compact light beam
tool_multimeter.png — cartoon multimeter with two probes
tool_psu_tester.png — small PSU tester box with connectors
tool_usb_installer.png — USB flash drive with a small OS disc icon
tool_thermal_paste.png — thermal paste tube matching mb_thermal_tube style
tool_cable_tie.png — bundle of zip ties matching gpu_cable_tie style
```

ไขควงแฉกใช้ `Assets/MiniGame/PartMainboard/mb_screwdriver.png` ซ้ำได้

## Batch 4 — Part-specific equipment

ทำหลังจาก interaction ผ่านแล้ว โดยดึงเฉพาะรายการที่ยังขาดจากเอกสารแต่ละ Part และใช้กฎนี้:

```text
part-specific asset for <PART>, only the missing state listed in its design document, top-down or straight side view as specified, identical canvas for normal/highlight/disabled states, transparent PNG, no baked-in paragraphs, reusable UI component.
```

## ประมาณการ

- RAM tools: 9 ไฟล์ใหม่
- RAM tool UI: 8 ไฟล์
- Shared ToolBelt: 11 ไฟล์ใหม่ (`tool_screwdriver_flat` เป็น flathead คนละชิ้นกับ screwdriver เดิม)
- รวม tool/equipment ชุดเริ่มต้น: 28 ไฟล์
- ยังไม่รวม tutorial, Pib, background, audio และ state เฉพาะ Part

## Definition of Done

- ขนาดและมุมมองตรงตามชุด
- transparent PNG และ canvas เท่ากันใน state เดียวกัน
- ASCII snake_case
- ไม่มีข้อความฝังในภาพ ยกเว้นไอคอนที่กำหนด
- ตรวจที่ 1152x648 ใน Godot ก่อนทำไฟล์ polish เพิ่ม
