
// ============================================================================
// SUB-SUBMODULE: BRANCH UNIT (Enhanced for 64-bit comparisons)
// ============================================================================
module Branch_Unit (
    input  logic       branch,
    input  logic [2:0] funct3,
    input  logic       alu_zero,
    input  logic [63:0] alu_result,    // Full ALU result for comparison
    output logic       branch_taken
);
    // Branch conditions (RV64I supports all 6 branch types):
    // BEQ  (000): Branch if Equal
    // BNE  (001): Branch if Not Equal
    // BLT  (100): Branch if Less Than (signed)
    // BGE  (101): Branch if Greater or Equal (signed)
    // BLTU (110): Branch if Less Than (unsigned)
    // BGEU (111): Branch if Greater or Equal (unsigned)
    
    always_comb begin
        branch_taken = 1'b0;
        
        if (branch) begin
            case (funct3)
                3'b000: branch_taken = alu_zero;           // BEQ: rs1 == rs2
                3'b001: branch_taken = ~alu_zero;          // BNE: rs1 != rs2
                3'b100: branch_taken = alu_result[0];      // BLT: rs1 < rs2 (signed)
                3'b101: branch_taken = ~alu_result[0] | alu_zero;  // BGE: rs1 >= rs2 (signed)
                3'b110: branch_taken = alu_result[0];      // BLTU: rs1 < rs2 (unsigned)
                3'b111: branch_taken = ~alu_result[0] | alu_zero;  // BGEU: rs1 >= rs2 (unsigned)
                default: branch_taken = 1'b0;
            endcase
        end
    end
endmodule