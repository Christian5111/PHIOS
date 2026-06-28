ASM = nasm
ASM_FLAGS = -f bin

SRC = source
BUILD = build

BOOTLOADER = boot.asm
BOOTLOADER_BIN = boot.bin

KERNEL = kernel.asm
KERNEL_BIN = kernel.bin

OS_IMAGE = PHI_OS.img

all: $(BUILD)/$(OS_IMAGE)

# Create Bootloader Binary
$(BUILD)/$(BOOTLOADER_BIN): $(SRC)/$(BOOTLOADER)
	$(ASM) $(ASM_FLAGS) $< -o $@

# Create Kernel Binary
$(BUILD)/$(KERNEL_BIN): $(SRC)/$(KERNEL)
	$(ASM) $(ASM_FLAGS) $< -o $@

# Create OS Image
$(BUILD)/$(OS_IMAGE): $(BUILD)/$(BOOTLOADER_BIN) $(BUILD)/$(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=$(BUILD)/$(BOOTLOADER_BIN) of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD)/$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null

# Clean the BUILD DIRECTORY
clean:
	rm -rf $(BUILD)/*