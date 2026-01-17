	.text
	.attribute	4, 16
	.attribute	5, "rv32i2p1"
	.file	"llvm-link"
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	builtin_hw_bf                   # -- Begin function builtin_hw_bf
	.p2align	2
	.type	builtin_hw_bf,@function
builtin_hw_bf:                          # @builtin_hw_bf
	.cfi_startproc
# %bb.0:                                # %entry
	#APP
	.insn r 91, 7, 0, a0, a0, a1
	#NO_APP
	ret
.Lfunc_end0:
	.size	builtin_hw_bf, .Lfunc_end0-builtin_hw_bf
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	builtin_hw_bf_p2                # -- Begin function builtin_hw_bf_p2
	.p2align	2
	.type	builtin_hw_bf_p2,@function
builtin_hw_bf_p2:                       # @builtin_hw_bf_p2
	.cfi_startproc
# %bb.0:                                # %entry
	#APP
	.insn r 43, 7, 0, a0, a0, a1
	#NO_APP
	ret
.Lfunc_end1:
	.size	builtin_hw_bf_p2, .Lfunc_end1-builtin_hw_bf_p2
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	builtin_hw_bf_p2_config_input   # -- Begin function builtin_hw_bf_p2_config_input
	.p2align	2
	.type	builtin_hw_bf_p2_config_input,@function
builtin_hw_bf_p2_config_input:          # @builtin_hw_bf_p2_config_input
	.cfi_startproc
# %bb.0:                                # %entry
	#APP
	.insn r 11, 7, 0, a0, a0, zero
	#NO_APP
	ret
.Lfunc_end2:
	.size	builtin_hw_bf_p2_config_input, .Lfunc_end2-builtin_hw_bf_p2_config_input
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	builtin_hw_bf_p2_config_output  # -- Begin function builtin_hw_bf_p2_config_output
	.p2align	2
	.type	builtin_hw_bf_p2_config_output,@function
builtin_hw_bf_p2_config_output:         # @builtin_hw_bf_p2_config_output
	.cfi_startproc
# %bb.0:                                # %entry
	#APP
	.insn r 91, 7, 0, a0, a0, zero
	#NO_APP
	ret
.Lfunc_end3:
	.size	builtin_hw_bf_p2_config_output, .Lfunc_end3-builtin_hw_bf_p2_config_output
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	pure_ntt                        # -- Begin function pure_ntt
	.p2align	2
	.type	pure_ntt,@function
pure_ntt:                               # @pure_ntt
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -64
	.cfi_def_cfa_offset 64
	sw	ra, 60(sp)                      # 4-byte Folded Spill
	sw	s0, 56(sp)                      # 4-byte Folded Spill
	sw	s1, 52(sp)                      # 4-byte Folded Spill
	sw	s2, 48(sp)                      # 4-byte Folded Spill
	sw	s3, 44(sp)                      # 4-byte Folded Spill
	sw	s4, 40(sp)                      # 4-byte Folded Spill
	sw	s5, 36(sp)                      # 4-byte Folded Spill
	sw	s6, 32(sp)                      # 4-byte Folded Spill
	sw	s7, 28(sp)                      # 4-byte Folded Spill
	sw	s8, 24(sp)                      # 4-byte Folded Spill
	sw	s9, 20(sp)                      # 4-byte Folded Spill
	sw	s10, 16(sp)                     # 4-byte Folded Spill
	sw	s11, 12(sp)                     # 4-byte Folded Spill
	.cfi_offset ra, -4
	.cfi_offset s0, -8
	.cfi_offset s1, -12
	.cfi_offset s2, -16
	.cfi_offset s3, -20
	.cfi_offset s4, -24
	.cfi_offset s5, -28
	.cfi_offset s6, -32
	.cfi_offset s7, -36
	.cfi_offset s8, -40
	.cfi_offset s9, -44
	.cfi_offset s10, -48
	.cfi_offset s11, -52
	sw	a0, 0(sp)                       # 4-byte Folded Spill
	#APP
	fence
	#NO_APP
	li	a0, 1
	li	s7, 256
.Lpcrel_hi0:
	auipc	a1, %pcrel_hi(PRE_COMPUT_TABLE_NTT)
	addi	a1, a1, %pcrel_lo(.Lpcrel_hi0)
	sw	a1, 4(sp)                       # 4-byte Folded Spill
	lui	a1, 1
	addi	s2, a1, -767
	j	.LBB4_2
.LBB4_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB4_2 Depth=1
	lw	a2, 8(sp)                       # 4-byte Folded Reload
	slli	a0, a2, 1
	li	a1, 64
	bgeu	a2, a1, .LBB4_7
.LBB4_2:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB4_4 Depth 2
                                        #       Child Loop BB4_6 Depth 3
	li	s3, 0
	andi	s9, s7, 510
	srli	s7, s7, 1
	seqz	s11, a0
	sw	a0, 8(sp)                       # 4-byte Folded Spill
	add	s11, a0, s11
	slli	s1, s7, 2
	lw	s4, 0(sp)                       # 4-byte Folded Reload
	j	.LBB4_4
.LBB4_3:                                # %for.cond.cleanup8
                                        #   in Loop: Header=BB4_4 Depth=2
	addi	s3, s3, 1
	add	s4, s4, s1
	beq	s3, s11, .LBB4_1
