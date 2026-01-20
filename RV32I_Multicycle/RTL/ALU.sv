module ALU #(  
    parameter ALU_OP = 16
    )(
    input logic [31:0]src1_i,
    input logic [31:0]src2_i,

    input logic [4:0]ALU_op_i,
    /*
        add = 0
        sub = 1

        sll = 2
        srl = 3
        sra = 4

        slt = 5
        sltu = 6

        xor = 7
        or = 8
        and = 9

        beq = 10
        bne = 11
        blt = 12
        bge = 13
        bltu = 14
        bgeu = 15

    */
    output logic [31:0]result_o,
    output logic branch_feedback_o
); 

    always_comb begin
        case(ALU_op_i)
            5'd0:begin
                result_o = src1_i + src2_i;
                branch_feedback_o = 0;
            end

            5'd1:begin
                result_o = src1_i - src2_i;
                branch_feedback_o = 0;
            end


            5'd2:begin
                result_o = src1_i << $unsigned(src2_i[4:0]);
                branch_feedback_o = 0;
            end

            5'd3:begin
                result_o = src1_i >> $unsigned(src2_i[4:0]);
                branch_feedback_o = 0;
            end

            5'd4:begin
                result_o = $signed(src1_i) >>> $unsigned(src2_i[4:0]);
                branch_feedback_o = 0;
            end

            5'd5:begin
                branch_feedback_o = 0;
                result_o ={31'd0 ,  $signed(src2_i) > $signed(src1_i)};
            end

            5'd6:begin
                result_o = {31'd0 , ($unsigned(src2_i) > $unsigned(src1_i))};
                branch_feedback_o = 0;
            end

            5'd7:begin
                result_o = src1_i ^ src2_i;
                branch_feedback_o = 0;
            end

            5'd8:begin
                result_o = src1_i | src2_i;
                branch_feedback_o = 0;
            end

            5'd9:begin
                result_o = src1_i & src2_i;
                branch_feedback_o = 0;
            end

            5'd10:begin
                result_o = 0;
                branch_feedback_o = (src1_i == src2_i);
            end

            5'd11:begin
                result_o = 0;
                branch_feedback_o = (src1_i != src2_i);
            end

            5'd12:begin
                result_o = 0;
                branch_feedback_o = ($signed(src1_i) < $signed(src2_i));
            end

            5'd13:begin
                result_o = 0;
                branch_feedback_o = ($signed(src1_i) >= $signed(src2_i));
            end

            5'd14:begin
                result_o = 0;
                branch_feedback_o = ($unsigned(src1_i) < $unsigned(src2_i));
            end

            5'd15:begin
                result_o = 0;
                branch_feedback_o = $unsigned(src1_i) >= $unsigned(src2_i);
            end

            default:begin
                result_o = 0;
                branch_feedback_o = 0;
            end
        endcase
    end
    
endmodule
