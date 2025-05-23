.data
free_list:
  .space 256
free_list_current_index:
   .quad 0

.text
.global delete
.global free_list
.global free_list_current_index

#delete the key
#Input : get the key from the word_ptrs and search the key, delete the key
delete:
  pushq %rbp
  movq %rsp, %rbp
  subq $32, %rsp
  movq $1, -8(%rbp)                     #use for index
  movq -8(%rbp), %r8
  movq word_ptrs(,%r8,8), %rdi          #get the key from word_ptrs
  #hash the key
  call hash
  movq %rax, -8(%rbp)                         #find the bucket index of the key
  movq -8(%rbp), %r8
  #fetch the node in the index
  #store the previous node & current node
  movq $0, -32(%rbp)                             #previous node
  movq store(,%r8,8), %r8                  
  cmpq $0, %r8                                   #check if the key exists in the bucket index
  je done
  movq %r8, -16(%rbp)                            #current node 
  movq (%r8), %rsi                               #destination key

#pass source key & dest key to verify match
linked_list:
  movq $1, %r8
  movq word_ptrs(,%r8,8), %rdi                  #source key
  movq word_lengths(,%r8,8), %rcx               #length of the key
  repe cmpsb
  jne next_node
  
  #if the node is head , unlink the head from the bucket
  cmpq $0, -32(%rbp)            #compare previous node with 0, if yes then it is head node
  je delete_head_from_bucket

  #if match found , unlink the node with neighbour nodes
  movq -32(%rbp), %r10            #previous node
  movq -16(%rbp), %rdx            #current node
  movq $2, %r8
  movq (%rdx,%r8,8),%rcx          #next node
  movq %rcx, (%r10,%r8,8)         #store next node pointer in previous node
  #delete the current node
  jmp add_to_free_list

  
  #move to next node and check if key matches
  next_node:
    movq -16(%rbp), %rdx
    movq %rdx, -32(%rbp)        #preserve current node to previous
    movq $2, %r8
    movq (%rdx,%r8,8), %r10     #next node
    cmpq $0, %r10               #check if the node is the last
    je done
    movq %r10, -16(%rbp)        #preserve next node to current
    movq (%r10), %rsi           #dest key
    jmp linked_list
  
  delete_head_from_bucket:
    movq -8(%rbp), %r8                   #restore bucket index
    movq $0, store(,%r8,8)               #remove the link
  
  add_to_free_list: 
    #keep track of free_list index
    movq free_list_current_index, %r8  
    movq -16(%rbp), %r10    
    movq %r10, free_list(,%r8,8)          #add the current node to free_list
    incq free_list_current_index
    movq $0, %rax                           #indicates successfully deleted
    addq $32, %rsp
    popq %rbp
    ret
  
  done:
    movq $1, %rax                         #no deletion happened
    addq $32, %rsp
    popq %rbp
    ret
    




  