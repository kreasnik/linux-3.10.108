/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 1994, 1995 Waldorf Electronics
 * Written by Ralf Baechle and Andreas Busse
 * Copyright (C) 1994 - 99, 2003, 06 Ralf Baechle
 * Copyright (C) 1996 Paul M. Antoine
 * Modified for DECStation and hence R3000 support by Paul M. Antoine
 * Further modifications by David S. Miller and Harald Koerfgen
 * Copyright (C) 1999 Silicon Graphics, Inc.
 * Kevin Kissell, kevink@mips.com and Carsten Langgaard, carstenl@mips.com
 * Copyright (C) 2000 MIPS Technologies, Inc.  All rights reserved.
 */
#include <linux/init.h>
#include <linux/threads.h>

#include <asm/addrspace.h>
#include <asm/asm.h>
#include <asm/asmmacro.h>
#include <asm/irqflags.h>
#include <asm/regdef.h>
#include <asm/pgtable-bits.h>
#include <asm/mipsregs.h>
#include <asm/stackframe.h>
#if defined (CONFIG_RALINK_MT7621)
#include <asm/cacheops.h>
#endif
#include <kernel-entry-init.h>

	/*
	 * inputs are the text nasid in t1, data nasid in t2.
	 */
	.macro MAPPED_KERNEL_SETUP_TLB
#ifdef CONFIG_MAPPED_KERNEL
	/*
	 * This needs to read the nasid - assume 0 for now.
	 * Drop in 0xffffffffc0000000 in tlbhi, 0+VG in tlblo_0,
	 * 0+DVG in tlblo_1.
	 */
	dli	t0, 0xffffffffc0000000
	dmtc0	t0, CP0_ENTRYHI
	li	t0, 0x1c000		# Offset of text into node memory
	dsll	t1, NASID_SHFT		# Shift text nasid into place
	dsll	t2, NASID_SHFT		# Same for data nasid
	or	t1, t1, t0		# Physical load address of kernel text
	or	t2, t2, t0		# Physical load address of kernel data
	dsrl	t1, 12			# 4K pfn
	dsrl	t2, 12			# 4K pfn
	dsll	t1, 6			# Get pfn into place
	dsll	t2, 6			# Get pfn into place
	li	t0, ((_PAGE_GLOBAL|_PAGE_VALID| _CACHE_CACHABLE_COW) >> 6)
	or	t0, t0, t1
	mtc0	t0, CP0_ENTRYLO0	# physaddr, VG, cach exlwr
	li	t0, ((_PAGE_GLOBAL|_PAGE_VALID| _PAGE_DIRTY|_CACHE_CACHABLE_COW) >> 6)
	or	t0, t0, t2
	mtc0	t0, CP0_ENTRYLO1	# physaddr, DVG, cach exlwr
	li	t0, 0x1ffe000		# MAPPED_KERN_TLBMASK, TLBPGMASK_16M
	mtc0	t0, CP0_PAGEMASK
	li	t0, 0			# KMAP_INX
	mtc0	t0, CP0_INDEX
	li	t0, 1
	mtc0	t0, CP0_WIRED
	tlbwi
#else
	mtc0	zero, CP0_WIRED
#endif
	.endm

	/*
	 * For the moment disable interrupts, mark the kernel mode and
	 * set ST0_KX so that the CPU does not spit fire when using
	 * 64-bit addresses.  A full initialization of the CPU's status
	 * register is done later in per_cpu_trap_init().
	 */
	.macro	setup_c0_status set clr
	.set	push
#ifdef CONFIG_MIPS_MT_SMTC
	/*
	 * For SMTC, we need to set privilege and disable interrupts only for
	 * the current TC, using the TCStatus register.
	 */
	mfc0	t0, CP0_TCSTATUS
	/* Fortunately CU 0 is in the same place in both registers */
	/* Set TCU0, TMX, TKSU (for later inversion) and IXMT */
	li	t1, ST0_CU0 | 0x08001c00
	or	t0, t1
	/* Clear TKSU, leave IXMT */
	xori	t0, 0x00001800
	mtc0	t0, CP0_TCSTATUS
	_ehb
	/* We need to leave the global IE bit set, but clear EXL...*/
	mfc0	t0, CP0_STATUS
	or	t0, ST0_CU0 | ST0_EXL | ST0_ERL | \set | \clr
	xor	t0, ST0_EXL | ST0_ERL | \clr
	mtc0	t0, CP0_STATUS
#else
	mfc0	t0, CP0_STATUS
	or	t0, ST0_CU0|\set|0x1f|\clr
	xor	t0, 0x1f|\clr
	mtc0	t0, CP0_STATUS
	.set	noreorder
	sll	zero,3				# ehb
#endif
	.set	pop
	.endm

	.macro	setup_c0_status_pri
#ifdef CONFIG_64BIT
	setup_c0_status ST0_KX 0
#else
	setup_c0_status 0 0
#endif
	.endm

	.macro	setup_c0_status_sec
#ifdef CONFIG_64BIT
	setup_c0_status ST0_KX ST0_BEV
#else
	setup_c0_status 0 ST0_BEV
#endif
	.endm

#ifndef CONFIG_NO_EXCEPT_FILL
	/*
	 * Reserved space for exception handlers.
	 * Necessary for machines which link their kernels at KSEG0.
	 */
	.fill	0x400
