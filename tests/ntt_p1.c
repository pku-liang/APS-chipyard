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
volatile uint16_t polyS_f_golden[MLKEM_N]  __attribute__((aligned(16)));
volatile uint16_t polyS_g[MLKEM_N]  __attribute__((aligned(16)));
volatile uint16_t polyS_h[MLKEM_N]  __attribute__((aligned(16)));

volatile uint16_t PRE_COMPUT_TABLE_NTT[MLKEM_N_HALF] __attribute__((aligned(16))) = {
    1, 1729, 2580, 3289, 2642, 630, 1897, 848, 1062, 1919, 193, 797, 2786, 3260, 569, 1746, 296, 2447, 1339, 1476,
    3046, 56, 2240, 1333, 1426, 2094, 535, 2882, 2393, 2879, 1974, 821, 289, 331, 3253, 1756, 1197, 2304, 2277, 2055,
    650, 1977, 2513, 632, 2865, 33, 1320, 1915, 2319, 1435, 807, 452, 1438, 2868, 1534, 2402, 2647, 2617, 1481, 648,
    2474, 3110, 1227, 910, 17, 2761, 583, 2649, 1637, 723, 2288, 1100, 1409, 2662, 3281, 233, 756, 2156, 3015, 3050,
    1703, 1651, 2789, 1789, 1847, 952, 1461, 2687, 939, 2308, 2437, 2388, 733, 2337, 268, 641, 1584, 2298, 2037, 3220,
    375, 2549, 2090, 1645, 1063, 319, 2773, 757, 2099, 561, 2466, 2594, 2804, 1092, 403, 1026, 1143, 2150, 2775, 886,
    1722, 1212, 1874, 1029, 2110, 2935, 885, 2154
};

// __attribute__((noinline))
volatile uint16_t PRE_COMPUT_TABLE_INTT[MLKEM_N_HALF] __attribute__((aligned(16))) = {
    1, 1600, 40, 749, 2481, 1432, 2699, 687, 1583, 2760, 69, 543, 2532, 3136, 1410, 2267, 2508, 1355, 450, 936, 447,
    2794, 1235, 1903, 1996, 1089, 3273, 283, 1853, 1990, 882, 3033, 2419, 2102, 219, 855, 2681, 1848, 712, 682, 927,
    1795, 461, 1891, 2877, 2522, 1894, 1010, 1414, 2009, 3296, 464, 2697, 816, 1352, 2679, 1274, 1052, 1025, 2132,
    1573, 76, 2998, 3040, 1175, 2444, 394, 1219, 2300, 1455, 2117, 1607, 2443, 554, 1179, 2186, 2303, 2926, 2237,
    525, 735, 863, 2768, 1230, 2572, 556, 3010, 2266, 1684, 1239, 780, 2954, 109, 1292, 1031, 1745, 2688, 3061,
    992, 2596, 941, 892, 1021, 2390, 642, 1868, 2377, 1482, 1540, 540, 1678, 1626, 279, 314, 1173, 2573, 3096,
    48, 667, 1920, 2229, 1041, 2606, 1692, 680, 2746, 568, 3312
};

uint32_t csubq(int32_t a) {
    if (a >= MLKEM_Q) {
        a -= MLKEM_Q;
    }
    return a;
}

uint32_t BarretMod(uint32_t val, uint16_t q, uint32_t u, uint16_t k)
{
    uint32_t r;
    uint32_t val1 = val >> (k - 1);
    uint32_t y2 = (val1 * u) >> (k + 1);
    uint32_t r1 = val - (y2 * q);
    uint32_t r2 = r1 & 0x1FFF;
    r = csubq(r2);
    r = csubq(r);
    return r;
}

uint32_t bf_op(uint16_t s, uint16_t x_l, uint16_t x_h)
{
    uint32_t ys = x_h * s;
    ys = BarretMod(ys , MLKEM_Q, BARRET_U, MLKEM_K);
    uint32_t tmp = x_l - ys + MLKEM_Q;
    uint16_t r_h = csubq(tmp);
    tmp = x_l + ys; 
    uint16_t r_l = csubq(tmp);
    return (r_h << 16) | r_l;
}

