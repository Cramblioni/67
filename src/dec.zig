const std = @import("std");

const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;
const Writer = std.Io.Writer;

const Oper = enum(u8) {
    PushSix,
    PushSeven,
    End,
    Add,
    Subtract,
    Multiply,
    EOF,
};

fn stepInstr(reader: *Reader) Reader.Error!Oper {
    // Instructions:
    //  PushSix     66
    //  PushSeven   67
    //  End         77
    //  Add         7666
    //  Subtract    7667
    //  Multiply    7676
    //  EOF         7677

    return switch (try reader.takeByte()) {
        '6' => switch (try reader.takeByte()) { // Literals
            '6' => .PushSix,
            '7' => .PushSeven,
            else => unreachable,
        },
        '7' => switch (try reader.takeByte()) {
            '6' => switch (try reader.takeByte()) {
                '6' => switch (try reader.takeByte()) {
                    '6' => .Add,
                    '7' => .Subtract,
                    else => unreachable,
                },
                '7' => switch (try reader.takeByte()) {
                    '6' => .Multiply,
                    '7' => .EOF,
                    else => unreachable,
                },
                else => unreachable,
            },
            '7' => .End,
            else => unreachable,
        },
        else => unreachable,
    };
}

pub fn annotate(source: *Reader, out: *Writer) !void {
    while (true) {
        const op = try stepInstr(source);
        try out.print("{}\n", .{op});
        if (op == .EOF) break;
    }
    try out.flush();
}

pub fn decode(alloc: Allocator, source: *Reader, dest: *Writer) !void {
    const stack = try alloc.alloc(u8, 1024 * 64);
    defer alloc.free(stack);
    var sp: u16 = 0;
    while (stepInstr(source)) |instr| {
        switch (instr) {
            .PushSix => {
                stack[sp] = 6;
                sp += 1;
            },
            .PushSeven => {
                stack[sp] = 7;
                sp += 1;
            },
            .EOF => break,
            .End => {
                try dest.writeByte(stack[sp - 1]);
                sp -= 1;
            },
            .Add => {
                const a = stack[sp - 2];
                const b = stack[sp - 1];
                sp -= 1;
                stack[sp - 1] = a +% b;
            },
            .Subtract => {
                const a = stack[sp - 2];
                const b = stack[sp - 1];
                sp -= 1;
                stack[sp - 1] = a -% b;
            },
            .Multiply => {
                const a = stack[sp - 2];
                const b = stack[sp - 1];
                sp -= 1;
                stack[sp - 1] = a *% b;
            },
        }
    } else |e| {
        return e;
    }
    try dest.flush();
    if (sp > 0) {
        return error{Unfinished67Stack}.Unfinished67Stack;
    }
}
