Toy-Redis - A minimal clone of Redis in x86-64 Assembly:

A low-level, educational project that reimagines a key value store using x86-64 assembly.
It was fun to peel out the abstractions and build this project in low-level assembly which is close to the metal!!!

Features:

	•	Simple key value store supporting put, get , delete operations
	•	Hashtable with 64 buckets and chaining for collision resolution
    	•	Manual memory management with brk syscall.
	•	Memory reuse via custom free list allocator


![alt text](image.png)

🚀 Getting Started

🔧 Prerequisites

	•	OS: Debian/Ubuntu Linux
	•	Tools: build-essential, gdb, make
 
	        sudo apt update && sudo apt install build-essential gdb make


🔨 Build Instructions

<img width="597" alt="Screenshot 2025-05-23 at 7 25 40 PM" src="https://github.com/user-attachments/assets/f128ce0a-0850-494b-9fb1-1dd28af139fd" />



▶️ Run the Program

<img width="674" alt="Screenshot 2025-05-23 at 7 28 07 PM" src="https://github.com/user-attachments/assets/8c506f3c-03b7-41c8-9720-378a7d48b124" />



Credits:

Massive thanks to Abhinav Upadhyay for sharing his deep insights on low-level systems.
Follow his amazing Substack at 👉 https://blog.codingconfessions.com/


🧠 Lessons Learned

	•	Parsing and string manipulation in assembly
	•	Building stack frames for function-local variables
	•	Manual memory management via brk syscall
	•	Creating and reusing a free list to avoid excessive syscalls
	•	Deep understanding of how high-level abstractions map to machine-level execution
