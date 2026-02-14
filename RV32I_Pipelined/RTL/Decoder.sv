module Decoder(
    input logic [31:0]Instr_i,

    output logic [4:0]rs1_o,
    output logic [4:0]rs2_o,
    output logic [4:0]rd,
    output logic [6:0]op_code_o,
    output logic [2:0]funct3,
    output logic [6:0]funct7,
    output logic [31:0]imm_o
);  
    assign op_code_o = Instr_i[6:0];
    assign funct3 = Instr_i[14:12];

    always_comb begin 
        casez(op_code_o)
    /*----- RSV32I -----*/    
        //I-Type
            7'b00z_0011:begin
                rd = Instr_i[11:7];
                rs1_o = Instr_i[19:15];
                rs2_o = 0;
                imm_o = {{20{Instr_i[31]}} , Instr_i[31:20]};
                funct7 = 0;
            end

        //S-Type
            7'b010_0011:begin
                rd = 0;
                rs1_o = Instr_i[19:15];
                rs2_o = Instr_i[24:20];
                imm_o = {20'd0 , Instr_i[31:25] , Instr_i[11:7]};
                funct7 = 0;
            end
        //R-Type    
            7'b011_0011:begin
                rd = Instr_i[11:7];
                rs1_o = Instr_i[19:15];
                rs2_o = Instr_i[24:20];
                imm_o = 0;
                funct7 = Instr_i[31:25];
            end
        
        //B-Type 
            7'b110_0011:begin
                rd = 0;
                rs1_o = Instr_i[19:15];
                rs2_o = Instr_i[24:20];
                imm_o = {{20{Instr_i[31]}} , Instr_i[7] , Instr_i[30:25] , Instr_i[11:8] , 1'b0};
                funct7 = 0;
            end
        //LUI Type
            7'b011_0111:begin
                rd = Instr_i[11:7];
                rs1_o = 0;
                rs2_o = 0;
                imm_o = {Instr_i[31:12] , 12'd0};
                funct7 = 0;
            end

        //J Type
            7'b110_1111:begin
                rd = Instr_i[11:7];
                rs1_o = 0;
                rs2_o = 0;
                imm_o = {{12{Instr_i[31]}} , Instr_i[19:12] , Instr_i[20] , Instr_i[30:21] , 1'd0};
                funct7 = 0;
            end
        //AUIPC
            7'b001_0111:begin
                rd = Instr_i[11:7];
                rs1_o = 0;
                rs2_o = 0;
                imm_o = {Instr_i[31:12] , 12'd0};
                funct7 = 0;
            end
        //FENCE
            7'b0001111:begin
                rd = 0;
                rs1_o = 0;
                rs2 = 0;
                imm_o = 0;
                funct7 = 0;
            end
        //CSR
            7'b0001111:begin
                rd = Instr_i[11:7];
                rs1_o = rd = Instr_i[19:15];
                rs2 = 0;
                imm_o = 0;
                funct7 = 0;
            end

        /*----- RV32M -----*/
            default:begin
                rd = 0;
                rs1_o = 0;
                rs2_o = 0;
                imm_o = 0;
                funct7 = 0;
            end
        endcase
    end
endmodule
