
ifneq ($(OS),Windows_NT)
ifneq "$(HDMI2USB_ENV)" "1"
$(error "Please 'source scripts/setup-env.sh'")
endif
endif

# Turn off Python's hash randomization
export PYTHONHASHSEED=0

BOARD ?= atlys
MSCDIR ?= third_party/misoc
ifneq ($(BOARD),pipistrello)
    PROG ?= openocd
endif
TARGET ?= hdmi2usb
FILTER ?= tee
ifneq ($(PROG),)
    PROGRAMMER_OPTION ?= -Op programmer $(PROG)
endif
HDMI2USBDIR = ../..
PYTHON = python3
DATE = `date +%Y_%m_%d`

# We use the special PIPESTATUS which is bash only below.
SHELL := /bin/bash

CMD = $(PYTHON) \
  make.py \
  -X $(HDMI2USBDIR) \
  -t $(BOARD)_$(TARGET) \
  -Ot firmware_filename $(HDMI2USBDIR)/firmware/softcpu/firmware.bin \
  $(PROGRAMMER_OPTION) \
  $(MISOC_EXTRA_CMDLINE)

ifeq ($(OS),Windows_NT)
	FLTERM = $(PYTHON) $(MSCDIR)/tools/flterm.py
else
	FLTERM = $(MSCDIR)/tools/flterm
endif

# Every target has a softcpu core
include Makefile.softcpu

# The edid_debug and hdmi2usb also use the Cypress FX2
ifneq ($(filter $(TARGET),edid_debug hdmi2usb),)
include Makefile.fx2
endif

help:
	@echo "Environment:"
	@echo "  BOARD=atlys OR opsis OR pipistrello  (current: $(BOARD))"
	@echo " TARGET=base OR hdmi2usb OR hdmi2eth"
	@echo "                        (current: $(TARGET))"
	@echo "   PROG=programmer      (current: $(PROG))"
	@echo ""
	@if [ ! -z "$(TARGETS)" ]; then echo " Extra firmware needed for: $(TARGETS)"; echo ""; fi
	@echo "Targets avaliable:"
	@echo " make help"
	@echo " make all"
	@echo " make gateware"
	@echo " make firmware"
	@echo " make download-prebuilt"
	@echo " make load"
	@echo " make flash"
	@for T in $(TARGETS); do make -s help-$$T; done
	@echo " make clean"

# All target
all: clean gateware firmware
	echo "Run 'make load' to load the firmware."

# Initialize submodules automatically
third_party/%/.git: .gitmodules
	git submodule sync --recursive -- $$(dirname $@)
	git submodule update --recursive --init $$(dirname $@)
	touch $@ -r .gitmodules

# Gateware
MODULES=migen misoc liteeth litescope
gateware-submodules: $(addsuffix /.git,$(addprefix third_party/,$(MODULES)))
	@true

gateware-generate: gateware-submodules $(addprefix gateware-generate-,$(TARGETS))
	@echo 'Building target: $@. First dep: $<'
ifneq ($(OS),Windows_NT)
	cd $(MSCDIR) && $(CMD) -Ob run False --csr_csv $(HDMI2USBDIR)/test/csr.csv build-csr-csv build-bitstream \
	| $(FILTER) $(PWD)/build/output.$(DATE).log; (exit $${PIPESTATUS[0]})
else
	cd $(MSCDIR) && $(CMD) -Ob run False --csr_csv $(HDMI2USBDIR)/test/csr.csv build-csr-csv build-bitstream
endif

gateware-build: gateware-submodules $(addprefix gateware-build-,$(TARGETS))
ifneq ($(OS),Windows_NT)
	cd $(MSCDIR) && $(CMD) --csr_csv $(HDMI2USBDIR)/test/csr.csv build-csr-csv build-bitstream \
	| $(FILTER) $(PWD)/build/output.$(DATE).log; (exit $${PIPESTATUS[0]})
else
	cd $(MSCDIR) && $(CMD) --csr_csv $(HDMI2USBDIR)/test/csr.csv build-csr-csv build-bitstream
endif

gateware: gateware-generate gateware-build
	@true

# Firmware
firmware: $(addprefix firmware-,$(TARGETS))
	@true

# Download pre-built firmware
download-prebuilt:
	scripts/download-prebuilt.sh
	
# Load
load-gateware:
	cd $(MSCDIR) && $(CMD) load-bitstream

load: load-gateware $(addprefix load-,$(TARGETS))
	@true

# Flash
flash:
	@echo "Not implemented yet"
	@exit 1

# Clean
clean:
	@for T in $(TARGETS); do make clean-$$T; done
	if [ -f $(MSCDIR)/software/include/generated/cpu.mak ]; then \
		(cd $(MSCDIR) && $(CMD) clean) \
	fi
	# FIXME - This is a temporarily hack until misoc clean works better.
	rm -rf $(MSCDIR)/software/include/generated && ( \
		mkdir $(MSCDIR)/software/include/generated && \
		touch $(MSCDIR)/software/include/generated/.keep_me)
	# Cleanup Python3's __pycache__ directories
	find . -name __pycache__ -type d -exec rm -r {} +
	# Delete any previously downloaded pre-built firmware
	rm -rf build/prebuilt
	rm -f third_party/misoc/build/*.bit
	rm -f firmware/fx2/hdmi2usb.hex

.DEFAULT_GOAL := help
.PHONY: all load-gateware load flash gateware gateware-submodules gateware-generate gateware-build firmware download-prebuilt third_party/*
