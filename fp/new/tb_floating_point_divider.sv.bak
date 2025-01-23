`timescale 1ns / 1ps

module tb_floating_point_divider;

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] a;
    reg [31:0] b;

    // Outputs
    wire [31:0] result;

    // Instantiate the Unit Under Test (UUT)
    floating_point_divider uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        a = 32'b0;
        b = 32'b0;

        // Apply reset
        #10;
        reset = 0;

        // Test Case 1: Divide 2.25 / 1.5
        #10;
        a = 32'h40080000; // 2.25 in IEEE 754
        b = 32'h3FC00000; // 1.5 in IEEE 754
        #20;
        $display("Test 1: a=%h, b=%h -> result=%h", a, b, result);

        // Test Case 2: Divide 5.5 / 2.5
        #10;
        a = 32'h40A00000; // 5.5 in IEEE 754
        b = 32'h40200000; // 2.5 in IEEE 754
        #20;
        $display("Test 2: a=%h, b=%h -> result=%h", a, b, result);

        // Test Case 3: Divide 1.0 / 0.25
        #10;
        a = 32'h3F800000; // 1.0 in IEEE 754
        b = 32'h3E800000; // 0.25 in IEEE 754
        #20;
        $display("Test 3: a=%h, b=%h -> result=%h", a, b, result);

        // End simulation
        #10;
        $stop;
    end
endmodule
