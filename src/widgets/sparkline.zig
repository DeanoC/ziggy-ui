const command_list = @import("../ui/render/command_list.zig");
const Rect = @import("../core/context.zig").Rect;

pub const Source = struct {
    ctx: *const anyopaque,
    count: usize,
    at: *const fn (ctx: *const anyopaque, idx: usize) f32,
};

pub const Options = struct {
    stroke_color: [4]f32,
    fill_color: [4]f32,
    background_color: [4]f32,
    border_color: [4]f32,
    min_value: ?f32 = null,
    max_value: ?f32 = null,
};

pub fn draw(
    commands: *command_list.CommandList,
    rect: Rect,
    source: Source,
    opts: Options,
) void {
    commands.pushRect(
        .{ .min = rect.min, .max = rect.max },
        .{ .fill = opts.background_color },
    );
    commands.pushRect(
        .{ .min = rect.min, .max = rect.max },
        .{ .stroke = opts.border_color },
    );
    if (source.count == 0) return;

    var min_value = opts.min_value orelse source.at(source.ctx, 0);
    var max_value = opts.max_value orelse min_value;
    if (opts.min_value == null or opts.max_value == null) {
        var i: usize = 0;
        while (i < source.count) : (i += 1) {
            const value = source.at(source.ctx, i);
            if (value < min_value) min_value = value;
            if (value > max_value) max_value = value;
        }
    }
    const span = @max(0.0001, max_value - min_value);

    const inner_min_x = rect.min[0] + 1.0;
    const inner_max_x = rect.max[0] - 1.0;
    const inner_min_y = rect.min[1] + 1.0;
    const inner_max_y = rect.max[1] - 1.0;
    const inner_w = @max(1.0, inner_max_x - inner_min_x);
    const inner_h = @max(1.0, inner_max_y - inner_min_y);

    const columns: usize = @max(1, @as(usize, @intFromFloat(@max(1.0, inner_w))));
    var col: usize = 0;
    while (col < columns) : (col += 1) {
        const sample_idx = if (columns <= 1 or source.count <= 1)
            source.count - 1
        else
            @min(
                source.count - 1,
                @as(usize, @intFromFloat((@as(f32, @floatFromInt(col)) * @as(f32, @floatFromInt(source.count - 1))) / @as(f32, @floatFromInt(columns - 1)))),
            );
        const value = source.at(source.ctx, sample_idx);
        const normalized = @max(0.0, @min(1.0, (value - min_value) / span));
        const point_y = inner_max_y - normalized * inner_h;
        const x = inner_min_x + @as(f32, @floatFromInt(col));
        const bar_top = @max(inner_min_y, @min(point_y, inner_max_y));
        const bar_h = @max(1.0, inner_max_y - bar_top);
        commands.pushRect(
            .{ .min = .{ x, bar_top }, .max = .{ x + 1.0, bar_top + bar_h } },
            .{ .fill = opts.fill_color },
        );
        commands.pushRect(
            .{ .min = .{ x, point_y }, .max = .{ x + 1.0, point_y + 1.0 } },
            .{ .fill = opts.stroke_color },
        );
    }
}
