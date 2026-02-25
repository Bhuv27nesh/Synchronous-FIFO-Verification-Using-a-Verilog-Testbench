/*
-------------------------MINI_Project---------------------------------------------
Write test cases for verifying the fifo who code is mentioned below. 

You need to create write task and read task inside the test bench and verify the 
design. Show the results after running the same in Modelsim/questa Simulation tool. 
*/
/////////////////////////////////////////////////////////////////////////////////// 
/*
//fifo memory 
  module fifo(clk, 
             rst_n, 
             wr,rd, 
             data_in,  
             data_out, 
             fifo_full, 
             fifo_empty); 
 
    parameter FIFO_WIDTH = 8; 
    parameter FIFO_DEPTH = 16; 
 
    input clk,rst_n,wr,rd; 
    input [FIFO_WIDTH-1:0]data_in; 
    output fifo_full,fifo_empty; 
    output [FIFO_WIDTH-1:0] data_out ; 
 
    reg [FIFO_WIDTH-1:0] data_out; 
 
    reg [FIFO_WIDTH-1:0]mem[FIFO_DEPTH-1:0]; // Memory Dec 
 
    reg [3:0]wr_ptr,rd_ptr,wr_rd_ptr_diff;  
    integer i; 
 
    reg [3:0]count,count1; 
 
 
    wire  fifo_full = (wr_ptr == 4'd0 & wr_rd_ptr_diff == 4'd14) ? 1 : 0; 
    wire  fifo_empty = (rd_ptr== 4'd0 & wr_rd_ptr_diff == 4'd0) ? 1 : 0; 
 
    always @ (posedge clk or negedge rst_n)begin 
        if(!rst_n) begin 
            for(i=0;i<=15;i=i+1) 
                mem[i]<=8'd0; 
        end 
        //WRITE PORTION 
        else if(wr) 
            mem[wr_ptr]<=data_in; 
    end 
 
    //Write Ptr 
    always @ (posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            wr_ptr <= 4'd0; 
        else if(wr) 
            wr_ptr <= wr_ptr + 4'd1;   
    end 
 
    //READ OPERATION 
    always @ (posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            data_out <= 8'd0; 
        else if(rd) 
            data_out <= mem[rd_ptr]; 
    end 
 
    //Read Ptr 
    always @ (posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            rd_ptr <= 4'd0; 
        else if(rd) 
            rd_ptr <= rd_ptr + 4'd1; 
    end 
    //FIFO EMPTY and FULL Logic 
    always @ (posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            wr_rd_ptr_diff <= 4'd0; 
        else if(wr &  wr_rd_ptr_diff !=4'd15) 
            wr_rd_ptr_diff <= wr_rd_ptr_diff + 4'd1; 
        else if(rd & wr_rd_ptr_diff != 4'd0) 
            wr_rd_ptr_diff <= wr_rd_ptr_diff - 4'd1; 
    end 
endmodule
*/

/*
//////////////////////////////////////////////////////////////////////////////////
Here are few of the design errors found in the design fifo.v :
1] the full condition logic i.e. wire fifo_full = (wr_ptr == 4'd0 & wr_rd_ptr_diff == 4'd14) ? 1 : 0; 
because a FIFO of depth 16 should detect full based on occupancy count reaching its maximum, not based on a specific
 pointer value combined with a difference of 14, so this condition does not correctly represent 
 the full state and therefore full is never asserted when 16 elements are written.
 
2]the write operation is not protected against overflow since else if(wr) mem[wr_ptr] <= data_in; 
without checking fifo_full, which allows new data to overwrite existing data when the FIFO is already full, 
causing corruption and mismatch during reads.

3]the read operation is not protected against underflow because  else if(rd) data_out <= mem[rd_ptr]; 
without checking fifo_empty, so the design continues to read and increment the read pointer even when 
no valid data is stored, which leads to invalid outputs and scoreboard errors.

4]the occupancy tracking logic 
else if(wr & wr_rd_ptr_diff !=4'd15) wr_rd_ptr_diff <= wr_rd_ptr_diff + 4'd1; 
else if(rd & wr_rd_ptr_diff != 4'd0) wr_rd_ptr_diff <= wr_rd_ptr_diff - 4'd1; 
because it does not correctly handle simultaneous read and write operations, 
and it artificially limits the maximum difference to 15 for a depth of 16, which results
 incorrect tracking of how many elements are actually stored.
 
5]the empty detection logic wire fifo_empty = (rd_ptr== 4'd0 & wr_rd_ptr_diff == 4'd0) ? 1 : 0; 
because emptiness should depend only on the occupancy count being zero, not on the read pointer being zero, 
since after pointer wrap-around the FIFO can be empty while rd_ptr is not zero, making this condition unreliable.


///////////////////////////////////////////////////////////////////////////////////
*/

module fifo (
    clk,
    rst_n,
    wr,
    rd,
    data_in,
    data_out,
    fifo_full,
    fifo_empty
);

parameter FIFO_WIDTH = 8;
parameter FIFO_DEPTH = 16;
parameter PTR_WIDTH  = 4;   // log2(16) = 4

input clk, rst_n;
input wr, rd;
input [FIFO_WIDTH-1:0] data_in;

output reg [FIFO_WIDTH-1:0] data_out;
output fifo_full, fifo_empty;

reg [FIFO_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

reg [PTR_WIDTH-1:0] wr_ptr;
reg [PTR_WIDTH-1:0] rd_ptr;
reg [PTR_WIDTH:0]   count;     // 5-bit to count 0–16

integer i;

// --------------------------------------------------
// FULL and EMPTY Conditions
// --------------------------------------------------
assign fifo_full  = (count == FIFO_DEPTH);
assign fifo_empty = (count == 0);

// --------------------------------------------------
// MEMORY WRITE
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            mem[i] <= 0;
    end
    else if (wr && !fifo_full) begin
        mem[wr_ptr] <= data_in;
    end
end

// --------------------------------------------------
// WRITE POINTER
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        wr_ptr <= 0;
    else if (wr && !fifo_full)
        wr_ptr <= wr_ptr + 1;
end

// --------------------------------------------------
// READ OPERATION
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 0;
    else if (rd && !fifo_empty)
        data_out <= mem[rd_ptr];
end

// --------------------------------------------------
// READ POINTER
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rd_ptr <= 0;
    else if (rd && !fifo_empty)
        rd_ptr <= rd_ptr + 1;
end

// --------------------------------------------------
// COUNT LOGIC (Handles simultaneous read/write)
// --------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        count <= 0;
    else begin
        case ({wr && !fifo_full, rd && !fifo_empty})
            2'b10: count <= count + 1;   // write only
            2'b01: count <= count - 1;   // read only
            2'b11: count <= count;       // simultaneous → no change
            default: count <= count;
        endcase
    end
end

endmodule
//*/
