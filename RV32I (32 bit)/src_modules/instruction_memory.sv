// ============================================================================
// SUBMODULE: INSTRUCTION MEMORY
// ============================================================================
module Instruction_Memory (
    input  logic        clk,
    input  logic        we,            // Write enable for loading
    input  logic [31:0] addr_w,        // Write address
    input  logic [31:0] data_w,        // Write data
    input  logic [31:0] addr_r,        // Read address (PC)
    output logic [31:0] data_r         // Instruction output
);
    logic [31:0] memory [0:1023];      // 1024 words = 4KB
    
    // Write port (for program loading)
    always_ff @(posedge clk) begin
        if (we)
            memory[addr_w[11:2]] <= data_w;
    end
    
    // Read port (combinational for instruction fetch)
    assign data_r = memory[addr_r[11:2]];
endmodule