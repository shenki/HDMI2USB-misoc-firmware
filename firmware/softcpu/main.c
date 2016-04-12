#include <stdio.h>
#include <stdlib.h>

#include <irq.h>
#include <uart.h>
#include <time.h>
#include <generated/csr.h>
#include <generated/mem.h>
#include <hw/flags.h>
#include <console.h>

#include "version.h"

extern void boot_helper(unsigned int r1, unsigned int r2, unsigned int r3,
		unsigned int addr);

static void __attribute__((noreturn)) boot(unsigned int r1, unsigned int r2,
		unsigned int r3, unsigned int addr) 
{
	uart_sync();
	irq_setmask(0);
	irq_setie(0);
	flush_cpu_icache();
	boot_helper(r1, r2, r3, addr);
	while(1);
}

int main(void)
{
	irq_setmask(0);
	irq_setie(1);
	uart_init();

	puts("\r\nHDMI2USB firmware  http://timvideos.us/");
	print_version();

	time_init();

	puts("returning to bios\n");
	boot(0, 0, 0, 0);

	return 0;
}
