`timescale 1ns / 1ps

module tb_floating_point_adder;

    // Testbench Signals
    reg clk;
    reg reset;
    reg [31:0] a; // Input A (IEEE 754 format)
    reg [31:0] b; // Input B (IEEE 754 format)
    wire [31:0] result; // Output Result (IEEE 754 format)

    // Instantiate the floating point adder module
    floating_point_adder #(
        .WIDTH(32)
    ) adder_inst (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result)
    );

    // Clock Generation
    always begin
        #5 clk = ~clk;  // Clock period of 10ns
    end

    // Test Sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        a = 32'b0;
        b = 32'b0;

        // Apply reset
        reset = 1;
        #10;
        reset = 0;

        // Test case 1: Add two positive numbers
        a = 32'b01000000101000000000000000000000; // 5.0 in IEEE 754
        b = 32'b01000000010010010000111111011010; // 3.14 in IEEE 754
        #10;

        // Test case 2: Add a positive and a negative number
        a = 32'b01000000101000000000000000000000; // 5.0 in IEEE 754
        b = 32'b11000000010010010000111111011010; // -3.14 in IEEE 754
        #10;

        // Test case 3: Add two negative numbers
        a = 32'b11000000101000000000000000000000; // -5.0 in IEEE 754
        b = 32'b11000000010010010000111111011010; // -3.14 in IEEE 754
        #10;

        // Test case 4: Add a large and a small number
        a = 32'b01111111100000000000000000000000; // Largest positive number (Inf) in IEEE 754
        b = 32'b00000000000000000000000000000000; // Zero in IEEE 754
        #10;

        // Test case 5: Adding zero and zero
        a = 32'b00000000000000000000000000000000; // 0.0 in IEEE 754
        b = 32'b00000000000000000000000000000000; // 0.0 in IEEE 754
        #10;

        // Test case 6: Add two very small numbers
        a = 32'b00111111000000000000000000000000; // 0.5 in IEEE 754
        b = 32'b00111111000000000000000000000001; // 0.5000002 in IEEE 754
        #10;

        // End simulation
        $stop;
    end

    // Monitor the results
    initial begin
        $monitor("Time = %0t, a = %b, b = %b, result = %b", $time, a, b, result);
    end

endmodule
