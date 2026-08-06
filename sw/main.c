/*=====================================================================
  main.c -- demo program for the single-cycle RV32I SoC

  Exercises the parts of the ISA a compiler actually emits: loads,
  stores, shifts, signed and unsigned compares, function calls, and
  array indexing through a base register.

  Behaviour on the board:
    - computes 24 Fibonacci numbers into RAM
    - the 16 switches select an index
    - the low  16 bits of that value appear on the 7-segment display
    - the high 16 bits appear on the LEDs
=====================================================================*/

#define LED  (*(volatile unsigned int *)0x20000000)   /* write */
#define SW   (*(volatile unsigned int *)0x20000004)   /* read  */
#define HEX  (*(volatile unsigned int *)0x20000008)   /* write */

#define N_FIB 24

static unsigned int fib[N_FIB];      /* .bss -- zeroed by crt0 */

static void compute_fib(void)
{
    int i;
    fib[0] = 0u;
    fib[1] = 1u;
    for (i = 2; i < N_FIB; i++)
        fib[i] = fib[i - 1] + fib[i - 2];
}

int main(void)
{
    unsigned int idx;
    unsigned int val;

    compute_fib();

    for (;;) {
        idx = SW & 0x1Fu;
        if (idx >= (unsigned int)N_FIB)
            idx = (unsigned int)(N_FIB - 1);

        val = fib[idx];

        HEX = val & 0xFFFFu;
        LED = (val >> 16) & 0xFFFFu;
    }

    return 0;   /* unreachable */
}