.LBB4_4:                                # %for.body4
                                        #   Parent Loop BB4_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB4_6 Depth 3
	mv	a0, s1
	mv	a1, s3
	call	__mulsi3
	mv	s6, a0
	mv	a0, s3
	mv	a1, s7
	call	__mulsi3
	lw	a1, 8(sp)                       # 4-byte Folded Reload
	add	a1, s3, a1
	slli	a1, a1, 1
	lw	a2, 4(sp)                       # 4-byte Folded Reload
	add	a1, a2, a1
	lhu	s5, 0(a1)
	slli	a0, a0, 1
	add	a1, a0, s7
	bgeu	a0, a1, .LBB4_3
# %bb.5:                                #   in Loop: Header=BB4_4 Depth=2
	add	s6, s9, s6
	lw	s8, 0(sp)                       # 4-byte Folded Reload
	add	s8, s8, s6
	mv	s0, s4
.LBB4_6:                                # %for.body9
                                        #   Parent Loop BB4_2 Depth=1
                                        #     Parent Loop BB4_4 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	add	s10, s0, s9
	lhu	a0, 0(s10)
	mv	a1, s5
	call	__mulsi3
	mv	a1, s2
	call	__umodsi3
	lhu	a1, 0(s0)
	mv	s6, a0
	add	a1, a1, s2
	sub	a0, a1, a0
	mv	a1, s2
	call	__umodsi3
	sh	a0, 0(s10)
	lhu	a0, 0(s0)
	add	a0, s6, a0
	mv	a1, s2
	call	__umodsi3
	sh	a0, 0(s0)
	addi	s0, s0, 2
	bne	s0, s8, .LBB4_6
	j	.LBB4_3
.LBB4_7:                                # %for.cond.cleanup
	#APP
	fence
	#NO_APP
	lw	ra, 60(sp)                      # 4-byte Folded Reload
	lw	s0, 56(sp)                      # 4-byte Folded Reload
	lw	s1, 52(sp)                      # 4-byte Folded Reload
	lw	s2, 48(sp)                      # 4-byte Folded Reload
	lw	s3, 44(sp)                      # 4-byte Folded Reload
	lw	s4, 40(sp)                      # 4-byte Folded Reload
	lw	s5, 36(sp)                      # 4-byte Folded Reload
	lw	s6, 32(sp)                      # 4-byte Folded Reload
	lw	s7, 28(sp)                      # 4-byte Folded Reload
	lw	s8, 24(sp)                      # 4-byte Folded Reload
	lw	s9, 20(sp)                      # 4-byte Folded Reload
	lw	s10, 16(sp)                     # 4-byte Folded Reload
	lw	s11, 12(sp)                     # 4-byte Folded Reload
	addi	sp, sp, 64
	ret
.Lfunc_end4:
	.size	pure_ntt, .Lfunc_end4-pure_ntt
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +zicsr, +zifencei
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -96
	.cfi_def_cfa_offset 96
	sw	ra, 92(sp)                      # 4-byte Folded Spill
	sw	s0, 88(sp)                      # 4-byte Folded Spill
	sw	s1, 84(sp)                      # 4-byte Folded Spill
	sw	s2, 80(sp)                      # 4-byte Folded Spill
	sw	s3, 76(sp)                      # 4-byte Folded Spill
	sw	s4, 72(sp)                      # 4-byte Folded Spill
	sw	s5, 68(sp)                      # 4-byte Folded Spill
	sw	s6, 64(sp)                      # 4-byte Folded Spill
	sw	s7, 60(sp)                      # 4-byte Folded Spill
	sw	s8, 56(sp)                      # 4-byte Folded Spill
	sw	s9, 52(sp)                      # 4-byte Folded Spill
	sw	s10, 48(sp)                     # 4-byte Folded Spill
	sw	s11, 44(sp)                     # 4-byte Folded Spill
	.cfi_offset ra, -4
	.cfi_offset s0, -8
	.cfi_offset s1, -12
	.cfi_offset s2, -16
	.cfi_offset s3, -20
	.cfi_offset s4, -24
	.cfi_offset s5, -28
	.cfi_offset s6, -32
	.cfi_offset s7, -36
	.cfi_offset s8, -40
	.cfi_offset s9, -44
	.cfi_offset s10, -48
	.cfi_offset s11, -52
	lui	s5, 16
	addi	s5, s5, -1
	#APP
	fence
	#NO_APP
	li	a0, 1
	li	s8, 256
.Lpcrel_hi1:
	auipc	a1, %pcrel_hi(PRE_COMPUT_TABLE_NTT)
	addi	s3, a1, %pcrel_lo(.Lpcrel_hi1)
.Lpcrel_hi2:
	auipc	a1, %pcrel_hi(a)
	addi	s2, a1, %pcrel_lo(.Lpcrel_hi2)
	j	.LBB5_2
.LBB5_1:                                # %for.cond.cleanup3.i
                                        #   in Loop: Header=BB5_2 Depth=1
	slli	a0, s9, 1
	li	a1, 64
	bgeu	s9, a1, .LBB5_10
.LBB5_2:                                # %for.body.i
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB5_4 Depth 2
                                        #       Child Loop BB5_9 Depth 3
	li	s1, 0
	mv	s9, a0
	andi	s10, s8, 510
	srli	s8, s8, 1
	seqz	s11, a0
	add	s11, a0, s11
	slli	a0, s8, 1
	sw	a0, 12(sp)                      # 4-byte Folded Spill
	andi	s7, s8, 255
	slli	s7, s7, 8
	mv	s0, s8
	sw	s9, 20(sp)                      # 4-byte Folded Spill
	sw	s11, 16(sp)                     # 4-byte Folded Spill
	j	.LBB5_4
