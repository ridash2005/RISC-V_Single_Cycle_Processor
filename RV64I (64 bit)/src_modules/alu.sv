// ============================================================================
// SUBMODULE: ALU (64-bit Arithmetic Logic Unit)
// ============================================================================
module ALU (
    input  logic [63:0] operand_a,
    input  logic [63:0] operand_b,
    input  logic [4:0]  alu_control,
    input  logic        word_op,       // 1=32-bit operation, 0=64-bit
    output logic [63:0] result,
    output logic        zero
);
    logic [63:0] alu_result;
    logic [31:0] word_result;
    
    always_comb begin
        if (word_op) begin
            // 32-bit operations on lower 32 bits
            case (alu_control)
                5'b00000: word_result = operand_a[31:0] + operand_b[31:0];  // ADDW
                5'b00001: word_result = operand_a[31:0] - operand_b[31:0];  // SUBW
                5'b00010: word_result = operand_a[31:0] << operand_b[4:0];  // SLLW
                5'b00110: word_result = operand_a[31:0] >> operand_b[4:0];  // SRLW
                5'b00111: word_result = $signed(operand_a[31:0]) >>> operand_b[4:0];  // SRAW
                default:  word_result = 32'b0;
            endcase
            // Sign-extend 32-bit result to 64-bit
            alu_result = {{32{word_result[31]}}, word_result};
        end
        else begin
            // Full 64-bit operations
            case (alu_control)
                5'b00000: alu_result = operand_a + operand_b;                      // ADD
                5'b00001: alu_result = operand_a - operand_b;                      // SUB
                5'b00010: alu_result = operand_a << operand_b[5:0];                // SLL (6 bits for 64-bit)
                5'b00011: alu_result = $signed(operand_a) < $signed(operand_b);    // SLT
                5'b00100: alu_result = operand_a < operand_b;                      // SLTU
                5'b00101: alu_result = operand_a ^ operand_b;                      // XOR
                5'b00110: alu_result = operand_a >> operand_b[5:0];                // SRL (6 bits for 64-bit)
                5'b00111: alu_result = $signed(operand_a) >>> operand_b[5:0];      // SRA (6 bits for 64-bit)
                5'b01000: alu_result = operand_a | operand_b;                      // OR
                5'b01001: alu_result = operand_a & operand_b;                      // AND
                default:  alu_result = 64'b0;
            endcase
        end
    end
    
    assign result = alu_result;
    assign zero = (alu_result == 64'b0);
endmodule