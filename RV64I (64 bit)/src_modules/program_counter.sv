// ============================================================================
// SUBMODULE: PROGRAM COUNTER (64-bit)
// ============================================================================
module Program_Counter (
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] pc_next,
    input  logic        halted,
    output logic [63:0] pc_current
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc_current <= 64'h0000000000000000;
        else if (!halted)
            pc_current <= pc_next;
    end
endmodule