__attribute__((alwaysinline))
void bf_baseline(uint16_t *a_j, uint16_t *a_j_t, uint16_t s) {
    uint16_t ys_golden = (*a_j_t * s) % MLKEM_Q;
    *a_j_t = (*a_j - ys_golden + MLKEM_Q) % MLKEM_Q;
    *a_j   = (*a_j + ys_golden) % MLKEM_Q;
}

void ntt_baseline(volatile uint16_t *a, volatile uint16_t *psi, uint16_t pruLength , uint16_t len)
{
    // uint32_t runtime = 0;
    uint32_t t = len;
    for (uint32_t m = 1; m < pruLength; m <<= 1) {//m=2 ** i
        // printf("m = %d, t = %d\n", m, t);
        t >>= 1;// 128,64,32,16,8,4,2
        for (uint32_t i = 0; i < m; i++) {//group num m=2 ** i
            uint32_t j1 = (i << 1) * t;//t is stride and also group size
            uint16_t s = psi[m + i];//i is r, m is bitrev(m/2)
            for (uint32_t j = j1; j < j1 + t; j++) {
                    // uint32_t start = get_mcycle();
                    // uint32_t ys_golden = ((uint32_t)a[j + t] * s) % MLKEM_Q;
                    bf_baseline(&a[j] , &a[j + t] , s);
                    // uint32_t end   = get_mcycle();
                    // runtime += (end - start);
            }
        }
    }
    // printf("isax Cycles: 0x%x\n",  runtime / (7*pruLength));
    // printf("NTT done\n");
    // uart_write_flush();
}

__attribute__((alwaysinline))
uint32_t hw_bf(uint32_t rs1, volatile void * rs2) {
    // printf("dst addr: %x, ", dst);
    // __asm__ volatile("fence.i");
    uint32_t rd = 0;
    asm volatile(
    ".insn r 0x5b, 0b111, 0x0, %0, %1, %2"
    : "=r"(rd) : "r"(rs1), "r"(rs2));
    // __asm__ volatile("fence.i");
    return rd;
}

// __attribute__((noinline))
// uint32_t hw_mod(uint32_t rs1) 
// {
//     // printf("dst addr: %x, ", dst);
//     // __asm__ volatile("fence.i");
//     uint32_t rd = 0;
//     asm volatile(
//     ".insn r 0x0b, 0b111, 0x0, %0, %1, x0"
//     : "=r"(rd) : "r"(rs1));
//     // __asm__ volatile("fence.i");
//     return rd;
// }

