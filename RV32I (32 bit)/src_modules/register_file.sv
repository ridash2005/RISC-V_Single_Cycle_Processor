// ============================================================================
// SUBMODULE: REGISTER FILE
// ============================================================================
module Register_File (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,            // Write enable
    input  logic [4:0]  addr_r1,       // Read address 1
    input  logic [4:0]  addr_r2,       // Read address 2
    input  logic [4:0]  addr_w,        // Write address
    input  logic [31:0] data_w,        // Write data
    output logic [31:0] data_r1,       // Read data 1
    output logic [31:0] data_r2        // Read data 2
);
    logic [31:0] registers [0:31];
    
    // Initialize all registers to 0
    integer i;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (we && addr_w != 5'b0)  // x0 is hardwired to 0
            registers[addr_w] <= data_w;
    end
    
    // Asynchronous reads
    assign data_r1 = (addr_r1 == 5'b0) ? 32'b0 : registers[addr_r1];
    assign data_r2 = (addr_r2 == 5'b0) ? 32'b0 : registers[addr_r2];
endmodule