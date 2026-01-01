// ============================================================================
// SUBMODULE: DATA MEMORY
// ============================================================================
module Data_Memory (
    input  logic        clk,
    input  logic        we,            // Write enable
    input  logic        re,            // Read enable
    input  logic [31:0] addr,          // Address
    input  logic [31:0] data_w,        // Write data
    output logic [31:0] data_r,        // Read data
    output logic [31:0] gpio_out,      // GPIO output
    input  logic [31:0] gpio_in        // GPIO input
);
    logic [31:0] memory [0:255];       // 256 words = 1KB
    
    // Memory-mapped I/O addresses
    localparam [31:0] GPIO_OUT_ADDR = 32'hFFFFFFFC;
    localparam [31:0] GPIO_IN_ADDR  = 32'hFFFFFFF8;
    
    // Write operation
    always_ff @(posedge clk) begin
        if (we) begin
            if (addr == GPIO_OUT_ADDR)
                gpio_out <= data_w;
            else
                memory[addr[9:2]] <= data_w;
        end
    end
    
    // Read operation
    always_comb begin
        if (re) begin
            if (addr == GPIO_IN_ADDR)
                data_r = gpio_in;
            else
                data_r = memory[addr[9:2]];
        end
        else
            data_r = 32'b0;
    end
endmodule
