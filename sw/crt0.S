#=====================================================================
# crt0.S -- reset vector and C runtime startup
#
# Lands at address 0 because link.ld puts .text.init first and the core
# resets its PC to 0. Sets up the stack, clears .bss, calls main().
# If main ever returns we spin forever -- there is no OS to return to.
#=====================================================================
    .section .text.init, "ax"
    .globl  _start
    .type   _start, @function

_start:
    # ---- stack pointer ----
    la      sp, _stack_top

    # ---- zero .bss ----
    la      t0, _bss_start
    la      t1, _bss_end
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b

2:  # ---- into C ----
    call    main

3:  j       3b                  # main returned: park here
    .size   _start, . - _start
