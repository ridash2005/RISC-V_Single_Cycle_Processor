// ============================================================================
// SUBMODULE: IMMEDIATE GENERATOR (64-bit sign extension)
// ============================================================================
module Immediate_Generator (
    input  logic [31:0] instruction,
    input  logic [2:0]  imm_src,
    output logic [63:0] immediate      // 64-bit immediate
);
    always_comb begin
        case (imm_src)
            3'b000: begin  // I-type: sign-extend to 64-bit
                immediate = {{52{instruction[31]}}, instruction[31:20]};
            end
            
            3'b001: begin  // S-type
                immediate = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            
            3'b010: begin  // B-type
                immediate = {{51{instruction[31]}}, instruction[31], instruction[7], 
                             instruction[30:25], instruction[11:8], 1'b0};
            end
            
            3'b011: begin  // J-type
                immediate = {{43{instruction[31]}}, instruction[31], instruction[19:12], 
                             instruction[20], instruction[30:21], 1'b0};
            end
            
            3'b100: begin  // U-type
                immediate = {{32{instruction[31]}}, instruction[31:12], 12'b0};
            end
            
            default: immediate = 64'b0;
        endcase
    end
endmodule
