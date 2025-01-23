module fpu_sp_top(
    input          clk,        // Clock signal
    input          rst_n,      // Active-low reset signal
    input  [3:0]   cmd,        // Command signal to select the operation
    input  [31:0]  din1,       // First 32-bit floating-point input
    input  [31:0]  din2,       // Second 32-bit floating-point input
    input          dval,       // Data valid signal
    output [31:0]  result,     // 32-bit floating-point result
    output         rdy         // Ready signal indicating operation completion
);

//--------------------------------------------------
// Local Signals for Single Precision Operations
//--------------------------------------------------

// Signals for addition operation
wire        sp_add_rdy;        // Ready signal for addition module
wire [31:0] sp_add_result;     // Result from addition module

// Signals for subtraction operation
wire        sp_sub_rdy;        // Ready signal for subtraction module
wire [31:0] sp_sub_result;     // Result from subtraction module

// Signals for multiplication operation
wire        sp_mul_rdy;        // Ready signal for multiplication module
wire [31:0] sp_mul_result;     // Result from multiplication module

// Signals for division operation
wire        sp_div_rdy;        // Ready signal for division module
wire [31:0] sp_div_result;     // Result from division module

//--------------------------------------------------
// Control Signals to Enable Specific Modules
//--------------------------------------------------

// Enable signal for addition module, active when `cmd` indicates addition
wire sp_add_dval = (dval) & (cmd == 4'b0001); // CMD_FPU_SP_ADD

// Enable signal for subtraction module, active when `cmd` indicates subtraction
wire sp_sub_dval = (dval) & (cmd == 4'b0010); // CMD_FPU_SP_SUB

// Enable signal for multiplication module, active when `cmd` indicates multiplication
wire sp_mul_dval = (dval) & (cmd == 4'b0011); // CMD_FPU_SP_MUL

// Enable signal for division module, active when `cmd` indicates division
wire sp_div_dval = (dval) & (cmd == 4'b0100); // CMD_FPU_SP_DIV

//--------------------------------------------------
// Ready and Result Signal Assignment
//--------------------------------------------------

// Assign the `rdy` output based on the active module's ready signal
assign rdy = (cmd == 4'b0001) ? sp_add_rdy    : // Addition module ready
             (cmd == 4'b0010) ? sp_sub_rdy    : // Subtraction module ready
             (cmd == 4'b0011) ? sp_mul_rdy    : // Multiplication module ready
             (cmd == 4'b0100) ? sp_div_rdy    : // Division module ready
             1'b0;                             // Default: not ready

// Assign the `result` output based on the active module's result
assign result = (cmd == 4'b0001) ? sp_add_result : // Result from addition module
                (cmd == 4'b0010) ? sp_sub_result : // Result from subtraction module
                (cmd == 4'b0011) ? sp_mul_result : // Result from multiplication module
                (cmd == 4'b0100) ? sp_div_result : // Result from division module
                32'b0;                             // Default: zero

//--------------------------------------------------
// Module Instantiations
//--------------------------------------------------

// Floating Point Addition Module
fpu_sp_add u_sp_add (
    .clk    (clk),             // Clock signal
    .rst_n  (rst_n),           // Reset signal
    .din1   (din1),            // First input operand
    .din2   (din2),            // Second input operand
    .dval   (sp_add_dval),     // Data valid signal for addition
    .result (sp_add_result),   // Result of addition
    .rdy    (sp_add_rdy)       // Ready signal for addition
);

// Floating Point Subtraction Module
fpu_sp_sub u_sp_sub (
    .clk    (clk),             // Clock signal
    .rst_n  (rst_n),           // Reset signal
    .din1   (din1),            // First input operand
    .din2   (din2),            // Second input operand
    .dval   (sp_sub_dval),     // Data valid signal for subtraction
    .result (sp_sub_result),   // Result of subtraction
    .rdy    (sp_sub_rdy)       // Ready signal for subtraction
);

// Floating Point Multiplication Module
fpu_sp_mul u_sp_mul (
    .clk    (clk),             // Clock signal
    .rst_n  (rst_n),           // Reset signal
    .din1   (din1),            // First input operand
    .din2   (din2),            // Second input operand
    .dval   (sp_mul_dval),     // Data valid signal for multiplication
    .result (sp_mul_result),   // Result of multiplication
    .rdy    (sp_mul_rdy)       // Ready signal for multiplication
);

// Floating Point Division Module
fpu_sp_div u_sp_div (
    .clk    (clk),             // Clock signal
    .rst_n  (rst_n),           // Reset signal
    .din1   (din1),            // First input operand
    .din2   (din2),            // Second input operand
    .dval   (sp_div_dval),     // Data valid signal for division
    .result (sp_div_result),   // Result of division
    .rdy    (sp_div_rdy)       // Ready signal for division
);

endmodule
