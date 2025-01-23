`timescale 1ns / 1ps

module fpu_sp_add_tb;

    reg clk;                     // Clock signal
    reg rst_n;                   // Reset signal (active low)
    reg [31:0] din1, din2;       // Inputs for addition
    reg dval;                    // Data valid signal
    wire [31:0] result;          // Output result
    wire rdy;                    // Output ready signal

    // Instantiate the fpu_sp_add module
    fpu_sp_add uut (
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

        // Test case 1: Normal addition
        #10; apply_test(32'h3F800000, 32'h40000000, 32'h40400000); // 1.0 + 2.0 = 3.0

        // Test case 2: Adding zero
        #10; apply_test(32'h00000000, 32'h40400000, 32'h40400000); // +0.0 + 3.0 = 3.0

        // Test case 3: Negative and positive number addition
        #10; apply_test(32'hC0400000, 32'h40400000, 32'h00000000); // -3.0 + 3.0 = +0.0

        // Test case 4: Addition involving infinity
        #10; apply_test(32'h7F800000, 32'h40400000, 32'h7F800000); // +Inf + 3.0 = +Inf

        // Test case 5: Infinity with opposite sign addition
        #10; apply_test(32'h7F800000, 32'hFF800000, 32'h7FC00000); // +Inf + -Inf = NaN

        // Test case 6: Adding NaN
        #10; apply_test(32'h7FC00000, 32'h40400000, 32'h7FC00000); // NaN + 3.0 = NaN

        // Test case 7: NaN with NaN
        #10; apply_test(32'h7FC00000, 32'h7FC00000, 32'h7FC00000); // NaN + NaN = NaN

        // Test case 8: Addition of positive and negative
        #10; apply_test(32'h3F800000, 32'hBF800000, 32'h00000000); // 1.0 + -1.0 = +0.0

        // Test case 9: Adding smallest denormalized number with normal number
        #10; apply_test(32'h00000001, 32'h3F800000, 32'h3F800000); // Smallest denorm + 1.0 = 1.0

        // Test case 10: Zero with zero
        #10; apply_test(32'h00000000, 32'h00000000, 32'h00000000); // +0.0 + +0.0 = +0.0
		  
		  // Test case 11: 
        #10; apply_test(32'h422e3333, 32'h428a3d71, 32'h42e1570a); // +43.549999237060546875(43.55) + 69.12000274658203125(69.12) = 112.6699981689453125(112.67)

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
                $display("PASS: %h + %h = %h", a, b, result);
            end else begin
                $display("FAIL: %h + %h = %h, expected %h", a, b, result, expected);
            end
        end
    endtask

endmodule
