// ============================================================================
// SUB-SUBMODULE: ALU DECODER (64-bit operations)
// ============================================================================
module ALU_Decoder (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_bit5,
    output logic [4:0] alu_control
);
    localparam [6:0] OP_RTYPE   = 7'b0110011;
    localparam [6:0] OP_RTYPE_W = 7'b0111011;
    localparam [6:0] OP_ITYPE   = 7'b0010011;
    localparam [6:0] OP_ITYPE_W = 7'b0011011;
    
    // ALU Control Encoding (5-bit for 64-bit ops):
    // 00000: ADD     00101: XOR     01010: MULH
    // 00001: SUB     00110: SRL     01011: MULHSU
    // 00010: SLL     00111: SRA     01100: MULHU
    // 00011: SLT     01000: OR      01101: DIV
    // 00100: SLTU    01001: AND     01110: DIVU
    //                               01111: REM
    //                               10000: REMU
    
    always_comb begin
        alu_control = 5'b00000;  // Default: ADD
        
        if (opcode == OP_RTYPE || opcode == OP_RTYPE_W || 
            opcode == OP_ITYPE || opcode == OP_ITYPE_W) begin
            case (funct3)
                3'b000: begin
                    // ADD/SUB
                    if ((opcode == OP_RTYPE || opcode == OP_RTYPE_W) && funct7_bit5)
                        alu_control = 5'b00001;  // SUB
                    else
                        alu_control = 5'b00000;  // ADD
                end
                3'b001: alu_control = 5'b00010;  // SLL
                3'b010: alu_control = 5'b00011;  // SLT
                3'b011: alu_control = 5'b00100;  // SLTU
                3'b100: alu_control = 5'b00101;  // XOR
                3'b101: begin
                    // SRL/SRA
                    if (funct7_bit5)
                        alu_control = 5'b00111;  // SRA
                    else
                        alu_control = 5'b00110;  // SRL
                end
                3'b110: alu_control = 5'b01000;  // OR
                3'b111: alu_control = 5'b01001;  // AND
            endcase
        end
    end
endmodule
