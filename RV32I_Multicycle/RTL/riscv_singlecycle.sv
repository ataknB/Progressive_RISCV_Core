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
logic [2:0]funct3;
logic [6:0]funct7;
logic [6:0]op_code;


logic [31:0]ALU_src1;
logic [31:0]ALU_src2;
logic [31:0]ALU_result;
logic branch_feedback;
logic [31:0]DMEM_out;
logic [31:0]DMEM_address;
logic [31:0]branch_address;

always_comb begin
    case({JAL_en_WB , JALR_en_WB , branch_feedback})
        3'b100:begin
            PC_in = Imm_out_Execute + PC_out_Execute;
        end

        3'b010:begin
            PC_in = ALU_result_Execute;
        end

        3'b001:begin
            PC_in = branch_address_Execute;
        end

        default:begin
            PC_in = PC_Increment_Fetch;
        end
    endcase
end

logic [31:0]branch_address_Fetch;
logic [31:0]branch_address_Decode;
logic [31:0]branch_address_Execute;



PC PC(
    .clk_i(clk_i),
    .rst_ni(rstn_i),
    .in_i(PC_in),
    .out_o(PC_out_Fetch)
);



assign PC_Increment_Fetch = PC_out_Fetch + 4;


IM IM(
    .IM_Address_i(PC_out_Fetch),
    .IM_out_o(Inst_Fetch)
);

logic [31:0]PC_Increment_Fetch;
logic [31:0]PC_Increment_Decode;
logic [31:0]PC_Increment_Execute;
logic [31:0]PC_Increment_Memory;

logic [31:0]PC_out_Fetch;
logic [31:0]PC_out_Decode;
logic [31:0]PC_out_Execute;
logic [31:0]PC_out_Memory;

logic [31:0]Inst_Decode;
logic [31:0]Inst_Fetch;

//-------------------Fetch----------------------
always_ff @(posedge clk_i)begin
    if(!rstn_i)begin
        PC_Increment_Decode <= 0;
        Inst_Decode <= 0;
        PC_out_Decode <= 0;
        branch_address_Decode <= 0;
    
    end else if(Stall_Fetch)begin
        PC_Increment_Decode <= PC_Increment_Decode;
        Inst_Decode <= Inst_Decode;
        PC_out_Decode <= PC_out_Decode;
        branch_address_Decode <= branch_address_Decode;
    end else begin
        PC_Increment_Decode <= PC_Increment_Fetch;
        Inst_Decode <= Inst_Fetch;
        PC_out_Decode <= PC_out_Execute;
        branch_address_Decode <= branch_address_Fetch;
    end
end

logic [4:0]rd_Decode;
logic [4:0]rd_Execute;
logic [4:0]rd_Memory;
logic [4:0]rd_WB;

logic [4:0]rs1_Decode;
logic [4:0]rs1_Execute;
logic [4:0]rs2_Decode;
logic [4:0]rs2_Execute;

Decoder Decoder(
    .Instr_i(Inst_Decode),
    .rs1_o(rs1_Decode),
    .rs2_o(rs2_Decode),
    .rd(rd_Decode),
    .op_code_o(op_code),
    .funct3(funct3),
    .funct7(funct7),
    .imm_o(Imm_out_Decode)
);

logic AUIPC_en;
logic LUI_en;

logic [31:0]ALU_src2_Decode;
logic [31:0]ALU_src1_Decode;

logic [31:0]ALU_src2_Execute;
logic [31:0]ALU_src1_Execute;

logic [4:0]ALU_op_Decode;
logic [4:0]ALU_op_Execute;

logic [31:0]rd2_store_Decode;
logic [31:0]rd2_store_Execute;

logic write_en_rf_Decode;
logic write_en_rf_Execute;
logic write_en_rf_Memory;
logic write_en_rf_WB;

logic [2:0]load_type_Decode;
logic [2:0]load_type_Execute;
logic [2:0]load_type_Memory;
logic [2:0]load_type_WB;

logic [1:0]store_type_Decode;
logic [1:0]store_type_Execute;
logic [1:0]store_type_Memory;

logic branch_en_Decode;
logic branch_en_Execute;

logic JAL_en_Decode;
logic JAL_en_Execute;
logic JAL_en_Memory;
logic JAL_en_WB;

logic JALR_en_Decode;
logic JALR_en_Execute;
logic JALR_en_Memory;
logic JALR_en_WB;

logic data_read_Decode;
logic data_read_Execute;
logic data_read_Memory;
logic data_read_WB;

