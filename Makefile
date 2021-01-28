#
# Makefile for teensykick

LIBRARYPATH = ../teensy-duino

TEENSYLC := 1
MCU = MKL26Z64
CPUARCH = cortex-m0plus

MCU_LD = $(LIBRARYPATH)/mkl26z64.ld
LIBS = -L$(LIBRARYPATH) -lteensy-lc

CDEFINES = -DF_CPU=48000000 -DUSB_MIDI_SERIAL

# options needed by many Arduino libraries to configure for Teensy 3.x
CDEFINES += -D__$(MCU)__ -DARDUINO=10805 -DTEENSYDUINO=144

CPPFLAGS = -Wall -g -Os -mcpu=$(CPUARCH) -mthumb -MMD $(CDEFINES) \
	-I$(LIBRARYPATH)/include
CPPFLAGS += -I$(LIBRARYPATH)/Audio -I$(LIBRARYPATH)/SPI \
	-I$(LIBRARYPATH)/SD -I$(LIBRARYPATH)/SerialFlash -I$(LIBRARYPATH)/Wire \
	-I$(LIBRARYPATH)/Bounce
CXXFLAGS = -std=gnu++14 -felide-constructors -fno-exceptions -fno-rtti
CFLAGS =
ARFLAGS = crvs
LDFLAGS = -Os -Wl,--gc-sections,--defsym=__rtc_localtime=0 \
	--specs=nano.specs -mcpu=$(CPUARCH) -mthumb -T$(MCU_LD) -Wl,-Map=$(basename $@).map

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

# TARGET = hello_sgt
TARGET = kick
# CPP_FILES = kick.cpp AudioSampleKick.cpp

LIBS := -L$(LIB_DIR) -lAudio -lWire $(LIBS)

.PHONY: all load clean
all: hello_lc.hex hello_midi.hex hello_8211.hex hello_sine.hex \
	hello_sgt.hex hello_timer.hex metronome.hex kick.hex

# CPP_FILES = $(TARGET).cpp analog_stub.cpp usb_write.cpp
# OBJS = $(addprefix $(OBJ_DIR)/,$(CPP_FILES:.cpp=.o))
# $(TARGET).elf: $(OBJ_DIR) $(OBJS) $(LIB_LIST) $(MCU_LD)
# 	$(LINK.o) $(OBJS) $(LIBS) -o $@
# 	@echo built $@

