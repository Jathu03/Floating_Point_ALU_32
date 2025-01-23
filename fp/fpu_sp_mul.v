module fpu_sp_mul(
    input clk,                   // Clock signal
    input rst_n,                 // Active-low reset signal
    input [31:0] din1,           // 32-bit input operand 1
    input [31:0] din2,           // 32-bit input operand 2
    input dval,                  // Data valid signal to start multiplication
    output reg [31:0] result,    // 32-bit output result of multiplication
    output reg rdy               // Ready signal indicating output is valid
);

    // Internal state registers and parameters for state encoding
    reg [3:0] state;
    parameter WAIT_REQ = 4'd0,
              UNPACK = 4'd1,
              SPECIAL_CASES = 4'd2,
              NORMALISE_A = 4'd3,
              NORMALISE_B = 4'd4,
              MULTIPLY_0 = 4'd5,
              MULTIPLY_1 = 4'd6,
              NORMALISE_1 = 4'd7,
              NORMALISE_2 = 4'd8,
              ROUND = 4'd9,
              PACK = 4'd10,
              OUT_RDY = 4'd11;

    // Registers for intermediate values and calculations
    reg [31:0] a, b, z;          // Inputs 'a' and 'b' and result 'z'
    reg [23:0] a_m, b_m, z_m;    // Mantissa parts of inputs and result
    reg [9:0] a_e, b_e, z_e;     // Exponent parts of inputs and result
    reg a_s, b_s, z_s;           // Sign bits of inputs and result
    reg guard, round_bit, sticky;// Rounding bits for final result
    reg [47:0] product;          // Intermediate product of mantissas

    // State machine for floating-point multiplication
    always @(negedge rst_n or posedge clk) begin
        if (rst_n == 0) begin
            // Reset state: Initialize to WAIT_REQ
            state <= WAIT_REQ;
            rdy <= 1'b0;
        end else begin
            case (state)
                WAIT_REQ: begin
                    // Waiting for valid input data
                    rdy <= 1'b0;
                    if (dval) begin
                        // Load inputs and move to UNPACK state
                        a <= din1;
                        b <= din2;
                        state <= UNPACK;
                    end
                end

                UNPACK: begin
                    // Extract sign, exponent, and mantissa from inputs
                    a_m <= a[22:0];
                    b_m <= b[22:0];
                    a_e <= a[30:23] - 127; // Adjust exponent with bias
                    b_e <= b[30:23] - 127;
                    a_s <= a[31];
                    b_s <= b[31];
                    state <= SPECIAL_CASES;
                end

                SPECIAL_CASES: begin
                    // Handle NaN and Infinity special cases
                    if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
                        // Return NaN if either input is NaN ( NaN = ffc00000 [0 11111111 10000000000000000000000])
								// We will consider sign bit 0 for the NaN
                        z[31] <= 0;
                        z[30:23] <= 255;
                        z[22] <= 1;
                        z[21:0] <= 0;
                        state <= OUT_RDY;
                    end else if (a_e == 128 && a_m == 0) begin
                        // Return infinity if a is infinity (+Infinity = 7f800000 [0 1111 1111 00000000000000000000000])
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        if ((($signed(b_e) == -127) && (b_m == 0)) || (b_e == 128 && b_m == 0)) begin
                            // Return NaN if b is zero or infinity
                            z[31] <= 0;
                            z[30:23] <= 255;
                            z[22] <= 1;
                            z[21:0] <= 0;
                        end
                        state <= OUT_RDY;
                    end else if (b_e == 128) begin
                        // Return infinity if b is infinity
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        if ((($signed(a_e) == -127) && (a_m == 0)) || (a_e == 128 && a_m == 0) ) begin
                            // Return NaN if a is zero or infinity
                            z[31] <= 0;
                            z[30:23] <= 255;
                            z[22] <= 1;
                            z[21:0] <= 0;
                        end
                        state <= OUT_RDY;
                    end else if (($signed(a_e) == -127) && (a_m == 0)) begin
                        // Return zero if a is zero
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 0;
                        z[22:0] <= 0;
                        state <= OUT_RDY;
                    end else if (($signed(b_e) == -127) && (b_m == 0)) begin
                        // Return zero if b is zero
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 0;
                        z[22:0] <= 0;
                        state <= OUT_RDY;
                    end else begin
                        // Normalize denormalized numbers
                        if ($signed(a_e) == -127) begin
                            a_e <= -126;
                        end else begin
                            a_m[23] <= 1;
                        end
                        if ($signed(b_e) == -127) begin
                            b_e <= -126;
                        end else begin
                            b_m[23] <= 1;
                        end
                        state <= NORMALISE_A;
                    end
                end

                NORMALISE_A: begin
                    // Normalize mantissa of a if needed
                    if (a_m[23]) begin
                        state <= NORMALISE_B;
                    end else begin
                        a_m <= a_m << 1;
                        a_e <= a_e - 1;
                    end
                end

                NORMALISE_B: begin
                    // Normalize mantissa of b if needed
                    if (b_m[23]) begin
                        state <= MULTIPLY_0;
                    end else begin
                        b_m <= b_m << 1;
                        b_e <= b_e - 1;
                    end
                end

                MULTIPLY_0: begin
                    // Multiply mantissas and calculate exponent
                    z_s <= a_s ^ b_s;
                    z_e <= a_e + b_e + 1;
                    product <= a_m * b_m;
                    state <= MULTIPLY_1;
                end

                MULTIPLY_1: begin
                    // Extract result mantissa and rounding bits
                    z_m <= product[47:24];
                    guard <= product[23];
                    round_bit <= product[22];
                    sticky <= (product[21:0] != 0);
                    state <= NORMALISE_1;
                end

                NORMALISE_1: begin
                    // Normalize result mantissa if needed
                    if (z_m[23] == 0) begin
                        z_e <= z_e - 1;
                        z_m <= z_m << 1;
                        z_m[0] <= guard;
                        guard <= round_bit;
                        round_bit <= 0;
                    end else begin
                        state <= NORMALISE_2;
                    end
                end

                NORMALISE_2: begin
                    // Handle cases where exponent is below range
                    if ($signed(z_e) < -126) begin
                        z_e <= z_e + 1;
                        z_m <= z_m >> 1;
                        guard <= z_m[0];
                        round_bit <= guard;
                        sticky <= sticky | round_bit;
                    end else begin
                        state <= ROUND;
                    end
                end

                ROUND: begin
                    // Round the result according to IEEE 754 rules
                    if (guard && (round_bit | sticky | z_m[0])) begin
                        z_m <= z_m + 1;
                        if (z_m == 24'hffffff) begin
                            z_e <= z_e + 1;
                        end
                    end
                    state <= PACK;
                end

                PACK: begin
                    // Pack sign, exponent, and mantissa into final result
                    z[22:0] <= z_m[22:0];
                    z[30:23] <= z_e[7:0] + 127;
                    z[31] <= z_s;
                    if ($signed(z_e) == -126 && z_m[23] == 0) begin
                        z[30:23] <= 0;
                    end
                    if ($signed(z_e) > 127) begin
                        z[22:0] <= 0;
                        z[30:23] <= 255;
                        z[31] <= z_s;
                    end
                    state <= OUT_RDY;
                end

                OUT_RDY: begin
                    // Set output valid and result signals
                    rdy <= 1'b1;
                    result <= z;
                    state <= WAIT_REQ;
                end
            endcase
        end
    end

endmodule
