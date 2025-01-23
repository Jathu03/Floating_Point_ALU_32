module top_module #(
    parameter WIDTH = 32,  // Width of the floating-point numbers (Default: 32-bit IEEE 754)
    parameter EXP_WIDTH = 8,  // Width of the exponent field (Default: 8 bits)
    parameter MANT_WIDTH = 23  // Width of the mantissa field (Default: 23 bits)
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] a,  // Input A (Floating-point format)
    input wire [WIDTH-1:0] b,  // Input B (Floating-point format)
    input wire [1:0] operation,  // Operation selector: 00->Add, 01->Subtract, 10->Multiply, 11->Divide
    output reg [WIDTH-1:0] result // Result (Floating-point format)
);

    // Internal wires to connect the individual operations
    wire [WIDTH-1:0] add_result;
    wire [WIDTH-1:0] sub_result;
    wire [WIDTH-1:0] mul_result;
    wire [WIDTH-1:0] div_result;

    // Instantiate the Floating-Point Adder
    floating_point_adder #(
        .WIDTH(WIDTH)
    ) adder (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(add_result)
    );
	 /*floating_point_adder adder (
        .clk(clk), 
        .reset(reset),
        .a(input_a), 
        .b(input_b),
        .result(add_result)
    );*/

    // Instantiate the Floating-Point Subtractor
    floating_point_subtractor #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) subtractor (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(sub_result)
    );

    // Instantiate the Floating-Point Multiplier
    floating_point_multiplier #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) multiplier (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(mul_result)
    );

    // Instantiate the Floating-Point Divider
    floating_point_divider #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) divider (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(div_result)
    );

    // MUX to select the appropriate result based on the operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= {WIDTH{1'b0}};
        end else begin
            case (operation)
                2'b00: result <= add_result;    // Addition
                2'b01: result <= sub_result;    // Subtraction
                2'b10: result <= mul_result;    // Multiplication
                2'b11: result <= div_result;    // Division
                default: result <= {WIDTH{1'b0}};
            endcase
        end
    end
endmodule
