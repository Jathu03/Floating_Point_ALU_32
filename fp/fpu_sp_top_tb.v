`timescale 1ns / 1ps

module fpu_sp_top_tb;

    reg clk;                      // Clock signal
    reg rst_n;                    // Reset signal (active low)
    reg [31:0] din1, din2;        // Input operands
    reg dval;                     // Data valid signal
    reg [3:0] cmd;                // Command signal
    wire [31:0] result;           // Output result
    wire rdy;                     // Ready signal

    // Instantiate the fpu_sp_top module
    fpu_sp_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd(cmd),
        .din1(din1),
        .din2(din2),
        .dval(dval),
        .result(result),
        .rdy(rdy)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Initialize testbench signals
    initial begin
        clk = 0;
        rst_n = 0;
        dval = 0;
        cmd = 0;
        din1 = 0;
        din2 = 0;

        // Apply reset
        #20;
        rst_n = 1;

        // Test addition
        $display("\n--- Testing Addition ---");
        cmd = 4'b0001; // CMD_FPU_SP_ADD
        #10;
        apply_test(32'h3F800000, 32'h40000000, 32'h40400000); // 1.0 + 2.0 = +3.0
        apply_test(32'h00000000, 32'h40400000, 32'h40400000); // 0.0 + 3.0 = +3.0
        apply_test(32'hC0400000, 32'h40400000, 32'h00000000); // -3.0 + 3.0 = +0.0
        apply_test(32'h7F800000, 32'h40400000, 32'h7F800000); // +Inf + 3.0 = +Inf
        apply_test(32'h7F800000, 32'hFF800000, 32'h7FC00000); // Inf + -Inf = NaN
        apply_test(32'h7FC00000, 32'h40400000, 32'h7FC00000); // NaN + 3.0 = NaN
        apply_test(32'h7FC00000, 32'h7FC00000, 32'h7FC00000); // NaN + NaN = NaN
        apply_test(32'h3F800000, 32'hBF800000, 32'h00000000); // 1.0 + -1.0 = +0.0
        apply_test(32'h00000001, 32'h3F800000, 32'h3F800000); // Denorm + 1.0 = 1.0
        apply_test(32'h00000000, 32'h00000000, 32'h00000000); // 0.0 + 0.0 = +0.0

        // Test subtraction
        $display("\n--- Testing Subtraction ---");
        cmd = 4'b0010; // CMD_FPU_SP_SUB
        #10;
        apply_test(32'h40000000, 32'h3F800000, 32'h3F800000); // 2.0 - 1.0 = 1.0
        apply_test(32'h40400000, 32'h40400000, 32'h00000000); // 3.0 - 3.0 = 0.0
        apply_test(32'hC0400000, 32'h40400000, 32'hC0C00000); // -3.0 - 3.0 = -6.0
        apply_test(32'h7F800000, 32'h40400000, 32'h7F800000); // Inf - 3.0 = +Inf
        apply_test(32'h7F800000, 32'hFF800000, 32'h7F800000); // Inf - -Inf = +Inf
        apply_test(32'h7FC00000, 32'h40400000, 32'h7FC00000); // NaN - 3.0 = NaN
        apply_test(32'h3F800000, 32'h00000000, 32'h3F800000); // 1.0 - 0.0 = +1.0
        apply_test(32'h3F800000, 32'hBF800000, 32'h40000000); // 1.0 - -1.0 = +2.0
        apply_test(32'h00000001, 32'h3F800000, 32'hBF800000); // Denorm - 1.0 = -1.0
        apply_test(32'h00000000, 32'h00000000, 32'h00000000); // 0.0 - 0.0 = +0.0

        // Test multiplication
        $display("\n--- Testing Multiplication ---");
        cmd = 4'b0011; // CMD_FPU_SP_MUL
        #10;
        apply_test(32'h3F800000, 32'h40000000, 32'h40000000); // 1.0 * 2.0 = +2.0
        apply_test(32'h00000000, 32'h40400000, 32'h00000000); // 0.0 * 3.0 = +0.0
        apply_test(32'hC0400000, 32'h40400000, 32'hC1100000); // -3.0 * 3.0 = -9.0
        apply_test(32'h7F800000, 32'h3F800000, 32'h7F800000); // Inf * 1.0 = +Inf
        apply_test(32'h7F800000, 32'h00000000, 32'h7FC00000); // Inf * 0.0 = NaN
        apply_test(32'h7FC00000, 32'h40400000, 32'h7FC00000); // NaN * 3.0 = NaN
        apply_test(32'h3F800000, 32'hBF800000, 32'hBF800000); // 1.0 * -1.0 = -1.0
        apply_test(32'h3F800000, 32'h00000000, 32'h00000000); // 1.0 * 0.0 = +0.0
        apply_test(32'h00000001, 32'h3F800000, 32'h00000001); // Denorm * 1.0 = Denorm
        apply_test(32'h00000000, 32'h00000000, 32'h00000000); // 0.0 * 0.0 = +0.0

        // Test division
        $display("\n--- Testing Division ---");
        cmd = 4'b0100; // CMD_FPU_SP_DIV
        #10;
        apply_test(32'h40000000, 32'h3F800000, 32'h40000000); // 2.0 / 1.0 = +2.0
        apply_test(32'h40400000, 32'h40400000, 32'h3F800000); // 3.0 / 3.0 = +1.0
        apply_test(32'hC0400000, 32'h40400000, 32'hbf800000); // -3.0 / 3.0 = -1.0
        apply_test(32'h7F800000, 32'h40400000, 32'h7F800000); // Inf / 3.0 = +Inf
        apply_test(32'h40400000, 32'h00000000, 32'h7F800000); // 3.0 / 0.0 = +Inf
        apply_test(32'h00000000, 32'h40400000, 32'h00000000); // 0.0 / 3.0 = +0.0
        apply_test(32'h7F800000, 32'h7F800000, 32'h7FC00000); // Inf / Inf = NaN
        apply_test(32'h3F800000, 32'hBF800000, 32'hBF800000); // 1.0 / -1.0 = -1.0
        apply_test(32'h3F800000, 32'h00000001, 32'h7F800000); // 1.0 / Denorm = +Inf
        apply_test(32'h00000000, 32'h3F800000, 32'h00000000); // 0.0 / 1.0 = +0.0

        // Complete simulation
        #20;
        $stop;
    end

    // Task to apply test cases
    task apply_test(input [31:0] a, input [31:0] b, input [31:0] expected);
        begin
            din1 = a;
            din2 = b;
            dval = 1;             // Signal valid input
            #10; dval = 0;        // Clear valid signal after a clock cycle
            wait(rdy);            // Wait for result to be ready
            #5;
            if (result === expected) begin
                $display("PASS: %h and %h => %h", a, b, result);
            end else begin
                $display("FAIL: %h and %h => %h, expected %h", a, b, result, expected);
            end
        end
    endtask

endmodule
