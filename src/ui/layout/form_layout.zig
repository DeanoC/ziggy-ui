const theme = @import("../theme.zig");
const button = @import("../widgets/button.zig");
const text_input = @import("../widgets/text_input.zig");

pub const Metrics = struct {
    inset: f32,
    inner_inset: f32,
    line_height: f32,
    input_height: f32,
    button_height: f32,
    title_gap: f32,
    label_gap: f32,
    label_to_input_gap: f32,
    row_gap: f32,
    section_gap: f32,
};

pub fn titleRowHeight(metrics: Metrics) f32 {
    return @max(
        metrics.line_height + metrics.inner_inset * 1.25,
        metrics.input_height * 0.9,
    );
}

pub fn labelRowHeight(metrics: Metrics) f32 {
    return @max(
        metrics.line_height + metrics.inner_inset * 1.1,
        metrics.input_height * 0.8,
    );
}

pub fn advanceAfterTitle(metrics: Metrics) f32 {
    return @max(metrics.title_gap, titleRowHeight(metrics) + metrics.label_gap);
}

pub fn advanceLabelToInput(metrics: Metrics) f32 {
    return @max(metrics.label_to_input_gap, labelRowHeight(metrics) + metrics.label_gap);
}

pub fn defaultMetrics(t: *const theme.Theme, line_height: f32, ui_scale: f32) Metrics {
    const input_h = text_input.defaultHeight(t, line_height);
    return .{
        .inset = @max(t.spacing.md, 12.0 * ui_scale),
        .inner_inset = @max(t.spacing.xs, 6.0 * ui_scale),
        .line_height = line_height,
        .input_height = input_h,
        .button_height = button.defaultHeight(t, line_height),
        .title_gap = line_height + @max(t.spacing.sm, line_height * 0.32),
        .label_gap = @max(t.spacing.xs, line_height * 0.4),
        .label_to_input_gap = @max(
            input_h,
            line_height + @max(t.spacing.sm, line_height * 0.5),
        ),
        .row_gap = @max(t.spacing.sm, line_height * 0.52),
        .section_gap = @max(t.spacing.md, line_height * 0.8),
    };
}
