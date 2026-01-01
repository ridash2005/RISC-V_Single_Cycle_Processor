// ============================================================================
// SUBMODULE: IMMEDIATE GENERATOR
// ============================================================================
module Immediate_Generator (
    input  logic [31:0] instruction,
    input  logic [2:0]  imm_src,
    output logic [31:0] immediate
);
    // Immediate formats:
    // 000: I-type
    // 001: S-type
    // 010: B-type
    // 011: J-type
    // 100: U-type
    
    always_comb begin
        case (imm_src)
            3'b000: begin  // I-type: imm[11:0] = inst[31:20]
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            3'b001: begin  // S-type: imm[11:0] = {inst[31:25], inst[11:7]}
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            
            3'b010: begin  // B-type: imm[12:0] = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                             instruction[30:25], instruction[11:8], 1'b0};
            end
            
            3'b011: begin  // J-type: imm[20:0] = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                             instruction[20], instruction[30:21], 1'b0};
            end
            
            3'b100: begin  // U-type: imm[31:0] = {inst[31:12], 12'b0}
                immediate = {instruction[31:12], 12'b0};
            end
            
            default: immediate = 32'b0;
        endcase
    end
endmodule