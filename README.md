# ziggy-ui

A backend-agnostic UI library for Zig with theme engine, widgets, and layout system.

## Features

- **Theme Engine**: JSON-based theme packs with hot-reload support
- **Widget System**: Buttons, checkboxes, text inputs, text editors, focus rings
- **Layout System**: Dock-based layout with panels, rails, and drag-and-drop
- **Backend Agnostic**: Works with WGPU, SDL, or custom renderers
- **Platform Support**: Desktop, Android, WASM

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .ziggy_ui = .{
        .url = "https://github.com/DeanoC/ziggy-ui/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "...",
    },
}
```

Add to your `build.zig`:

```zig
const ziggy_ui_dep = b.dependency("ziggy_ui", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("ziggy-ui", ziggy_ui_dep.module("ziggy-ui"));
```

## Quick Start

```zig
const std = @import("std");
const ui = @import("ziggy-ui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize theme engine
    const caps = ui.PlatformCaps.defaultForTarget();
    var engine = ui.ThemeEngine.init(allocator, caps);
    defer engine.deinit();

    // Load a theme pack
    try engine.loadAndApplyThemePackDir("themes/default");

    // Get current theme
    const theme = ui.theme_engine.theme.current();
    
    // Use widgets...
    const button_height = ui.widgets.button.defaultHeight(theme, 16.0);
}
```

## Theme System

### Creating a Theme Pack

Theme packs are directories with the following structure:

```
themes/my-theme/
├── manifest.json
├── tokens/
│   ├── base.json      # Base tokens (required)
│   ├── light.json     # Light variant (optional)
│   └── dark.json      # Dark variant (optional)
├── styles/
│   └── components.json # Component styles (optional)
├── profiles/
│   ├── desktop.json   # Desktop profile overrides (optional)
│   ├── phone.json     # Phone profile overrides (optional)
│   └── tablet.json    # Tablet profile overrides (optional)
└── assets/
    └── images/        # Theme assets (optional)
```

### Token Format

```json
{
    "colors": {
        "background": [0.078, 0.090, 0.102, 1.0],
        "surface": [0.118, 0.137, 0.169, 1.0],
        "primary": [0.898, 0.580, 0.231, 1.0],
        "text_primary": [0.902, 0.914, 0.929, 1.0],
        ...
    },
    "typography": {
        "font_family": "Space Grotesk",
        "title_size": 22.0,
        "heading_size": 18.0,
        "body_size": 16.0,
        "caption_size": 12.0
    },
    "spacing": {
        "xs": 4.0, "sm": 8.0, "md": 16.0, "lg": 24.0, "xl": 32.0
    },
    "radius": {
        "sm": 4.0, "md": 8.0, "lg": 12.0, "full": 9999.0
    }
}
```

## Widgets

### Button

```zig
const button = ui.widgets.button;

const opts = button.Options{
    .variant = .primary,
    .disabled = false,
};

const state = button.updateState(rect, mouse_pos, mouse_down, opts);
const paint = button.getBackgroundPaint(theme, state, opts.variant, null);
const text_color = button.getTextColor(theme, state, opts.variant);
```

### Checkbox

```zig
const checkbox = ui.widgets.checkbox;

const opts = checkbox.Options{ .checked = true };
const state = checkbox.updateState(rect, mouse_pos, mouse_down, true, opts);
const fill = checkbox.getFillPaint(theme, state, opts);
const border = checkbox.getBorderColor(theme, state, opts);
```

### Text Input

```zig
const text_input = ui.widgets.text_input;

const opts = text_input.Options{
    .placeholder = "Enter text...",
};
const state = text_input.updateState(rect, mouse_pos, clicked, is_focused);
const fill = text_input.getFillPaint(theme, state, opts);
```

## Layout System

### Dock Graph

```zig
var graph = ui.layout.dock_graph.DockGraph.init(allocator);
defer graph.deinit();

// Create root node
const root = try graph.createNode();

// Split node
const split = try graph.splitNode(root, .horizontal, 0.5);

// Calculate layout
graph.calculateLayout(.{ .x = 0, .y = 0, .width = 1024, .height = 768 });
```

### Dock Rail

```zig
var rail = ui.layout.dock_rail.DockRail.init(allocator, .left);
defer rail.deinit();

try rail.addItem(.{
    .id = "chat",
    .icon = "💬",
    .tooltip = "Chat",
});
```

## Architecture

```
ziggy-ui/
├── src/
│   ├── theme_engine/    # Theme loading, profiles, style sheets
│   │   ├── theme_engine.zig
│   │   ├── schema.zig
│   │   ├── profile.zig
│   │   ├── runtime.zig
│   │   ├── style_sheet.zig
│   │   └── theme_package.zig
│   ├── themes/          # Default theme tokens
│   │   ├── theme.zig
│   │   ├── colors.zig
│   │   ├── typography.zig
│   │   └── spacing.zig
│   ├── widgets/         # UI widgets
│   │   ├── button.zig
│   │   ├── checkbox.zig
│   │   ├── text_input.zig
│   │   ├── text_editor.zig
│   │   ├── focus_ring.zig
│   │   └── kinetic_scroll.zig
│   └── layout/          # Layout system
│       ├── dock_graph.zig
│       ├── dock_rail.zig
│       ├── dock_detach.zig
│       ├── dock_drop.zig
│       └── custom_layout.zig
└── themes/              # Example theme packs
    └── default/
```

## Panel Split Scaffold

Application-specific panels are now grouped behind a single boundary module:

- `src/ui/panels/panels.zig`
- `src/ui/panels/interfaces.zig` (panel runtime contract types: action + draw result)
- `src/ui/panels/runtime.zig` (panel dispatch implementation used by main window)

Internal callers should import panel implementations through that module instead of
directly importing individual panel files. This is the extraction seam for moving
panel-level UI into a dedicated repository while keeping core primitives (`widgets`,
`components`, layout, render/input systems, theme engine) in `ziggy-ui`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Desktop (Windows/Linux/macOS) | ✅ Supported | Native builds |
| Android | ⚠️ Partial | Platform-specific code behind configs |
| WASM | ⚠️ Partial | Async theme loading |

## License

MIT License - see LICENSE file for details.

## Version

Current version: 0.1.0

## Roadmap

- [x] Theme engine with JSON packs
- [x] Core widgets (button, checkbox, text input)
- [x] Dock-based layout system
- [ ] Full WGPU renderer integration
- [ ] Full SDL renderer integration
- [ ] Animation system
- [ ] More widgets (slider, dropdown, etc.)
- [ ] Accessibility support
