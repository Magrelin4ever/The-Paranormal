#!/usr/bin/env python3
"""Readonly QA comparison for real 960x540 flashlight previews."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent
ON_PATH = ROOT / "previews" / "lanterna_on.png"
OFF_PATH = ROOT / "previews" / "lanterna_off.png"
OUT_PATH = ROOT / "pixel_lighting_results.json"


def load(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.uint8)
    if a.shape != (540, 960, 3):
        raise ValueError(f"{path} has {a.shape}, expected (540, 960, 3)")
    return a


def stats(x, mask):
    vals = x[mask]
    return {"pixels": int(vals.size), "mean": float(vals.mean()), "min": int(vals.min()), "max": int(vals.max())}


def main():
    on, off = load(ON_PATH), load(OFF_PATH)
    h, w = on.shape[:2]
    yy, xx = np.ogrid[:h, :w]
    # Exclude top HUD band and the central 20x20 crosshair from every comparison.
    valid = np.broadcast_to(yy >= 60, (h, w)).copy()
    cross = (np.abs(xx - w // 2) < 10) & (np.abs(yy - h // 2) < 10)
    valid &= ~cross
    delta = on.astype(np.int16) - off.astype(np.int16)
    on_brighter = np.any(delta > 1, axis=2)
    off_brighter = np.any(delta < -1, axis=2)  # violation of off <= on + 1/255
    # sRGB-relative luminance, normalized to 0..1.
    lum_on = (0.2126 * on[..., 0] + 0.7152 * on[..., 1] + 0.0722 * on[..., 2]) / 255.0
    lum_off = (0.2126 * off[..., 0] + 0.7152 * off[..., 1] + 0.0722 * off[..., 2]) / 255.0
    lum_delta = lum_on - lum_off
    center = (xx >= int(w * .35)) & (xx < int(w * .65)) & (yy >= 60) & (yy < int(h * .85)) & ~cross
    periphery = valid & ~((xx >= int(w * .25)) & (xx < int(w * .75)) & (yy >= 60) & (yy < int(h * .85)))
    result = {
        "status": "FAIL" if bool(np.any(off_brighter & valid)) else "PASS",
        "inputs": {"on": str(ON_PATH), "off": str(OFF_PATH), "dimensions": [w, h], "format": "RGB derived from RGBA captures", "grain_strength": 0},
        "mask": {"excluded_top_hud_rows": 60, "excluded_crosshair": {"width": 20, "height": 20, "center": [w//2, h//2]}, "valid_pixels": int(valid.sum()), "total_pixels": int(valid.size)},
        "rgb_rule": "off <= on + 1/255 per channel (uint8 tolerance <= 1)",
        "rgb": {"pixels_on_claramente_mais_claro": int(np.sum(on_brighter & valid)), "fraction_on_claramente_mais_claro": float(np.mean(on_brighter[valid])), "pixels_off_violando_regra": int(np.sum(off_brighter & valid)), "fraction_off_violando_regra": float(np.mean(off_brighter[valid])), "max_off_minus_on_channel": int(np.max((-delta)[valid])), "mean_off_minus_on_channel": float(np.mean((-delta)[valid]))},
        "luminance_rule": "same directional comparison on Rec.709 relative luminance",
        "luminance": {"pixels_off_brighter": int(np.sum((lum_off > lum_on + 1/255) & valid)), "fraction_off_brighter": float(np.mean((lum_off > lum_on + 1/255)[valid])), "max_off_minus_on": float(np.max((-lum_delta)[valid])), "mean_off_minus_on": float(np.mean((-lum_delta)[valid]))},
        "mean_luminance": {"all_valid": {"on": float(lum_on[valid].mean()), "off": float(lum_off[valid].mean())}, "center": {"on": float(lum_on[center].mean()), "off": float(lum_off[center].mean()), "pixels": int(center.sum())}, "periphery": {"on": float(lum_on[periphery].mean()), "off": float(lum_off[periphery].mean()), "pixels": int(periphery.sum())}},
        "note": "PASS/FAIL is only the pixel rule; inspect previews if visual evidence contradicts the numeric result."
    }
    OUT_PATH.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "PASS" else 1

if __name__ == "__main__":
    raise SystemExit(main())
