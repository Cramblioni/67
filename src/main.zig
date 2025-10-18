const std = @import("std");
const dec = @import("dec");

// The CLI stuff

const Usage =
    \\Usage: 67 [-d] [input [output]]
    \\       67 -a [input]
    \\Both `input` and `output` file paths are optional,
    \\defaulting to stdin/stdout.
    \\Switches:
    \\      -d : Decode
    \\      -a : Annotate
;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.smp_allocator);
    defer std.process.argsFree(std.heap.smp_allocator, args);

    if (args.len == 1) try onEncode(args[1..]); // Special case
    if (args.len < 2) { // minimum n of args is ~2
        onInvalid();
    }
    if (std.mem.eql(u8, args[1], "-d")) return try onDecode(args[2..]);
    if (std.mem.eql(u8, args[1], "-a")) return try onAnnotate(args[2..]);
    try onEncode(args[1..]);
}

fn onEncode(args: []const []const u8) !void {
    _ = args;
    std.log.err("Encoding is not implemented yet :)", .{});
    return;
}

fn onDecode(args: []const []const u8) !void {
    var pipeline = try Pipeline.get(args);
    defer pipeline.deinit();

    try dec.decode(
        std.heap.smp_allocator,
        &pipeline.input.interface,
        &pipeline.output.interface,
    );
}

fn onAnnotate(args: []const []const u8) !void {
    var pipeline = try Pipeline.get(args);
    defer pipeline.deinit();

    try dec.annotate(
        &pipeline.input.interface,
        &pipeline.output.interface,
    );
}

fn onInvalid() noreturn {
    std.debug.print("{s}\n", .{Usage});
    std.process.exit(1);
}

// File pipeline

const Pipeline = struct {
    input: std.fs.File.Reader,
    output: std.fs.File.Writer,

    fn get(paths: []const []const u8) !Pipeline {
        var out: Pipeline = undefined;

        const inBuff = try std.heap.smp_allocator.alloc(u8, 1024);
        errdefer std.heap.smp_allocator.free(inBuff);

        const outBuff = try std.heap.smp_allocator.alloc(u8, 1024);
        errdefer std.heap.smp_allocator.free(outBuff);

        if (paths.len <= 0) { // setup stdin and stdout
            out.input = std.fs.File.stdin().reader(inBuff);
            out.output = std.fs.File.stdout().writer(outBuff);
            return out;
        }

        const inFile = try std.fs.cwd().openFile(paths[0], .{
            .mode = .read_only,
        });
        errdefer inFile.close();
        out.input = inFile.reader(inBuff);

        if (paths.len <= 1) { // setup stdout
            out.output = std.fs.File.stdout().writer(outBuff);
            return out;
        }

        const outFile = try std.fs.cwd().openFile(paths[1], .{
            .mode = .write_only,
        });
        errdefer outFile.close();
        out.output = outFile.writer(outBuff);

        return out;
    }
    fn deinit(self: Pipeline) void {
        self.input.file.close();
        self.output.file.close();
        std.heap.smp_allocator.free(self.output.interface.buffer);
        std.heap.smp_allocator.free(self.input.interface.buffer);
    }
};