// __attribute__((noinline))
// uint32_t sw_bf(uint32_t rs1, uint32_t rs2)
// {
//     uint16_t x_l = rs1 & 0x0fff;
//     uint16_t x_h = (rs1 >> 16) & 0x0fff;
//     uint16_t s   = rs2 & 0x0fff;
//     uint32_t result = bf_op(s, x_l, x_h);
//     return result;
// }
void ntt_radix2_single_bf(volatile uint16_t *a, volatile uint16_t *psi, uint16_t pruLength , uint16_t len)
{
    uint32_t t = len;
    // uint32_t runtime = 0;
    for (uint32_t m = 1; m < pruLength; m <<= 1) {//m=2 ** i
        // printf("m = %d, t = %d\n", m, t);
        t >>= 1;// 128,64,32,16,8,4,2
        for (uint32_t i = 0; i < m; i++) {//group num m=2 ** i
            uint32_t j1 = (i << 1) * t;//t is stride and also group size
            uint16_t s = psi[m + i];//i is r, m is bitrev(m/2)
            for (uint32_t j = j1; j < j1 + t; j++) {
                // uint32_t ys_golden = (a[j + t] * s) % MLKEM_Q;
                // uint32_t a_j_golden   = (a[j] + ys_golden) % MLKEM_Q;
                // uint32_t a_j_t_golden = (a[j] - ys_golden + MLKEM_Q) % MLKEM_Q;
                // uint32_t start = get_mcycle();
                //*****************************/
                //       bf v1                //
                //*****************************/
                // uint32_t rs1 = (a[j + t] << 16) | a[j];
                // uint32_t rs2 = s | 0x0000;
                // uint32_t rd_hw = hw_bf(rs1, rs2);
                // a[j] = rd_hw & 0x0fff;
                // a[j + t] = (rd_hw >> 16) & 0x0fff;
                //*****************************/
                //       bf v2                //
                //*****************************/
                uint16_t index = (t << 8) | j;
                uint32_t rs1 = (s << 16) | index;
                uint32_t rd_hw = hw_bf(rs1, a);
                a[j] = rd_hw & 0x0fff;
                a[j + t] = (rd_hw >> 16) & 0x0fff;
                // uint32_t end   = get_mcycle();
                // runtime += (end - start);
                // uint32_t rd    = sw_bf(rs1, rs2);//
                // if(rd != rd_hw) {
                //     printf("a[j]: %x, a[j + t]:%x, s: %x, sw_bf: %x, hw_bf: %x\n", a[j], a[j + t],  s , rd, rd_hw);
                // }
                // uart_write_flush();
                // a[j] = rd & 0x0fff;
                // a[j + t] = (rd >> 16) & 0x0fff;
                // if(a[j] != a_j_golden || a[j + t] != a_j_t_golden){
                //     printf("a[j]: %x, a[j + t]:%x, a_j_golden: %x, a_j_t_golden: %x\n", a[j], a[j + t],  a_j_golden , a_j_t_golden);
                // }
            }
        }
    }
    // printf("isax Cycles: 0x%x\n",  runtime / (7*pruLength));
    // printf("NTT done\n");
    // uart_write_flush();
}


int main() {
    // uart_init(); // setup the uart peripheral

    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");
    // wait until uart has finished sending
    // uart_write_flush();


    for (uint16_t i = 0; i < MLKEM_N; i++) {
        polyS_f_golden[i] = i;
    }

    // for (size_t i = 0; i < MLKEM_N; i++) {
    //     polyS_g[i] = i;
    // }

    //******************************//
    //       ntt baseline           //
    //******************************//
    // uint32_t start = get_mcycle();
    asm volatile ("fence");
    ntt_baseline(polyS_f_golden, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    asm volatile ("fence");
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%ld\n",  end - start);
    printf("NTT baseline done\n");
    // uart_write_flush();
    
    //******************************//
    //           ntt isax           //
    //******************************//
    for (uint16_t i = 0; i < MLKEM_N; i++) {
        polyS_f[i] = i;
    }
    // uint32_t start_1 = get_mcycle();
    asm volatile ("fence");
    ntt_radix2_single_bf(polyS_f, PRE_COMPUT_TABLE_NTT, MLKEM_N_HALF , MLKEM_N);
    asm volatile ("fence");
    // uint32_t end_1   = get_mcycle();
    // printf("isax Cycles: 0x%ld\n",  end_1 - start_1);
    printf("NTT isax done\n");
    // uart_write_flush();

    for (int i = 0 ; i < MLKEM_N ; i+=1)
    {
        if(polyS_f[i] != polyS_f_golden[i]){
            printf("index %d expected %ld , get %ld \n", i ,polyS_f_golden[i] ,  polyS_f[i]);
        }

    }
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
    // uint32_t start = get_mcycle();
    // ntt_mul_baseline(polyS_h , polyS_f , polyS_g);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("PWM done\n");
    // uart_write_flush();
    //******************************//
    //          pwm hw              //
    //******************************//
    // uint32_t start = get_mcycle();
    // ntt_mul_hw(polyS_h , polyS_f , polyS_g);
    // uint32_t end   = get_mcycle();
    // printf("isax Cycles: 0x%x\n",  end - start);
    // printf("PWM done\n");
    // uart_write_flush();

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
