#
# Makefile snippet to build libraries for teensy-duino in your project space.
#

ARDUINO_ROOT ?= ${HOME}/.arduino15
HARDWARE_ROOT ?= $(wildcard ${ARDUINO_ROOT}/packages/teensy/hardware/avr/*)
HARDWARE_LIB_PATH := ${HARDWARE_ROOT}/libraries

# CORE_SRC_CPP = $(wildcard ${HARDWARE_ROOT}/cores/${PLATFORM}/*.cpp)

LIB_C_FILES = analog.c mk20dx128.c nonstd.c pins_teensy.c serial1.c \
	usb_desc.c usb_dev.c usb_inst.c usb_mem.c usb_midi.c \
	usb_seremu.c usb_serial.c
LIB_CPP_FILES = AudioStream.cpp DMAChannel.cpp EventResponder.cpp \
	HardwareSerial.cpp HardwareSerial1.cpp IntervalTimer.cpp Print.cpp \
	WMath.cpp WString.cpp avr_emulation.cpp main.cpp \
	new.cpp serialEvent.cpp usb_audio.cpp yield.cpp

LIBOBJDIR ?= ${OBJDIR}

CORE_OBJ := $(LIB_C_FILES:.c=.o) $(LIB_CPP_FILES:.cpp=.o)
CORE_OBJ := $(addprefix $(LIBOBJDIR)/,$(CORE_OBJ))

# CORE_SRC_PATH := ${HARDWARE_ROOT}/cores/${PLATFORM}
CORE_SRC_PATH := ${LIBRARYPATH}/src

$(LIBOBJDIR)/%.o : ${CORE_SRC_PATH}/%.c | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${CORE_SRC_PATH}/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(TEENSY_LIB): ${CORE_OBJ} | ${LIBDIR}
	@echo Collecting library $@ from ${CORE_SRC_PATH}
	@$(AR) $(ARFLAGS) $@ $^

AUDIO_LIB_CPP_FILES = control_sgtl5000.cpp effect_multiply.cpp filter_biquad.cpp \
	mixer.cpp output_i2s.cpp output_pt8211.cpp play_memory.cpp play_memory2.cpp \
	synth_dc.cpp synth_simple_drum.cpp synth_sine.cpp synth_whitenoise.cpp
AUDIO_LIB_C_FILES = data_ulaw.c data_waveforms.c
AUDIO_LIB_S_FILES = memcpy_audio.S
AUDIO_OBJS := $(addprefix $(LIBOBJDIR)/,$(AUDIO_LIB_C_FILES:.c=.o) \
	$(AUDIO_LIB_CPP_FILES:.cpp=.o) $(AUDIO_LIB_S_FILES:.S=.o))
AUDIO_LIB_PATH := ${LIBRARYPATH}/Audio

$(LIBOBJDIR)/%.o : $(LIBRARYPATH)/Audio/%.c | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : $(LIBRARYPATH)/Audio/%.S | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.S) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : $(LIBRARYPATH)/Audio/%.cpp | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(AUDIO_LIB): $(AUDIO_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${AUDIO_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^

BOUNCE_LIB_CPP_FILES = Bounce.cpp
BOUNCE_LIB_C_FILES =
BOUNCE_OBJS := $(addprefix $(LIBOBJDIR)/,$(BOUNCE_LIB_C_FILES:.c=.o) \
	$(BOUNCE_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${HARDWARE_ROOT}/libraries/Bounce/%.c | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${HARDWARE_ROOT}/libraries/Bounce/%.cpp | $(LIBOBJDIR)
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(BOUNCE_LIB): $(BOUNCE_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${HARDWARE_LIB_PATH}/Bounce
	@$(AR) $(ARFLAGS) $@ $^

WIRE_LIB_CPP_FILES = Wire.cpp WireKinetis.cpp
WIRE_LIB_C_FILES =
WIRE_OBJS := $(addprefix $(LIBOBJDIR)/,$(WIRE_LIB_C_FILES:.c=.o) \
	$(WIRE_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${LIBRARYPATH}/Wire/%.c
	@echo Compiling $@ from $<
	@$(COMPILE.c) $(OUTPUT_OPTION) $<

$(LIBOBJDIR)/%.o : ${LIBRARYPATH}/Wire/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(WIRE_LIB): $(WIRE_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${LIBRARYPATH}/Wire
	@echo Collecting library $@
	@$(AR) $(ARFLAGS) $@ $^

SD_LIB_CPP_FILES := SD.cpp
SD_OBJS := $(addprefix $(LIBOBJDIR)/,$(SD_LIB_CPP_FILES:.cpp=.o))
SD_LIB_PATH := ${LIBRARYPATH}/SD
# SD_LIB_PATH := ${HARDWARE_ROOT}/libraries/SD/src
${SD_OBJS}: CPPFLAGS += -I${HARDWARE_ROOT}/libraries/SdFat/src \
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

SPI_LIB_CPP_FILES = SPI.cpp
SPI_OBJS := $(addprefix $(LIBOBJDIR)/,$(SPI_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : ${HARDWARE_ROOT}/libraries/SPI/%.cpp
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(SPI_LIB): $(SPI_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${HARDWARE_LIB_PATH}/SPI
	@$(AR) $(ARFLAGS) $@ $^

I2C_LIB_CPP_FILES = i2c_t3.cpp
I2C_OBJS := $(addprefix $(LIBOBJDIR)/,$(I2C_LIB_CPP_FILES:.cpp=.o))

$(LIBOBJDIR)/%.o : $(HARDWARE_ROOT)/libraries/i2c_t3/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $<
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(I2C_LIB): $(I2C_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${HARDWARE_LIB_PATH}/libraries
	@$(AR) $(ARFLAGS) $@ $^

ADC_LIB_CPP_FILES = ADC.cpp ADC_Module.cpp
ADC_OBJS := $(addprefix $(LIBOBJDIR)/,$(ADC_LIB_CPP_FILES:.cpp=.o))
ADC_LIB_PATH := ${HARDWARE_LIB_PATH}/ADC

$(LIBOBJDIR)/%.o : ${ADC_LIB_PATH}/%.cpp | ${LIBOBJDIR}
	@echo Compiling $@ from $(notdir $<)
	@$(COMPILE.cpp) $(OUTPUT_OPTION) $<

$(ADC_LIB): $(ADC_OBJS) | ${LIBDIR}
	@echo Collecting library $@ from ${ADC_LIB_PATH}
	@$(AR) $(ARFLAGS) $@ $^
