// ============================================================================
// SUB-SUBMODULE: MAIN DECODER (RV64I)
// ============================================================================
module Main_Decoder (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    output logic       branch,
    output logic       jump,
    output logic       alu_src,
    output logic       reg_write_en,
    output logic       mem_write_en,
    output logic       mem_read_en,
    output logic [1:0] result_src,
    output logic [2:0] imm_src,
    output logic [1:0] mem_size,
    output logic       mem_unsigned,
    output logic       word_op,
    output logic       halted
);
    // Opcode definitions
    localparam [6:0] OP_RTYPE  = 7'b0110011;  // R-type (64-bit ops)
    localparam [6:0] OP_RTYPE_W= 7'b0111011;  // R-type Word (32-bit ops on 64-bit regs)
    localparam [6:0] OP_ITYPE  = 7'b0010011;  // I-type (64-bit ops)
    localparam [6:0] OP_ITYPE_W= 7'b0011011;  // I-type Word (32-bit ops)
    localparam [6:0] OP_LOAD   = 7'b0000011;  // Load
    localparam [6:0] OP_STORE  = 7'b0100011;  // Store
    localparam [6:0] OP_BRANCH = 7'b1100011;  // Branch
    localparam [6:0] OP_JAL    = 7'b1101111;  // JAL
    localparam [6:0] OP_JALR   = 7'b1100111;  // JALR
    localparam [6:0] OP_LUI    = 7'b0110111;  // LUI
    localparam [6:0] OP_AUIPC  = 7'b0010111;  // AUIPC
    localparam [6:0] OP_SYSTEM = 7'b1110011;  // ECALL/EBREAK
    
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
        mem_size     = 2'b11;      // Default: doubleword
        mem_unsigned = 1'b0;
        word_op      = 1'b0;
        halted       = 1'b0;
        
        case (opcode)
            OP_RTYPE: begin
                reg_write_en = 1'b1;
                word_op      = 1'b0;  // 64-bit operation
            end
            
            OP_RTYPE_W: begin      // NEW: 32-bit ops on 64-bit registers
                reg_write_en = 1'b1;
                word_op      = 1'b1;  // 32-bit operation, sign-extend result
            end
            
            OP_ITYPE: begin
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b000;  // I-type
                word_op      = 1'b0;    // 64-bit
            end
            
            OP_ITYPE_W: begin      // NEW: ADDIW, SLLIW, etc.
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b000;  // I-type
                word_op      = 1'b1;    // 32-bit operation
            end
            
            OP_LOAD: begin
                reg_write_en = 1'b1;
                mem_read_en  = 1'b1;
                alu_src      = 1'b1;
                result_src   = 2'b01;   // Memory
                imm_src      = 3'b000;  // I-type
                // Decode memory size from funct3
                case (funct3)
                    3'b000: begin mem_size = 2'b00; mem_unsigned = 1'b0; end  // LB
                    3'b001: begin mem_size = 2'b01; mem_unsigned = 1'b0; end  // LH
                    3'b010: begin mem_size = 2'b10; mem_unsigned = 1'b0; end  // LW
                    3'b011: begin mem_size = 2'b11; mem_unsigned = 1'b0; end  // LD (64-bit)
                    3'b100: begin mem_size = 2'b00; mem_unsigned = 1'b1; end  // LBU
                    3'b101: begin mem_size = 2'b01; mem_unsigned = 1'b1; end  // LHU
                    3'b110: begin mem_size = 2'b10; mem_unsigned = 1'b1; end  // LWU (NEW)
                    default: mem_size = 2'b11;
                endcase
            end
            
            OP_STORE: begin
                mem_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b001;  // S-type
                // Decode memory size from funct3
                case (funct3)
                    3'b000: mem_size = 2'b00;  // SB
                    3'b001: mem_size = 2'b01;  // SH
                    3'b010: mem_size = 2'b10;  // SW
                    3'b011: mem_size = 2'b11;  // SD (64-bit, NEW)
                    default: mem_size = 2'b11;
                endcase
            end
            
            OP_BRANCH: begin
                branch  = 1'b1;
                imm_src = 3'b010;  // B-type
            end
            
            OP_JAL: begin
                reg_write_en = 1'b1;
                jump         = 1'b1;
                result_src   = 2'b10;  // PC+4
                imm_src      = 3'b011; // J-type
            end
            
            OP_JALR: begin
                reg_write_en = 1'b1;
                jump         = 1'b1;
                alu_src      = 1'b1;
                result_src   = 2'b10;  // PC+4
                imm_src      = 3'b000; // I-type
            end
            
            OP_LUI: begin
                reg_write_en = 1'b1;
                result_src   = 2'b11;  // Immediate
                imm_src      = 3'b100; // U-type
            end
            
            OP_AUIPC: begin
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                imm_src      = 3'b100; // U-type
            end
            
            OP_SYSTEM: begin
                halted = 1'b1;  // ECALL/EBREAK
            end
            
            default: begin
                // NOP
            end
        endcase
    end
endmodule