module fpga #(
    parameter DATA_WIDTH = 32,  // Default width of the floating-point numbers (IEEE 754)
    parameter EXP_WIDTH = 8,    // Width of the exponent field (IEEE 754)
    parameter MANT_WIDTH = 23   // Width of the mantissa field (IEEE 754)
)(
    input wire clk,                 // Clock signal
    input wire reset,               // Reset signal
    output logic [6:0] out1, out2, out3, out4, out5, out6, out7 // Outputs for 7-segment displays
);

    // Internal signals for inputs and operation selector
    reg [DATA_WIDTH-1:0] a;         // Input A (floating-point format)
    reg [DATA_WIDTH-1:0] b;         // Input B (floating-point format)
    reg [1:0] operation;            // Operation selector (Add, Subtract, Multiply, Divide)
    wire [DATA_WIDTH-1:0] results;  // Result from the top module
    reg [DATA_WIDTH-1:0] result;    // Internal copy of the result

    // Always block to update the values of a, b, and operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a <= 32'h00000000; 
            b <= 32'h00000000; 
            operation <= 2'b00; // Addition
        end else begin
				a = 32'b01000001010001001100110011001101; //12.3
				b = 32'b01000000010110011001100110011010; //3.4
				operation <= 2'b00;                
				result <= results;                  
				
        end
    end

    // Instantiate the top module (floating-point arithmetic unit)
    top_module #(
        .WIDTH(DATA_WIDTH)
    ) top (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .operation(operation),
        .result(results)   // Connect result from top_module to results
    );


    // Internal logic for splitting the result into 4-bit segments
    reg [3:0] one1, one2, one3, one4, one5, one6, one7,one8;

    // Assigning segments from the result
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize segments to zero on reset
            one1 <= 4'b0000;
            one2 <= 4'b0000;
            one3 <= 4'b0000;
            one4 <= 4'b0000;
            one5 <= 4'b0000;
            one6 <= 4'b0000;
            one7 <= 4'b0000;
				one8 <= 4'b0000;
        end else begin
            // Split the result into 4-bit segments
            one1 <= result[3:0];   // Lower 4 bits of result
            one2 <= result[7:4];   // Next 4 bits
            one3 <= result[11:8];  // Next 4 bits
            one4 <= result[15:12]; // Next 4 bits
            one5 <= result[19:16]; // Next 4 bits
            one6 <= result[23:20]; // Next 4 bits
            one7 <= result[27:24]; // Next 4 bits
				one8 <= result[31:28]; // Next 4 bits
        end
    end

    // Instantiate binary-to-7-segment converters
    binary_to_7seg ss1 (.data_in(one8), .data_out(out1)); 
    binary_to_7seg ss2 (.data_in(one7), .data_out(out2));
    binary_to_7seg ss3 (.data_in(one6), .data_out(out3));
    binary_to_7seg ss4 (.data_in(one5), .data_out(out4));
    binary_to_7seg ss5 (.data_in(one4), .data_out(out5));
    binary_to_7seg ss6 (.data_in(one3), .data_out(out6));
    binary_to_7seg ss7 (.data_in(one2), .data_out(out7));
	 binary_to_7seg ss8 (.data_in(one1), .data_out(out8));
endmodule