.LBB5_3:                                # %for.cond.cleanup8.i
                                        #   in Loop: Header=BB5_4 Depth=2
	addi	s1, s1, 1
	add	s0, s0, s10
	beq	s1, s11, .LBB5_1
.LBB5_4:                                # %for.body4.i
                                        #   Parent Loop BB5_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB5_9 Depth 3
	mv	a0, s1
	mv	a1, s8
	call	__mulsi3
	add	a1, s1, s9
	slli	a1, a1, 1
	add	a1, s3, a1
	lhu	a1, 0(a1)
	slli	s6, a0, 1
	add	a0, s6, s8
	bgeu	s6, a0, .LBB5_3
# %bb.5:                                # %for.body9.lr.ph.i
                                        #   in Loop: Header=BB5_4 Depth=2
	andi	a0, s8, 1
	and	a1, a1, s5
	sw	a1, 28(sp)                      # 4-byte Folded Spill
	beqz	a0, .LBB5_7
# %bb.6:                                # %ClonedBB.prol
                                        #   in Loop: Header=BB5_4 Depth=2
	slli	a0, s6, 1
	add	s11, s2, a0
	lw	a0, 12(sp)                      # 4-byte Folded Reload
	add	a0, s11, a0
	sw	a0, 24(sp)                      # 4-byte Folded Spill
	slli	a0, a1, 16
	andi	a1, s6, 255
	or	a1, a1, s7
	or	a0, a0, a1
	mv	s9, s2
	#APP
	.insn r 91, 7, 0, s2, a0, s2
	#NO_APP
	mv	a0, s2
	call	extract_main_1
	mv	s4, s3
	mv	s3, a0
	mv	a0, s2
	mv	s2, s9
	lw	s9, 20(sp)                      # 4-byte Folded Reload
	call	extract_main_0
	lw	a1, 24(sp)                      # 4-byte Folded Reload
	sh	s3, 0(a1)
	mv	s3, s4
	sh	a0, 0(s11)
	lw	s11, 16(sp)                     # 4-byte Folded Reload
	addi	s6, s6, 1
.LBB5_7:                                # %ClonedBB.prol.loopexit
                                        #   in Loop: Header=BB5_4 Depth=2
	addi	a0, s8, -1
	beqz	a0, .LBB5_3
# %bb.8:                                # %ClonedBB.preheader
                                        #   in Loop: Header=BB5_4 Depth=2
	#APP
	.insn r 11, 7, 0, a0, s2, zero
	#NO_APP
	addi	a0, sp, 32
	#APP
	.insn r 91, 7, 0, a0, a0, zero
	#NO_APP
	slli	a0, s6, 1
	add	a0, s2, a0
	addi	a0, a0, 2
	lw	s4, 28(sp)                      # 4-byte Folded Reload
	slli	s4, s4, 16
.LBB5_9:                                # %ClonedBB
                                        #   Parent Loop BB5_2 Depth=1
                                        #     Parent Loop BB5_4 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	andi	a1, s6, 255
	or	a1, s4, a1
	or	a1, a1, s7
	addi	a2, s6, 1
	andi	a2, a2, 255
	or	a3, s4, s7
	or	a2, a3, a2
	#APP
	.insn r 43, 7, 0, a1, a1, a2
	#NO_APP
	lw	a1, 32(sp)
	add	a2, a0, s10
	lw	a3, 36(sp)
	and	a4, a1, s5
	srli	a1, a1, 16
	and	a1, a1, s5
	and	a5, a3, s5
	srli	a3, a3, 16
	and	a3, a3, s5
	sh	a3, 0(a2)
	sh	a4, -2(a2)
	sh	a5, -2(a0)
	sh	a1, 0(a0)
	addi	s6, s6, 2
	addi	a0, a0, 4
	bne	s0, s6, .LBB5_9
	j	.LBB5_3
.LBB5_10:                               # %pure_ntt.exit
	#APP
	fence
	#NO_APP
.Lpcrel_hi3:
	auipc	a0, %pcrel_hi(.L.str)
	addi	s0, a0, %pcrel_lo(.Lpcrel_hi3)
	addi	s1, s2, 512
.LBB5_11:                               # %for.body
                                        # =>This Inner Loop Header: Depth=1
	lhu	a1, 0(s2)
	mv	a0, s0
	call	printf
	addi	s2, s2, 2
	bne	s2, s1, .LBB5_11
# %bb.12:                               # %for.cond.cleanup
	li	a0, 0
	lw	ra, 92(sp)                      # 4-byte Folded Reload
	lw	s0, 88(sp)                      # 4-byte Folded Reload
	lw	s1, 84(sp)                      # 4-byte Folded Reload
	lw	s2, 80(sp)                      # 4-byte Folded Reload
	lw	s3, 76(sp)                      # 4-byte Folded Reload
	lw	s4, 72(sp)                      # 4-byte Folded Reload
	lw	s5, 68(sp)                      # 4-byte Folded Reload
	lw	s6, 64(sp)                      # 4-byte Folded Reload
	lw	s7, 60(sp)                      # 4-byte Folded Reload
	lw	s8, 56(sp)                      # 4-byte Folded Reload
	lw	s9, 52(sp)                      # 4-byte Folded Reload
	lw	s10, 48(sp)                     # 4-byte Folded Reload
	lw	s11, 44(sp)                     # 4-byte Folded Reload
	addi	sp, sp, 96
	ret
