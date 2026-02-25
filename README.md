# Synchronous-FIFO-Verification-Using-a-Verilog-Testbench
A structured testbench that includes dedicated write tasks and read tasks to validate FIFO behavior under different operating 
conditions. The FIFO design consists of configurable width (8-bit) and depth (16 entries), along with proper full and empty flag generation logic.

## Verification Approach
Created reusable write and read tasks inside the testbench  
Generated directed test cases covering:  
-Normal write and read operations  
-FIFO full condition  
-FIFO empty condition  
-Pointer increment behavior  
-Reset functionality  
-Verified correct data ordering (FIFO property)  
-Checked flag assertions (fifo_full, fifo_empty)  

## Results
Successfully executed 200+ test cases  
All test cases passed using Icarus tool  
Verified correct pointer management and memory access behavior  
Confirmed functional correctness of FIFO under boundary conditions  
