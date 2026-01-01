// ============================================================================
// SUB-SUBMODULE: MAIN DECODER
// ============================================================================
module Main_Decoder (
    input  logic [6:0] opcode,
    output logic       branch,
    output logic       jump,
    output logic       alu_src,
    output logic       reg_write_en,
    output logic       mem_write_en,
    output logic       mem_read_en,
    output logic [1:0] result_src,
    output logic [2:0] imm_src,
    output logic       halted
);
    // Opcode definitions
    localparam [6:0] OP_RTYPE  = 7'b0110011;
    localparam [6:0] OP_ITYPE  = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;
    localparam [6:0] OP_SYSTEM = 7'b1110011;
    
    always_comb begin
        // Default values
        reg_write_en = 1'b0;
        mem_write_en = 1'b0;
        mem_read_en  = 1'b0;
        alu_src      = 1'b0;
        result_src   = 2'b00;
        branch       = 1'b0;
        jump         = 1'b0;
        imm_src      = 3'b000;
        halted       = 1'b0;
        
        case (opcode)
            OP_RTYPE: begin
                reg_write_en = 1'b1;
                // alu_src = 0, result_src = 00, imm_src = don't care
            end
            
            OP_ITYPE: begin
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b000;  // I-type
            end
            
            OP_LOAD: begin
                reg_write_en = 1'b1;
                mem_read_en  = 1'b1;
                alu_src      = 1'b1;
                result_src   = 2'b01;   // Memory
                imm_src      = 3'b000;  // I-type
            end
            
            OP_STORE: begin
                mem_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b001;  // S-type
            end
            
            OP_BRANCH: begin
                branch  = 1'b1;
                imm_src = 3'b010;       // B-type
            end
            
            OP_JAL: begin
                reg_write_en = 1'b1;
                jump         = 1'b1;
                result_src   = 2'b10;   // PC+4
                imm_src      = 3'b011;  // J-type
            end
            
            OP_JALR: begin
                reg_write_en = 1'b1;
                jump         = 1'b1;
                alu_src      = 1'b1;
                result_src   = 2'b10;   // PC+4
                imm_src      = 3'b000;  // I-type
            end
            
            OP_LUI: begin
                reg_write_en = 1'b1;
                result_src   = 2'b11;   // Immediate
                imm_src      = 3'b100;  // U-type
            end
            
            OP_AUIPC: begin
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b100;  // U-type
            end
            
            OP_SYSTEM: begin
                halted = 1'b1;          // ECALL/EBREAK
            end
            
            default: begin
                // NOP - all zeros
            end
        endcase
    end
endmodule