`timescale 1ns / 1ps

module floating_point_subtractor_tb;

    // Parameters for the floating point format
    parameter WIDTH = 32;
    parameter EXP_WIDTH = 8;
    parameter MANT_WIDTH = 23;

    // Testbench signals
    reg clk;
    reg reset;
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    wire [WIDTH-1:0] result;

    // Instantiate the DUT (Device Under Test)
    floating_point_subtractor #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        a = 32'b0;
        b = 32'b0;
        #10;

        reset = 0;

        // Test case 1: Subtract two positive numbers
        a = 32'b01000000101000000000000000000000; // 5.0 (IEEE 754)
        b = 32'b01000000001000000000000000000000; // 2.5 (IEEE 754)
        #20;
        $display("Test Case 1: 5.0 - 2.5 = %b", result);

        // Test case 2: Subtract a smaller positive number from a larger one
        a = 32'b01000000001000000000000000000000; // 2.5 (IEEE 754)
        b = 32'b01000000101000000000000000000000; // 5.0 (IEEE 754)
        #20;
        $display("Test Case 2: 2.5 - 5.0 = %b", result);

        // Test case 3: Subtract a positive number from a negative number
        a = 32'b11000000001000000000000000000000; // -2.5 (IEEE 754)
        b = 32'b01000000101000000000000000000000; // 5.0 (IEEE 754)
        #20;
        $display("Test Case 3: -2.5 - 5.0 = %b", result);

        // Test case 4: Subtract two negative numbers
        a = 32'b11000000101000000000000000000000; // -5.0 (IEEE 754)
        b = 32'b11000000001000000000000000000000; // -2.5 (IEEE 754)
        #20;
        $display("Test Case 4: -5.0 - (-2.5) = %b", result);

        // Test case 5: Subtract zero
        a = 32'b01000000101000000000000000000000; // 5.0 (IEEE 754)
        b = 32'b00000000000000000000000000000000; // 0.0 (IEEE 754)
        #20;
        $display("Test Case 5: 5.0 - 0.0 = %b", result);

        // Test case 6: Subtract from zero
        a = 32'b00000000000000000000000000000000; // 0.0 (IEEE 754)
        b = 32'b01000000101000000000000000000000; // 5.0 (IEEE 754)
        #20;
        $display("Test Case 6: 0.0 - 5.0 = %b", result);

        // Finish simulation
        $stop;
    end

endmodule
