#
# Makefile for teensykick

LIBRARYPATH = ../teensy-duino

TEENSYLC := 1
MCU = MKL26Z64
CPUARCH = cortex-m0plus

MCU_LD = $(LIBRARYPATH)/mkl26z64.ld
LIBS = -L$(LIBRARYPATH) -lteensy-lc

CDEFINES = -DF_CPU=48000000 -DUSB_SERIAL

# options needed by many Arduino libraries to configure for Teensy 3.x
CDEFINES += -D__$(MCU)__ -DARDUINO=10805 -DTEENSYDUINO=144

CPPFLAGS = -Wall -g -Os -mcpu=$(CPUARCH) -mthumb -MMD $(CDEFINES) \
	-I$(LIBRARYPATH)/include
CPPFLAGS += -I$(LIBRARYPATH)/Audio -I$(LIBRARYPATH)/SPI \
	-I$(LIBRARYPATH)/SD -I$(LIBRARYPATH)/SerialFlash -I$(LIBRARYPATH)/Wire
CXXFLAGS = -std=gnu++14 -felide-constructors -fno-exceptions -fno-rtti
CFLAGS =
LDFLAGS = -Os -Wl,--gc-sections,--defsym=__rtc_localtime=0 \
	--specs=nano.specs --specs=nosys.specs -mcpu=$(CPUARCH) -mthumb -T$(MCU_LD) -Wl,-Map=$(basename $@).map

# names for the compiler programs
CROSS_COMPILE=arm-none-eabi-
CC      = $(CROSS_COMPILE)gcc
CXX     = $(CROSS_COMPILE)g++
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE    = $(CROSS_COMPILE)size
AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib

MKDIR   = mkdir -p

TEENSY_LIB = $(LIBRARYPATH)/libteensy-lc.a
BOUNCE_LIB = $(LIB_DIR)/libBounce.a
AUDIO_LIB  = $(LIB_DIR)/libAudio.a
SPI_LIB    = $(LIB_DIR)/libSPI.a
WIRE_LIB   = $(LIB_DIR)/libWire.a
LIB_LIST   = $(TEENSY_LIB) $(AUDIO_LIB) $(WIRE_LIB)
OBJ_DIR = obj
LIB_DIR = lib

# TARGET = hello_midi
TARGET = kick
CPP_FILES = $(TARGET).cpp
# CPP_FILES = kick.cpp AudioSampleKick.cpp

OBJS := $(addprefix $(OBJ_DIR)/,$(C_FILES:.c=.o) $(CPP_FILES:.cpp=.o))
LIBS := -L$(LIB_DIR) -lAudio -lWire $(LIBS)

.PHONY: all load clean
all: hello_lc.hex hello_midi.hex hello_sine.hex kick.hex

$(TARGET).elf: $(OBJ_DIR) $(OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(OBJS) $(LIBS) -o $@
	@echo built $@

hello_midi.elf: $(OBJ_DIR) $(OBJ_DIR)/hello_midi.o $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(OBJ_DIR)/hello_midi.o $(LIBS) -o $@
	@echo built $@

hello_lc.elf: $(OBJ_DIR) $(OBJ_DIR)/hello_lc.o $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(OBJ_DIR)/hello_lc.o $(LIBS) -o $@
	@echo built $@

hello_sine.elf: $(OBJ_DIR) $(OBJ_DIR)/hello_sine.o $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(OBJ_DIR)/hello_sine.o $(LIBS) -o $@
	@echo built $@

# Create final output file (.hex) from ELF output file.
%.hex: %.elf
	@echo
	@$(SIZE) $<
	@echo
	@echo Converting $@ from $<
	$(OBJCOPY) -O ihex -R .eeprom -R .fuse -R .lock -R .signature $< $@
	@echo

load: $(TARGET).hex
	teensy_loader_cli.exe --mcu=$(MCU) -w -v $<

-include $(OBJS:.o=.d)

clean:
	-rm -f *.d *.o *.elf *.hex *.a
	-rm -rf $(OBJ_DIR) $(LIB_DIR)

$(OBJ_DIR): ; $(MKDIR) $@
$(LIB_DIR): ; $(MKDIR) $@

$(OBJ_DIR)/%.o : %.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : %.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

LIB_C_FILES = analog.c mk20dx128.c nonstd.c pins_teensy.c serial1.c
LIB_C_FILES += usb_desc.c usb_dev.c usb_mem.c usb_midi.c usb_seremu.c usb_serial.c
LIB_CPP_FILES = AudioStream.cpp DMAChannel.cpp EventResponder.cpp \
	HardwareSerial.cpp HardwareSerial1.cpp Print.cpp WString.cpp \
	main.cpp serialEvent.cpp yield.cpp

LIB_OBJS := $(LIB_C_FILES:.c=.o) $(LIB_CPP_FILES:.cpp=.o)
LIB_OBJS := $(addprefix $(OBJ_DIR)/,$(LIB_OBJS))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/src/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/src/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(TEENSY_LIB): $(OBJ_DIR) $(LIB_OBJS)
	$(AR) crvs $@ $(LIB_OBJS)

AUDIO_LIB_CPP_FILES = control_sgtl5000.cpp effect_multiply.cpp filter_biquad.cpp \
	mixer.cpp output_i2s.cpp output_pt8211.cpp synth_dc.cpp synth_sine.cpp \
	synth_whitenoise.cpp
AUDIO_LIB_C_FILES = data_waveforms.c
AUDIO_LIB_S_FILES = memcpy_audio.S
AUDIO_OBJS := $(addprefix $(OBJ_DIR)/,$(AUDIO_LIB_C_FILES:.c=.o) \
	$(AUDIO_LIB_CPP_FILES:.cpp=.o) $(AUDIO_LIB_S_FILES:.S=.o))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Audio/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Audio/%.S
	$(COMPILE.S) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Audio/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(AUDIO_LIB): $(OBJ_DIR) $(LIB_DIR) $(AUDIO_OBJS)
	$(AR) crvs $@ $(AUDIO_OBJS)

WIRE_LIB_CPP_FILES = Wire.cpp WireKinetis.cpp
WIRE_LIB_C_FILES = 
WIRE_OBJS := $(addprefix $(OBJ_DIR)/,$(WIRE_LIB_C_FILES:.c=.o) \
	$(WIRE_LIB_CPP_FILES:.cpp=.o))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Wire/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Wire/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(WIRE_LIB): $(OBJ_DIR) $(LIB_DIR) $(WIRE_OBJS)
	$(AR) crvs $@ $(WIRE_OBJS)
