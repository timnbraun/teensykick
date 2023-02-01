#
# Makefile for teensykick
#

PLATFORM := teensyLC

LIBRARYPATH   := ../teensy-duino
MYTEENSYDUINOPATH := ../teensy-duino
ARDUINO_ROOT  ?= ${HOME}/.arduino15
ARDUINOPATH   := ${ARDUINO_ROOT}/packages/teensy
HARDWAREROOT  := $(wildcard ${ARDUINOPATH}/hardware/avr/*)
TOOLSPATH     := $(abspath $(ARDUINOPATH)/tools)
USERLIBPATH   := ${HOME}/Arduino/libraries

HARDWARE_LIB_PATH := ${HARDWAREROOT}/libraries

# TEENSYLC := 1
MCU      := MKL26Z64
CPUARCH  := cortex-m0plus
CORE     := teensy3
OPTIONS  := -DF_CPU=48000000
SPECS    := --specs=nano.specs
MCU_LD   := $(LIBRARYPATH)/mkl26z64.ld

LIBS     := -larm_cortexM0l_math
LOCALTEENSY_LIBRARIES = Audio
USERLIBRARIES := TimedBlink/src

CDEFINES := ${OPTIONS} -DUSB_MIDI_SERIAL -DLAYOUT_US_ENGLISH

# options needed by many Arduino libraries to configure for Teensy 3.x
CDEFINES += -D__$(MCU)__ -DARDUINO=10813 -DTEENSYDUINO=157

CINCLUDES += $(addprefix -I${MYTEENSYDUINOPATH}/,${LOCALTEENSY_LIBRARIES})
CINCLUDES += $(addprefix -I${USERLIBPATH}/,${USERLIBRARIES})
CPPFLAGS = -Wall -g -Os -mcpu=$(CPUARCH) -mthumb -MMD $(CDEFINES) \
	-I$(LIBRARYPATH)/include ${CINCLUDES}

ifdef LIBRARIES_GOOD
CPPFLAGS += \
	-I${HARDWAREROOT}/libraries/SD/src -I${HARDWAREROOT}/libraries/SerialFlash \
	-I${HARDWAREROOT}/libraries/Wire
else
CPPFLAGS += \
	-I${LIBRARYPATH}/SPI \
	-I${LIBRARYPATH}/SD -I${LIBRARYPATH}/SerialFlash \
	-I${LIBRARYPATH}/Wire
endif

CPPFLAGS += \
	-I${HARDWAREROOT}/libraries/SPI \
	-I${HARDWAREROOT}/libraries/Bounce \
	-I${HARDWAREROOT}/libraries/i2c_t3 \
	-I${HARDWAREROOT}/libraries/ADC

CXXFLAGS = -std=gnu++14 -felide-constructors -fno-exceptions -fno-rtti
CFLAGS =
ARFLAGS = crvs
LDFLAGS = -Os -Wl,--gc-sections,--defsym=__rtc_localtime=0 \
	${SPECS} -mcpu=$(CPUARCH) -mthumb -T$(MCU_LD) -Wl,-Map=$(basename $@).map \
	--sysroot=${TOOLSPATH}/teensy-compile/5.4.1/arm \
	-L${TOOLSPATH}/teensy-compile/5.4.1/arm/arm-none-eabi/lib

# names for the compiler programs
CROSS_COMPILE=arm-none-eabi-
CC      = $(CROSS_COMPILE)gcc
CXX     = $(CROSS_COMPILE)g++
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE    = $(CROSS_COMPILE)size
AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib

MKDIR   = mkdir -p

OBJDIR = obj
LIBDIR = lib
LIBOBJDIR = ${LIBDIR}/obj
BUILDDIR = build

# Generate a version string from git for the C++ code to use
GIT_DIRTY := $(shell test -n "`git diff-index --name-only HEAD`" && echo '-dirty')
GIT_VERSION := $(shell git describe --tags || echo -n 'V0.NO-GIT')$(GIT_DIRTY)

BUILD_DATE := $(shell date '+%y/%m/%d')
CDEFINES += -DTEENSYKICK_VERSION=\"${GIT_VERSION}\" -DBUILD_DATE=\"${BUILD_DATE}\"

CORE_LIB       := $(LIBDIR)/libCore.a  # from teensy-duino
ADC_LIB        := $(LIBDIR)/libADC.a
AUDIO_LIB      := $(LIBDIR)/libAudio.a # from teensy-duino
BOUNCE_LIB     := $(LIBDIR)/libBounce.a
I2C_LIB        := $(LIBDIR)/libi2c_t3.a
SD_LIB         := $(LIBDIR)/libSD.a	   # broken, from teensy-duino
SPI_LIB        := $(LIBDIR)/libSPI.a
TIMEDBLINK_LIB := $(LIBDIR)/libTimedBlink.a
WIRE_LIB       := $(LIBDIR)/libWire.a  # from teensy-duino

USERLIB_LIST := ${TIMEDBLINK_LIB}
LIB_LIST      = ${AUDIO_LIB} ${WIRE_LIB} ${ADC_LIB} ${TIMEDBLINK_LIB} ${CORE_LIB}

LIBS := -L$(LIBDIR) $(subst lib/lib,-l,$(LIB_LIST:.a=)) $(LIBS)

TARGET := kick

TARGETS = \
	hello_lc hello_adc hello_midi hello_8211 hello_sine hello_sgt hello_timer \
	metronome kick kick_synth

.PHONY: all load clean upload
all: $(addprefix ${BUILDDIR}/,${TARGETS:=.hex}) | ${BUILDDIR}

# CPP_FILES = $(TARGET).cpp analog_stub.cpp usb_write.cpp
# OBJS = $(addprefix $(OBJDIR)/,$(CPP_FILES:.cpp=.o))
# $(TARGET).elf: $(OBJDIR) $(OBJS) $(LIB_LIST) $(MCU_LD)
# 	$(LINK.o) $(OBJS) $(LIBS) -o $@
# 	@echo built $@

CPP_FILES := usb_write.cpp

HELLO_MIDI_CPP := hello_midi.cpp analog_stub.cpp
HM_OBJS := $(addprefix $(OBJDIR)/,$(HELLO_MIDI_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_midi.elf: $(HM_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HM_OBJS) $(LIBS) -o $@
	@echo built $@

HL_OBJS := $(addprefix $(OBJDIR)/,hello_lc.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_lc.elf: $(HL_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@echo Linking $@ LIBS=${LIBS}
	@$(LINK.o) $(HL_OBJS) $(LIBS) -o $@
	@echo built $@

H8_OBJS := $(addprefix $(OBJDIR)/,hello_8211.o $(CPP_FILES:.cpp=.o))
${H8_OBJS} : CPPFLAGS += -I${HARDWAREROOT}/libraries/SdFat/src
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

HA_OBJS := $(addprefix $(OBJDIR)/,hello_adc.o $(CPP_FILES:.cpp=.o))
${BUILDDIR}/hello_adc.elf: $(HA_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(HA_OBJS) $(LIBS) -o $@
	@echo built $@

METRONOME_CPP := metronome.cpp analog_stub.cpp AudioSampleKiddykick.cpp
M_OBJS := $(addprefix $(OBJDIR)/,$(METRONOME_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/metronome.elf: $(M_OBJS) $(LIB_LIST) $(BOUNCE_LIB) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(M_OBJS) $(LIBS) -lBounce -o $@
	@echo built $@

KICK_CPP := kick.cpp piezoTrigger.cpp AudioSampleKiddykick.cpp
K_OBJS := $(addprefix $(OBJDIR)/,$(KICK_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/kick.elf: $(K_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(K_OBJS) $(LIBS) -o $@
	@echo built $@ ${GIT_VERSION}

KICK_SYNTH_CPP := kick_synth.cpp piezoTrigger.cpp
K_S_OBJS := $(addprefix $(OBJDIR)/,$(KICK_SYNTH_CPP:.cpp=.o) $(CPP_FILES:.cpp=.o))
${BUILDDIR}/kick_synth.elf: $(K_S_OBJS) $(LIB_LIST) $(MCU_LD) | ${BUILDDIR}
	@$(LINK.o) $(K_S_OBJS) $(LIBS) -o $@
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

AudioSampleKiddykick.cpp : KiddyKick.wav
	@echo Generating $@ from $<
	wav2sketch -16 $<

include libs.mak
# include $(LIBRARYPATH)/libraries.mak

-include $(wildcard $(OBJDIR)/*.d)
-include $(wildcard $(LIBOBJDIR)/*.d)
