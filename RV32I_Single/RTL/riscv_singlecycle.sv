//`include "pkg/riscv_pkg.sv"
/* verilator lint_off IMPORTSTAR */


// Aşağıda bulunan output siyalleri tasarladığınız risc-v işlemcinin log dosyalasını doldurmak için kullanılacak
// yani örnek olarak update_o sinyali işlemcideki değişimin logunun basılması için valid sinyali olacak,
// valid sinyaliniz 1 olduğunda reg_addr_o sinyalinde gelen bilgi log dosyasının ilgili kısımına düzgün
// formatta basılacak.


// 
//  data_o ve addr_i sinyallerine bit uzunluğuna uygun "0" bağlayın.
// 

// retire terimi kullanma sebebimiz o cycle'daki işlemin bittiği noktada verilecek sinyaller olmasıdır.
// Memory read ve write sinyali memory üzerindeki değişimi loglamanız içindir. Memory'nize bağlamak kendi 
// tercihinize bağlıdır. Yani, memory'nizde değişim olacağını instructiondan anlayıp sinyal belirleyebilirsiniz.
//

//
// Kurmanız beklenen sistemde asıl olan değişimleri anlamak ve göstermektir. İşlemci gibi büyük sistemlerin testlerini
// waveform üzerinden yapmak imkansız olacağı için burada otomatik bir kontrol sistemine uyum sağlayacak bir kontrol loglama
// sistemi kurmanız gerekiyor. İşlemci mimarisi öğrenmenizin yanında bu ödevin size kazandırmasını hedeflediğimiz şey budur.
//
module riscv_singlecycle
#(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem"       // instruction memory initialization file
)(
    input  logic             clk_i,       // system clock
    input  logic             rstn_i,      // system reset
    input  logic  [XLEN-1:0] addr_i,      
    output logic  [XLEN-1:0] data_o,     
    output logic             update_o,    // retire signal
    output logic  [XLEN-1:0] pc_o,        // retired program counter
    output logic  [XLEN-1:0] instr_o,     // retired instruction
    output logic  [     4:0] reg_addr_o,  // retired register address
    output logic  [XLEN-1:0] reg_data_o,  // retired register data
    output logic  [XLEN-1:0] mem_addr_o,  // retired memory address
    output logic  [XLEN-1:0] mem_data_o,  // retired memory data
    output logic             mem_wrt_o,   // retired memory write enable signal
    output logic             mem_read_o   // retired memory readed signal
);



logic [31:0]PC_in;
logic [31:0]PC_out;
logic [31:0]PC_increment;
logic [31:0]Inst;
logic [4:0]rs1;
logic [4:0]rs2;
logic [4:0]rd;
logic [2:0]funct3;
logic [6:0]funct7;
logic [31:0]Imm_out;
logic [6:0]op_code;
logic write_en_rf;
logic ImmSrc;
logic MemWrite;
logic Result_Src;
logic [4:0]ALU_op;
logic write_en_DMEM;
logic [2:0]load_type;
logic [1:0]store_type;
logic ALU_rd2_select;
logic branch_en;
logic JAL_en;
logic JALR_en;
logic data_read;
logic [31:0]rd1;
logic [31:0]rd2;
logic [31:0]ALU_src1;
logic [31:0]ALU_src2;
logic [31:0]rd2_store;
logic [31:0]ALU_result;
logic branch_feedback;
logic [31:0]DMEM_out;
logic [31:0]DMEM_address;
logic [31:0]branch_address;
logic [31:0]wr_data_RF;



always_comb begin
    case({JAL_en , JALR_en , branch_feedback})
        3'b100:begin
            PC_in = Imm_out + PC_out;
        end

        3'b010:begin
            PC_in = ALU_result;
        end

        3'b001:begin
            PC_in = branch_address;
        end

        default:begin
            PC_in = PC_increment;
        end
    endcase
end

assign branch_address = Imm_out + PC_out;

PC PC(
    .clk_i(clk_i),
    .rst_ni(rstn_i),
    .in_i(PC_in),
    .out_o(PC_out)
);



assign PC_increment = PC_out + 4;


IM IM(
    .IM_Address_i(PC_out),
    .IM_out_o(Inst)
);



Decoder Decoder(
    .Instr_i(Inst),
    .rs1_o(rs1),
    .rs2_o(rs2),
    .rd(rd),
    .op_code_o(op_code),
    .funct3(funct3),
    .funct7(funct7),
    .imm_o(Imm_out)
);

