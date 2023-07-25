const mb = @cImport(@cInclude("multiboot2.h"));

pub const HEADER_MAGIC: u32 = mb.MULTIBOOT2_HEADER_MAGIC; // 0xe85250d6;
pub const BOOTLOADER_MAGIC: u32 = mb.MULTIBOOT2_BOOTLOADER_MAGIC; // 0x36d76289;

pub const Error = error{
    InvalidTagType,
};

pub const TagType = enum(u32) {
    BasicMemInfo = mb.MULTIBOOT_TAG_TYPE_BASIC_MEMINFO,
    BootDev = mb.MULTIBOOT_TAG_TYPE_BOOTDEV,
    MMap = mb.MULTIBOOT_TAG_TYPE_MMAP,
    Vbe = mb.MULTIBOOT_TAG_TYPE_VBE,
    FrameBuffer = mb.MULTIBOOT_TAG_TYPE_FRAMEBUFFER,
    ElfSections = mb.MULTIBOOT_TAG_TYPE_ELF_SECTIONS,
    Apm = mb.MULTIBOOT_TAG_TYPE_APM,
    Efi32 = mb.MULTIBOOT_TAG_TYPE_EFI32,
    Efi64 = mb.MULTIBOOT_TAG_TYPE_EFI64,
    Smbios = mb.MULTIBOOT_TAG_TYPE_SMBIOS,
    AcpiOld = mb.MULTIBOOT_TAG_TYPE_ACPI_OLD,
    AcpiNew = mb.MULTIBOOT_TAG_TYPE_ACPI_NEW,
    Network = mb.MULTIBOOT_TAG_TYPE_NETWORK,
    EfiMMap = mb.MULTIBOOT_TAG_TYPE_EFI_MMAP,
    EfiBs = mb.MULTIBOOT_TAG_TYPE_EFI_BS,
    Efi32_IH = mb.MULTIBOOT_TAG_TYPE_EFI32_IH,
    Efi64_IH = mb.MULTIBOOT_TAG_TYPE_EFI64_IH,
    LoadBaseAddr = mb.MULTIBOOT_TAG_TYPE_LOAD_BASE_ADDR,
};

pub const BootInfoTag = extern struct {
    type: u32,
    size: u32,

    pub fn tag_type(self: BootInfoTag) Error!TagType {
        switch (self.type) {
            @intFromEnum(TagType.BasicMemInfo) => return TagType.BasicMemInfo,
            @intFromEnum(TagType.BootDev) => return TagType.BootDev,
            @intFromEnum(TagType.MMap) => return TagType.MMap,
            @intFromEnum(TagType.Vbe) => return TagType.Vbe,
            @intFromEnum(TagType.FrameBuffer) => return TagType.FrameBuffer,
            @intFromEnum(TagType.ElfSections) => return TagType.ElfSections,
            @intFromEnum(TagType.Apm) => return TagType.Apm,
            @intFromEnum(TagType.Efi32) => return TagType.Efi32,
            @intFromEnum(TagType.Efi64) => return TagType.Efi64,
            @intFromEnum(TagType.Smbios) => return TagType.Smbios,
            @intFromEnum(TagType.AcpiOld) => return TagType.AcpiOld,
            @intFromEnum(TagType.AcpiNew) => return TagType.AcpiNew,
            @intFromEnum(TagType.Network) => return TagType.Network,
            @intFromEnum(TagType.EfiMMap) => return TagType.EfiMMap,
            @intFromEnum(TagType.EfiBs) => return TagType.EfiBs,
            @intFromEnum(TagType.Efi32_IH) => return TagType.Efi32_IH,
            @intFromEnum(TagType.Efi64_IH) => return TagType.Efi64_IH,
            @intFromEnum(TagType.LoadBaseAddr) => return TagType.LoadBaseAddr,
            else => return Error.InvalidTagType,
        }
    }
};

pub const BasicMemInfo = extern struct {
    mem_lower: u32,
    mem_upper: u32,
};

pub const BootInfoTagData = extern union {
    basic_mem: BasicMemInfo,
};

pub const BootInfoTagPtr = struct {
    ptr: *BootInfoTag,

    pub fn data(self: BootInfoTagPtr) Error!*BootInfoTagData {
        const tag_type = try self.ptr.*.tag_type();
        const data_ptr = ptr_advance_bytes(self.*.size);
        switch (tag_type) {
            TagType.BasicMemInfo => return .{ .basic_mem = @ptrCast(data_ptr) },
            else => @panic("TODO"),
        }
    }
};

pub const BootInfoIter = struct {
    ptr: *u32,
    end_ptr: *const u32,
    total_size: u32,

    pub fn init(info_ptr: *u32) BootInfoIter {
        var ptr = info_ptr;

        // The first tag is actually `struct { total_size: u32, reserved: u32 }`.
        const total_size = ptr.*;
        ptr = ptr_advance_bytes(ptr, @sizeOf(u32) * 2);
        const end_ptr = ptr_advance_bytes(ptr, total_size);
        return .{ .ptr = ptr, .end_ptr = end_ptr, .total_size = total_size };
    }

    pub fn next(self: *BootInfoIter) ?BootInfoTagPtr {
        if (self.ptr == self.end_ptr) {
            return null;
        }
        const tag_ptr: *BootInfoTag = @ptrCast(self.ptr);
        self.ptr = ptr_advance_bytes(self.ptr, tag_ptr.*.size);
        return .{ .ptr = tag_ptr };
    }
};

fn ptr_advance_bytes(ptr: anytype, n: anytype) @TypeOf(ptr) {
    var addr = @intFromPtr(ptr);
    addr += n;
    return @ptrFromInt(addr);
}
