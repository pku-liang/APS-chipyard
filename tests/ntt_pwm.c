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
#include <stdint.h>

#define MLKEM_Q    3329
#define MLKEM_N        256
#define MLKEM_N_HALF   128
#define MLKEM_PTNTT_N  128
#define MLKEM_PTNTT_N_HALF   64
#define MLKEM_INVN 3303 
#define QINV 62209
#define ROOT  17
#define MLKEM_K  12
#define BARRET_U (1 << (2 * MLKEM_K)) / MLKEM_Q

volatile uint16_t polyS_f[MLKEM_N]  __attribute__((aligned(16)));
volatile uint16_t polyS_g[MLKEM_N]  __attribute__((aligned(16)));
volatile uint16_t polyS_h[MLKEM_N]  __attribute__((aligned(16)));
volatile uint16_t polyS_h_golden[MLKEM_N]  __attribute__((aligned(16)));

// volatile uint16_t PRE_COMPUT_TABLE_NTT[MLKEM_N_HALF] __attribute__((aligned(16))) = {
//     1, 1729, 2580, 3289, 2642, 630, 1897, 848, 1062, 1919, 193, 797, 2786, 3260, 569, 1746, 296, 2447, 1339, 1476,
//     3046, 56, 2240, 1333, 1426, 2094, 535, 2882, 2393, 2879, 1974, 821, 289, 331, 3253, 1756, 1197, 2304, 2277, 2055,
//     650, 1977, 2513, 632, 2865, 33, 1320, 1915, 2319, 1435, 807, 452, 1438, 2868, 1534, 2402, 2647, 2617, 1481, 648,
//     2474, 3110, 1227, 910, 17, 2761, 583, 2649, 1637, 723, 2288, 1100, 1409, 2662, 3281, 233, 756, 2156, 3015, 3050,
//     1703, 1651, 2789, 1789, 1847, 952, 1461, 2687, 939, 2308, 2437, 2388, 733, 2337, 268, 641, 1584, 2298, 2037, 3220,
//     375, 2549, 2090, 1645, 1063, 319, 2773, 757, 2099, 561, 2466, 2594, 2804, 1092, 403, 1026, 1143, 2150, 2775, 886,
//     1722, 1212, 1874, 1029, 2110, 2935, 885, 2154
// };

// // __attribute__((noinline))
// volatile uint16_t PRE_COMPUT_TABLE_INTT[MLKEM_N_HALF] __attribute__((aligned(16))) = {
//     1, 1600, 40, 749, 2481, 1432, 2699, 687, 1583, 2760, 69, 543, 2532, 3136, 1410, 2267, 2508, 1355, 450, 936, 447,
//     2794, 1235, 1903, 1996, 1089, 3273, 283, 1853, 1990, 882, 3033, 2419, 2102, 219, 855, 2681, 1848, 712, 682, 927,
//     1795, 461, 1891, 2877, 2522, 1894, 1010, 1414, 2009, 3296, 464, 2697, 816, 1352, 2679, 1274, 1052, 1025, 2132,
//     1573, 76, 2998, 3040, 1175, 2444, 394, 1219, 2300, 1455, 2117, 1607, 2443, 554, 1179, 2186, 2303, 2926, 2237,
//     525, 735, 863, 2768, 1230, 2572, 556, 3010, 2266, 1684, 1239, 780, 2954, 109, 1292, 1031, 1745, 2688, 3061,
//     992, 2596, 941, 892, 1021, 2390, 642, 1868, 2377, 1482, 1540, 540, 1678, 1626, 279, 314, 1173, 2573, 3096,
//     48, 667, 1920, 2229, 1041, 2606, 1692, 680, 2746, 568, 3312
// };

volatile uint16_t ZETAS[MLKEM_N_HALF] __attribute__((aligned(16))) = {
  17, 3312, 2761,  568,  583, 2746, 2649,  680,
1637, 1692,  723, 2606, 2288, 1041, 1100, 2229,
1409, 1920, 2662,  667, 3281,   48,  233, 3096,
 756, 2573, 2156, 1173, 3015,  314, 3050,  279,
1703, 1626, 1651, 1678, 2789,  540, 1789, 1540,
1847, 1482,  952, 2377, 1461, 1868, 2687,  642,
 939, 2390, 2308, 1021, 2437,  892, 2388,  941,
 733, 2596, 2337,  992,  268, 3061,  641, 2688,
1584, 1745, 2298, 1031, 2037, 1292, 3220,  109,
 375, 2954, 2549,  780, 2090, 1239, 1645, 1684,
1063, 2266,  319, 3010, 2773,  556,  757, 2572,
2099, 1230,  561, 2768, 2466,  863, 2594,  735,
2804,  525, 1092, 2237,  403, 2926, 1026, 2303,
1143, 2186, 2150, 1179, 2775,  554,  886, 2443,
1722, 1607, 1212, 2117, 1874, 1455, 1029, 2300,
2110, 1219, 2935,  394,  885, 2444, 2154, 1175
};

