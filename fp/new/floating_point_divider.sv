module floating_point_divider #(
    parameter WIDTH = 32,         // Total width of the floating-point number
    parameter EXP_WIDTH = 8,      // Width of the exponent field
    parameter MANT_WIDTH = 23     // Width of the mantissa field
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] a,     // Input A (Floating-point format)
    input wire [WIDTH-1:0] b,     // Input B (Floating-point format)
    output reg [WIDTH-1:0] result // Result (Floating-point format)
);

    // Internal signals
    reg [EXP_WIDTH-1:0] exp_a, exp_b, exp_result;
    reg [MANT_WIDTH:0] mant_a, mant_b; // Includes implicit leading 1
    reg sign_a, sign_b, sign_result;
    reg [MANT_WIDTH:0] mant_b_inv;    // Inverse of mantissa B for division
    reg [2*MANT_WIDTH+1:0] temp_result; // Temporary result for division

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= {WIDTH{1'b0}}; // Clear result on reset
        end else begin
            // Split inputs into components
            sign_a = a[WIDTH-1];
            sign_b = b[WIDTH-1];
            exp_a = a[WIDTH-2:WIDTH-1-EXP_WIDTH];
            exp_b = b[WIDTH-2:WIDTH-1-EXP_WIDTH];
            mant_a = (exp_a == 0) ? {1'b0, a[MANT_WIDTH-1:0]} : {1'b1, a[MANT_WIDTH-1:0]};
            mant_b = (exp_b == 0) ? {1'b0, b[MANT_WIDTH-1:0]} : {1'b1, b[MANT_WIDTH-1:0]};

            // Calculate the result's exponent (exp_a - exp_b + bias)
            exp_result = exp_a - exp_b + ((1 << (EXP_WIDTH - 1)) - 1);

            // Calculate the result's sign
            sign_result = sign_a ^ sign_b;

            // Perform inverse operation for mantissa B
            mant_b_inv = (1 << MANT_WIDTH) / mant_b;

            // Perform division: mant_a / mant_b_inv
            temp_result = mant_a * mant_b_inv;

            // Directly assign the result without normalization
            result <= {sign_result, exp_result, temp_result[MANT_WIDTH-1:0]};
        end
    end
endmodule
