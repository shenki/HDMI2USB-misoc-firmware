typedef unsigned int u32;

static void *base = (void *)0xe0001000;
#define	UART_RXTX	0x00
#define UART_TXFULL	0x04
#define UART_RXEMPTY	0x08

static u32 readl(volatile u32 *addr)
{
	return *addr;
}

static void writel(u32 *addr, u32 val)
{
	*addr = val;
}

static unsigned char uart_getc(void)
{
	return readl(base + UART_RXTX);
}

static void uart_putc(unsigned char value)
{
	writel(base + UART_RXTX, value);
}

static unsigned char uart_rxempty(void)
{
	return readl(base + UART_RXEMPTY);
}

static unsigned char uart_txfull(void)
{
	return readl(base + UART_TXFULL);
}

static void boot(long addr)
{
	asm("call r0");
}

static void reboot(void)
{
	boot(0x20000000);
}

#if defined (__lm32__)
#define NOP "nop"
#elif defined (__or1k__)
#define NOP "l.nop"
#else
#error Unsupported architecture
#endif

static void cdelay(int i)
{
	while(i--)
		__asm__ volatile(NOP);
}

void my_putc(char c)
{
	while (uart_txfull());
	uart_putc(c);
	while (uart_txfull());
}

void my_puts(char *s)
{
	while (*s)
		my_putc(*s++);
}

int main(void)
{
	my_puts("Hello, World!\n");

	while(uart_rxempty());

	reboot();

	return 0;
}
