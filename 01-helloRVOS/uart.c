#include "types.h"
#include "platform.h"

/*
 * UART (Universal Asynchronous Receiver and Transmitter)
 * The UART control registers are memory-mapped at address UART0. 
 * This macro returns the address of one of the registers.
 */
#define UART_REG(reg) ((volatile uint8_t *)(UART0 + reg))

/*
 * Reference NS16550a 
 * [1]: TECHNICAL DATA ON 16550, http://byterunner.com/16550.html
 */

/*
 * UART control registers map. see [1] "PROGRAMMING TABLE"
 * note some are reused by multiple functions
 * 0 (write mode): THR/DLL
 * 1 (write mode): IER/DLM
 */
#define RHR 0	// Receive Holding Register (read mode)
#define THR 0	// Transmit Holding Register (write mode)
#define DLL 0	// LSB of Divisor Latch (write mode)
#define IER 1	// Interrupt Enable Register (write mode)
#define DLM 1	// MSB of Divisor Latch (write mode)
#define FCR 2	// FIFO Control Register (write mode)
#define ISR 2	// Interrupt Status Register (read mode)
#define LCR 3	// Line Control Register
#define MCR 4	// Modem Control Register
#define LSR 5	// Line Status Register
#define MSR 6	// Modem Status Register
#define SPR 7	// ScratchPad Register

/*
 * POWER UP DEFAULTS
 * IER = 0: TX/RX holding register interrupts are both disabled
 * ISR = 1: no interrupt penting
 * LCR = 0
 * MCR = 0
 * LSR = 60 HEX
 * MSR = BITS 0-3 = 0, BITS 4-7 = inputs
 * FCR = 0
 * TX = High
 * OP1 = High
 * OP2 = High
 * RTS = High
 * DTR = High
 * RXRDY = High
 * TXRDY = Low
 * INT = Low
 */

/*
 * LINE STATUS REGISTER (LSR)
 * LSR BIT 0:
 * 0 = no data in receive holding register or FIFO.
 * 1 = data has been receive and saved in the receive holding register or FIFO.
 * ......
 * LSR BIT 5:
 * 0 = transmit holding register is full. 16550 will not accept any data for transmission.
 * 1 = transmitter hold register (or FIFO) is empty. CPU can load the next character.
 * ......
 */
#define LSR_RX_READY (1 << 0) // 0000 0000 0000 0000 0000 0000 0000 0001
#define LSR_TX_IDLE  (1 << 5) // 0000 0000 0000 0000 0000 0000 0010 0000

#define uart_read_reg(reg) (*(UART_REG(reg)))
#define uart_write_reg(reg, v) (*(UART_REG(reg)) = (v))

void uart_init()
{
	/* disable interrupts. */
	uart_write_reg(IER, 0x00);

	/*
	 * Setting baud rate. Just a demo here if we care about the divisor,
	 * but for our purpose [QEMU-virt], this doesn't really do anything.
	 *
	 * Notice that the divisor register DLL (divisor latch least) and DLM (divisor
	 * latch most) have the same base address as the receiver/transmitter and the
	 * interrupt enable register. To change what the base address points to, we
	 * open the "divisor latch" by writing 1 into the Divisor Latch Access Bit
	 * (DLAB), which is bit index 7 of the Line Control Register (LCR).
	 *
	 * Regarding the baud rate value, see [1] "BAUD RATE GENERATOR PROGRAMMING TABLE".
	 * We use 38.4K when 1.8432 MHZ crystal, so the corresponding value is 3.
	 * And due to the divisor register is two bytes (16 bits), so we need to
	 * split the value of 3(0x0003) into two bytes, DLL stores the low byte,
	 * DLM stores the high byte.
	 */

	// http://byterunner.com/16550.html
	// BAUD RATE  1.8432 MHZ clock  7.3728 MHZ clock
	// 38.4K           3                 12
	uint8_t lcr = uart_read_reg(LCR);
	uart_write_reg(LCR, lcr | (1 << 7)); // LCR (Line Control Register)
	// set DLM DLL to 3 to set BAUD RATE to 38.4k
	// DLM DLL: 00000000 00000011
	uart_write_reg(DLL, 0x03); // DLL (divisor latch least)
	uart_write_reg(DLM, 0x00); // DLM (divisor latch most)

	/*
	 * Continue setting the asynchronous data communication format.
	 * - number of the word length: 8 bits
	 * - number of stop bits：1 bit when word length is 8 bits
	 * - no parity
	 * - no break control
	 * - disabled baud latch
	 */
	lcr = 0;
	uart_write_reg(LCR, lcr | (3 << 0));
	// lcr = 0x00, 3 << 0 = 0x00 00 00 03
	// lcr | (3 << 0) = 0x00 00 00 03
	// LCR = lcr | (3 << 0) -> LCR = 0x03
}

int uart_putc(char ch)
{
	// LSR (Line Status Register)
	// uart_read_reg(LSR) = XX1X XXXX or XX0X XXXX
	// LSR_TX_IDLE = 0000 0000 0000 0000 0000 0000 0010 0000
	// XX1X XXXX & LSR_TX_IDLE = 0x00 00 00 20 != 0 (int zero)
	// XX0X XXXX & LSR_TX_IDLE = 0x00 00 00 00 == 0 (int zero)
	while ((uart_read_reg(LSR) & LSR_TX_IDLE) == 0);
	// THR (Transmit Holding Register)
	return uart_write_reg(THR, ch);
}

// char s[] = {'H', 'e', 'l', 'l', 'o', '\0'};
void uart_puts(char *s)
{
	// while (*s != '\0') {
	while (*s) {
		uart_putc(*s); s++;
	}
}

