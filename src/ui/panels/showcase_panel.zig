const panel_impl = @import("ziggy-ui-panels").showcase_panel;

const Host = struct {
    pub const components = @import("../components/components.zig");
    pub const draw_context = @import("../draw_context.zig");
    pub const input_router = @import("../input/input_router.zig");
    pub const input_state = @import("../input/input_state.zig");
    pub const theme = @import("../theme.zig");
    pub const widgets = @import("../widgets/widgets.zig");
    pub const panel_chrome = @import("../panel_chrome.zig");
    pub const theme_runtime = @import("../theme_engine/runtime.zig");
    pub const nav_router = @import("../input/nav_router.zig");
    pub const surface_chrome = @import("../surface_chrome.zig");
};

const Impl = panel_impl.ShowcasePanel(Host);

pub const Action = Impl.Action;
pub const Options = Impl.Options;
pub const draw = Impl.draw;
