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

TEENSY_LIB = $(LIBDIR)/libteensy-lc.a
BOUNCE_LIB = $(LIBDIR)/libBounce.a
AUDIO_LIB  = $(LIBDIR)/libAudio.a
SPI_LIB    = $(LIBDIR)/libSPI.a
WIRE_LIB   = $(LIBDIR)/libWire.a
LIB_LIST   = $(TEENSY_LIB) $(AUDIO_LIB) $(WIRE_LIB)
OBJDIR = obj
LIBDIR = lib
LIBOBJDIR = ${LIBDIR}/obj
BUILDDIR = build

# Generate a version string from git for the C++ code to use
GIT_DIRTY := $(shell test -n "`git diff-index --name-only HEAD`" && echo '-dirty')
GIT_VERSION := $(shell git describe --tags || echo -n 'V0.NO-GIT')$(GIT_DIRTY)
CDEFINES += -DTEENSYKICK_VERSION=\"${GIT_VERSION}\"

# TARGET = hello_sgt
TARGET = kick
# CPP_FILES = kick.cpp AudioSampleKick.cpp

LIBS := -L$(LIBDIR) -lAudio -lWire $(LIBS)

.PHONY: all load clean upload
all: $(addprefix ${BUILDDIR}/,hello_lc.hex hello_midi.hex hello_8211.hex hello_sine.hex \
	hello_sgt.hex hello_timer.hex metronome.hex kick.hex) | ${BUILDDIR}

# CPP_FILES = $(TARGET).cpp analog_stub.cpp usb_write.cpp
# OBJS = $(addprefix $(OBJDIR)/,$(CPP_FILES:.cpp=.o))
# $(TARGET).elf: $(OBJDIR) $(OBJS) $(LIB_LIST) $(MCU_LD)
# 	$(LINK.o) $(OBJS) $(LIBS) -o $@
# 	@echo built $@

CPP_FILES := analog_stub.cpp usb_write.cpp

HELLO_MIDI_CPP := hello_midi.cpp
HM_OBJS := $(addprefix $(OBJDIR)/,$(HELLO_MIDI_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_midi.elf: $(OBJDIR) $(HM_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HM_OBJS) $(LIBS) -o $@
	@echo built $@

HL_OBJS := $(addprefix $(OBJDIR)/,hello_lc.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_lc.elf: $(HL_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HL_OBJS) $(LIBS) -o $@
	@echo built $@

H8_OBJS := $(addprefix $(OBJDIR)/,hello_8211.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_8211.elf: $(H8_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(H8_OBJS) $(LIBS) -o $@
	@echo built $@

HS_OBJS := $(addprefix $(OBJDIR)/,hello_sine.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_sine.elf: $(HS_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HS_OBJS) $(LIBS) -o $@
	@echo built $@

HSGT_OBJS := $(addprefix $(OBJDIR)/,hello_sgt.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_sgt.elf: $(HSGT_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HSGT_OBJS) $(LIBS) -o $@
	@echo built $@

HT_OBJS := $(addprefix $(OBJDIR)/,hello_timer.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_timer.elf: $(HT_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HT_OBJS) $(LIBS) -o $@
	@echo built $@

METRONOME_CPP := metronome.cpp
M_OBJS := $(addprefix $(OBJDIR)/,$(METRONOME_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/metronome.elf: $(M_OBJS) $(LIB_LIST) $(BOUNCE_LIB) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(M_OBJS) $(LIBS) -lBounce -o $@
	@echo built $@

KICK_CPP := kick.cpp AudioSampleKick.cpp
K_OBJS := $(addprefix $(OBJDIR)/,$(KICK_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/kick.elf: $(K_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(K_OBJS) $(LIBS) -o $@
	@echo built $@ ${GIT_VERSION}

# Create final output file (.hex) from ELF output file.
${BUILDDIR}/%.hex: ${BUILDDIR}/%.elf | ${BUILDDIR}
	@echo
	@$(SIZE) $<
	@echo
	@echo Converting $@ from $<
	@$(OBJCOPY) -O ihex -R .eeprom -R .fuse -R .lock -R .signature $< $@
	@echo

upload load: ${BUILDDIR}/$(TARGET).hex
	teensy_loader_cli.exe --mcu=$(MCU) -w -v $<

clean:
	-rm -f *.d *.o *.elf *.hex *.a
	-rm -rf $(OBJDIR) ${LIBOBJDIR} $(LIBDIR) ${BUILDDIR}

$(OBJDIR) $(LIBDIR) $(LIBOBJDIR) $(BUILDDIR) : ; $(MKDIR) $@
$(LIB_LIST) : | $(LIBDIR)

$(OBJDIR)/%.o : %.c | ${OBJDIR}
	@echo Building $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(OBJDIR)/%.o : %.cpp | ${OBJDIR}
	@echo Building $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

include $(LIBRARYPATH)/libraries.mak

-include $(wildcard $(OBJDIR)/*.d)
-include $(wildcard $(LIBOBJDIR)/*.d)
