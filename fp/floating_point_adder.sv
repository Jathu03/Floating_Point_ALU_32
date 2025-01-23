module floating_point_adder #(
    parameter WIDTH = 32 // Fixed to 32 bits for single precision
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] a, // Input A (IEEE 754 format)
    input wire [WIDTH-1:0] b, // Input B (IEEE 754 format)
    output reg [WIDTH-1:0] result // Result (IEEE 754 format)
);

    // Parameters for single precision
    localparam EXP_WIDTH = 8;  // Exponent size
    localparam MANT_WIDTH = 23; // Mantissa size

    // Internal signals
    reg [EXP_WIDTH-1:0] exp_a, exp_b, exp_diff, exp_result;
    reg [MANT_WIDTH:0] mant_a, mant_b; // Mantissas with implicit leading 1
    reg sign_a, sign_b, sign_result;
    reg [MANT_WIDTH+1:0] mant_sum; // For intermediate addition result

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= 0;
        end else begin
            // Split inputs into components
            sign_a = a[WIDTH-1];
            sign_b = b[WIDTH-1];
            exp_a = a[WIDTH-2:WIDTH-1-EXP_WIDTH];
            exp_b = b[WIDTH-2:WIDTH-1-EXP_WIDTH];
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

            // Add or subtract mantissas based on signs
            if (sign_a == sign_b) begin
                mant_sum = mant_a + mant_b;
                sign_result = sign_a;
            end else if (mant_a >= mant_b) begin
                mant_sum = mant_a - mant_b;
                sign_result = sign_a;
            end else begin
                mant_sum = mant_b - mant_a;
                sign_result = sign_b;
            end

            // Directly construct the result without normalization
            result <= {sign_result, exp_result, mant_sum[MANT_WIDTH-1:0]};
        end
    end
endmodule
