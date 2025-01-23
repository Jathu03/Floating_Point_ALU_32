`timescale 1ns / 1ps

module tb_top_module;

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] a;
    reg [31:0] b;
    reg [1:0] operation;  // 00->Add, 01->Subtract, 10->Multiply, 11->Divide

    // Outputs
    wire [31:0] result;

    // Instantiate the Top Module (UUT)
    top_module uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .operation(operation),
        .result(result)
    );

    // Clock generation: toggle clk every 5 ns
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        a = 32'b0;
        b = 32'b0;
        operation = 2'b00;  // Default operation (Addition)

        // Apply reset for 10 ns
        #10;
        reset = 0;

        // Test Case 1: Addition (2.25 + 1.5)
        #10;
        a = 32'h40080000; // 2.125 in IEEE 754
        b = 32'h3FC00000; // 1.5 in IEEE 754
        operation = 2'b00; // Addition
        #20;
        $display("Test 1: a=%h, b=%h, operation=Add -> result=%h", a, b, result);

        // Test Case 2: Subtraction (2.25 - 1.5)
        #10;
        a = 32'h40080000; // 2.125 in IEEE 754
        b = 32'h3FC00000; // 1.5 in IEEE 754
        operation = 2'b01; // Subtraction
        #20;
        $display("Test 2: a=%h, b=%h, operation=Sub -> result=%h", a, b, result);

        // Test Case 3: Multiplication (2.5 * 1.25)
        #10;
        a = 32'h40200000; // 2.5 in IEEE 754
        b = 32'h3FA00000; // 1.25 in IEEE 754
        operation = 2'b10; // Multiplication
        #20;
        $display("Test 3: a=%h, b=%h, operation=Mul -> result=%h", a, b, result);

        // Test Case 4: Division (5.5 / 2.5)
        #10;
        a = 32'h40A00000; // 5.5 in IEEE 754
        b = 32'h40200000; // 2.5 in IEEE 754
        operation = 2'b11; // Division
        #20;
        $display("Test 4: a=%h, b=%h, operation=Div -> result=%h", a, b, result);

        // End simulation after all tests
        #10;
        $stop;
    end
endmodule
