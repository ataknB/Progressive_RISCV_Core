module IM #(
    parameter WIDTH = 32
)(
    input logic [WIDTH-1:0]IM_Address_i,
    output logic [WIDTH-1:0]IM_out_o
);  
    logic [31:0]mem[2048 -1:0];
    initial begin
        $readmemh("imem.mem", mem);
    end
    
    logic [31:0]address;
    assign address = {4'd0 , IM_Address_i[27:0]};

    assign IM_out_o = mem[address>>2];
endmodule