logic AUIPC_en;
logic LUI_en;

Control_Unit Control_Unit(
    .op_code_i(op_code),
    .funct3_i(funct3),
    .funct7_i(funct7),
    .write_en_rf_o(write_en_rf),
    .ImmSrc_o(ImmSrc),
    .MemWrite_o(MemWrite),
    .ALU_op_o(ALU_op),
    .write_en_DMEM_i(write_en_DMEM),
    .load_type_o(load_type),
    .store_type(store_type),
    .ALU_rd2_select_o(ALU_rd2_select),
    .branch_en(branch_en),
    .JAL_en_o(JAL_en),
    .JALR_en_o(JALR_en),
    .data_read(data_read),
    .AUIPC_en(AUIPC_en),
    .LUI_en(LUI_en)
);



RF RF(
    .clk_i(clk_i),
    .rst_ni(rstn_i),
    .rs1_i(rs1),
    .rs2_i(rs2),
    .wd_address_i(rd),
    .wd_data_i(wr_data_RF),
    .write_en_rf_i(write_en_rf),
    .rd1_o(rd1),
    .rd2_o(rd2)
);









always_comb begin
    case(store_type)
        2'd1:begin
            rd2_store = {24'd0 , rd2[7:0]};
        end 
        2'd2:begin
            rd2_store = {16'd0 , rd2[15:0]};
        end

        2'd3:begin
            rd2_store = {rd2[31:0]};
        end 

        default:begin
            rd2_store = {rd2[31:0]};
        end
    endcase
end
assign ALU_src2 = (ALU_rd2_select) ? Imm_out : rd2_store;
assign ALU_src1 = (AUIPC_en) ? PC_out : rd1;
ALU ALU(
    .src1_i(ALU_src1),
    .src2_i(ALU_src2),
    .ALU_op_i(ALU_op),
    .result_o(ALU_result),
    .branch_feedback_o(branch_feedback)

);



always_comb begin
    case(store_type)
        2'd1:begin
            DMEM_address = {24'd0 , ALU_result[7:0]};
        end

        2'd2:begin
            DMEM_address = {16'd0 , ALU_result[15:0]};
        end

        2'd3:begin
            DMEM_address = {ALU_result[31:0]};
        end
        default:begin
            DMEM_address = 0;
        end
    endcase
end

DMEM DMEM(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .DMEM_Address_i(ALU_result),
    .wd_data_i(rd2_store),
    .write_en_DMEM_i(write_en_DMEM),
    .DMEM_out_o(DMEM_out)
);

logic [31:0]Load_Data_DMEM;

always_comb begin
    case(load_type)
        3'd1:begin
            Load_Data_DMEM = {{24{DMEM_out[7]}} , DMEM_out[7:0]};
        end

        3'd2:begin
            Load_Data_DMEM = {{16{DMEM_out[15]}} , DMEM_out[15:0]};
        end

        3'd3:begin
            Load_Data_DMEM = {DMEM_out[31:0]};
        end

        3'd4:begin
            Load_Data_DMEM = {24'd0 , DMEM_out[7:0]};
        end

        3'd5:begin
            Load_Data_DMEM = {16'd0 , DMEM_out[15:0]};
        end

        default:begin
            Load_Data_DMEM = 0;
        end
    endcase
end



always_comb begin
    case({{JALR_en || JAL_en }, {write_en_DMEM || data_read} , AUIPC_en , LUI_en})
        4'b0001:begin
            wr_data_RF = Imm_out;
        end
        4'b0010:begin
            wr_data_RF = ALU_result;
        end

        4'b0100:begin
            wr_data_RF = Load_Data_DMEM;
        end

        4'b1000:begin
            wr_data_RF = PC_increment;
        end
        
        default:begin
            wr_data_RF = ALU_result;
        end
    endcase
end

assign pc_o = PC_out;
assign instr_o = Inst;
assign data_o = 0;
assign update_o = rstn_i;
assign reg_addr_o = rd;
assign reg_data_o = wr_data_RF;
assign mem_addr_o = ALU_result;
assign mem_data_o = (load_type > 0 ) ? Load_Data_DMEM : store_type > 0 ?  rd2_store : 0;
assign mem_wrt_o = write_en_DMEM;
assign mem_read_o = data_read;

endmodule
