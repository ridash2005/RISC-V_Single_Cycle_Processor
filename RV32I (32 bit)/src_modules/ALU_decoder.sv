// ============================================================================
// SUB-SUBMODULE: ALU DECODER
// ============================================================================
module ALU_Decoder (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_bit5,
    output logic [3:0] alu_control
);
    localparam [6:0] OP_RTYPE = 7'b0110011;
    localparam [6:0] OP_ITYPE = 7'b0010011;
    
    // ALU Control Encoding:
    // 0000: ADD    0101: XOR
    // 0001: SUB    0110: SRL
    // 0010: SLL    0111: SRA
    // 0011: SLT    1000: OR
    // 0100: SLTU   1001: AND
    
    always_comb begin
        alu_control = 4'b0000;  // Default: ADD
        
        if (opcode == OP_RTYPE || opcode == OP_ITYPE) begin
            case (funct3)
                3'b000: begin
                    // ADD/SUB (SUB only for R-type with funct7[5]=1)
                    if (opcode == OP_RTYPE && funct7_bit5)
                        alu_control = 4'b0001;  // SUB
                    else
                        alu_control = 4'b0000;  // ADD
                end
                3'b001: alu_control = 4'b0010;  // SLL
                3'b010: alu_control = 4'b0011;  // SLT
                3'b011: alu_control = 4'b0100;  // SLTU
                3'b100: alu_control = 4'b0101;  // XOR
                3'b101: begin
                    // SRL/SRA
                    if (funct7_bit5)
                        alu_control = 4'b0111;  // SRA
                    else
                        alu_control = 4'b0110;  // SRL
                end
                3'b110: alu_control = 4'b1000;  // OR
                3'b111: alu_control = 4'b1001;  // AND
            endcase
        end
        // For other instructions (LOAD, STORE, BRANCH, etc.), default ADD is fine
    end
endmodule