.Lfunc_end5:
	.size	main, .Lfunc_end5-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.globl	builtin_packed_main_hw_bf_rs1   # -- Begin function builtin_packed_main_hw_bf_rs1
	.p2align	2
	.type	builtin_packed_main_hw_bf_rs1,@function
builtin_packed_main_hw_bf_rs1:          # @builtin_packed_main_hw_bf_rs1
	.cfi_startproc
# %bb.0:                                # %entry
	slli	a0, a0, 16
	andi	a1, a1, 255
	or	a0, a0, a1
	andi	a1, a2, 255
	slli	a1, a1, 8
	or	a0, a0, a1
	ret
.Lfunc_end6:
	.size	builtin_packed_main_hw_bf_rs1, .Lfunc_end6-builtin_packed_main_hw_bf_rs1
	.cfi_endproc
                                        # -- End function
	.globl	builtin_packed_main_hw_bf_rs2   # -- Begin function builtin_packed_main_hw_bf_rs2
	.p2align	2
	.type	builtin_packed_main_hw_bf_rs2,@function
builtin_packed_main_hw_bf_rs2:          # @builtin_packed_main_hw_bf_rs2
	.cfi_startproc
# %bb.0:                                # %entry
	ret
.Lfunc_end7:
	.size	builtin_packed_main_hw_bf_rs2, .Lfunc_end7-builtin_packed_main_hw_bf_rs2
	.cfi_endproc
                                        # -- End function
	.globl	extract_main_0                  # -- Begin function extract_main_0
	.p2align	2
	.type	extract_main_0,@function
extract_main_0:                         # @extract_main_0
	.cfi_startproc
# %bb.0:                                # %entry
	slli	a0, a0, 16
	srli	a0, a0, 16
	ret
.Lfunc_end8:
	.size	extract_main_0, .Lfunc_end8-extract_main_0
	.cfi_endproc
                                        # -- End function
	.globl	extract_main_1                  # -- Begin function extract_main_1
	.p2align	2
	.type	extract_main_1,@function
extract_main_1:                         # @extract_main_1
	.cfi_startproc
# %bb.0:                                # %entry
	srli	a0, a0, 16
	ret
.Lfunc_end9:
	.size	extract_main_1, .Lfunc_end9-extract_main_1
	.cfi_endproc
                                        # -- End function
	.type	PRE_COMPUT_TABLE_NTT,@object    # @PRE_COMPUT_TABLE_NTT
	.data
	.globl	PRE_COMPUT_TABLE_NTT
	.p2align	4, 0x0
PRE_COMPUT_TABLE_NTT:
	.half	1                               # 0x1
	.half	1729                            # 0x6c1
	.half	2580                            # 0xa14
	.half	3289                            # 0xcd9
	.half	2642                            # 0xa52
	.half	630                             # 0x276
	.half	1897                            # 0x769
	.half	848                             # 0x350
	.half	1062                            # 0x426
	.half	1919                            # 0x77f
	.half	193                             # 0xc1
	.half	797                             # 0x31d
	.half	2786                            # 0xae2
	.half	3260                            # 0xcbc
	.half	569                             # 0x239
	.half	1746                            # 0x6d2
	.half	296                             # 0x128
	.half	2447                            # 0x98f
	.half	1339                            # 0x53b
	.half	1476                            # 0x5c4
	.half	3046                            # 0xbe6
	.half	56                              # 0x38
	.half	2240                            # 0x8c0
	.half	1333                            # 0x535
	.half	1426                            # 0x592
	.half	2094                            # 0x82e
	.half	535                             # 0x217
	.half	2882                            # 0xb42
	.half	2393                            # 0x959
	.half	2879                            # 0xb3f
	.half	1974                            # 0x7b6
	.half	821                             # 0x335
	.half	289                             # 0x121
	.half	331                             # 0x14b
	.half	3253                            # 0xcb5
	.half	1756                            # 0x6dc
	.half	1197                            # 0x4ad
	.half	2304                            # 0x900
	.half	2277                            # 0x8e5
	.half	2055                            # 0x807
	.half	650                             # 0x28a
	.half	1977                            # 0x7b9
	.half	2513                            # 0x9d1
	.half	632                             # 0x278
	.half	2865                            # 0xb31
	.half	33                              # 0x21
	.half	1320                            # 0x528
	.half	1915                            # 0x77b
	.half	2319                            # 0x90f
	.half	1435                            # 0x59b
	.half	807                             # 0x327
	.half	452                             # 0x1c4
	.half	1438                            # 0x59e
	.half	2868                            # 0xb34
	.half	1534                            # 0x5fe
	.half	2402                            # 0x962
	.half	2647                            # 0xa57
	.half	2617                            # 0xa39
	.half	1481                            # 0x5c9
	.half	648                             # 0x288
	.half	2474                            # 0x9aa
	.half	3110                            # 0xc26
	.half	1227                            # 0x4cb
	.half	910                             # 0x38e
	.half	17                              # 0x11
	.half	2761                            # 0xac9
	.half	583                             # 0x247
	.half	2649                            # 0xa59
	.half	1637                            # 0x665
	.half	723                             # 0x2d3
	.half	2288                            # 0x8f0
	.half	1100                            # 0x44c
	.half	1409                            # 0x581
	.half	2662                            # 0xa66
	.half	3281                            # 0xcd1
	.half	233                             # 0xe9
	.half	756                             # 0x2f4
	.half	2156                            # 0x86c
	.half	3015                            # 0xbc7
	.half	3050                            # 0xbea
	.half	1703                            # 0x6a7
	.half	1651                            # 0x673
	.half	2789                            # 0xae5
	.half	1789                            # 0x6fd
	.half	1847                            # 0x737
	.half	952                             # 0x3b8
	.half	1461                            # 0x5b5
	.half	2687                            # 0xa7f
	.half	939                             # 0x3ab
	.half	2308                            # 0x904
	.half	2437                            # 0x985
	.half	2388                            # 0x954
	.half	733                             # 0x2dd
	.half	2337                            # 0x921
	.half	268                             # 0x10c
	.half	641                             # 0x281
	.half	1584                            # 0x630
	.half	2298                            # 0x8fa
	.half	2037                            # 0x7f5
	.half	3220                            # 0xc94
	.half	375                             # 0x177
	.half	2549                            # 0x9f5
	.half	2090                            # 0x82a
	.half	1645                            # 0x66d
	.half	1063                            # 0x427
	.half	319                             # 0x13f
	.half	2773                            # 0xad5
	.half	757                             # 0x2f5
	.half	2099                            # 0x833
	.half	561                             # 0x231
	.half	2466                            # 0x9a2
	.half	2594                            # 0xa22
	.half	2804                            # 0xaf4
	.half	1092                            # 0x444
	.half	403                             # 0x193
	.half	1026                            # 0x402
	.half	1143                            # 0x477
	.half	2150                            # 0x866
	.half	2775                            # 0xad7
	.half	886                             # 0x376
	.half	1722                            # 0x6ba
	.half	1212                            # 0x4bc
	.half	1874                            # 0x752
	.half	1029                            # 0x405
	.half	2110                            # 0x83e
	.half	2935                            # 0xb77
	.half	885                             # 0x375
	.half	2154                            # 0x86a
	.size	PRE_COMPUT_TABLE_NTT, 256

	.type	PRE_COMPUT_TABLE_INTT,@object   # @PRE_COMPUT_TABLE_INTT
	.globl	PRE_COMPUT_TABLE_INTT
	.p2align	4, 0x0
