// ============================================================================
// SUBMODULE: CONTROL UNIT (RV64I with sub-modules)
// ============================================================================
module Control_Unit (
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic        funct7_bit5,
    input  logic        alu_zero,
    input  logic [63:0] alu_result,    // Full ALU result for branch comparisons
    output logic        pc_src,
    output logic        alu_src,
    output logic        reg_write_en,
    output logic        mem_write_en,
    output logic        mem_read_en,
    output logic [1:0]  result_src,
    output logic [2:0]  imm_src,
    output logic [4:0]  alu_control,
    output logic [1:0]  mem_size,
    output logic        mem_unsigned,
    output logic        word_op,
    output logic        halted
);
    // Internal signals
    logic       branch;
    logic       jump;
    logic       branch_taken;
    
    // Main Decoder
    Main_Decoder MAIN_DEC (
        .opcode      (opcode),
        .funct3      (funct3),
        .branch      (branch),
        .jump        (jump),
        .alu_src     (alu_src),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .mem_read_en (mem_read_en),
        .result_src  (result_src),
        .imm_src     (imm_src),
        .mem_size    (mem_size),
        .mem_unsigned(mem_unsigned),
        .word_op     (word_op),
        .halted      (halted)
    );
    
    // ALU Decoder (64-bit operations)
    ALU_Decoder ALU_DEC (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_bit5(funct7_bit5),
        .alu_control(alu_control)
    );
    
    // Branch Unit (Enhanced for 64-bit)
    Branch_Unit BRANCH_UNIT (
        .branch      (branch),
        .funct3      (funct3),
        .alu_zero    (alu_zero),
        .alu_result  (alu_result),     // Pass full ALU result
        .branch_taken(branch_taken)
    );
    
    // PC Source Logic
    assign pc_src = jump | branch_taken;
endmodule