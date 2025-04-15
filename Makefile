# Project Name
PROJECT = makefile-blink

# Path you your toolchain and openocd installation, leave empty if already in system PATH
TOOLCHAIN_ROOT := "/opt/wch/mounriver-studio-toolchain-riscv-gcc/bin/"
OPENOCD_ROOT   := "/opt/wch/mounriver-studio-toolchain-openocd/bin/"

###############################################################################

# Project specific
TARGET = $(PROJECT).elf
SRC_DIR = src/
VENDOR_SRC_DIR = vendor/EVT/EXAM/SRC/

# Toolchain
CC = $(TOOLCHAIN_ROOT)riscv-none-embed-gcc
DB = $(TOOLCHAIN_ROOT)riscv-none-embed-gdb
SIZE = $(TOOLCHAIN_ROOT)riscv-none-embed-size

# Project sources
SRC_FILES = $(wildcard $(SRC_DIR)*.c) 

# Vendor sources:
ASM_FILES += $(VENDOR_SRC_DIR)Startup/startup_CH592.S
SRC_FILES += $(VENDOR_SRC_DIR)RVMSIS/core_riscv.c
SRC_FILES += $(wildcard $(VENDOR_SRC_DIR)StdPeriphDriver/*.c) 
# BLE sources
ASM_FILES += $(VENDOR_SRC_DIR)../BLE/LIB/ble_task_scheduler.S
SRC_FILES += $(wildcard $(VENDOR_SRC_DIR)../BLE/HAL/*.c)
SRC_FILES += $(VENDOR_SRC_DIR)../BLE/Peripheral/APP/peripheral.c
SRC_FILES += $(VENDOR_SRC_DIR)../BLE/Peripheral/Profile/devinfoservice.c
SRC_FILES += $(VENDOR_SRC_DIR)../BLE/Peripheral/Profile/gattprofile.c

# Vendor includes
INCLUDES += -I$(VENDOR_SRC_DIR)StdPeriphDriver/inc/
INCLUDES += -I$(VENDOR_SRC_DIR)RVMSIS/
# BLE includes
INCLUDES += -I$(VENDOR_SRC_DIR)../BLE/HAL/include/
INCLUDES += -I$(VENDOR_SRC_DIR)../BLE/LIB/
INCLUDES += -I$(VENDOR_SRC_DIR)../BLE/Peripheral/Profile/include/
INCLUDES += -I$(VENDOR_SRC_DIR)../BLE/Peripheral/APP/include/

# Vendor Link Script
LD_SCRIPT = $(VENDOR_SRC_DIR)Ld/Link.ld

# Vendor Libraries
LIBS = -L$(VENDOR_SRC_DIR)/StdPeriphDriver -lISP592
# BLE library
LIBS += $(VENDOR_SRC_DIR)../BLE/LIB/LIBCH59xBLE.a

# Compiler Flags
CFLAGS  = -march=rv32imac -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -Os
CFLAGS += -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wunused -Wuninitialized -g #-x assembler
CFLAGS += -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)"
CFLAGS += $(INCLUDES)

# Assembler Flags
ASMFLAGS = -x assembler-with-cpp

# Linker Flags
LFLAGS = -T $(LD_SCRIPT) -nostartfiles -Xlinker --gc-sections -Wl,-Map,$(PROJECT).map --specs=nano.specs --specs=nosys.specs

###############################################################################

# This does an in-source build. An out-of-source build that places all object
# files into a build directory would be a better solution, but the goal was to
# keep this file very simple.

CXX_OBJS = $(SRC_FILES:.c=.o)
ASM_OBJS = $(ASM_FILES:.S=.o)
ALL_OBJS = $(ASM_OBJS) $(CXX_OBJS)

.PHONY: clean prog gdb-server_openocd gdb-client

all: $(TARGET) $(PROJECT).hex

# Compile

$(ASM_OBJS): %.o: %.S
	@echo "[ASM CC] $@"
	$(CC) $(CFLAGS) $(ASMFLAGS) -c $< -o $@

$(CXX_OBJS): %.o: %.c
	@echo "[CC] $@"
	@$(CC) $(CFLAGS) -c $< -o $@

# Link
%.elf: $(ALL_OBJS)
	@echo "[LD] $@"
	$(CC) $(CFLAGS) $(LFLAGS) $(ALL_OBJS) $(LIBS) -o $@
	@$(SIZE) $@

%.hex: %.elf
	@echo "[OBJCOPY] $@"
	@$(TOOLCHAIN_ROOT)riscv-none-embed-objcopy -O ihex "$(PROJECT).elf" "$(PROJECT).hex"

# Clean
clean:
	@rm -f $(ALL_OBJS) $(ALL_OBJS:o=d) $(TARGET) $(PROJECT).map

# Program
flash: $(TARGET)
	sudo $(OPENOCD_ROOT)openocd -f $(OPENOCD_ROOT)wch-riscv.cfg -c "chip_id CH59x" -c init -c halt -c "program $(PROJECT).hex" -c "resume 0" -c exit

gdb:
	sudo $(OPENOCD_ROOT)openocd -f $(OPENOCD_ROOT)wch-riscv.cfg -c "chip_id CH59x"