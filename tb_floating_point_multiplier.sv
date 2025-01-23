`timescale 1ns / 1ps

module tb_floating_point_multiplier;

    // Parameters
    parameter WIDTH = 32;
    parameter EXP_WIDTH = 8;
    parameter MANT_WIDTH = 23;

    // Inputs
    reg clk;
    reg reset;
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;

    // Output
    wire [WIDTH-1:0] result;

    // Instantiate the floating_point_multiplier
    floating_point_multiplier #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to display the results
    task display_result;
        input [WIDTH-1:0] input_a;
        input [WIDTH-1:0] input_b;
        input [WIDTH-1:0] output_result;
        begin
            $display("Time: %0t | A: %h | B: %h | Result: %h", $time, input_a, input_b, output_result);
        end
    endtask

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        a = 0;
        b = 0;

        // Apply reset
        #10;
        reset = 0;

        // Test Case 1: Multiply 1.5 * 2.25
        #10;
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h40080000; // 2.25 in IEEE 754
        #20;
        display_result(a, b, result);

        // Test Case 2: Multiply -1.25 * 0.5
        #10;
        a = 32'hBF800000; // -1.25 in IEEE 754
        b = 32'h3F000000; // 0.5 in IEEE 754
        #20;
        display_result(a, b, result);

        // Test Case 3: Multiply 0.125 * 8.0
        #10;
        a = 32'h3E000000; // 0.125 in IEEE 754
        b = 32'h41000000; // 8.0 in IEEE 754
        #20;
        display_result(a, b, result);

        // Test Case 4: Multiply -0.75 * -0.25
        #10;
        a = 32'hBE400000; // -0.75 in IEEE 754
        b = 32'hBE800000; // -0.25 in IEEE 754
        #20;
        display_result(a, b, result);

        // Test Case 5: Multiply 0 * 3.5
        #10;
        a = 32'h00000000; // 0 in IEEE 754
        b = 32'h40600000; // 3.5 in IEEE 754
        #20;
        display_result(a, b, result);

        // End simulation
        #10;
        $stop;
    end
endmodule
