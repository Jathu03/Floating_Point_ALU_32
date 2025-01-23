module floating_point_subtractor #(
    parameter WIDTH = 32,          // Adjustable input/output width
    parameter EXP_WIDTH = 8,       // Width of the exponent field
    parameter MANT_WIDTH = 23      // Width of the mantissa field
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] a,       // Input A (IEEE 754 format)
    input wire [WIDTH-1:0] b,       // Input B (IEEE 754 format)
    output reg [WIDTH-1:0] result   // Result (IEEE 754 format)
);

    // Internal signals
    reg [EXP_WIDTH-1:0] exp_a, exp_b, exp_diff, exp_result;
    reg [MANT_WIDTH:0] mant_a, mant_b; // Include implicit leading 1
    reg sign_a, sign_b, sign_result;
    reg [MANT_WIDTH+1:0] temp_diff;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= {WIDTH{1'b0}}; // Clear result on reset
        end else begin
            // Split inputs into components
            sign_a = a[WIDTH-1];
            sign_b = b[WIDTH-1];
            exp_a = a[WIDTH-2:WIDTH-EXP_WIDTH-1]; // Exponent part of A
            exp_b = b[WIDTH-2:WIDTH-EXP_WIDTH-1]; // Exponent part of B
            mant_a = (exp_a == 0) ? {1'b0, a[MANT_WIDTH-1:0]} : {1'b1, a[MANT_WIDTH-1:0]};
            mant_b = (exp_b == 0) ? {1'b0, b[MANT_WIDTH-1:0]} : {1'b1, b[MANT_WIDTH-1:0]};

            // Align exponents
            if (exp_a > exp_b) begin
                exp_diff = exp_a - exp_b;
                mant_b = mant_b >> exp_diff;
                exp_result = exp_a;
            end else begin
                exp_diff = exp_b - exp_a;
                mant_a = mant_a >> exp_diff;
                exp_result = exp_b;
            end

            // Perform subtraction or addition of mantissas
            if (sign_a == sign_b) begin
                if (mant_a >= mant_b) begin
                    temp_diff = mant_a - mant_b;
                    sign_result = sign_a;
                end else begin
                    temp_diff = mant_b - mant_a;
                    sign_result = sign_b;
                end
            end else begin
                temp_diff = mant_a + mant_b;
                sign_result = sign_a;
            end

            // Directly assign the result without normalization
            result <= {sign_result, exp_result, temp_diff[MANT_WIDTH-1:0]};
        end
    end
endmodule
