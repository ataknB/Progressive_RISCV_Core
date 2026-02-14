module RF #(
    parameter WIDTH = 32,
    parameter RD = 5
    )
    (
    input logic clk_i,
    input logic rst_ni,

    input logic [RD-1:0]rs1_i,
    input logic [RD-1:0]rs2_i,

    input logic [RD-1:0]wd_address_i,
    input logic [WIDTH-1:0]wd_data_i,

    input logic write_en_rf_i,

    output logic [WIDTH-1:0]rd1_o,
    output logic [WIDTH-1:0]rd2_o
);

    logic [31:0]rf_mem[31:0];

    always_ff @(posedge clk_i)begin
        if(!rst_ni)begin
            rf_mem <= '{default:0};
        end else begin
            if(write_en_rf_i)begin
                rf_mem[wd_address_i] <= wd_data_i;
            end
            else begin
                rf_mem <= rf_mem;
            end
            rf_mem[0] <= 0;
        end
    end

    assign rd1_o = rf_mem[rs1_i];
    assign rd2_o = rf_mem[rs2_i];
    
endmodule
