`timescale 1ns / 1ps

module tb_fpga;

    // Testbench signals
    reg clk;
    reg reset;
    wire [6:0] out1, out2, out3, out4, out5, out6, out7;

    // Instantiate the fpga module
    fpga uut (
        .clk(clk),
        .reset(reset),
        .out1(out1),
        .out2(out2),
        .out3(out3),
        .out4(out4),
        .out5(out5),
        .out6(out6),
        .out7(out7)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle clock every 5 ns
    end

    // Stimulus for the testbench
    initial begin
        // Initialize signals
        reset = 1;  // Start with reset active
        #10;
        reset = 0;  // Deassert reset after 10 ns
        #100;        // Run the simulation for some time

        // Optionally, you can add more stimulus here by changing a, b, and operation.
        // Example: Change inputs or apply a new reset cycle

        // Test different operations by changing operation and checking outputs
        
        // End simulation after some time
        #200;
        $stop;
    end

    // Monitor the outputs to check correctness
    initial begin
        $monitor("At time %t, out1=%b, out2=%b, out3=%b, out4=%b, out5=%b, out6=%b, out7=%b", 
                 $time, out1, out2, out3, out4, out5, out6, out7);
    end

endmodule
