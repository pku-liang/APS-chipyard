#include <stdint.h>
#include <stdio.h>

#define CSR_GAIN_CFG 0x801
#define CSR_BIAS_CFG 0x802

#define INPUT_SIZE 16
#define GAIN_Q8 0x200u
#define BIAS 7u

volatile uint32_t input_data[INPUT_SIZE] __attribute__((aligned(128))) = {
  1, 2, 3, 4,
  5, 6, 7, 8,
  9, 10, 11, 12,
  13, 14, 15, 16
};

volatile uint32_t output_data[INPUT_SIZE] __attribute__((aligned(128))) = {0};

static inline void write_csr_u32(uint32_t csr, uint32_t value) {
  switch (csr) {
    case CSR_GAIN_CFG:
      asm volatile("csrw 0x801, %0" :: "r"(value));
      break;
    case CSR_BIAS_CFG:
      asm volatile("csrw 0x802, %0" :: "r"(value));
      break;
  }
}

static inline uint32_t read_csr_u32(uint32_t csr) {
  uint32_t value = 0;
  switch (csr) {
    case CSR_GAIN_CFG:
      asm volatile("csrr %0, 0x801" : "=r"(value));
      break;
    case CSR_BIAS_CFG:
      asm volatile("csrr %0, 0x802" : "=r"(value));
      break;
  }
  return value;
}

static inline uint32_t csr_partition_loop(uint32_t rs1, uint32_t rs2) {
  uint32_t rd = 0;
  asm volatile(".insn r 0x2B, 0b111, 0x1e, %0, %1, %2"
               : "=r"(rd)
               : "r"(rs1), "r"(rs2));
  return rd;
}

int main(void) {
  for (int i = 0; i < INPUT_SIZE; ++i)
    output_data[i] = 0;

  write_csr_u32(CSR_GAIN_CFG, GAIN_Q8);
  write_csr_u32(CSR_BIAS_CFG, BIAS);
  asm volatile("fence");

  uint32_t gain_seen = read_csr_u32(CSR_GAIN_CFG);
  uint32_t bias_seen = read_csr_u32(CSR_BIAS_CFG);
  if (gain_seen != GAIN_Q8 || bias_seen != BIAS) {
    printf("CSR readback mismatch: gain=%lu bias=%lu\n",
           (unsigned long)gain_seen, (unsigned long)bias_seen);
    return 1;
  }

  uint32_t rd = csr_partition_loop((uint32_t)(uintptr_t)input_data,
                                   (uint32_t)(uintptr_t)output_data);
  asm volatile("fence");

  int errors = 0;
  for (int i = 0; i < INPUT_SIZE; ++i) {
    uint32_t expected = ((input_data[i] * GAIN_Q8) >> 8) + BIAS;
    uint32_t actual = output_data[i];
    if (actual != expected) {
      printf("mismatch[%d]: expected=%lu actual=%lu\n",
             i, (unsigned long)expected, (unsigned long)actual);
      ++errors;
    }
  }

  if (errors != 0) {
    printf("csr_partition_loop failed: rd=%lu errors=%d\n",
           (unsigned long)rd, errors);
    return 1;
  }

  printf("csr_partition_loop passed: rd=%lu\n", (unsigned long)rd);
  return 0;
}
