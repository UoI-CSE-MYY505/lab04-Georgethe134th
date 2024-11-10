
.globl str_ge, recCheck

.data

maria:    .string "Maria"
markos:   .string "Markos"
marios:   .string "Marios"
marianna: .string "Marianna"

.align 4  # make sure the string arrays are aligned to words (easier to see in ripes memory view)

# These are string arrays
# The labels below are replaced by the respective addresses
arraySorted:    .word maria, marianna, marios, markos

arrayNotSorted: .word marianna, markos, maria

.text

            la   a0, arrayNotSorted
            li   a1, 4
            jal  recCheck

            li   a7, 10
            ecall

# ----------------------------------------------------------------------------

# Subroutine str_ge

# Accepts two strings (poiners)
# Returns 1 if the first is lexicographically greater or equal than the second
# Otherwise returns 0

# a0 holds the first string (pointer) [no NULL check, no Bounds check]
# a1 holds the second string (pointer) [no NULL check, no Bounds check]
# a0 will hold the result (0 or 1)

# Performance:
# Overhead: if equal 6 cycles else 5 cycles
# Cost: 6 cycles * length of longest shared prefix (\0 excluded)

str_ge_loop:
    bne t0, zero, str_ge_next # if both strings have ended, they are equal
    addi a0, zero, 1          # return 1
    jr ra
str_ge_next:
    addi a0, a0, 1            # move to the next chars
    addi a1, a1, 1
str_ge:                       # - Entry Point -
    lbu t0, 0(a0)             # load current chars
    lbu t1, 0(a1)
    beq t0, t1, str_ge_loop   # if they are not equal stop searching
    slt a0, t1, t0            # return the appropriate value
    jr ra                     # (different strings are sorted as their first different chars)
 
# ----------------------------------------------------------------------------

# Subroutine recCheck

# Accepts an array of strings (poiners) as a pointer and an integer
# Returns 1 if the array is lexicographically sorted
# Otherwise returns 0

# a0 holds the base address of the array [no NULL check, no Bounds check]
# a1 holds the size of the array [treated as unsigned]
# a0 will hold the result (0 or 1)

# Performance:
# Overhead: if sorted 5 cycles
#           else min 19 cycles, max extra 6 cycles * length of second longest string
#           plus 3 words on the stack (temporary)
# Cost: min 33 cycles * (length of longest sorted prefix - 1)
#       max (34 cycles + 6 cycles * length of second longest string in longest sorted prefix) *
#           (length of longest sorted prefix - 1)


# C-style Pseudocode:
# recCheck(char* array[], uint size) {
#     if (size == 0 or size == 1) return 1
#     if (!str_ge(array[1], array[0])) return 0
#     return recCheck(&(array[1]), size-1)
# }

recCheck:                        # - Entry Point -
    andi t1, a1, 1               # get the size without the LSB
    sub t1, a1, t1
    bne t1, zero, recCheck_check # if the size is 0 or 1, it's sorted
    addi a0, zero, 1             # return 1
    jr ra
recCheck_check:
    addi sp, sp, -12             # push ra, a1, a0
    sw ra, 8(sp)
    sw a1, 4(sp)
    sw a0, 0(sp)
    lw a1, 0(a0)                 # get the current string
    lw a0, 4(a0)                 # get the next string
    jal ra, str_ge               # if the next one is less than the current, it's not sorted
    bne a0, zero, recCheck_call
    lw ra, 8(sp)                 # pop a0, a1, ra
    addi sp, sp, 12              # (the old values of a0 and a1 are not needed)
    jr ra                        # return 0 (a0 is already 0)
recCheck_call:
    lw a0, 0(sp)                 # pop a0, a1, ra
    lw a1, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    addi a0, a0, 4               # recursively call recCheck for the tail of the input
    addi a1, a1, -1              # (the tail of the input is itself without the first element)
    jal zero, recCheck           # (don't link! This call returns the same as the recursive one)
