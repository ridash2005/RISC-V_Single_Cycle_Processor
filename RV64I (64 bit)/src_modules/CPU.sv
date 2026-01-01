// ============================================================================
// 64-BIT SINGLE-CYCLE RISC-V RV64I PROCESSOR
// ============================================================================
// Architecture: Non-Pipelined Single-Cycle with Harvard Architecture
// Data Width: 64-bit (Double-word size)
// ISA: RISC-V RV64I Base Integer Instruction Set (64-bit)
// CPI: 1.0 (One instruction per clock cycle)
// Memory: Separate Instruction Memory (4KB) and Data Memory (2KB)
// Features: 32 x 64-bit General Purpose Registers, Memory-Mapped GPIO
// 
// Key Differences from RV32I:
// - All registers are 64-bit wide (instead of 32-bit)
// - Address space: 2^64 bytes (16 exabytes) theoretical
// - New instructions: LW/SW operate on 32-bit, LD/SD on 64-bit
// - ADDIW, SLLIW, SRLIW, SRAIW for 32-bit operations on 64-bit registers
// - Instructions remain 32-bit fixed width
//
// Module Hierarchy:
// CPU (Top)
//  ├── Program_Counter           - 64-bit PC register
//  ├── Instruction_Memory        - 4KB program storage (32-bit instructions)
//  ├── Control_Unit              - Instruction decoder with RV64I support
//  │    ├── Main_Decoder         - Opcode decoder
//  │    ├── ALU_Decoder          - ALU operation selector (64-bit ops)
//  │    └── Branch_Unit          - Branch condition evaluator
//  ├── Register_File             - 32 x 64-bit registers
//  ├── Immediate_Generator       - Immediate extraction/sign-extension to 64-bit
//  ├── ALU                       - 64-bit Arithmetic Logic Unit
//  ├── Data_Memory               - 2KB RAM + Memory-mapped GPIO
//  └── Mux modules               - Data path multiplexers
// ============================================================================

