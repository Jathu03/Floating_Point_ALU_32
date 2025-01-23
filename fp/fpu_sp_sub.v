module fpu_sp_sub(
    input clk,                // Clock signal
    input rst_n,              // Active-low reset signal
    input [31:0] din1,        // 32-bit floating-point input 1
    input [31:0] din2,        // 32-bit floating-point input 2
    input dval,               // Data valid signal
    output reg [31:0] result, // 32-bit floating-point result
    output reg rdy            // Ready signal to indicate the output is valid
);

  // Intermediate registers for storing results and states
  reg [31:0] s_output_z;  // Internal output register

  // State register
  reg [3:0] state;

  // State encoding
  parameter WAIT_REQ      = 4'd0,   // Waiting for input
            UNPACK        = 4'd1,   // Unpack input values
            SPECIAL_CASES = 4'd2,   // Handle special cases like NaN or infinity
            ALIGN         = 4'd3,   // Align the exponents
            ADD_0         = 4'd4,   // Perform addition or subtraction
            ADD_1         = 4'd5,   // Handle normalization of the result
            NORMALISE_1   = 4'd6,   // Normalize the result (step 1)
            NORMALISE_2   = 4'd7,   // Normalize the result (step 2)
            ROUND         = 4'd8,   // Round the result
            PACK          = 4'd9,   // Pack the result into IEEE 754 format
            OUT_RDY       = 4'd10;  // Output the result and signal ready

  // Registers for decomposing inputs and storing temporary results
  reg [31:0] a, b, z;               // Input and output floating-point numbers
  reg [26:0] a_m, b_m;              // Mantissas of inputs with extra bits for alignment
  reg [23:0] z_m;                   // Mantissa of the result
  reg [9:0] a_e, b_e, z_e;          // Exponents with extra bits for calculations
  reg a_s, b_s, z_s;                // Signs of inputs and result
  reg guard, round_bit, sticky;     // Additional bits for rounding
  reg [27:0] pre_sum;               // Sum or difference of mantissas

  // Main state machine to control the addition process
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset logic: initialize state and ready signal
      state <= WAIT_REQ;
      rdy <= 1'b0;
    end else begin
      // Main state machine
      case (state)
        WAIT_REQ: begin
          // Wait for valid input
          rdy <= 1'b0; // Clear ready signal
          if (dval) begin
            a <= din1;  // Load first input
            b <= din2;  // Load second input
            state <= UNPACK; // Move to unpack state
          end
        end

        UNPACK: begin
          // Unpack sign, exponent, and mantissa from inputs
          a_m <= {a[22:0], 3'b0};  // Extract mantissa of input a
          b_m <= {b[22:0], 3'b0};  // Extract mantissa of input b
          a_e <= a[30:23] - 127;   // Adjust exponent of a
          b_e <= b[30:23] - 127;   // Adjust exponent of b
          a_s <= a[31];            // Extract sign of a
          b_s <= ~b[31];            // Extract sign of b, invert it cuz this is subtraction
          state <= SPECIAL_CASES;  // Move to special cases state
        end

        SPECIAL_CASES: begin
          // Handle NaN, infinity, and zero cases
          if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
            // If either input is NaN, output NaN => Consider this as NaN for output - 7fc00000 - 0 11111111 10000000000000000000000
            z[31] <= 1'b0;
            z[30:23] <= 255;
            z[22] <= 1'b1;
            z[21:0] <= 0;
            state <= OUT_RDY;
          end else if (a_e == 128 && a_m == 0) begin
            // If a is infinity, return infinity with sign of a
            z[31] <= a_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            if ((b_e == 128 && b_m == 0) && (a_s != b_s)) begin
              // If b is also infinity and opposite signs, return NaN as 7fc00000 - 0 11111111 10000000000000000000000
              z[31] <= 1'b0;
              z[30:23] <= 255;
              z[22] <= 1'b1;
              z[21:0] <= 0;
            end
            state <= OUT_RDY;
          end else if (b_e == 128 && b_m == 0) begin
            // If b is infinity, return infinity with sign of b
            z[31] <= b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            state <= OUT_RDY;
          end else if (($signed(a_e) == -127 && a_m == 0) && ($signed(b_e) == -127 && b_m == 0)) begin
            // If both inputs are zero, return zero with appropriate sign
            z[31] <= a_s & b_s;
            z[30:23] <= b_e[7:0] + 127;
            z[22:0] <= b_m[26:3];
            state <= OUT_RDY;
          end else if (($signed(a_e) == -127) && (a_m == 0)) begin
            // If a is zero, return b
            z[31] <= b_s;
            z[30:23] <= b_e[7:0] + 127;
            z[22:0] <= b_m[26:3];
            state <= OUT_RDY;
          end else if (($signed(b_e) == -127) && (b_m == 0)) begin
            // If b is zero, return a
            z[31] <= a_s;
            z[30:23] <= a_e[7:0] + 127;
            z[22:0] <= a_m[26:3];
            state <= OUT_RDY;
          end else begin
            // Handle denormalized numbers by adjusting exponent and mantissa
            if ($signed(a_e) == -127) a_e <= -126; else a_m[26] <= 1'b1;
            if ($signed(b_e) == -127) b_e <= -126; else b_m[26] <= 1'b1;
            state <= ALIGN;
          end
        end

        ALIGN: begin
          // Align the exponents of a and b by shifting the mantissa of the smaller exponent
          if ($signed(a_e) > $signed(b_e)) begin
            b_e <= b_e + 1;
            b_m <= {1'b0, b_m[26:1]}; // Shift right
            b_m[0] <= b_m[1];         // Propagate sticky bit
          end else if ($signed(a_e) < $signed(b_e)) begin
            a_e <= a_e + 1;
            a_m <= {1'b0, a_m[26:1]}; // Shift right
            a_m[0] <= a_m[1];         // Propagate sticky bit
          end else begin
            state <= ADD_0; // Move to addition state
          end
        end

        ADD_0: begin
          // Perform addition or subtraction of the aligned mantissas
          z_e <= a_e; // Use the aligned exponent for the result
          if (a_s == b_s) begin
            pre_sum <= a_m + b_m; // Add mantissas if signs are the same
            z_s <= a_s;
          end else if (a_m >= b_m) begin
            pre_sum <= a_m - b_m; // Subtract mantissas if signs differ
            z_s <= a_s;
          end else begin
            pre_sum <= b_m - a_m;
            z_s <= b_s;
          end
          state <= ADD_1;
        end

        ADD_1: begin
          // Normalize and round the result
          if (pre_sum[27]) begin
            z_m <= pre_sum[27:4]; // Shift right if overflow
            guard <= pre_sum[3];
            round_bit <= pre_sum[2];
            sticky <= pre_sum[1] | pre_sum[0];
            z_e <= z_e + 1;
          end else begin
            z_m <= pre_sum[26:3];
            guard <= pre_sum[2];
            round_bit <= pre_sum[1];
            sticky <= pre_sum[0];
          end
          state <= NORMALISE_1;
        end

        NORMALISE_1: begin
          // Further normalize if needed by shifting left
          if (z_m[23] == 0 && $signed(z_e) > -126) begin
            z_e <= z_e - 1;
            z_m <= {z_m[22:0], guard}; // Shift left and update guard bit
            guard <= round_bit;
            round_bit <= 0;
          end else begin
            state <= NORMALISE_2;
          end
        end

        NORMALISE_2: begin
          // Handle denormalized numbers if exponent is too small
          if ($signed(z_e) < -126) begin
            z_e <= z_e + 1;
            z_m <= {1'b0, z_m[23:1]}; // Shift right
            guard <= z_m[0];
            round_bit <= guard;
            sticky <= sticky | round_bit;
          end else begin
            state <= ROUND;
          end
        end

        ROUND: begin
          // Round the result according to IEEE 754 rounding rules
          if (guard && (round_bit | sticky | z_m[0])) z_m <= z_m + 1; // Round up if needed
          if (z_m == 24'hffffff) z_e <= z_e + 1; // Handle mantissa overflow
          state <= PACK;
        end

        PACK: begin
          // Pack the result into IEEE 754 format
          z[22:0] <= z_m[22:0];         // Mantissa
          z[30:23] <= z_e[7:0] + 127;   // Exponent
          z[31] <= z_s;                 // Sign
          if ($signed(z_e) == -126 && z_m[23] == 0) z[30:23] <= 0; // Denormalize if needed
          if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) z[31] <= 1'b0; // Zero result fix
          if ($signed(z_e) > 127) begin // Handle overflow by setting to infinity
            z[22:0] <= 0;
            z[30:23] <= 255;
            z[31] <= z_s;
          end
          state <= OUT_RDY;
        end

        OUT_RDY: begin
          // Output the result and set ready signal
          rdy <= 1'b1;
          result <= z;
          state <= WAIT_REQ;
        end

      endcase
    end
  end

endmodule