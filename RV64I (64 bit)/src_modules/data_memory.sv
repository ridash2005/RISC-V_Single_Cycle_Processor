// ============================================================================
// SUBMODULE: DATA MEMORY (64-bit with various access sizes)
// ============================================================================
module Data_Memory (
    input  logic        clk,
    input  logic        we,
    input  logic        re,
    input  logic [63:0] addr,
    input  logic [63:0] data_w,
    input  logic [1:0]  mem_size,      // 00=byte, 01=half, 10=word, 11=double
    input  logic        mem_unsigned,
    output logic [63:0] data_r,
    output logic [63:0] gpio_out,
    input  logic [63:0] gpio_in
);
    logic [63:0] memory [0:255];       // 256 x 64-bit = 2KB
    
    // Memory-mapped I/O addresses
    localparam [63:0] GPIO_OUT_ADDR = 64'hFFFFFFFFFFFFFFF8;
    localparam [63:0] GPIO_IN_ADDR  = 64'hFFFFFFFFFFFFFFF0;
    
    // Write operation
    always_ff @(posedge clk) begin
        if (we) begin
            if (addr == GPIO_OUT_ADDR)
                gpio_out <= data_w;
            else begin
                case (mem_size)
                    2'b00: memory[addr[10:3]][7:0]   <= data_w[7:0];   // SB
                    2'b01: memory[addr[10:3]][15:0]  <= data_w[15:0];  // SH
                    2'b10: memory[addr[10:3]][31:0]  <= data_w[31:0];  // SW
                    2'b11: memory[addr[10:3]]        <= data_w;        // SD
                endcase
            end
        end
    end
    
    // Read operation
    logic [63:0] mem_data;
    always_comb begin
        if (re) begin
            if (addr == GPIO_IN_ADDR)
                mem_data = gpio_in;
            else
                mem_data = memory[addr[10:3]];
            
            // Extract and sign/zero extend based on size
            case (mem_size)
                2'b00: begin  // Byte
                    if (mem_unsigned)
                        data_r = {56'b0, mem_data[7:0]};              // LBU
                    else
                        data_r = {{56{mem_data[7]}}, mem_data[7:0]};  // LB
                end
                2'b01: begin  // Halfword
                    if (mem_unsigned)
                        data_r = {48'b0, mem_data[15:0]};              // LHU
                    else
                        data_r = {{48{mem_data[15]}}, mem_data[15:0]}; // LH
                end
                2'b10: begin  // Word
                    if (mem_unsigned)
                        data_r = {32'b0, mem_data[31:0]};              // LWU (NEW for RV64)
                    else
                        data_r = {{32{mem_data[31]}}, mem_data[31:0]}; // LW
                end
                2'b11: data_r = mem_data;                              // LD (Doubleword)
            endcase
        end
        else
            data_r = 64'b0;
    end
endmodule