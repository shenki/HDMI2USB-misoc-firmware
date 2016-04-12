# XXX remove this
MSCDIR=../../third_party/misoc
include $(MSCDIR)/software/common.mak

CFLAGS += -Wno-unused-function

OBJECTS=isr.o \
        main.o \
	version.o \
	boot-helper-$(CPU).o

all: version_info libs firmware.bin

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
	chmod -x $@
	cp $@ boot.bin

firmware.elf: $(OBJECTS)

%.elf: linker.ld $(MSCDIR)/software/libbase/crt0-$(CPU).o $(MSCDIR)/software/libbase/libbase-nofloat.a $(MSCDIR)/software/libcompiler-rt/libcompiler-rt.a
	$(LD) $(LDFLAGS) \
		-T linker.ld \
		-N -o $@ \
		$(MSCDIR)/software/libbase/crt0-$(CPU).o \
		$(OBJECTS) \
		-L$(MSCDIR)/software/libbase \
		-L$(MSCDIR)/software/libcompiler-rt \
		-lbase-nofloat -lcompiler-rt
	chmod -x $@

%.o: %.c
	$(compile-dep)

version.o: version.h version_data.h

%.o: %.S
	$(assemble)

libs:
	$(MAKE) -C $(MSCDIR)/software/libcompiler-rt
	$(MAKE) -C $(MSCDIR)/software/libbase

clean:
	$(RM) $(OBJECTS) $(OBJECTS:.o=.d) firmware.elf firmware.bin
	$(RM) .*~ *~

version_info:
	bash version_data.sh

.PHONY: all clean libs load version_info
