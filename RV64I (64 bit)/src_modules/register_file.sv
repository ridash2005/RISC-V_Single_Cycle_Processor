// ============================================================================
// SUBMODULE: REGISTER FILE (64-bit)
// ============================================================================
module Register_File (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,
    input  logic [4:0]  addr_r1,
    input  logic [4:0]  addr_r2,
    input  logic [4:0]  addr_w,
    input  logic [63:0] data_w,        // 64-bit write data
    output logic [63:0] data_r1,       // 64-bit read data 1
    output logic [63:0] data_r2        // 64-bit read data 2
);
    logic [63:0] registers [0:31];     // 32 x 64-bit registers
    
    integer i;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 64'b0;
        end
        else if (we && addr_w != 5'b0)
            registers[addr_w] <= data_w;
    end
    
    assign data_r1 = (addr_r1 == 5'b0) ? 64'b0 : registers[addr_r1];
    assign data_r2 = (addr_r2 == 5'b0) ? 64'b0 : registers[addr_r2];
endmodule