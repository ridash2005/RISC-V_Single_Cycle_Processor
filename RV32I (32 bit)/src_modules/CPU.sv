// ============================================================================
// SINGLE-CYCLE RISC-V RV32I PROCESSOR
// ============================================================================
// Architecture: Non-Pipelined Single-Cycle with Harvard Architecture
// ISA: RISC-V RV32I Base Integer Instruction Set (32-bit)
// CPI: 1.0 (One instruction per clock cycle)
// Memory: Separate Instruction Memory (4KB) and Data Memory (1KB)
// Features: 32 General Purpose Registers, Memory-Mapped GPIO
// 
// Design Characteristics:
// - All instructions complete in one clock cycle
// - Long critical path limits maximum clock frequency
// - Simple control logic without pipeline hazards
// - Suitable for educational purposes and low-complexity applications
//
// Module Hierarchy:
// CPU (Top)
//  ├── Program_Counter           - PC register and update logic
//  ├── Instruction_Memory        - 4KB program storage
//  ├── Control_Unit              - Instruction decoder
//  │    ├── Main_Decoder         - Opcode decoder
//  │    ├── ALU_Decoder          - ALU operation selector
//  │    └── Branch_Unit          - Branch condition evaluator
//  ├── Register_File             - 32 x 32-bit registers
//  ├── Immediate_Generator       - Immediate extraction/sign-extension
//  ├── ALU                       - Arithmetic Logic Unit
//  ├── Data_Memory               - 1KB RAM + Memory-mapped GPIO
//  └── Mux modules               - Data path multiplexers
// ============================================================================
// ============================================================================
// TOP-LEVEL CPU MODULE
// ============================================================================
module CPU (
    // Clock and Reset
    input  logic        clk,
    input  logic        reset,
    
    // Program Loading Interface
    input  logic        prog_load_en,      // Enable program loading
    input  logic [31:0] prog_addr,         // Program load address
    input  logic [31:0] prog_data,         // Program instruction data
    
    // Debug/Monitor Interface
    output logic [31:0] debug_pc,          // Current PC
    output logic [31:0] debug_instruction, // Current instruction
    output logic [31:0] debug_alu_result,  // ALU result
    output logic [31:0] debug_reg_wdata,   // Register write data
    output logic [4:0]  debug_reg_waddr,   // Register write address
    output logic        debug_reg_wen,     // Register write enable
    
    // GPIO Interface
    output logic [31:0] gpio_out,          // GPIO output
    input  logic [31:0] gpio_in,           // GPIO input
    
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
    logic [3:0]  alu_control;      // ALU operation
    logic [2:0]  imm_src;          // Immediate type
    
    // ========================================
    // Internal Wires - Data Path
    // ========================================
    logic [31:0] pc_current;       // Current PC
    logic [31:0] pc_next;          // Next PC
    logic [31:0] pc_plus4;         // PC + 4
    logic [31:0] pc_target;        // Branch/Jump target
    
    logic [31:0] instruction;      // Current instruction
    
    logic [31:0] reg_data1;        // Register read data 1
    logic [31:0] reg_data2;        // Register read data 2
    logic [31:0] reg_write_data;   // Register write data
    
    logic [31:0] immediate;        // Extended immediate
    
    logic [31:0] alu_operand_a;    // ALU input A
    logic [31:0] alu_operand_b;    // ALU input B
    logic [31:0] alu_result;       // ALU output
    logic        alu_zero;         // ALU zero flag
    
    logic [31:0] mem_read_data;    // Data memory read
    
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
    
    // Program Counter
    Program_Counter PC_MODULE (
        .clk       (clk),
        .reset     (reset),
        .pc_next   (pc_next),
        .halted    (cpu_halted),
        .pc_current(pc_current)
    );
    
    // PC Adder for PC+4
    assign pc_plus4 = pc_current + 32'd4;
    
    // PC Target Calculator
    assign pc_target = pc_current + immediate;
    
    // PC Mux
    Mux2 #(.WIDTH(32)) PC_MUX (
        .in0 (pc_plus4),
        .in1 (pc_target),
        .sel (pc_src),
        .out (pc_next)
    );
    
    // Instruction Memory
    Instruction_Memory IMEM (
        .clk      (clk),
        .we       (prog_load_en),
        .addr_w   (prog_addr),
        .data_w   (prog_data),
        .addr_r   (pc_current),
        .data_r   (instruction)
    );
    
    // Control Unit
    Control_Unit CTRL (
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7_bit5 (funct7_bit5),
        .alu_zero    (alu_zero),
        .alu_result  (alu_result),
        .pc_src      (pc_src),
        .alu_src     (alu_src),
        .reg_write_en(reg_write_en),
        .mem_write_en(mem_write_en),
        .mem_read_en (mem_read_en),
        .result_src  (result_src),
        .imm_src     (imm_src),
        .alu_control (alu_control),
        .halted      (cpu_halted)
    );
    
    // Register File
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
    
    // Immediate Generator
    Immediate_Generator IMM_GEN (
        .instruction(instruction),
        .imm_src    (imm_src),
        .immediate  (immediate)
    );
    
    // ALU Source Mux
    assign alu_operand_a = reg_data1;
    Mux2 #(.WIDTH(32)) ALU_SRC_MUX (
        .in0 (reg_data2),
        .in1 (immediate),
        .sel (alu_src),
        .out (alu_operand_b)
    );
    
    // ALU
    ALU ALU_MODULE (
        .operand_a  (alu_operand_a),
        .operand_b  (alu_operand_b),
        .alu_control(alu_control),
        .result     (alu_result),
        .zero       (alu_zero)
    );
    
    // Data Memory
    Data_Memory DMEM (
        .clk      (clk),
        .we       (mem_write_en),
        .re       (mem_read_en),
        .addr     (alu_result),
        .data_w   (reg_data2),
        .data_r   (mem_read_data),
        .gpio_out (gpio_out),
        .gpio_in  (gpio_in)
    );
    
    // Result Mux (4-to-1)
    Mux4 #(.WIDTH(32)) RESULT_MUX (
        .in0 (alu_result),     // 00: ALU result
        .in1 (mem_read_data),  // 01: Memory data
        .in2 (pc_plus4),       // 10: PC+4 (for JAL/JALR)
        .in3 (immediate),      // 11: Immediate (for LUI)
        .sel (result_src),
        .out (reg_write_data)
    );
    
endmodule