logic AUIPC_en_Decode;
logic AUIPC_en_Execute;
logic AUIPC_en_Memory;
logic AUIPC_en_WB;

logic LUI_en_Decode;
logic LUI_en_Execute;
logic LUI_en_Memory;
logic LUI_en_WB;

logic [31:0]Imm_out_Decode;
logic [31:0]Imm_out_Execute;
logic [31:0]Imm_out_Memory;
logic [31:0]Imm_out_WB;

logic ALU_rd2_select_Decode;
logic ALU_rd2_select_Execute;

logic write_en_DMEM_Decode;
logic write_en_DMEM_Execute;
logic write_en_DMEM_Memory;
logic write_en_DMEM_WB;



Control_Unit Control_Unit(
    .op_code_i(op_code),
    .funct3_i(funct3),
    .funct7_i(funct7),
    .write_en_rf_o(write_en_rf_Decode),
    .ImmSrc_o(ImmSrc),
    .ALU_op_o(ALU_op_Decode),
    .write_en_DMEM_i(write_en_DMEM),
    .load_type_o(load_type_Decode),
    .store_type(store_type_Decode),
    .ALU_rd2_select_o(ALU_rd2_select_Decode),
    .branch_en(branch_en_Decode),
    .JAL_en_o(JAL_en_Decode),
    .JALR_en_o(JALR_en_Decode),
    .data_read(data_read_Decode),
    .AUIPC_en(AUIPC_en_Decode),
    .LUI_en(LUI_en_Decode)
);



RF RF(
    .clk_i(clk_i),
    .rst_ni(rstn_i),
    .rs1_i(rs1_Decode),
    .rs2_i(rs2_Decode),
    .wd_address_i(rd_WB),
    .wd_data_i(wr_data_RF),
    .write_en_rf_i(write_en_rf_WB),
    .rd1_o(rd1),
    .rd2_o(rd2)
);





//------------------Decode--------------------
always_ff @(posedge clk_i)begin
    if(!rstn_i || Flush_Decode)begin
        ALU_src2_Execute <= 0;
        ALU_src1_Execute <= 0;
        ALU_op_Execute <= 0;
        write_en_rf_Execute <= 0;
        load_type_Execute <= 0;
        store_type_Execute <= 0;
        branch_en_Execute <= 0;
        JAL_en_Execute <= 0;
        JALR_en_Execute <= 0;
        data_read_Execute <= 0;
        AUIPC_en_Execute <= 0;
        LUI_en_Execute <= 0;
        Imm_out_Execute <= 0;
        ALU_rd2_select_Execute <= 0;
        rd_Execute <= 0;
        write_en_rf_Execute <= 0;
        write_en_DMEM_Execute <= 0;
        rs1_Execute <= 0;
        rs2_Execute <= 0;
        PC_out_Execute <= 0;
    end else if(Stall_Decode)begin
        ALU_src2_Execute <= ALU_src2_Execute;
        ALU_src1_Execute <= ALU_src1_Execute;
        ALU_op_Execute <= ALU_op_Execute;
        write_en_rf_Execute <= write_en_rf_Execute;
        load_type_Execute <= load_type_Execute;
        store_type_Execute <= store_type_Execute;
        branch_en_Execute <= branch_en_Execute;
        JAL_en_Execute <= JAL_en_Execute;
        JALR_en_Execute <= JALR_en_Execute;
        data_read_Execute <= data_read_Execute;
        AUIPC_en_Execute <= AUIPC_en_Execute;
        LUI_en_Execute <= LUI_en_Execute;
        Imm_out_Execute <= Imm_out_Execute;
        ALU_rd2_select_Execute <= ALU_rd2_select_Execute;
        rd_Execute <= rd_Execute;
        write_en_rf_Execute <= write_en_rf_Execute;
        write_en_DMEM_Execute <= write_en_DMEM_Execute;
        rs1_Execute <= rs1_Execute;
        rs2_Execute <= rs2_Execute;
        PC_out_Execute <= PC_out_Execute;
    end else begin
        ALU_src2_Execute <= ALU_src2_Decode;
        ALU_src1_Execute <= ALU_src1_Decode;
        ALU_op_Execute <= ALU_op_Decode;
        write_en_rf_Execute <= write_en_rf_Decode;
        load_type_Execute <= load_type_Decode;
        store_type_Execute <= store_type_Decode;
        branch_en_Execute <= branch_en_Execute;
        JAL_en_Execute <= JAL_en_Decode;
        JALR_en_Execute <= JALR_en_Decode;
        data_read_Execute <= data_read_Decode;
        AUIPC_en_Execute <= AUIPC_en_Decode;
        LUI_en_Execute <= LUI_en_Decode;
        Imm_out_Execute <= Imm_out_Decode;
        PC_Increment_Execute <= PC_Increment_Decode;
        ALU_rd2_select_Execute <= ALU_rd2_select_Decode;
        rd_Execute <= rd_Decode;
        write_en_rf_Execute <= write_en_rf_Decode;
        write_en_DMEM_Execute <= write_en_DMEM_Decode;
        rs1_Execute <= rs1_Decode;
        rs2_Execute <= rs1_Decode;
        PC_out_Execute <= PC_out_Decode;
    end
