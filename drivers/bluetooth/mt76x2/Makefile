export KERNEL_SRC := /lib/modules/$(shell uname -r)/build

###############################################################################
# USB
###############################################################################
USB_MOD_NAME = btmtk_usb
USB_CFILES := \
	btmtk_usb_main.c \
	btmtk_usb_fifo.c
$(USB_MOD_NAME)-objs := $(USB_CFILES:.c=.o)

###############################################################################
# SDIO
###############################################################################
#SDIO_MOD_NAME = btmtk_sdio
#SDIO_CFILES := \
#	btmtk_sdio_main.c
#$(SDIO_MOD_NAME)-objs := $(SDIO_CFILES:.c=.o)

###############################################################################
# Common
###############################################################################
obj-y += $(USB_MOD_NAME).o


all:
	make -C $(KERNEL_SRC) M=$(PWD) $(USB_MOD_NAME).ko

usb:
	make -C $(KERNEL_SRC) M=$(PWD) $(USB_MOD_NAME).ko

#sdio:
#	make -C $(KERNEL_SRC) M=$(PWD) $(SDIO_MOD_NAME).ko

clean:
	make -C $(KERNEL_SRC) M=$(PWD) clean


###############################################################################
# Check coding style
###############################################################################
ccs:
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_usb_main.c
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_usb_main.h
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_config.h
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_define.h
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_usb_fifo.c
	./util/checkpatch.pl --no-tree --show-types --max-line-length=120 -f btmtk_usb_fifo.h
