`include "controls.sv" 

module ALU (
  input logic signed [DATA_WIDTH-1:0] in_a, in_b,
  input logic [OP_SEL-1:0] operation,
  output logic signed [DATA_WIDTH-1:0] result,
  output logic zero_flag, negative_flag
);

  // Define parameters as localparam
  localparam DATA_WIDTH  = 32;
  localparam OP_SEL       = 4;

  always_comb begin
    unique case (operation)
      `ADD: result = in_a + in_b;
      `SUB: result = in_a - in_b;
      `SLL: result = in_a << $unsigned(in_b);
      `SRL: result = in_a >> $unsigned(in_b);
      `SRA: result = in_a >>> $unsigned(in_b);  // Arithmetic right shift retains MSB
      `AND: result = in_a & in_b;
      `OR: result = in_a | in_b;
      `XOR: result = in_a ^ in_b;
      `SLT: result = in_a < in_b;
      `SLTU: result = $unsigned(in_a) < $unsigned(in_b);
      `LOAD_A: result = in_a;
      `LOAD_B: result = in_b;
      `MUL: result = $unsigned(in_a) * $unsigned(in_b);
      default: result = 'b0;
    endcase
  end

  assign zero_flag = (result == 0);
  assign negative_flag = (result < 0);

endmodule
