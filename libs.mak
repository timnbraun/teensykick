#
# Makefile snippet to build libraries for teensy-duino in your project space.
#

LIBOBJDIR ?= ${LIBDIR}/obj

# CORE_SRC_CPP = $(wildcard ${HARDWAREROOT}/cores/${CORE}/*.cpp)

CORE_SRC_PATH := ${MYTEENSYDUINOPATH}/src
# CORE_SRC_PATH := ${HARDWAREROOT}/cores/${CORE}
LIB_C_FILES = analog.c mk20dx128.c nonstd.c pins_teensy.c serial1.c \
	usb_desc.c usb_dev.c usb_inst.c usb_mem.c usb_midi.c \
	usb_seremu.c usb_serial.c
LIB_CPP_FILES = AudioStream.cpp DMAChannel.cpp EventResponder.cpp \
	HardwareSerial.cpp HardwareSerial1.cpp IntervalTimer.cpp Print.cpp \
	WMath.cpp WString.cpp avr_emulation.cpp main.cpp \
	new.cpp serialEvent.cpp usb_audio.cpp yield.cpp

CORE_OBJ := $(LIB_C_FILES:.c=.o) $(LIB_CPP_FILES:.cpp=.o)
CORE_OBJ := $(addprefix $(LIBOBJDIR)/,$(CORE_OBJ))

$(LIBOBJDIR)/%.o : ${CORE_SRC_PATH}/%.c | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${CORE_SRC_PATH}/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(CORE_LIB): ${CORE_OBJ} | ${LIBDIR}
	@echo Collecting library $@ from ${CORE_SRC_PATH}
	@$(AR) $(ARFLAGS) $@ $^

AUDIO_LIB_PATH := ${MYTEENSYDUINOPATH}/Audio
AUDIO_LIB_CPP_FILES = control_sgtl5000.cpp effect_multiply.cpp filter_biquad.cpp \
	mixer.cpp output_i2s.cpp output_pt8211.cpp play_memory.cpp play_memory2.cpp \
	synth_dc.cpp synth_simple_drum.cpp synth_sine.cpp synth_whitenoise.cpp
AUDIO_LIB_C_FILES = data_ulaw.c data_waveforms.c
AUDIO_LIB_S_FILES = memcpy_audio.S
AUDIO_OBJS := $(addprefix $(LIBOBJDIR)/,$(AUDIO_LIB_C_FILES:.c=.o) \
	$(AUDIO_LIB_CPP_FILES:.cpp=.o) $(AUDIO_LIB_S_FILES:.S=.o))

$(LIBOBJDIR)/%.o : ${AUDIO_LIB_PATH}/%.c | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${AUDIO_LIB_PATH}/%.S | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.S) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${AUDIO_LIB_PATH}/%.cpp | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(AUDIO_LIB): $(AUDIO_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${AUDIO_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^

ADC_LIB_PATH := ${HARDWARELIB_PATH}/ADC
ADC_LIB_CPP_FILES = ADC.cpp ADC_Module.cpp
ADC_OBJS := $(addprefix $(LIBOBJDIR)/,$(ADC_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${ADC_LIB_PATH}/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(ADC_LIB): $(ADC_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from \
		$(subst ${HARDWAREROOT}/,HARDWARE/,${ADC_LIB_PATH})
	@$(AR) $(ARFLAGS) $@ $^

BOUNCE_LIB_PATH := ${HARDWARELIB_PATH}/Bounce
BOUNCE_LIB_CPP_FILES = Bounce.cpp
BOUNCE_LIB_C_FILES =
BOUNCE_OBJS := $(addprefix $(LIBOBJDIR)/,$(BOUNCE_LIB_C_FILES:.c=.o) \
	$(BOUNCE_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${BOUNCE_LIB_PATH}/%.c | $(LIBOBJDIR)
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${BOUNCE_LIB_PATH}/%.cpp | $(LIBOBJDIR)
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(BOUNCE_LIB): $(BOUNCE_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from $(subst ${HARDWAREROOT},HARDWARE,${BOUNCE_LIB_PATH})
	@$(AR) $(ARFLAGS) $@ $^

I2C_LIB_PATH := ${HARDWARELIB_PATH}/i2c_t3
I2C_LIB_CPP_FILES = i2c_t3.cpp
I2C_OBJS := $(addprefix $(LIBOBJDIR)/,$(I2C_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${I2C_LIB_PATH}/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(I2C_LIB): $(I2C_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${I2C_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^

TIMEDBLINK_LIB_PATH := ${USERLIBPATH}/TimedBlink/src
TIMEDBLINK_LIB_CPP_FILES = $(notdir $(wildcard ${TIMEDBLINK_LIB_PATH}/*.cpp))
TIMEDBLINK_LIB_C_FILES = $(notdir $(wildcard ${TIMEDBLINK_LIB_PATH}/*.c))
TIMEDBLINK_OBJS := $(addprefix $(LIBOBJDIR)/,$(TIMEDBLINK_LIB_C_FILES:.c=.o) \
	$(TIMEDBLINK_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${TIMEDBLINK_LIB_PATH}/%.c | $(LIBOBJDIR)
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${TIMEDBLINK_LIB_PATH}/%.cpp | $(LIBOBJDIR)
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(TIMEDBLINK_LIB): $(TIMEDBLINK_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from $(subst ${USERLIBPATH},USERLIBPATH,${TIMEDBLINK_LIB_PATH})
	@$(AR) $(ARFLAGS) $@ $^

SD_LIB_PATH := ${MYTEENSYDUINOPATH}/SD
# SD_LIB_PATH := ${HARDWAREROOT}/libraries/SD/src
SD_LIB_CPP_FILES := SD.cpp
SD_OBJS := $(addprefix $(LIBOBJDIR)/,$(SD_LIB_CPP_FILES:.cpp=.o))
${SD_OBJS}: CPPFLAGS += -I${HARDWAREROOT}/libraries/SdFat/src \
	-I${SD_LIB_PATH}/utility

$(LIBOBJDIR)/%.o : ${SD_LIB_PATH}/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${SD_LIB_PATH}/utility/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(SD_LIB): $(SD_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${SD_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^

SPI_LIB_PATH := ${HARDWARELIB_PATH}/SPI
SPI_LIB_CPP_FILES = SPI.cpp
SPI_OBJS := $(addprefix $(LIBOBJDIR)/,$(SPI_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${SPI_LIB_PATH}/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(SPI_LIB): $(SPI_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${SPI_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^

WIRE_LIB_PATH := ${MYTEENSYDUINOPATH}/Wire
WIRE_LIB_CPP_FILES = Wire.cpp WireKinetis.cpp
WIRE_LIB_C_FILES =
WIRE_OBJS := $(addprefix $(LIBOBJDIR)/,$(WIRE_LIB_C_FILES:.c=.o) \
	$(WIRE_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${WIRE_LIB_PATH}/%.c
	@echo Compiling $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${WIRE_LIB_PATH}/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(WIRE_LIB): $(WIRE_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${WIRE_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^
