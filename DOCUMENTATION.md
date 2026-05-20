# 2dCard API Reference
Generated: 2026-05-20

A node that can be used to create 2D cards for card games

## Class: Card2D
**Inherits:** [Sprite2D](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html)


### ⚙️ Inspector Variables (Exported)
| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| **_name** | `String;` | `-` | Display name of this card |
| **description** | `String;` | `-` | Flavour text shown in card UI |
| **is_draggable** | `bool` | `true` | Whether the player can drag this card with the mouse |
| **speed** | `float` | `15.0` | SmoothMovement lerp speed for following mouse and snapping |
| **smooth_movement_enabled** | `bool` | `true` | Use SmoothMovement lerp instead of instant position |
| **bounce** | `bool` | `true` | Adds elastic overshoot when the card reaches its target |
| **disable_bounce_while_dragging** | `bool` | `true` | Turns off bounce while actively held |
| **movement_tilt** | `bool` | `true` | Tilts the card based on horizontal velocity |
| **disable_movement_tilt_while_dragging** | `bool` | `true` | Disables tilt while dragging so the card stays flat |
| **fake_3d** | `bool` | `false` | Replaces the Sprite2D with a Polygon2D for pseudo-3D perspective skew |
| **default_scale** | `float` | `1` | Normal scale when idle or in hand |
| **grabbed_scale** | `float` | `1.2` | Scale applied while the card is being dragged |
| **allow_stacking** | `bool` | `false` | Allow multiple cards to occupy the same grid cell |
| **hand** | `CardHand` | `-` | The CardHand this card belongs to; auto-detected if parent is a CardHand |

### 🛠️ Methods
| Method | Arguments | Returns | Description |
| :--- | :--- | :--- | :--- |
| **()** | - | `void` |  Helper function to detect if another card is already at the target snapped position |

---

