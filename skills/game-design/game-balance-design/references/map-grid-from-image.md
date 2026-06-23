# Map Grid from User-Drawn Image

> Technique: Extract room grid layout and connectivity from a user's hand-drawn map image.
> Verified: 2026-06-22 (雾隐山脉 5×5 map design session)

## Workflow

### Step 1: Receive & Describe

When the user says "I drew a picture" or sends an image, use the available vision tools to get an initial description of the layout. Note:
- Grid dimensions
- Labeled special rooms (入口/出口/核心)
- Line types between nodes (arrows vs plain lines)
- Legend entries

### Step 2: Pixel Analysis with PIL

Use `execute_code` with Python/PIL to verify the grid structure programmatically.

```python
from PIL import Image
img = Image.open('/path/to/image.png').convert('RGB')
w, h = img.size
```

#### Find Blue Square Positions

```python
def find_blue_regions(img, step=3):
    w, h = img.size
    rows, cols = [], []
    for y in range(0, h, step):
        blue_count = sum(1 for x in range(0, w, step)
                         if img.getpixel((x, y))[2] > 180
                         and img.getpixel((x, y))[1] > 150
                         and img.getpixel((x, y))[0] < 200)
        if blue_count > 10:
            rows.append(y)
    for x in range(0, w, step):
        blue_count = sum(1 for y in range(0, h, step)
                         if img.getpixel((x, y))[2] > 180
                         and img.getpixel((x, y))[1] > 150
                         and img.getpixel((x, y))[0] < 200)
        if blue_count > 10:
            cols.append(x)
    # Cluster into approximate centers
```

#### Check Connections Between Adjacent Cells

```python
def check_horizontal(img, x_mid, y, threshold=200):
    for dy in range(-15, 16):
        r, g, b = img.getpixel((x_mid, y + dy))
        if r + g + b < threshold:
            return True
    return False

def check_arrow(img, x_mid, y):
    for dx in range(-6, 6, 2):
        for dy in [-4, 4]:
            r, g, b = img.getpixel((x_mid + dx, y + dy))
            if r + g + b < 200:
                return True
    return False
```

#### Build Connectivity Matrix

Combine horizontal and vertical checks into a dict of `(cx, cy) → {north, south, east, west}`.

### Step 3: Cross-reference with Description

The vision description (from step 1) is often more reliable about unidirectional vs bidirectional than pixel heuristics. Trust the description for arrow direction; use pixel checks for confirming connection presence.

### Step 4: Create Confirmation Image

Render the interpreted map using PIL rectangles + arrows, send to user for confirmation before coding.

### Pitfalls

- Arrow detection heuristics are unreliable. The pixel-analysis `check_arrow()` function has high false-positive rates. Trust the human description for arrow directions.
- Connection lines may be at different y offsets than square centers. Scan a range (e.g., ±15px) around the midpoint.
- Color thresholds need tuning per image. Adjust per image.
- The user's drawn grid may not be perfectly aligned. Use clustering rather than assuming uniform spacing.
- Always confirm before implementing. The interpreted connectivity is a hypothesis until the user approves it.
