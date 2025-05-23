.data
store:
  .space 512      #64 buckets to store linked list of nodes
input_buffer:
    .space 128
word_ptrs:
    .space 48
word_lengths:
    .space 48
new_line:
    .byte 10
null:
    .byte 0
space:
    .byte 32
put_str:
  .asciz "put"
get_str:
  .asciz "get"
delete_str:
  .asciz "delete"
unkonwn_str:
  .asciz "unknown command\n"
key_already_exists:
  .asciz "key already exists\n"
key_found_deleted:
  .asciz "deleted the key\n"
key_not_found:
  .asciz "key not found\n"

.text
.global _start
.global store 
.global word_ptrs 
.global word_lengths

#store the key and value in the hashtable
#Input: use word_ptrs register to fetch the inputs
put:
  #allocate space for node (24 bytes)
  movq $24,%rdi
  call allocate
  movq %rax, %rbx                     # node address

  #allocate space for key
  movq $1, %r10
  movq word_lengths(,%r10,8), %rdi   #allocate length bytes
  incq %rdi
  call allocate

  movq %rax, (%rbx)                 #save the key pointer to the node

  #copy the key to allocated space on the heap
  movq %rax, %rsi                      #arg1 : heap memory
  movq $1, %r10
  movq word_ptrs(,%r10,8), %rdi        #arg2: pointer to key
  call copy_loop

  #find the bucket index
  movq (%rbx), %rdi                    #pass key pointer
  call hash
  movq %rax, %r8                       #save bucket index

  #allocate space for value
  movq $2, %r10
  movq word_lengths(,%r10,8), %rdi       #allocate length bytes
  incq %rdi
  call allocate
  movq $1, %r10                         #index in node
  movq %rax, (%rbx,%r10,8)              #save value pointer to node address

  #copy the value to new space
  movq %rax, %rsi   #memory for value
  movq $2, %r10
  movq word_ptrs(,%r10,8), %rdi
  call copy_loop

  #check if the bucket index free or occupied
  cmpq $0, store(,%r8,8)              #check for free bucket
  jne add_to_list
  movq %rbx, store(,%r8,8)            #save the node address at the bucket index
  ret

  #copy the string character by character to memory
  #input : rdi contains source key pointer
  #        rsi contains destination new node key address
  copy_loop:
    pushq %rbp
    movq %rsp, %rbp

    copy:
      movzbq (%rdi), %rax      #load 1 byte from source
      movb %al, (%rsi)         #store the byte at destination
      test %al, %al            #check for null terminator
      je done_copy

      incq %rdi
      incq %rsi
      jmp copy

      done_copy:
        movb $0, (%rsi)          #insert null byte
        popq %rbp
        ret

  add_to_list:
    #link the head of the list to new node
    movq store(,%r8,8), %rax      #preserve the previous head
    movq $2, %r10
    movq %rax, (%rbx,%r10,8)      #store the previous head pointer in the new node pointer
    movq %rbx, store(,%r8,8)      #store new node pointer in the bucket index


#Input: use word_ptrs register to fetch the inputs
#output: rax=value / unknown
get:
   #hash the key
   movq $1, %r10
   movq word_ptrs(,%r10,8), %rdi          #input key
   call hash
   movq word_ptrs(,%r10,8), %rdi          #source string key
   movq %rax, %r10                        #move bucket index to r10
   movq store(,%r10,8), %r8               #gives us node address at bucket index
   cmpq $0, %r8                           #check if node is empty or not
   je exit_with_unknown
   movq (%r8), %rsi                       #destination key (dereference the node address and copy the key pointer)
   
   
   #loop through the linked list and match the key
   linked_list:
    movq $1, %r10
    movq word_ptrs(,%r10,8), %rdi          #source string key 
    movq word_lengths(,%r10,8), %rcx       #key length
    repe cmpsb                             #compare keys for a match , character by character until mismatch
    jne next_node
    movq $1, %r10                         #index of the value in the node 
    movq (%r8,%r10,8), %rax               #fetch the value from node address
    ret

   next_node:
    movq $2, %r10
    movq (%r8,%r10,8), %rsi               #next node pointer
    #if next node is empty then exit_with_unknown
    cmpq $0, %rsi
    je exit_with_unknown
    movq %rsi, %r8                       #preserve node address in r8 to jump through the linked list
    movq (%r8), %rsi                     #use rsi that stores the key pointer to verify if key meets the condition
    jmp linked_list
  
   exit_with_unknown:
    movq $key_not_found, %rax
    ret