PRE_COMPUT_TABLE_INTT:
	.half	1                               # 0x1
	.half	1600                            # 0x640
	.half	40                              # 0x28
	.half	749                             # 0x2ed
	.half	2481                            # 0x9b1
	.half	1432                            # 0x598
	.half	2699                            # 0xa8b
	.half	687                             # 0x2af
	.half	1583                            # 0x62f
	.half	2760                            # 0xac8
	.half	69                              # 0x45
	.half	543                             # 0x21f
	.half	2532                            # 0x9e4
	.half	3136                            # 0xc40
	.half	1410                            # 0x582
	.half	2267                            # 0x8db
	.half	2508                            # 0x9cc
	.half	1355                            # 0x54b
	.half	450                             # 0x1c2
	.half	936                             # 0x3a8
	.half	447                             # 0x1bf
	.half	2794                            # 0xaea
	.half	1235                            # 0x4d3
	.half	1903                            # 0x76f
	.half	1996                            # 0x7cc
	.half	1089                            # 0x441
	.half	3273                            # 0xcc9
	.half	283                             # 0x11b
	.half	1853                            # 0x73d
	.half	1990                            # 0x7c6
	.half	882                             # 0x372
	.half	3033                            # 0xbd9
	.half	2419                            # 0x973
	.half	2102                            # 0x836
	.half	219                             # 0xdb
	.half	855                             # 0x357
	.half	2681                            # 0xa79
	.half	1848                            # 0x738
	.half	712                             # 0x2c8
	.half	682                             # 0x2aa
	.half	927                             # 0x39f
	.half	1795                            # 0x703
	.half	461                             # 0x1cd
	.half	1891                            # 0x763
	.half	2877                            # 0xb3d
	.half	2522                            # 0x9da
	.half	1894                            # 0x766
	.half	1010                            # 0x3f2
	.half	1414                            # 0x586
	.half	2009                            # 0x7d9
	.half	3296                            # 0xce0
	.half	464                             # 0x1d0
	.half	2697                            # 0xa89
	.half	816                             # 0x330
	.half	1352                            # 0x548
	.half	2679                            # 0xa77
	.half	1274                            # 0x4fa
	.half	1052                            # 0x41c
	.half	1025                            # 0x401
	.half	2132                            # 0x854
	.half	1573                            # 0x625
	.half	76                              # 0x4c
	.half	2998                            # 0xbb6
	.half	3040                            # 0xbe0
	.half	1175                            # 0x497
	.half	2444                            # 0x98c
	.half	394                             # 0x18a
	.half	1219                            # 0x4c3
	.half	2300                            # 0x8fc
	.half	1455                            # 0x5af
	.half	2117                            # 0x845
	.half	1607                            # 0x647
	.half	2443                            # 0x98b
	.half	554                             # 0x22a
	.half	1179                            # 0x49b
	.half	2186                            # 0x88a
	.half	2303                            # 0x8ff
	.half	2926                            # 0xb6e
	.half	2237                            # 0x8bd
	.half	525                             # 0x20d
	.half	735                             # 0x2df
	.half	863                             # 0x35f
	.half	2768                            # 0xad0
	.half	1230                            # 0x4ce
	.half	2572                            # 0xa0c
	.half	556                             # 0x22c
	.half	3010                            # 0xbc2
	.half	2266                            # 0x8da
	.half	1684                            # 0x694
	.half	1239                            # 0x4d7
	.half	780                             # 0x30c
	.half	2954                            # 0xb8a
	.half	109                             # 0x6d
	.half	1292                            # 0x50c
	.half	1031                            # 0x407
	.half	1745                            # 0x6d1
	.half	2688                            # 0xa80
	.half	3061                            # 0xbf5
	.half	992                             # 0x3e0
	.half	2596                            # 0xa24
	.half	941                             # 0x3ad
	.half	892                             # 0x37c
	.half	1021                            # 0x3fd
	.half	2390                            # 0x956
	.half	642                             # 0x282
	.half	1868                            # 0x74c
	.half	2377                            # 0x949
	.half	1482                            # 0x5ca
	.half	1540                            # 0x604
	.half	540                             # 0x21c
	.half	1678                            # 0x68e
	.half	1626                            # 0x65a
	.half	279                             # 0x117
	.half	314                             # 0x13a
	.half	1173                            # 0x495
	.half	2573                            # 0xa0d
	.half	3096                            # 0xc18
	.half	48                              # 0x30
	.half	667                             # 0x29b
	.half	1920                            # 0x780
	.half	2229                            # 0x8b5
	.half	1041                            # 0x411
	.half	2606                            # 0xa2e
	.half	1692                            # 0x69c
	.half	680                             # 0x2a8
	.half	2746                            # 0xaba
	.half	568                             # 0x238
	.half	3312                            # 0xcf0
	.size	PRE_COMPUT_TABLE_INTT, 256

	.type	zetas,@object                   # @zetas
	.section	.rodata,"a",@progbits
	.globl	zetas
	.p2align	4, 0x0
