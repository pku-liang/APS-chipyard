// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include <stdio.h>
#include <riscv-pk/encoding.h>
#include "marchid.h"
#include <stdint.h>

__attribute__((alwaysinline))
uint32_t hw_dma(uint32_t *ptr, uint32_t size) {
    uint32_t rd = 0;
    uint32_t r1 = (uint32_t)ptr;
    asm volatile(
    ".insn r 0x5b, 0b111, 0x0, %0, %1, %2"
    : "=r"(rd) : "r"(r1), "r"(size));
    return rd;
}


volatile uint32_t array[64] __attribute__((aligned(128))) = {
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
  0xdeadbeef, 0xcafebaba, 0x8badf00d, 0xfeedface,
  0xabad1dea, 0xfaceb00c, 0xdefec8ed, 0xdecafbad,
};

int main() {
    printf("hello dma test\n");
    // for (int i = 0; i < 4; i++) {
    //     printf("1array[%d] = 0x%x\n", i, array[i]);
    // }
    array[0] = 0x11111111;
    array[1] = 0x22222222;
    array[2] = 0x33333333;
    array[3] = 0x44444444;
    asm volatile("fence" ::: "memory");
    uint32_t rd = hw_dma(array, 7); // 2^size, should >= 3 (4 bytess) and <= 6 (64 bytes)
    for (int i = 0; i < 4; i++) {
        printf("2array[%d] = 0x%x\n", i, array[i]);
    }
    while (1);
    return rd;
}