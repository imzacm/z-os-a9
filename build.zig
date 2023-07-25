const std = @import("std");
const Builder = @import("std").build.Builder;
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;

const x86_target = blk: {
    const features = Target.x86.Feature;
    var disabled_features = Feature.Set.empty;
    disabled_features.addFeature(@intFromEnum(features.mmx));
    disabled_features.addFeature(@intFromEnum(features.sse));
    disabled_features.addFeature(@intFromEnum(features.sse2));
    disabled_features.addFeature(@intFromEnum(features.avx));
    disabled_features.addFeature(@intFromEnum(features.avx2));

    var enabled_features = Feature.Set.empty;
    enabled_features.addFeature(@intFromEnum(features.soft_float));

    break :blk CrossTarget{
        .cpu_arch = Target.Cpu.Arch.x86,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = Target.Abi.none,
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    };
};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .version = .{ .major = 0, .minor = 1, .patch = 0 },
        .root_source_file = .{ .path = "src/x86-main.zig" },
        .target = x86_target,
        .optimize = optimize,
    });
    kernel.code_model = .kernel;
    kernel.linker_script = .{ .path = "src/x86/linker.ld" };
    // kernel.addAssemblyFile("src/x86/multiboot.S");
    kernel.addAssemblyFile("src/x86/start.S");
    kernel.addIncludePath("src/x86");
    b.installArtifact(kernel);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.step);

    // Multiboot ISO
    // const iso_dir = b.fmt("{s}/iso_root", .{b.cache_root});
    // const kernel_path = b.getInstallPath(b.dest_dir, kernel.out_filename);
    // const iso_path = b.fmt("{s}/disk.iso", .{b.exe_dir});

    // const iso_cmd_str = &[_][]const u8{
    //     "/bin/sh", "-c",
    //     std.mem.concat(b.allocator, u8, &[_][]const u8{
    //         "mkdir -p ", iso_dir, " && ",
    //         "cp ", kernel_path, " ", iso_dir, " && ",
    //         "cp src/grub.cfg ", iso_dir, " && ",
    //         "grub-mkrescue -o ", iso_path, " ", iso_dir
    //     }) catch unreachable
    // };

    const run_cmd = b.addRunArtifact(kernel);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = x86_target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
