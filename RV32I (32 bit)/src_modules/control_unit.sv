// ============================================================================
// SUBMODULE: CONTROL UNIT (with sub-modules)
// ============================================================================
module Control_Unit (
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic        funct7_bit5,
    input  logic        alu_zero,
    input  logic [31:0] alu_result,  // Full ALU result for branch unit
    output logic        pc_src,
    output logic        alu_src,
    output logic        reg_write_en,
    output logic        mem_write_en,
    output logic        mem_read_en,
    output logic [1:0]  result_src,
    output logic [2:0]  imm_src,
    output logic [3:0]  alu_control,
    output logic        halted
);
    // Internal signals
    logic       branch;
    logic       jump;
    logic       branch_taken;
    
    // Main Decoder
    Main_Decoder MAIN_DEC (
        .opcode      (opcode),
        .branch      (branch),
        .jump        (jump),
        .alu_src     (alu_src),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .mem_read_en (mem_read_en),
        .result_src  (result_src),
        .imm_src     (imm_src),
        .halted      (halted)
    );
    
    // ALU Decoder
    ALU_Decoder ALU_DEC (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7_bit5(funct7_bit5),
        .alu_control(alu_control)
    );
    
    // Branch Unit
    Branch_Unit BRANCH_UNIT (
        .branch      (branch),
        .funct3      (funct3),
        .alu_zero    (alu_zero),
        .alu_result  (alu_result),
        .branch_taken(branch_taken)
    );
    
    // PC Source Logic
    assign pc_src = jump | branch_taken;
endmodule