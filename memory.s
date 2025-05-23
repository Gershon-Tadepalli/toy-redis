.data
current_brk: .quad 0

.text
.global allocate

#rdi - consists of n bytes
#rax - return base address
allocate:
  #stack frame
  pushq %rbp
  movq %rsp, %rbp
  
  #if the request is for node , check the free_list and if there are any blocks return it
  cmpq $24, %rdi
  je return_free_list
 
 memory_allocate:
  #brk syscall to determine current_brk
  pushq %rdi
  movq $12, %rax
  xorq %rdi, %rdi
  syscall

  #store in current_brk
  movq %rax, current_brk

  #8-byte memory alignment as we are storing 8-byte pointers in node structure
  popq %rdi
  addq $7, %rdi             #pad to next multiple of 8
  andq $-8, %rdi            #clear lowest 3 bits to align
  movq $12, %rax
  addq current_brk, %rdi   #move the brk position by passing new address
  syscall
 
  #return base address
  movq current_brk, %rax
  popq %rbp
  ret

  #check the free list if there is any available node
  return_free_list:
    cmpq $0, free_list_current_index
    je memory_allocate
    #return the current free list item
    decq free_list_current_index                        #remove the free item
    movq free_list_current_index, %r8
    movq free_list(,%r8,8), %r10  

    #clear the items in the node
    movq (%r10), %rsi
    movq $0, (%rsi)                         #clear the key
    movq $1, %r8
    movq (%r10,%r8,8), %rsi
    movq $0, (%rsi)                         #clear the value

    movq $0, (%r10)                        #clear key pointer
    movq $0, (%r10,%r8,8)                  #clear value pointer
    incq %r8
    movq $0, (%r10,%r8,8)                  #clear next node pointer
    movq %r10, %rax                        #return the free node pointer
    popq %rbp
    ret
  