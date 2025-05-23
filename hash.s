.text
.global hash

#hash the supplied key to find the bucket & and add it to the head node
#Input : rdi - pointer to key
#output: rax - contains the bucket index
hash:
 pushq %rbp
 movq %rsp, %rbp

 xorq %rax, %rax
 #convert the input key to number by adding asci values of each character
hash_loop:
  movzbq (%rdi), %rcx
  testb %cl, %cl    #check for null terminator
  je hash_done 
  cmpb $0x0A, %cl   #check for new line
  je hash_done
  addq %rcx, %rax
  incq %rdi
  jmp hash_loop

hash_done:
  #perform modulo operation to find the bucket
  andq $63, %rax
  popq %rbp
  ret
 
 