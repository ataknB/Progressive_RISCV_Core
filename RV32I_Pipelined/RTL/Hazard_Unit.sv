module Hazard_Unit(
    input logic [4:0]rs1_Decode,
    input logic [4:0]rs2_Decode,
    input logic [4:0]rs1_Execute,
    input logic [4:0]rs2_Execute,

    input logic [4:0]rd_Execute,
    input logic [4:0]rd_Memory,
    input logic [4:0]rd_WB,
    input logic write_en_rf_Memory,
    input logic write_en_rf_WB,

    input logic data_read_Execute,
    input logic branch_feedback,

    output logic [1:0]Forward_rd1,
    output logic [1:0]Forward_rd2,

    output logic Stall_Fetch,
    output logic Stall_Decode,

    output logic Flush_Decode,
    output logic Flush_Execute

    /*
        00 normal
        01 memory
        10 wb
    */
);

    always_comb begin
        if((rs1_Execute == rd_Memory) &&write_en_rf_Memory & rs1_Execute !=0)begin
            Forward_rd1 = 2'b01;
        end else begin
            if((rs1_Execute == rd_WB) &&write_en_rf_WB & rs1_Execute !=0)begin
                Forward_rd1 = 2'b10;
            end else begin
                Forward_rd1 = 2'b10;
            end
        end

        if((rs2_Execute == rd_Memory) &&write_en_rf_Memory & rs2_Execute !=0)begin
            Forward_rd2 = 2'b01;
        end else begin
            if((rs2_Execute == rd_WB) &&write_en_rf_WB & rs2_Execute !=0)begin
                Forward_rd2 = 2'b10;
            end else begin
                Forward_rd2 = 2'b10;
            end
        end

        //Stall
        if(data_read_Execute & ((rs1_Decode == rd_Execute) || (rs2_Decode == rd_Execute)))begin
            Stall_Fetch = 1;
            Stall_Decode = 1;
            Flush_Execute = 1;
        end else begin  
            Stall_Fetch = 0;
            Stall_Decode = 0;
            Flush_Execute = 0;
        end

        //Flush
        if(branch_feedback)begin
            Flush_Decode <= 1;
            Flush_Execute <= 1;
        end else begin
            Flush_Decode <= 0;
            Flush_Execute <= 0;
        end
    end
endmodule