__attribute__((alwaysinline))
uint32_t hw_pwm_config_1(volatile void * rs1, volatile void *  rs2) 
{
    // printf("dst addr: %x, ", dst);
    // __asm__ volatile("fence.i");
    uint32_t rd = 0;
    asm volatile(
    ".insn r 0x5b, 0b111, 0x0, %0, %1, %2"
    : "=r"(rd) : "r"(rs1), "r"(rs2));
    // __asm__ volatile("fence.i");
    return rd;
}

__attribute__((alwaysinline))
uint32_t hw_pwm_config_2(volatile void *  rs1) 
{
    // printf("dst addr: %x, ", dst);
    // __asm__ volatile("fence.i");
    uint32_t rd = 0;
    asm volatile(
    ".insn r 0x0b, 0b111, 0x0, %0, %1, x0"
     : "=r"(rd)
     : "r"(rs1));
    // __asm__ volatile("fence.i");
    return rd;
}

__attribute__((alwaysinline))
uint32_t hw_pwm(uint32_t rs1, uint32_t rs2) 
{
    // printf("dst addr: %x, ", dst);
    // __asm__ volatile("fence.i");
    uint32_t rd = 0;
    asm volatile(
    ".insn r 0x2b, 0b111, 0x0, %0, %1, %2"
     : "=r"(rd)
     : "r"(rs1), "r"(rs2));
    // __asm__ volatile("fence.i");
    return rd;
}

void basemul(uint16_t *h_even, uint16_t *h_odd, uint16_t f_even, uint16_t f_odd, uint16_t g_even, uint16_t g_odd, uint16_t zeta)
{
    // uint32_t e_m_e = f_even * g_even;
    // uint32_t o_m_o = f_odd  * g_odd;
    // uint32_t o_a_e = f_odd  + f_even;
    // uint32_t e_a_o = g_even + g_odd;
    // o_a_e = csubq(o_a_e);
    // e_a_o = csubq(e_a_o);
    // e_m_e = BarretMod(e_m_e, MLKEM_Q, BARRET_U, 12);
    // o_m_o = BarretMod(o_m_o, MLKEM_Q, BARRET_U, 12);
    // uint32_t o_m_o_zeta = o_m_o * zeta;
    // o_m_o_zeta = BarretMod(o_m_o_zeta, MLKEM_Q, BARRET_U, 12);
    // *h_even = csubq(e_m_e + o_m_o_zeta);
    // uint32_t m1 = o_a_e * e_a_o;
    // m1 = BarretMod(m1, MLKEM_Q, BARRET_U, 12);
    // uint32_t m2 = m1 + MLKEM_Q - e_m_e ;
    // m2 = csubq(m2);
    // uint32_t m3 = m2 + MLKEM_Q - o_m_o ;
    // *h_odd = csubq(m3);
    *h_even = ((uint64_t)(f_even * g_even) + (uint64_t)(f_odd * g_odd * zeta)) % MLKEM_Q;
    // uint16_t h_even_golden_step_1 = (uint64_t)(f_even * g_even) % MLKEM_Q;
    // uint16_t h_even_golden_step_2 = (uint64_t)(f_odd * g_odd ) % MLKEM_Q;
    // uint16_t h_even_golden_step_3 = (uint64_t)(h_even_golden_step_2 * zeta) % MLKEM_Q;
    // *h_even = (h_even_golden_step_3 + h_even_golden_step_1) % MLKEM_Q;
    *h_odd = ((uint64_t)(f_odd * g_even) + (uint64_t)(f_even * g_odd)) % MLKEM_Q;
    // printf("golden: %d , %d \n",h_even_golden, 
    //        h_odd_golden);
    // printf("h_even = %d, h_odd = %d, f_even = %d, f_odd = %d, g_even = %d, g_odd = %d, zeta = %d\n", *h_even, *h_odd, f_even, f_odd, g_even, g_odd, zeta);
    // if (h_even_golden != *h_even ||
    //     h_odd_golden != *h_odd) {
    //     printf("Error in basemul, expected: %d , %d , get h_even = %d, h_odd = %d \n",h_even_golden , h_odd_golden ,  *h_even, *h_odd);
    // }
}