zetas:
	.half	17                              # 0x11
	.half	65519                           # 0xffef
	.half	2761                            # 0xac9
	.half	62775                           # 0xf537
	.half	583                             # 0x247
	.half	64953                           # 0xfdb9
	.half	2649                            # 0xa59
	.half	62887                           # 0xf5a7
	.half	1637                            # 0x665
	.half	63899                           # 0xf99b
	.half	723                             # 0x2d3
	.half	64813                           # 0xfd2d
	.half	2288                            # 0x8f0
	.half	63248                           # 0xf710
	.half	1100                            # 0x44c
	.half	64436                           # 0xfbb4
	.half	1409                            # 0x581
	.half	64127                           # 0xfa7f
	.half	2662                            # 0xa66
	.half	62874                           # 0xf59a
	.half	3281                            # 0xcd1
	.half	62255                           # 0xf32f
	.half	233                             # 0xe9
	.half	65303                           # 0xff17
	.half	756                             # 0x2f4
	.half	64780                           # 0xfd0c
	.half	2156                            # 0x86c
	.half	63380                           # 0xf794
	.half	3015                            # 0xbc7
	.half	62521                           # 0xf439
	.half	3050                            # 0xbea
	.half	62486                           # 0xf416
	.half	1703                            # 0x6a7
	.half	63833                           # 0xf959
	.half	1651                            # 0x673
	.half	63885                           # 0xf98d
	.half	2789                            # 0xae5
	.half	62747                           # 0xf51b
	.half	1789                            # 0x6fd
	.half	63747                           # 0xf903
	.half	1847                            # 0x737
	.half	63689                           # 0xf8c9
	.half	952                             # 0x3b8
	.half	64584                           # 0xfc48
	.half	1461                            # 0x5b5
	.half	64075                           # 0xfa4b
	.half	2687                            # 0xa7f
	.half	62849                           # 0xf581
	.half	939                             # 0x3ab
	.half	64597                           # 0xfc55
	.half	2308                            # 0x904
	.half	63228                           # 0xf6fc
	.half	2437                            # 0x985
	.half	63099                           # 0xf67b
	.half	2388                            # 0x954
	.half	63148                           # 0xf6ac
	.half	733                             # 0x2dd
	.half	64803                           # 0xfd23
	.half	2337                            # 0x921
	.half	63199                           # 0xf6df
	.half	268                             # 0x10c
	.half	65268                           # 0xfef4
	.half	641                             # 0x281
	.half	64895                           # 0xfd7f
	.half	1584                            # 0x630
	.half	63952                           # 0xf9d0
	.half	2298                            # 0x8fa
	.half	63238                           # 0xf706
	.half	2037                            # 0x7f5
	.half	63499                           # 0xf80b
	.half	3220                            # 0xc94
	.half	62316                           # 0xf36c
	.half	375                             # 0x177
	.half	65161                           # 0xfe89
	.half	2549                            # 0x9f5
	.half	62987                           # 0xf60b
	.half	2090                            # 0x82a
	.half	63446                           # 0xf7d6
	.half	1645                            # 0x66d
	.half	63891                           # 0xf993
	.half	1063                            # 0x427
	.half	64473                           # 0xfbd9
	.half	319                             # 0x13f
	.half	65217                           # 0xfec1
	.half	2773                            # 0xad5
	.half	62763                           # 0xf52b
	.half	757                             # 0x2f5
	.half	64779                           # 0xfd0b
	.half	2099                            # 0x833
	.half	63437                           # 0xf7cd
	.half	561                             # 0x231
	.half	64975                           # 0xfdcf
	.half	2466                            # 0x9a2
	.half	63070                           # 0xf65e
	.half	2594                            # 0xa22
	.half	62942                           # 0xf5de
	.half	2804                            # 0xaf4
	.half	62732                           # 0xf50c
	.half	1092                            # 0x444
	.half	64444                           # 0xfbbc
	.half	403                             # 0x193
	.half	65133                           # 0xfe6d
	.half	1026                            # 0x402
	.half	64510                           # 0xfbfe
	.half	1143                            # 0x477
	.half	64393                           # 0xfb89
	.half	2150                            # 0x866
	.half	63386                           # 0xf79a
	.half	2775                            # 0xad7
	.half	62761                           # 0xf529
	.half	886                             # 0x376
	.half	64650                           # 0xfc8a
	.half	1722                            # 0x6ba
	.half	63814                           # 0xf946
	.half	1212                            # 0x4bc
	.half	64324                           # 0xfb44
	.half	1874                            # 0x752
	.half	63662                           # 0xf8ae
	.half	1029                            # 0x405
	.half	64507                           # 0xfbfb
	.half	2110                            # 0x83e
	.half	63426                           # 0xf7c2
	.half	2935                            # 0xb77
	.half	62601                           # 0xf489
	.half	885                             # 0x375
	.half	64651                           # 0xfc8b
	.half	2154                            # 0x86a
	.half	63382                           # 0xf796
	.size	zetas, 256

	.type	zetas_positive,@object          # @zetas_positive
	.bss
	.globl	zetas_positive
	.p2align	4, 0x0
