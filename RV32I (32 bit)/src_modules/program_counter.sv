// ============================================================================
// SUBMODULE: PROGRAM COUNTER
// ============================================================================
module Program_Counter (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc_next,
    input  logic        halted,
    output logic [31:0] pc_current
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc_current <= 32'h00000000;
        else if (!halted)
            pc_current <= pc_next;
    end
endmodule