module floating_point_adder (
    input wire clk,
    input wire reset,
    input wire [31:0] a, // Input A (IEEE 754 format)
    input wire [31:0] b, // Input B (IEEE 754 format)
    output reg [31:0] result // Result (IEEE 754 format)
);

    // Internal signals
    reg [7:0] exp_a, exp_b, exp_diff;
    reg [23:0] mant_a, mant_b, mant_sum;
    reg sign_a, sign_b, sign_result;
    reg [7:0] exp_result;
    reg [24:0] temp_sum;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= 32'b0;
        end else begin
            // Split inputs into components
            sign_a = a[31];
            sign_b = b[31];
            exp_a = a[30:23];
            exp_b = b[30:23];
            mant_a = {1'b1, a[22:0]}; // Add implicit leading 1
            mant_b = {1'b1, b[22:0]}; // Add implicit leading 1

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

            // Perform addition/subtraction of mantissas
            if (sign_a == sign_b) begin
                temp_sum = mant_a + mant_b;
                sign_result = sign_a;
            end else if (mant_a >= mant_b) begin
                temp_sum = mant_a - mant_b;
                sign_result = sign_a;
            end else begin
                temp_sum = mant_b - mant_a;
                sign_result = sign_b;
            end

            // Normalize the result
            if (temp_sum[24]) begin
                mant_sum = temp_sum[24:1];
                exp_result = exp_result + 1;
            end else begin
                mant_sum = temp_sum[23:0];
            end

            // Remove implicit 1 and round
            result <= {sign_result, exp_result, mant_sum[22:0]};
        end
    end
endmodule