zetas_positive:
	.zero	256
	.size	zetas_positive, 256

	.type	a,@object                       # @a
	.data
	.globl	a
	.p2align	4, 0x0
a:
	.half	1971                            # 0x7b3
	.half	2753                            # 0xac1
	.half	1570                            # 0x622
	.half	1848                            # 0x738
	.half	2764                            # 0xacc
	.half	59                              # 0x3b
	.half	419                             # 0x1a3
	.half	388                             # 0x184
	.half	3322                            # 0xcfa
	.half	2682                            # 0xa7a
	.half	865                             # 0x361
	.half	2323                            # 0x913
	.half	2833                            # 0xb11
	.half	51                              # 0x33
	.half	1904                            # 0x770
	.half	3226                            # 0xc9a
	.half	728                             # 0x2d8
	.half	1876                            # 0x754
	.half	2475                            # 0x9ab
	.half	901                             # 0x385
	.half	651                             # 0x28b
	.half	601                             # 0x259
	.half	1548                            # 0x60c
	.half	1170                            # 0x492
	.half	1212                            # 0x4bc
	.half	1569                            # 0x621
	.half	1424                            # 0x590
	.half	2062                            # 0x80e
	.half	1594                            # 0x63a
	.half	2441                            # 0x989
	.half	1765                            # 0x6e5
	.half	236                             # 0xec
	.half	1866                            # 0x74a
	.half	1050                            # 0x41a
	.half	2084                            # 0x824
	.half	2345                            # 0x929
	.half	1110                            # 0x456
	.half	219                             # 0xdb
	.half	2733                            # 0xaad
	.half	2147                            # 0x863
	.half	2901                            # 0xb55
	.half	1314                            # 0x522
	.half	1141                            # 0x475
	.half	2405                            # 0x965
	.half	1365                            # 0x555
	.half	3045                            # 0xbe5
	.half	17                              # 0x11
	.half	2093                            # 0x82d
	.half	2637                            # 0xa4d
	.half	2492                            # 0x9bc
	.half	2994                            # 0xbb2
	.half	1003                            # 0x3eb
	.half	808                             # 0x328
	.half	2257                            # 0x8d1
	.half	2173                            # 0x87d
	.half	3065                            # 0xbf9
	.half	1541                            # 0x605
	.half	1312                            # 0x520
	.half	2842                            # 0xb1a
	.half	3135                            # 0xc3f
	.half	425                             # 0x1a9
	.half	1278                            # 0x4fe
	.half	1086                            # 0x43e
	.half	6                               # 0x6
	.half	2329                            # 0x919
	.half	3170                            # 0xc62
	.half	2351                            # 0x92f
	.half	1154                            # 0x482
	.half	60                              # 0x3c
	.half	2799                            # 0xaef
	.half	3301                            # 0xce5
	.half	676                             # 0x2a4
	.half	784                             # 0x310
	.half	2158                            # 0x86e
	.half	796                             # 0x31c
	.half	2149                            # 0x865
	.half	2918                            # 0xb66
	.half	813                             # 0x32d
	.half	913                             # 0x391
	.half	2226                            # 0x8b2
	.half	3306                            # 0xcea
	.half	1622                            # 0x656
	.half	3229                            # 0xc9d
	.half	1829                            # 0x725
	.half	550                             # 0x226
	.half	3117                            # 0xc2d
	.half	1565                            # 0x61d
	.half	3135                            # 0xc3f
	.half	1101                            # 0x44d
	.half	1078                            # 0x436
	.half	2941                            # 0xb7d
	.half	1526                            # 0x5f6
	.half	72                              # 0x48
	.half	1742                            # 0x6ce
	.half	2576                            # 0xa10
	.half	116                             # 0x74
	.half	2628                            # 0xa44
	.half	1598                            # 0x63e
	.half	1270                            # 0x4f6
	.half	403                             # 0x193
	.half	2112                            # 0x840
	.half	2286                            # 0x8ee
	.half	1080                            # 0x438
	.half	2897                            # 0xb51
	.half	1115                            # 0x45b
	.half	1876                            # 0x754
	.half	1717                            # 0x6b5
	.half	1749                            # 0x6d5
	.half	2690                            # 0xa82
	.half	2631                            # 0xa47
	.half	646                             # 0x286
	.half	382                             # 0x17e
	.half	1968                            # 0x7b0
	.half	1591                            # 0x637
	.half	3255                            # 0xcb7
	.half	2519                            # 0x9d7
	.half	1379                            # 0x563
	.half	1492                            # 0x5d4
	.half	40                              # 0x28
	.half	195                             # 0xc3
	.half	285                             # 0x11d
	.half	697                             # 0x2b9
	.half	1721                            # 0x6b9
	.half	1401                            # 0x579
	.half	2439                            # 0x987
	.half	2012                            # 0x7dc
	.half	1517                            # 0x5ed
	.half	1738                            # 0x6ca
	.half	1325                            # 0x52d
	.half	502                             # 0x1f6
	.half	2142                            # 0x85e
	.half	109                             # 0x6d
	.half	2789                            # 0xae5
	.half	3222                            # 0xc96
	.half	3006                            # 0xbbe
	.half	1619                            # 0x653
	.half	2813                            # 0xafd
	.half	1394                            # 0x572
	.half	1083                            # 0x43b
	.half	3218                            # 0xc92
	.half	1740                            # 0x6cc
	.half	1730                            # 0x6c2
	.half	271                             # 0x10f
	.half	380                             # 0x17c
	.half	3321                            # 0xcf9
	.half	1242                            # 0x4da
	.half	614                             # 0x266
	.half	2415                            # 0x96f
	.half	2734                            # 0xaae
	.half	654                             # 0x28e
	.half	2611                            # 0xa33
	.half	734                             # 0x2de
	.half	1351                            # 0x547
	.half	2047                            # 0x7ff
	.half	2136                            # 0x858
	.half	462                             # 0x1ce
	.half	731                             # 0x2db
	.half	1368                            # 0x558
	.half	3244                            # 0xcac
	.half	2056                            # 0x808
	.half	1871                            # 0x74f
	.half	2057                            # 0x809
	.half	3209                            # 0xc89
	.half	2375                            # 0x947
	.half	2994                            # 0xbb2
	.half	2886                            # 0xb46
	.half	1709                            # 0x6ad
	.half	2479                            # 0x9af
	.half	1996                            # 0x7cc
	.half	2793                            # 0xae9
	.half	2368                            # 0x940
	.half	407                             # 0x197
	.half	1194                            # 0x4aa
	.half	355                             # 0x163
	.half	1831                            # 0x727
	.half	2230                            # 0x8b6
	.half	1597                            # 0x63d
	.half	160                             # 0xa0
	.half	2360                            # 0x938
	.half	2046                            # 0x7fe
	.half	815                             # 0x32f
	.half	1642                            # 0x66a
	.half	495                             # 0x1ef
	.half	3210                            # 0xc8a
	.half	1405                            # 0x57d
	.half	346                             # 0x15a
	.half	1387                            # 0x56b
	.half	2136                            # 0x858
	.half	1715                            # 0x6b3
	.half	1303                            # 0x517
	.half	1907                            # 0x773
	.half	257                             # 0x101
	.half	1075                            # 0x433
	.half	1788                            # 0x6fc
	.half	2632                            # 0xa48
	.half	741                             # 0x2e5
	.half	2389                            # 0x955
	.half	1012                            # 0x3f4
	.half	935                             # 0x3a7
	.half	1056                            # 0x420
	.half	476                             # 0x1dc
	.half	1018                            # 0x3fa
	.half	2508                            # 0x9cc
	.half	2714                            # 0xa9a
	.half	2417                            # 0x971
	.half	2054                            # 0x806
	.half	2659                            # 0xa63
	.half	685                             # 0x2ad
	.half	2215                            # 0x8a7
	.half	2735                            # 0xaaf
	.half	446                             # 0x1be
	.half	745                             # 0x2e9
	.half	2092                            # 0x82c
	.half	1986                            # 0x7c2
	.half	1670                            # 0x686
	.half	168                             # 0xa8
	.half	2332                            # 0x91c
	.half	3058                            # 0xbf2
	.half	19                              # 0x13
	.half	718                             # 0x2ce
	.half	2076                            # 0x81c
	.half	2971                            # 0xb9b
	.half	975                             # 0x3cf
	.half	866                             # 0x362
	.half	2474                            # 0x9aa
	.half	1322                            # 0x52a
	.half	1607                            # 0x647
	.half	1534                            # 0x5fe
	.half	50                              # 0x32
	.half	257                             # 0x101
	.half	306                             # 0x132
	.half	1570                            # 0x622
	.half	1276                            # 0x4fc
	.half	529                             # 0x211
	.half	2000                            # 0x7d0
	.half	364                             # 0x16c
	.half	2583                            # 0xa17
	.half	2374                            # 0x946
	.half	2094                            # 0x82e
	.half	2513                            # 0x9d1
	.half	1780                            # 0x6f4
	.half	255                             # 0xff
	.half	3258                            # 0xcba
	.half	544                             # 0x220
	.half	2241                            # 0x8c1
	.half	2644                            # 0xa54
	.half	1756                            # 0x6dc
	.half	1245                            # 0x4dd
	.half	2373                            # 0x945
	.half	1776                            # 0x6f0
	.half	1963                            # 0x7ab
	.half	2164                            # 0x874
	.half	1418                            # 0x58a
	.half	654                             # 0x28e
	.half	3030                            # 0xbd6
	.half	1607                            # 0x647
	.size	a, 512

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"a[i]: %x \n"
	.size	.L.str, 11

	.ident	"clang version 18.1.0rc (https://github.com/lyh552506/llvm-project.git 720c0cf7bcb074923be36bd28e9e760d220813d7)"
	.ident	"clang version 18.1.0rc (https://github.com/lyh552506/llvm-project.git 720c0cf7bcb074923be36bd28e9e760d220813d7)"
	.section	".note.GNU-stack","",@progbits
