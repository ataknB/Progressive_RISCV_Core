module PC(
    input logic clk_i,
    input logic rst_ni,
    input logic [31:0]in_i,
    output logic [31:0]out_o
);

    always_ff @(posedge clk_i)begin
        if(!rst_ni)begin
            out_o <= 32'h8000_0000;
        end else begin
            out_o <= in_i;
        end
    end
endmodule