void ntt_mul_hw(volatile uint16_t *h , volatile uint16_t *f , volatile uint16_t *g)
{
    // uint32_t runtime = 0;
    uint32_t zero_t = hw_pwm_config_1(f , g);
    zero_t = hw_pwm_config_2(h);
    for (int i = 0 ; i < MLKEM_N_HALF ; i++){
        // printf("h_even[%d] = %d, h_odd[%d] = %d\n", i, h_even[i], i, h_odd[i]);
        // uint16_t h_gold = h[i << 1];
        // uint16_t h_1_gold = h[(i << 1)+ 1];

        // uint32_t start = get_mcycle();
        uint16_t zeta = ZETAS[i];

        uint32_t h_result = hw_pwm(i , zeta);
        // printf("111");
        ((uint32_t*)h)[i] = h_result;
        // h[i << 1] = h_result & 0xffff;
        // h[(i << 1) + 1] =(h_result >> 16) & 0xffff;
        // uint32_t end   = get_mcycle();
        // runtime += (end - start);

        // printf("h_even[%d] = %d, h_odd[%d] = %d\n", i, h[i << 1], i, h[(i << 1)+ 1]);
        // basemul(&h_gold, &h_1_gold, 
        //          f[i << 1] , f[(i << 1)+ 1], 
        //          g[i << 1] , g[(i << 1)+ 1], 
        //         ZETAS[i]);
        
        // if (h_gold != h[i << 1] ||
        //     h_1_gold != h[(i << 1)+ 1]) {
        // printf("Error in basemul, expected: %d , %d , get h_even = %d, h_odd = %d \n",h_gold , h_1_gold ,  h[i << 1], h[(i << 1)+ 1]);
        // }

    }
    // printf("isax Cycles: 0x%x\n",  runtime / (MLKEM_N_HALF));
    // printf("PWM done\n");
    // uart_write_flush();
    // return;
}

void ntt_mul_baseline(volatile uint16_t *h , volatile uint16_t *f , volatile uint16_t *g){
    // uint32_t runtime = 0;
    for (int i = 0 ; i < MLKEM_N_HALF ; i++){
        // uint32_t start = get_mcycle();
        basemul(&h[i << 1] , &h[(i << 1)+ 1], 
                 f[i << 1] , f[(i << 1)+ 1], 
                 g[i << 1] , g[(i << 1)+ 1], 
                ZETAS[i]);
        // uint32_t end   = get_mcycle();
        // runtime += (end - start);
    }
    // printf("isax Cycles: 0x%x\n",  runtime / (MLKEM_N_HALF));
    // printf("PWM done\n");
    // uart_write_flush();
}

int main() {
    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");

    for (size_t i = 0; i < MLKEM_N; i++) {
        polyS_f[i] = i;
    }
    for (size_t i = 0; i < MLKEM_N; i++) {
        polyS_g[i] = i;
    }


    // for (size_t i = 0; i < MLKEM_N; i++) {
    //     polyS_g[i] = i;
    // }

    //******************************//
    //       ntt baseline           //
    //******************************//
    // uint32_t start = get_mcycle();
    // ntt_baseline(polyS_f, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("NTT done\n");
    // uart_write_flush();
    //******************************//
    //           ntt isax           //
    //******************************//
    // uint32_t start = get_mcycle();
    // ntt_radix2_single_bf(polyS_f, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("NTT done\n");
    // uart_write_flush();
    //******************************//
    //           ntt isax p2        //
    //******************************//
    // uint32_t start = get_mcycle();
    // ntt_radix2_bf_p2(polyS_f, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("NTT done\n");
    // uart_write_flush();
    // ******************************//
    //         ntt isax p2 v2       //
    // ******************************//
    // uint32_t start = get_mcycle();
    // ntt_radix2_bf_p2_v2(polyS_f, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("NTT done\n");
    // uart_write_flush();
    //******************************//
    //          pwm baseline        //
    //******************************//
    asm volatile ("fence");
    ntt_mul_baseline(polyS_h_golden , polyS_f , polyS_g);
    asm volatile ("fence");
    printf("PWM done\n");

    //******************************//
    //          pwm hw              //
    //******************************//
    asm volatile ("fence");
    ntt_mul_hw(polyS_h , polyS_f , polyS_g);
    asm volatile ("fence");
    printf("PWM done\n");

    for (size_t j = 0; j < MLKEM_N; j++) {        
        if(polyS_h[j] != polyS_h_golden[j]){
            printf("index %x , polyS_h[j]: %x, polyS_h_golden[j]:%x \n", j , polyS_h[j], polyS_h_golden[j]);
        }
    }

    // toggling some GPIOs
    // gpio_set_direction(0xFFFF, 0x000F); // lowest four as outputs
    // gpio_write(0x0A);  // ready output pattern
    // gpio_enable(0xFF); // enable lowest eight
    // // wait a few cycles to give GPIO signal time to propagate
    // asm volatile ("nop; nop; nop; nop; nop;");
    // printf("GPIO (expect 0xA0): 0x%x\n", gpio_read());

    // gpio_toggle(0x0F); // toggle lower 8 GPIOs
    // asm volatile ("nop; nop; nop; nop; nop;");
    // printf("GPIO (expect 0x50): 0x%x\n", gpio_read());
    // uart_write_flush();

    // doing some compute
    // uint32_t start = get_mcycle();
    // uint32_t res   = isqrt(1234567890UL);
    // uint32_t end   = get_mcycle();
    // printf("Result: 0x%x, Cycles: 0x%x\n", res, end - start);
    // uart_write_flush();
    return 0;
    // TODO: using the timer
    // printf("Tick\n");
    // sleep_ms(5);
    // printf("Tock\n");
    // uart_write_flush();
    // return 1;
}