#input: rdi contains the address
print:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp             #allocate 16 bytes of stack space

    movq %rdi, %rsi             #pointer to output string
    movq %rdi, -16(%rbp)        #save pointer to output string
    movl $0, -4(%rbp)           #loop counter
    count_loop:
      movzbq (%rdi), %rax
      cmpb new_line, %al
      je print_result
      incq %rdi
      incl -4(%rbp)
      jmp count_loop
    #print the output to stdout
    print_result:
      movq $1, %rax
      movq $1, %rdi
      movq -16(%rbp), %rsi
      movl -4(%rbp), %edx    #length of the string
      incl %edx
      syscall
      #leave           #movq %rbp, %rsp & pop %rbp
      addq $16, %rsp
      popq %rbp
      ret

#loop through the input_buffer character by character
#rdi contains input_buffer address
loop_next_char:
  movzbq (%rdi), %rax  #fetch 1 byte into register
  cmpb new_line, %al    #new line check
  je done
  cmpb space, %al     #space character
  je split_word
  cmpb null, %al       #null check
  je done
  #move to next byte
  incq %rdi 
  incq %rsi
  jmp loop_next_char

#store word count
split_word:
  movb $0, (%rdi)                       #replace space with null terminator
  movq %rsi, word_lengths(,%rcx,8)      #store word length into word_lengths array
  xorq %rsi, %rsi #reset word length
  #split over spaces
  incq %rdi

split_spaces:
  movzbq (%rdi), %rax
  cmpb space, %al
  je skip_space
  jmp set_new_word

skip_space:
  incq %rdi
  jmp split_spaces

set_new_word:
  incq %rcx  #increment word count
  movq %rdi, word_ptrs(,%rcx,8) #store word start address into word_ptrs array
  jmp loop_next_char

done:
  movq %rsi, word_lengths(,%rcx,8)      #store last word length into word_lengths array
  #if the input is single word then 
  ret

#simple cli loop
_start:
   accept_input:
    #accept the input from stdin
    movq $0, %rax
    movq $0, %rdi
    movq $input_buffer, %rsi
    movq $128, %rdx
    syscall

    #parse the input
    xorq %rcx, %rcx #word count
    movq $0, %rsi #word length
    movq $input_buffer, %rdi
    movq %rdi, word_ptrs(,%rcx,8) #store 1st word start address
    call loop_next_char

    #compare 1st word with the commands(put,get)
    cmpq $0, %rcx               #input has only 1 word
    je check_unknown
    movq $put_str, %rsi         #copy command to rsi
    movq word_ptrs, %rdi        #copy the 1st word to rdi
    movq (word_lengths), %rcx   #copy the word length to rcx
    repe cmpsb                  #compare until mismatch
    jne check_get

    #check if key already exists
    call get
    movq %rax, %rdi
    movq $key_not_found, %rsi         #copy command to rsi
    movq $13, %rcx                   #copy the word length to rcx
    repe cmpsb                      #compare until mismatch
    jne print_the_val
    
    #if key not exists, then insert (key,value)
    call put
    jmp clear

  print_the_val:
    movq $key_already_exists, %rdi
    call print
    jmp clear

  check_get:
    movq $get_str, %rsi
    movq word_ptrs, %rdi
    movq (word_lengths), %rcx
    repe cmpsb                    #compare until mismatch
    jne  delete_operation
    #jne  check_unknown
    call get
    movq %rax, %rdi
    call print
    jmp clear

  delete_operation:
    movq $delete_str, %rsi
    movq word_ptrs, %rdi
    movq word_lengths,%rcx
    repe cmpsb
    jne check_unknown
    call delete
    cmpq $0, %rax             #key found and deleted the key
    je print_deleted
    movq $key_not_found, %rdi
    call print
    jmp clear

  print_deleted:
    movq $key_found_deleted, %rdi
    call print
    jmp clear

  check_unknown:
    movq $unkonwn_str,%rdi
    call print
    jmp clear

  clear:
    movq $word_ptrs, %rdi        #consits of input commands
    movq $6, %rcx                #set loop count

    clear_loop:
      movq $0, (%rdi)              #clear bits
      addq $8, %rdi
      loop clear_loop
      jmp accept_input