#endif

EXPORT(_stext)

#ifdef CONFIG_BOOT_RAW
	/*
	 * Give us a fighting chance of running if execution beings at the
	 * kernel load address.	 This is needed because this platform does
	 * not have a ELF loader yet.
	 */
FEXPORT(__kernel_entry)
	j	kernel_entry
#endif

	__REF

#ifdef CONFIG_EVA
	.align  8
#endif

NESTED(kernel_entry, 16, sp)			# kernel entry point

	kernel_entry_setup                      # cpu specific setup

	setup_c0_status_pri
#ifdef CONFIG_RALINK_MT7621
	/* Set L2 CCA Override to WT on lowest 256MB */
	.set push
	.set noreorder

	jal 1f
	li t0, 5
1:
	ins ra, t0, 29, 3
	addiu   ra, 2f-1b
	jr  ra
	nop

   /* Running in KSEG 1*/
2:
	.set pop
	/* Flush L2 Cache before setting CCA overrides */
	/* Define L2 Cache Line Size 32 */
#define L2_LINE_SIZE  32
	/* Define L2 Size 256K */
#define L2_SIZE       (256<<10)
	li      v0, L2_SIZE
	move    v1, zero 

1:
	cache   Index_Writeback_Inv_SD, 0(v1)
	addiu   v1, v1, L2_LINE_SIZE    /* Increase Index */
	bne     v1, v0, 1b
	nop

	sync

	/* Override bottom half of DDR to uncached (DMA zone) */
	lui     v0,0xbfbf
	ori     v0,v0,0x8000

	lui    v1, (~(((CONFIG_KERNEL_START_ADDR-0x80001000)-1)>>16))& 0xFFFF
	ori     v1,v1,0x0051
	sw      v1, 0xb8(v0)

	/* Base */
	sw      zero,0xb0(v0)

	/* Set default override to WT */
	lui     v1,0x1fbf
	ori     v1,v1,0x8010
	sw      v1, 0x08(v0)
#endif

	/* We might not get launched at the address the kernel is linked to,
	   so we jump there.  */
	PTR_LA	t0, 0f
	jr.hb   t0
#ifdef CONFIG_EVA
	.align  8
#endif
0:

#ifdef CONFIG_MIPS_MT_SMTC
	/*
	 * In SMTC kernel, "CLI" is thread-specific, in TCStatus.
	 * We still need to enable interrupts globally in Status,
	 * and clear EXL/ERL.
	 *
	 * TCContext is used to track interrupt levels under
	 * service in SMTC kernel. Clear for boot TC before
	 * allowing any interrupts.
	 */
	mtc0	zero, CP0_TCCONTEXT

	mfc0	t0, CP0_STATUS
	ori	t0, t0, 0xff1f
	xori	t0, t0, 0x001e
	mtc0	t0, CP0_STATUS
#endif /* CONFIG_MIPS_MT_SMTC */

	PTR_LA		t0, __bss_start		# clear .bss
	LONG_S		zero, (t0)
	PTR_LA		t1, __bss_stop - LONGSIZE
1:
	PTR_ADDIU	t0, LONGSIZE
	LONG_S		zero, (t0)
	bne		t0, t1, 1b

	LONG_S		a0, fw_arg0		# firmware arguments
	LONG_S		a1, fw_arg1
	LONG_S		a2, fw_arg2
	LONG_S		a3, fw_arg3

	MTC0		zero, CP0_CONTEXT	# clear context register
	PTR_LA		$28, init_thread_union
	/* Set the SP after an empty pt_regs.  */
	PTR_LI		sp, _THREAD_SIZE - 32 - PT_SIZE
	PTR_ADDU	sp, $28
	back_to_back_c0_hazard
	set_saved_sp	sp, t0, t1
	PTR_SUBU	sp, 4 * SZREG		# init stack pointer

	j		start_kernel
	END(kernel_entry)

	__CPUINIT

#ifdef CONFIG_SMP
/*
 * SMP slave cpus entry point.	Board specific code for bootstrap calls this
 * function after setting up the stack and gp registers.
 */

#ifdef CONFIG_EVA
	.align  8
#endif

NESTED(smp_bootstrap, 16, sp)

#ifdef CONFIG_MIPS_MT_SMTC
	/*
	 * Read-modify-writes of Status must be atomic, and this
	 * is one case where CLI is invoked without EXL being
	 * necessarily set. The CLI and setup_c0_status will
	 * in fact be redundant for all but the first TC of
	 * each VPE being booted.
	 */
	DMT	10	# dmt t2 /* t0, t1 are used by CLI and setup_c0_status() */
	jal	mips_ihb
#endif /* CONFIG_MIPS_MT_SMTC */

	smp_slave_setup
	setup_c0_status_sec

#ifdef CONFIG_MIPS_MT_SMTC
	andi	t2, t2, VPECONTROL_TE
	beqz	t2, 2f
	EMT		# emt
2:
#endif /* CONFIG_MIPS_MT_SMTC */
	j	start_secondary
#ifdef CONFIG_EVA
	.align  8
#endif
	END(smp_bootstrap)
#endif /* CONFIG_SMP */

	__FINIT
