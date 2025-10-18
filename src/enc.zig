const std = @import("std");

const Reader = std.Io.Reader;
const Writer = std.Io.Writer;

const ruleset = @import("ruleset.zig").RuleShorthand;

// will be changed later
pub fn encode(source: *Reader, drain: *Writer) !void {
    while (source.takeByte()) |val| {
        try drain.writeAll(ruleset[val]);
        try drain.writeAll("77");
    } else |err| {
        // Forwarding actual errors
        if (err != error.EndOfStream) return err;
    }
    try drain.writeAll("7677"); // EOF
    try drain.flush();
}
