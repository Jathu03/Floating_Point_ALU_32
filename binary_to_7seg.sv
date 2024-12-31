module disp_7seg (
    input logic [3:0] data_in,
    output logic [6:0] segments
);

    // Lookup table for digits 0-9
    localparam [9:0][6:0] lut_7seg = {
        7'b0111111, // 0
        7'b0000110, // 1
        7'b1011011, // 2
        7'b1001111, // 3
        7'b1100110, // 4
        7'b1101101, // 5
        7'b1111101, // 6
        7'b0000111, // 7
        7'b1111111, // 8
        7'b1101111  // 9
    };

    // Output assignment (inverting for common anode)
    assign segments = ~lut_7seg[data_in[3:0]];

endmodule
