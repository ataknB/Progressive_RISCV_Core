module DMEM #(
    parameter WIDTH = 32
    )
    (
    input logic clk_i,
    input logic rstn_i,

    input logic [31:0]DMEM_Address_i,
    input logic [WIDTH-1:0]wd_data_i,

    input logic write_en_DMEM_i,

    output logic [WIDTH-1:0]DMEM_out_o
);
    logic [31:0]DMEM_mem[2048-1:0];
    logic [31:0]address;

    assign address = {16'd0 , DMEM_Address_i[15:0]};

    always_ff @(posedge clk_i)begin
        if(!rstn_i)begin
           $readmemh("dmem.mem" , DMEM_mem);
        end else begin
            if(write_en_DMEM_i)begin
                DMEM_mem[address] <= wd_data_i;
            end
            else begin
                DMEM_mem <= DMEM_mem;
            end
        end
    end
    assign DMEM_out_o = DMEM_mem[address];
    
endmodule