end

logic [31:0]ALU_result_Execute;
logic [31:0]ALU_result_Memory;

logic [31:0]ALU_src1_Forwarded;
logic [31:0]ALU_src2_Forwarded;

always_comb begin
    case(Forward_rd1)
        2'b01:begin
            ALU_src1_Forwarded = ALU_result_Memory;
        end

        2'b10:begin
            ALU_src1_Forwarded = wr_data_RF;
        end
        default:begin
            ALU_src1_Forwarded = ALU_src1_Execute;
        end
    endcase

    case(Forward_rd2)
        2'b01:begin
            ALU_src2_Forwarded = ALU_result_Memory;
        end

        2'b10:begin
            ALU_src2_Forwarded = wr_data_RF;
        end
        default:begin
            ALU_src2_Forwarded = ALU_src2_Execute;
        end
    endcase
end

always_comb begin
    case(store_type_Execute)
        2'd1:begin
            rd2_store_Execute = {24'd0 , ALU_src2_Forwarded[7:0]};
        end 
        2'd2:begin
            rd2_store_Execute = {16'd0 , ALU_src2_Forwarded[15:0]};
        end

        2'd3:begin
            rd2_store_Execute = {ALU_src2_Forwarded[31:0]};
        end 

        default:begin
            rd2_store_Execute = {ALU_src2_Forwarded[31:0]};
        end
    endcase
end

assign ALU_src2 = (ALU_rd2_select_Execute) ? Imm_out_Execute : rd2_store_Execute;
assign ALU_src1 = (AUIPC_en_Execute) ? PC_out_Execute : ALU_src1_Forwarded;

logic [31:0]rd2_store_Memory;


ALU ALU(
    .src1_i(ALU_src1),
    .src2_i(ALU_src2),
    .ALU_op_i(ALU_op_Execute),
    .result_o(ALU_result_Execute),
    .branch_feedback_o(branch_feedback)
);

assign branch_address = Imm_out_Execute + PC_out_Execute;

logic data_read_Memory;
logic [31:0]ALU_result_Memory;
logic [31:0]PC_Increment_Memory;
//--------------Execute---------------
always_ff @(posedge clk_i)begin
    if(!rstn_i || Flush_Execute)begin
        ALU_result_Memory <= 0;
        data_read_Memory <= 0;
        store_type_Memory <= 0;
        rd2_store_Memory <= 0;
        rd_Memory <= 0;
        write_en_rf_Memory <= 0;
        load_type_Memory <= 0;
        write_en_DMEM_Memory <= 0;
        JALR_en_Memory <= 0;
        JAL_en_Memory <= 0;
        AUIPC_en_Memory <= 0;
        LUI_en_Memory <= 0;
        ALU_result_Memory <= 0;
        PC_Increment_Memory <= 0;
    end else begin
        ALU_result_Memory <= ALU_result_Execute;
        data_read_Memory <= data_read_Execute;
        store_type_Memory <= store_type_Execute;
        rd2_store_Memory <= rd2_store_Execute;
        rd_Memory <= rd_Execute;
        write_en_rf_Memory <= write_en_rf_Execute;
        load_type_Memory <= load_type_Execute;
        write_en_DMEM_Memory <= write_en_DMEM_Execute;
        JALR_en_Memory <= JALR_en_Execute;
        JAL_en_Memory <= JAL_en_Execute;
        AUIPC_en_Memory <= AUIPC_en_Execute;
        LUI_en_Memory <= LUI_en_Execute;
        ALU_result_Memory <= ALU_result_Execute;
        PC_Increment_Memory <= PC_Increment_Execute;
    end
end

always_comb begin
    case(store_type_Memory)
        2'd1:begin
            DMEM_address = {24'd0 , ALU_result_Memory[7:0]};
        end

        2'd2:begin
            DMEM_address = {16'd0 , ALU_result_Memory[15:0]};
        end

        2'd3:begin
            DMEM_address = {ALU_result_Memory[31:0]};
        end
        default:begin
            DMEM_address = 0;
        end
    endcase
end

logic [31:0]DMEM_out_Memory;
logic [31:0]DMEM_out_WB;

DMEM DMEM(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .DMEM_Address_i(DMEM_address),
    .wd_data_i(rd2_store_Memory),
    .write_en_DMEM_i(write_en_DMEM),
    .DMEM_out_o(DMEM_out_Memory)
);

logic [31:0]ALU_result_WB;
logic [31:0]PC_Increment_WB;

always_ff @(posedge clk_i)begin
    if(!rstn_i)begin
        DMEM_out_WB <= 0;
        rd_WB <= 0;
        write_en_rf_WB <= 0;
        load_type_WB <= 0;
        write_en_DMEM_WB <= 0;
        JALR_en_WB <= 0;
        JAL_en_WB <= 0;
        data_read_WB <= 0;
        AUIPC_en_WB <= 0;
        LUI_en_WB <= 0;
        ALU_result_WB <= 0;
        PC_Increment_WB <= 0;
        PC_out_WB <= 0;
    end else begin
        DMEM_out_WB <= DMEM_out_Memory;
        rd_WB <= rd_Memory;
        write_en_rf_WB <= write_en_rf_Memory;
        load_type_WB <= load_type_Memory;
        write_en_DMEM_WB <= write_en_DMEM_Memory;
        JALR_en_WB <= JALR_en_Memory;
        JAL_en_WB <= JAL_en_Memory;
        data_read_WB <= data_read_Memory;
        AUIPC_en_WB <= AUIPC_en_Memory;
        LUI_en_WB <= LUI_en_Memory;
        ALU_result_WB <= ALU_result_Memory;
        PC_Increment_WB <= PC_Increment_Memory;
    end
end

logic [31:0]Load_Data_DMEM;

always_comb begin

    
    case(load_type_WB)
        3'd1:begin
            Load_Data_DMEM = {{24{DMEM_out_WB[7]}} , DMEM_out_WB[7:0]};
        end

        3'd2:begin
            Load_Data_DMEM = {{16{DMEM_out_WB[15]}} , DMEM_out_WB[15:0]};
        end

        3'd3:begin
            Load_Data_DMEM = {DMEM_out_WB[31:0]};
        end

        3'd4:begin
            Load_Data_DMEM = {24'd0 , DMEM_out_WB[7:0]};
        end

        3'd5:begin
            Load_Data_DMEM = {16'd0 , DMEM_out_WB[15:0]};
        end

        default:begin
            Load_Data_DMEM = 0;
        end
    endcase
end

logic [31:0]wr_data_RF;
logic [3:0]RF_Data_Control;
assign RF_Data_Control = {{JALR_en_WB || JAL_en_WB }, {write_en_DMEM_WB || data_read_WB} , AUIPC_en_WB , LUI_en_WB};
always_comb begin
    case(RF_Data_Control)
        4'b0001:begin
            wr_data_RF = Imm_out_WB;
        end
        4'b0010:begin
            wr_data_RF = ALU_result_WB;
        end

        4'b0100:begin
            wr_data_RF = Load_Data_DMEM;
        end

        4'b1000:begin
            wr_data_RF = PC_Increment_WB;
        end
        
        default:begin
            wr_data_RF = ALU_result_WB;
        end
    endcase
end

logic [1:0]Forward_rd1;
logic [1:0]Forward_rd2;
logic Stall_Decode;
logic Stall_Fetch;

logic Flush_Decode;
logic Flush_Execute;

Hazard_Unit Hazard_Unit(
    .rs1_Decode(rs1_Decode),
    .rs2_Decode(rs2_Decode),
    .rs1_Execute(rs1_Execute),
    .rs2_Execute(rs2_Execute),
    .rd_Execute(rd_Execute),
    .rd_Memory(rd_Memory),
    .rd_WB(rd_WB),
    .write_en_rf_Memory(write_en_rf_Memory),
    .write_en_rf_WB(write_en_rf_WB),
    .data_read_Execute(data_read_Execute),
    .branch_feedback({branch_feedback || JALR_en_Execute || JAL_en_Execute}),

    .Forward_rd1(Forward_rd1),
    .Forward_rd2(Forward_rd2),
    .Stall_Fetch(Stall_Fetch),
    .Stall_Decode(Stall_Decode),
    .Flush_Decode(Flush_Decode),
    .Flush_Execute(Flush_Execute)
);



endmodule
