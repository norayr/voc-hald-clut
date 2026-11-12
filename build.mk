VOCROOT ?= $(ROOT)/install
VOCLIBDIR ?= $(VOCROOT)/lib
VOC ?= $(VOCROOT)/bin/voc
MODEL ?= 2
BUILD := $(abspath $(BUILD))
PORTS := $(ROOT)/src/ports
HALD_BUILD_MK := $(lastword $(MAKEFILE_LIST))
CFLAGS ?= -O3 -fno-strict-aliasing
export CFLAGS VOCROOT VOCLIBDIR

.PHONY: all sequential cpu codecs test check-source
all: sequential cpu

check-source:
	@test -f "$(PORTS)/polpo/png-codec/src/PNG0.Mod" -a -f "$(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod" || { echo 'set VOC_SOURCE to a VOC source tree containing the PNG and JPEG codecs'; exit 1; }

codecs: check-source $(BUILD)/codecs/ready

$(BUILD)/codecs/ready: $(ROOT)/src/library/Args.Mod $(wildcard $(PORTS)/s3/Zlib*.Mod) $(PORTS)/polpo/png-codec/src/PNG0.Mod $(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod $(HALD_BUILD_MK)
	mkdir -p "$(BUILD)/codecs"
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(ROOT)/src/library/Args.Mod"
	cd "$(BUILD)/codecs" && for name in Zlib ZlibBuffers ZlibInflate ZlibDeflate; do "$(VOC)" -O$(MODEL) -sF "$(PORTS)/s3/$$name.Mod" || exit; done
	cd "$(BUILD)/codecs" && "$(VOC)" -O$(MODEL) -sF "$(PORTS)/polpo/png-codec/src/PNG0.Mod" "$(PORTS)/polpo/jpeg-codec/src/JPEG0.Mod"
	touch "$@"

sequential: codecs
	mkdir -p "$(BUILD)/sequential"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/sequential/"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFj "$(HALD_SOURCE)"
	cd "$(BUILD)/sequential" && "$(VOC)" -O$(MODEL) -sFm "$(COMMAND_SOURCE)"

cpu: codecs
	mkdir -p "$(BUILD)/cpu"
	cp "$(BUILD)/codecs/"*.h "$(BUILD)/codecs/"*.sym "$(BUILD)/codecs/"*.o "$(BUILD)/cpu/"
	cd "$(BUILD)/cpu" && "$(VOC)" -O$(MODEL) -sFjP "$(HALD_SOURCE)"
	cd "$(BUILD)/cpu" && "$(VOC)" -O$(MODEL) -sFmjP "$(COMMAND_SOURCE)"

test: all
	LD_LIBRARY_PATH="$(VOCLIBDIR)$${LD_LIBRARY_PATH:+:$$LD_LIBRARY_PATH}" DYLD_LIBRARY_PATH="$(VOCLIBDIR)$${DYLD_LIBRARY_PATH:+:$$DYLD_LIBRARY_PATH}" sh "$(ROOT)/src/tools/make/python.sh" "$(TEST_SOURCE)" --build "$(BUILD)"
