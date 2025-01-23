module fpu_sp_div(
    input clk,               // Clock signal
    input rst_n,             // Active low reset signal
    input [31:0] din1,       // 32-bit input number 1 (dividend)
    input [31:0] din2,       // 32-bit input number 2 (divisor)
    input dval,              // Input valid signal
    output reg [31:0] result,// 32-bit division result (output)
    output reg rdy           // Output ready signal
);

    // Define internal state machine states
    reg [3:0] state;
    // State definitions for FSM (Finite State Machine)
    parameter WAIT_REQ      = 4'd0,   // Waiting for input data
              UNPACK        = 4'd1,   // Unpacking the input values
              SPECIAL_CASES = 4'd2,   // Handling special cases like NaN, Inf, etc.
              NORMALISE_A   = 4'd3,   // Normalize the mantissa of input A
              NORMALISE_B   = 4'd4,   // Normalize the mantissa of input B
              DIVIDE_0      = 4'd5,   // Prepare for division
              DIVIDE_1      = 4'd6,   // First step of long division
              DIVIDE_2      = 4'd7,   // Continue long division
              DIVIDE_3      = 4'd8,   // Finalize quotient
              NORMALISE_1   = 4'd9,   // Normalize result after division
              NORMALISE_2   = 4'd10,  // Further normalization if necessary
              ROUND         = 4'd11,  // Round the result
              PACK          = 4'd12,  // Pack result back into IEEE 754 format
              OUT_RDY       = 4'd13;  // Output result ready state

    // Internal registers for floating-point components
    reg [31:0] a, b, z;                // Raw inputs (a, b) and result (z)
    reg [23:0] a_m, b_m, z_m;          // Mantissas of a, b, and result
    reg [9:0] a_e, b_e, z_e;           // Exponents of a, b, and result
    reg a_s, b_s, z_s;                 // Sign bits of a, b, and result
    reg guard, round_bit, sticky;      // Rounding control bits
    reg [50:0] quotient, divisor, dividend, remainder; // Division components
    reg [5:0] count;                   // Counter for division loop

    // Main FSM logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT_REQ;         // Reset: go to initial state
            rdy <= 1'b0;               // Output not ready during reset
        end else begin
            case (state)

                // WAIT_REQ: Wait for valid data input
                WAIT_REQ: begin
                    rdy <= 1'b0;       // Output is not ready yet
                    if (dval) begin    // If data is valid, capture the inputs
                        a <= din1;
                        b <= din2;
                        state <= UNPACK; // Move to UNPACK state
                    end
                end

                // UNPACK: Extract the sign, exponent, and mantissa from IEEE 754 format
                UNPACK: begin
                    a_m <= a[22:0];    // Extract mantissa of input A
                    b_m <= b[22:0];    // Extract mantissa of input B
                    a_e <= a[30:23] - 127; // Extract and unbias exponent of A
                    b_e <= b[30:23] - 127; // Extract and unbias exponent of B
                    a_s <= a[31];      // Extract sign of A
                    b_s <= b[31];      // Extract sign of B
                    state <= SPECIAL_CASES; // Check for special cases
                end

                // SPECIAL_CASES: Handle NaN, infinity, and zero cases
                SPECIAL_CASES: begin
                    if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
                        // Case: NaN (Not a Number) result
                        z[31] <= 1'b0; // NaN sign is 0
                        z[30:23] <= 8'd255; // Exponent all 1's for NaN
                        z[22] <= 1'b1; // Mantissa non-zero for NaN
                        z[21:0] <= 22'd0; // Rest of mantissa is 0
                        state <= OUT_RDY; // Move to output ready state
                    end else if ((a_e == 128 && a_m == 0) && (b_e == 128 && b_m == 0)) begin
                        // Case: a and b both infinity (Inf/Inf = NaN)
                        z[31] <= 1'b0; // NaN sign is zero
                        z[30:23] <= 8'd255;
                        z[22] <= 1'b1;
                        z[21:0] <= 22'd0;
                        state <= OUT_RDY;
                    end else if (a_e == 128 && a_m == 0) begin
                        // Case: a is infinity (result is infinity)
                        z[31] <= a_s ^ b_s; // Result sign is XOR of a and b signs
                        z[30:23] <= 8'd255; // Exponent all 1's for infinity
                        z[22:0] <= 23'd0; // Mantissa is 0 for infinity
                        state <= OUT_RDY;
                    end else if (($signed(b_e) == -127 && b_m == 0) && !($signed(a_e) == -127 && a_m == 0))  begin
                        // Case: b is zero but a is non zero (infinity result for divide by zero)
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 8'd255;
                        z[22:0] <= 22'd0;
                        state <= OUT_RDY;
                    end else if (b_e == 128) begin
                        // Case: b is infinity (result is zero)
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 8'd0;
                        z[22:0] <= 23'd0;
                        state <= OUT_RDY;
                    end else if (($signed(a_e) == -127 && a_m == 0) && !($signed(b_e) == -127 && b_m == 0)) begin
                        // Case: a is zero but b is non zero (result is zero)
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 8'd0;
                        z[22:0] <= 23'd0;
                        state <= OUT_RDY;
						  end else if (($signed(a_e) == -127 && a_m == 0) && ($signed(b_e) == -127 && b_m == 0)) begin
								// Case: a and b both are zero (result is NaN with sign as 0)
								z[31] <= 1'b0; // NaN sign is zero
                        z[30:23] <= 8'd255;
                        z[22] <= 1'b1;
                        z[21:0] <= 22'd0;
                        state <= OUT_RDY;
                    end else begin
                        // Normal cases: process further
                        if ($signed(a_e) == -127) a_e <= -126;
                        else a_m[23] <= 1'b1; // Set hidden bit for normalized A

                        if ($signed(b_e) == -127) b_e <= -126;
                        else b_m[23] <= 1'b1; // Set hidden bit for normalized B

                        state <= NORMALISE_A;
                    end
                end

                // NORMALISE_A: Normalize mantissa of input A
                NORMALISE_A: begin
                    if (a_m[23]) state <= NORMALISE_B; // Already normalized
                    else begin
                        a_m <= a_m << 1;   // Shift mantissa left to normalize
                        a_e <= a_e - 1;    // Decrement exponent to match
                    end
                end

                // NORMALISE_B: Normalize mantissa of input B
                NORMALISE_B: begin
                    if (b_m[23]) state <= DIVIDE_0; // Already normalized
                    else begin
                        b_m <= b_m << 1;   // Shift mantissa left to normalize
                        b_e <= b_e - 1;    // Decrement exponent to match
                    end
                end

                // DIVIDE_0: Prepare for division by setting up initial values
                DIVIDE_0: begin
                    z_s <= a_s ^ b_s;     // Result sign is XOR of a and b signs
                    z_e <= a_e - b_e;     // Subtract exponents
                    quotient <= 0;        // Initialize quotient
                    remainder <= 0;       // Initialize remainder
                    count <= 0;           // Initialize iteration counter
                    dividend <= a_m << 27; // Prepare dividend
                    divisor <= b_m;       // Prepare divisor
                    state <= DIVIDE_1;    // Start division process
                end

                // DIVIDE_1: Perform long division (shift left)
                DIVIDE_1: begin
                    quotient <= quotient << 1; // Shift quotient left
                    remainder <= remainder << 1; // Shift remainder left
                    remainder[0] <= dividend[50]; // Add bit from dividend
                    dividend <= dividend << 1;   // Shift dividend left
                    state <= DIVIDE_2;           // Move to next step
                end

                // DIVIDE_2: Continue long division and check for completion
                DIVIDE_2: begin
                    if (remainder >= divisor) begin
                        quotient[0] <= 1'b1;    // Set quotient bit to 1
                        remainder <= remainder - divisor; // Subtract divisor
                    end
                    if (count == 49) state <= DIVIDE_3; // Done dividing
                    else begin
                        count <= count + 1;    // Increment counter
                        state <= DIVIDE_1;     // Continue division
                    end
                end

                // DIVIDE_3: Finalize division result and prepare for normalization
                DIVIDE_3: begin
                    z_m <= quotient[26:3];     // Truncate quotient for mantissa
                    guard <= quotient[2];      // Set guard bit for rounding
                    round_bit <= quotient[1];  // Set rounding bit
                    sticky <= quotient[0] | (remainder != 0); // Set sticky bit
                    state <= NORMALISE_1;      // Normalize result
                end

                // NORMALISE_1: Normalize result mantissa if necessary
                NORMALISE_1: begin
                    if (z_m[23] == 0 && $signed(z_e) > -126) begin
                        z_e <= z_e - 1;    // Adjust exponent
                        z_m <= z_m << 1;   // Shift mantissa left
                        z_m[0] <= guard;   // Handle guard bit
                        guard <= round_bit;
                        round_bit <= 0;
                    end else state <= NORMALISE_2;
                end

                // NORMALISE_2: Further normalization to ensure correct exponent range
                NORMALISE_2: begin
                    if ($signed(z_e) < -126) begin
                        z_e <= z_e + 1;    // Increment exponent
                        z_m <= z_m >> 1;   // Shift mantissa right
                        guard <= z_m[0];   // Adjust guard bit
                        round_bit <= guard;
                        sticky <= sticky | round_bit; // Combine sticky bit
                    end else state <= ROUND;
                end

                // ROUND: Perform rounding based on guard, round, and sticky bits
                ROUND: begin
                    if (guard && (round_bit | sticky | z_m[0])) begin
                        z_m <= z_m + 1;    // Round up if necessary
                        if (z_m == 24'hffffff) z_e <= z_e + 1; // Handle overflow
                    end
                    state <= PACK;
                end

                // PACK: Pack the result back into IEEE 754 format
                PACK: begin
                    z[22:0] <= z_m[22:0];  // Set mantissa
                    z[30:23] <= z_e[7:0] + 127; // Set biased exponent
                    z[31] <= z_s;         // Set sign bit

                    if ($signed(z_e) == -126 && z_m[23] == 0) z[30:23] <= 8'd0; // Denormalized case

                    if ($signed(z_e) > 127) begin
                        z[22:0] <= 23'd0;  // Overflow: Set mantissa to 0
                        z[30:23] <= 8'd255; // Set exponent to infinity
                        z[31] <= z_s;      // Set sign bit
                    end
                    state <= OUT_RDY;
                end

                // OUT_RDY: Output the result and go back to waiting for input
                OUT_RDY: begin
                    rdy <= 1'b1;          // Set ready signal
                    result <= z;          // Output the result
                    state <= WAIT_REQ;    // Go back to waiting for new inputs
                end

            endcase
        end
    end
endmodule