CPP_FILES := analog_stub.cpp usb_write.cpp
HM_OBJS := $(addprefix $(OBJ_DIR)/,hello_midi.o $(CPP_FILES:.cpp=.o))
hello_midi.elf: $(OBJ_DIR) $(HM_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(HM_OBJS) $(LIBS) -o $@
	@echo built $@

HL_OBJS := $(addprefix $(OBJ_DIR)/,hello_lc.o $(CPP_FILES:.cpp=.o))
hello_lc.elf: $(OBJ_DIR) $(HL_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(HL_OBJS) $(LIBS) -o $@
	@echo built $@

H8_OBJS := $(addprefix $(OBJ_DIR)/,hello_8211.o $(CPP_FILES:.cpp=.o))
hello_8211.elf: $(OBJ_DIR) $(H8_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(H8_OBJS) $(LIBS) -o $@
	@echo built $@

HS_OBJS := $(addprefix $(OBJ_DIR)/,hello_sine.o $(CPP_FILES:.cpp=.o))
hello_sine.elf: $(OBJ_DIR) $(HS_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(HS_OBJS) $(LIBS) -o $@
	@echo built $@

HSGT_OBJS := $(addprefix $(OBJ_DIR)/,hello_sgt.o $(CPP_FILES:.cpp=.o))
hello_sgt.elf: $(OBJ_DIR) $(HSGT_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(HSGT_OBJS) $(LIBS) -o $@
	@echo built $@

HT_OBJS := $(addprefix $(OBJ_DIR)/,hello_timer.o $(CPP_FILES:.cpp=.o))
hello_timer.elf: $(OBJ_DIR) $(HT_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(HT_OBJS) $(LIBS) -o $@
	@echo built $@

M_OBJS := $(addprefix $(OBJ_DIR)/,metronome.o $(CPP_FILES:.cpp=.o))
metronome.elf: $(OBJ_DIR) $(M_OBJS) $(LIB_LIST) $(BOUNCE_LIB) $(MCU_LD)
	$(LINK.o) $(M_OBJS) $(LIBS) -lBounce -o $@
	@echo built $@

K_OBJS := $(addprefix $(OBJ_DIR)/,kick.o $(CPP_FILES:.cpp=.o))
kick.elf: $(OBJ_DIR) $(K_OBJS) $(LIB_LIST) $(MCU_LD)
	$(LINK.o) $(K_OBJS) $(LIBS) -o $@
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

-include $(wildcard $(OBJ_DIR)/*.d)

clean:
	-rm -f *.d *.o *.elf *.hex *.a
	-rm -rf $(OBJ_DIR) $(LIB_DIR)

$(OBJ_DIR): ; $(MKDIR) $@
$(LIB_DIR): ; $(MKDIR) $@
$(LIB_LIST) : $(LIB_DIR)

$(OBJ_DIR)/%.o : %.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : %.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

LIB_C_FILES = analog.c mk20dx128.c nonstd.c pins_teensy.c serial1.c
LIB_C_FILES += usb_desc.c usb_dev.c usb_mem.c usb_midi.c usb_seremu.c usb_serial.c
LIB_CPP_FILES = AudioStream.cpp DMAChannel.cpp EventResponder.cpp \
	HardwareSerial.cpp HardwareSerial1.cpp IntervalTimer.cpp Print.cpp WString.cpp \
	i2c_t3.cpp main.cpp serialEvent.cpp yield.cpp

LIB_OBJS := $(LIB_C_FILES:.c=.o) $(LIB_CPP_FILES:.cpp=.o)
LIB_OBJS := $(addprefix $(OBJ_DIR)/,$(LIB_OBJS))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/src/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/src/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(TEENSY_LIB): $(LIB_OBJS)
	$(AR) $(ARFLAGS) $@ $(LIB_OBJS)

AUDIO_LIB_CPP_FILES = control_sgtl5000.cpp effect_multiply.cpp filter_biquad.cpp \
	mixer.cpp output_i2s.cpp output_pt8211.cpp synth_dc.cpp synth_simple_drum.cpp \
	synth_sine.cpp synth_whitenoise.cpp
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

$(AUDIO_LIB): $(AUDIO_OBJS)
	$(AR) $(ARFLAGS) $@ $(AUDIO_OBJS)

WIRE_LIB_CPP_FILES = Wire.cpp WireKinetis.cpp
WIRE_LIB_C_FILES =
WIRE_OBJS := $(addprefix $(OBJ_DIR)/,$(WIRE_LIB_C_FILES:.c=.o) \
	$(WIRE_LIB_CPP_FILES:.cpp=.o))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Wire/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Wire/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(WIRE_LIB): $(WIRE_OBJS)
	$(AR) $(ARFLAGS) $@ $(WIRE_OBJS)

BOUNCE_LIB_CPP_FILES = Bounce.cpp
BOUNCE_LIB_C_FILES =
BOUNCE_OBJS := $(addprefix $(OBJ_DIR)/,$(BOUNCE_LIB_C_FILES:.c=.o) \
	$(BOUNCE_LIB_CPP_FILES:.cpp=.o))

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Bounce/%.c
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJ_DIR)/%.o : $(LIBRARYPATH)/Bounce/%.cpp
	$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(BOUNCE_LIB): $(BOUNCE_OBJS)
	$(AR) $(ARFLAGS) $@ $(BOUNCE_OBJS)
