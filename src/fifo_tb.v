`timescale 1ns/1ps

module fifo_tb;

parameter FIFO_WIDTH = 8;
parameter FIFO_DEPTH = 16;

reg clk;
reg rst_n;
reg wr, rd;
reg [FIFO_WIDTH-1:0] data_in;

wire [FIFO_WIDTH-1:0] data_out;
wire fifo_full;
wire fifo_empty;

// ------------------------------------------------
// Test Counters
// ------------------------------------------------
integer total_tests = 0;
integer passed_tests = 0;
integer failed_tests = 0;

// ------------------------------------------------
// Golden Reference Model (Independent of DUT)
// ------------------------------------------------
reg [FIFO_WIDTH-1:0] ref_mem [0:FIFO_DEPTH-1];
integer ref_wr_ptr = 0;
integer ref_rd_ptr = 0;
integer ref_count  = 0;

// ------------------------------------------------
// DUT
// ------------------------------------------------
fifo dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr(wr),
    .rd(rd),
    .data_in(data_in),
    .data_out(data_out),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty)
);

// ------------------------------------------------
// Clock
// ------------------------------------------------
always #5 clk = ~clk;

// ------------------------------------------------
// Waveform
// ------------------------------------------------
initial begin
    $dumpfile("fifo_dump.vcd");
    $dumpvars(0,fifo_tb);
end

// ------------------------------------------------
// Continuous Monitor
// ------------------------------------------------
always @(posedge clk) begin
    $display("T=%0t | WR=%b RD=%b | DIN=%0d | DOUT=%0d | REF_COUNT=%0d | DUT_FULL=%b DUT_EMPTY=%b",$time, wr, rd, data_in, data_out, ref_count, fifo_full, fifo_empty);
end

// ------------------------------------------------
// RESET
// ------------------------------------------------
task reset_fifo;
begin
    rst_n = 0;
    wr = 0;
    rd = 0;
    data_in = 0;
    #20;
    rst_n = 1;
    #20;
end
endtask

// ------------------------------------------------
// WRITE TASK (Reference + DUT)
// ------------------------------------------------
task write_fifo(input [7:0] data);
begin
    @(posedge clk);
    wr = 1;
    rd = 0;
    data_in = data;

    // Golden model update (independent of DUT full)
    if (ref_count < FIFO_DEPTH) begin
        ref_mem[ref_wr_ptr] = data;
        ref_wr_ptr = (ref_wr_ptr + 1) % FIFO_DEPTH;
        ref_count = ref_count + 1;
    end
    else begin
        $display("EXPECTED OVERFLOW (reference full)");
    end

    @(posedge clk);
    wr = 0;
end
endtask

// ------------------------------------------------
// READ TASK (Reference + Compare)
// ------------------------------------------------
task read_fifo;
reg [7:0] expected;
begin
    @(posedge clk);
    wr = 0;
    rd = 1;

    if (ref_count > 0) begin
        expected = ref_mem[ref_rd_ptr];
        ref_rd_ptr = (ref_rd_ptr + 1) % FIFO_DEPTH;
        ref_count = ref_count - 1;

        @(posedge clk);

        total_tests = total_tests + 1;

        if (data_out === expected) begin
            passed_tests = passed_tests + 1;
            $display("PASS: Expected=%0d Actual=%0d", expected, data_out);
        end
        else begin
            failed_tests = failed_tests + 1;
            $display("FAIL: Expected=%0d Actual=%0d", expected, data_out);
        end
    end
    else begin
        $display("EXPECTED UNDERFLOW (reference empty)");
        @(posedge clk);
    end

    rd = 0;
end
endtask

// ------------------------------------------------
// Manual 16 Write / 16 Read Test
// ------------------------------------------------
task manual_test;
integer i;
begin
    $display("\n===== MANUAL 16 WRITE / READ =====");

    for (i=0; i<16; i=i+1)
        write_fifo(i+10);   // Values: 10 to 25

    if (fifo_full)
        $display("DUT FULL asserted");
    else
        $display("DUT FULL NOT asserted (BUG)");

    for (i=0; i<16; i=i+1)
        read_fifo;

    if (fifo_empty)
        $display("DUT EMPTY asserted");
    else
        $display("DUT EMPTY NOT asserted (BUG)");

    $display("===== END MANUAL TEST =====\n");
end
endtask

// ------------------------------------------------
// Random Stress Test (200+ verified reads)
// ------------------------------------------------
task random_stress(input integer required_reads);
reg [7:0] rand_data;
reg rand_op;
begin
    $display("\n===== RANDOM STRESS START =====");

    while (total_tests < required_reads) begin
        @(posedge clk);
        rand_op = $random % 2;

        if (rand_op)
            write_fifo($random);
        else
            read_fifo;
    end

    $display("===== RANDOM STRESS END =====\n");
end
endtask

// ------------------------------------------------
// Initial Block
// ------------------------------------------------
initial begin
    clk = 0;

    reset_fifo;

    manual_test;

    random_stress(200);

    #50;

    $display("\n================================");
    $display("TOTAL TESTS  = %0d", total_tests);
    $display("PASSED TESTS = %0d", passed_tests);
    $display("FAILED TESTS = %0d", failed_tests);
    $display("================================\n");

    $finish;
end

endmodule
