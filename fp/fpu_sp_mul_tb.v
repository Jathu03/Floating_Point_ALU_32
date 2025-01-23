`timescale 1ns / 1ps

module fpu_sp_mul_tb;

    reg clk;                     // Clock signal
    reg rst_n;                   // Reset signal (active low)
    reg [31:0] din1, din2;       // Inputs for multiplication
    reg dval;                    // Data valid signal
    wire [31:0] result;          // Output result
    wire rdy;                    // Output ready signal

    // Instantiate the fpu_sp_mul module
    fpu_sp_mul uut (
        .clk(clk),
        .rst_n(rst_n),
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
        din1 = 0;
        din2 = 0;

        // Apply reset
        #20;
        rst_n = 1;

        // Test case 1: Normal numbers
        #10; apply_test(32'h3F800000, 32'h40000000, 32'h40000000); // 1.0 * 2.0 = 2.0

        // Test case 2: Zero times a number
        #10; apply_test(32'h00000000, 32'h40400000, 32'h00000000); // +0.0 * 3.0 = +0.0

        // Test case 3: A number times zero
        #10; apply_test(32'hC0400000, 32'h00000000, 32'h80000000); // -3.0 * +0.0 = -0.0

        // Test case 4: Infinity times a number
        #10; apply_test(32'h7F800000, 32'h40400000, 32'h7F800000); // +Inf * 3.0 = +Inf

        // Test case 5: Number times Infinity
        #10; apply_test(32'h3F800000, 32'hFF800000, 32'hFF800000); // 1.0 * -Inf = -Inf

        // Test case 6: NaN times a number
        #10; apply_test(32'h7FC00000, 32'h40400000, 32'h7fc00000); // NaN * 3.0 = NaN

        // Test case 7: Number times NaN
        #10; apply_test(32'h3F800000, 32'h7FC00000, 32'h7fc00000); // 1.0 * NaN = NaN

        // Test case 8: Positive and Negative numbers
        #10; apply_test(32'h3F800000, 32'hBF800000, 32'hBF800000); // 1.0 * -1.0 = -1.0

        // Test case 9: Denormalized number times normal number
        #10; apply_test(32'h00000001, 32'h3F800000, 32'h00000001); // Smallest denorm * 1.0 = Smallest denorm

        // Test case 10: Infinity times zero (should result in NaN)
        #10; apply_test(32'h7F800000, 32'h00000000, 32'h7fc00000); // +Inf * 0.0 = NaN
		  
		  // Test case 11: Infinity times Infinity (should result in NaN)
        #10; apply_test(32'h7f800000, 32'h7f800000, 32'h7fc00000); // +Inf * +Inf = NaN
		  
		  // Test case 12: 
        #10; apply_test(32'h42050000, 32'hc2610000, 32'hc4e9ca00); // 33.25 * -56.25 = -1870.3125

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
                $display("PASS: %h * %h = %h", a, b, result);
            end else begin
                $display("FAIL: %h * %h = %h, expected %h", a, b, result, expected);
            end
        end
    endtask

endmodule