// ============================================================================
// TOP-LEVEL CPU MODULE - 64-BIT
// ============================================================================
module CPU (
    // Clock and Reset
    input  logic        clk,
    input  logic        reset,
    
    // Program Loading Interface
    input  logic        prog_load_en,      // Enable program loading
    input  logic [63:0] prog_addr,         // Program load address (64-bit)
    input  logic [31:0] prog_data,         // Program instruction data (still 32-bit)
    
    // Debug/Monitor Interface
    output logic [63:0] debug_pc,          // Current PC (64-bit)
    output logic [31:0] debug_instruction, // Current instruction (32-bit)
    output logic [63:0] debug_alu_result,  // ALU result (64-bit)
    output logic [63:0] debug_reg_wdata,   // Register write data (64-bit)
    output logic [4:0]  debug_reg_waddr,   // Register write address
    output logic        debug_reg_wen,     // Register write enable
    
    // GPIO Interface
    output logic [63:0] gpio_out,          // GPIO output (64-bit)
    input  logic [63:0] gpio_in,           // GPIO input (64-bit)
    
    // Status
    output logic        cpu_halted         // CPU halted flag
);

    // ========================================
    // Internal Wires - Control Signals
    // ========================================
    logic        pc_src;           // PC source: 0=PC+4, 1=PC+Imm
    logic        alu_src;          // ALU source: 0=reg, 1=immediate
    logic        reg_write_en;     // Register write enable
    logic        mem_write_en;     // Memory write enable
    logic        mem_read_en;      // Memory read enable
    logic [1:0]  result_src;       // Result mux select
    logic [4:0]  alu_control;      // ALU operation (expanded to 5 bits for 64-bit ops)
    logic [2:0]  imm_src;          // Immediate type
    logic [1:0]  mem_size;         // Memory access size (00=byte, 01=half, 10=word, 11=double)
    logic        mem_unsigned;     // Unsigned load
    logic        word_op;          // 32-bit operation on 64-bit registers (W-type)
    
    // ========================================
    // Internal Wires - Data Path (64-bit)
    // ========================================
    logic [63:0] pc_current;       // Current PC (64-bit)
    logic [63:0] pc_next;          // Next PC
    logic [63:0] pc_plus4;         // PC + 4
    logic [63:0] pc_target;        // Branch/Jump target
    
    logic [31:0] instruction;      // Current instruction (still 32-bit)
    
    logic [63:0] reg_data1;        // Register read data 1 (64-bit)
    logic [63:0] reg_data2;        // Register read data 2 (64-bit)
    logic [63:0] reg_write_data;   // Register write data (64-bit)
    
    logic [63:0] immediate;        // Extended immediate (64-bit)
    
    logic [63:0] alu_operand_a;    // ALU input A (64-bit)
    logic [63:0] alu_operand_b;    // ALU input B (64-bit)
    logic [63:0] alu_result;       // ALU output (64-bit)
    logic        alu_zero;         // ALU zero flag
    
    logic [63:0] mem_read_data;    // Data memory read (64-bit)
    
    // ========================================
    // Instruction Fields
    // ========================================
    logic [6:0]  opcode;
    logic [4:0]  rd;               // Destination register
    logic [4:0]  rs1;              // Source register 1
    logic [4:0]  rs2;              // Source register 2
    logic [2:0]  funct3;
    logic [6:0]  funct7_bit5;
    
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct3 = instruction[14:12];
    assign funct7_bit5 = instruction[31:25];
    
    // ========================================
    // Debug Outputs
    // ========================================
    assign debug_pc = pc_current;
    assign debug_instruction = instruction;
    assign debug_alu_result = alu_result;
    assign debug_reg_wdata = reg_write_data;
    assign debug_reg_waddr = rd;
    assign debug_reg_wen = reg_write_en;
    
    // ========================================
    // MODULE INSTANTIATIONS
    // ========================================
    
    // Program Counter (64-bit)
    Program_Counter PC_MODULE (
        .clk       (clk),
        .reset     (reset),
        .pc_next   (pc_next),
        .halted    (cpu_halted),
        .pc_current(pc_current)
    );
    
    // PC Adder for PC+4
    assign pc_plus4 = pc_current + 64'd4;
    
    // PC Target Calculator
    assign pc_target = pc_current + immediate;
    
    // PC Mux
    Mux2 #(.WIDTH(64)) PC_MUX (
        .in0 (pc_plus4),
        .in1 (pc_target),
        .sel (pc_src),
        .out (pc_next)
    );
    
    // Instruction Memory (instructions still 32-bit)
    Instruction_Memory IMEM (
        .clk      (clk),
        .we       (prog_load_en),
        .addr_w   (prog_addr),
        .data_w   (prog_data),
        .addr_r   (pc_current),
        .data_r   (instruction)
    );
    
    // Control Unit (RV64I support)
    Control_Unit CTRL (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7_bit5 (funct7_bit5),
        .alu_zero    (alu_zero),
        .alu_result  (alu_result),     // Pass ALU result for branch decisions
        .pc_src      (pc_src),
        .alu_src     (alu_src),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .mem_read_en (mem_read_en),
        .result_src  (result_src),
        .imm_src     (imm_src),
        .alu_control (alu_control),
        .mem_size    (mem_size),
        .mem_unsigned(mem_unsigned),
        .word_op     (word_op),
        .halted      (cpu_halted)
    );
    
    // Register File (64-bit)
    Register_File REGFILE (
        .clk      (clk),
        .reset    (reset),
        .we       (reg_write_en),
        .addr_r1  (rs1),
        .addr_r2  (rs2),
        .addr_w   (rd),
        .data_w   (reg_write_data),
        .data_r1  (reg_data1),
        .data_r2  (reg_data2)
    );
    
    // Immediate Generator (64-bit)
    Immediate_Generator IMM_GEN (
        .instruction(instruction),
        .imm_src    (imm_src),
        .immediate  (immediate)
    );
    
    // ALU Source Mux
    assign alu_operand_a = reg_data1;
    Mux2 #(.WIDTH(64)) ALU_SRC_MUX (
        .in0 (reg_data2),
        .in1 (immediate),
        .sel (alu_src),
        .out (alu_operand_b)
    );
    
    // ALU (64-bit)
    ALU ALU_MODULE (
        .operand_a  (alu_operand_a),
        .operand_b  (alu_operand_b),
        .alu_control(alu_control),
        .word_op    (word_op),
        .result     (alu_result),
        .zero       (alu_zero)
    );
    
    // Data Memory (64-bit)
    Data_Memory DMEM (
        .clk        (clk),
        .we         (mem_write_en),
        .re         (mem_read_en),
        .addr       (alu_result),
        .data_w     (reg_data2),
        .mem_size   (mem_size),
        .mem_unsigned(mem_unsigned),
        .data_r     (mem_read_data),
        .gpio_out   (gpio_out),
        .gpio_in    (gpio_in)
    );
    
    // Result Mux (4-to-1)
    Mux4 #(.WIDTH(64)) RESULT_MUX (
        .in0 (alu_result),     // 00: ALU result
        .in1 (mem_read_data),  // 01: Memory data
        .in2 (pc_plus4),       // 10: PC+4 (for JAL/JALR)
        .in3 (immediate),      // 11: Immediate (for LUI)
        .sel (result_src),
        .out (reg_write_data)
    );
    
endmodule