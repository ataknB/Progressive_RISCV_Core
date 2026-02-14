module Control_Unit(
    input logic [6:0]op_code_i, //op code of instruction
    input logic [2:0]funct3_i, //funct3 signal came from decoder
    input logic [6:0]funct7_i, // funct7 singal that came from decoder

    output logic write_en_rf_o, // Controls writing to rgeister file
    output logic ImmSrc_o, // 0 = signed , 1 = unsigned
    output logic [4:0]ALU_op_o, //Indicates ALU operations
    output logic write_en_DMEM_i, //Controls writing to memory
    output logic [2:0]load_type_o, //Controls loading type
    output logic [1:0]store_type, //Controls storing type
    output logic fence_en_o,
    output logic ALU_rd2_select_o, // 0 = rd2 , 1 = Imm
    output logic branch_en, //Enables branches
    output logic JAL_en_o, //Enables JAL command
    output logic JALR_en_o, //Enables JALR command
    output logic data_read, //Enables Data reaidng from DMEM
    output logic AUIPC_en, //Enables AUIPC command
    output logic LUI_en //Enables LUI command
);
    /*
        add = 0
        sub = 1

        sll = 2
        srl = 3
        sra = 4

        sll = 5
        slt = 6
        sltu = 7

        xor = 8
        or = 9
        and = 10

        beq = 11
        bne = 12
        blt = 13
        bge = 14
        bltu = 15
        bgeu = 16

    */
    always_comb 
    begin
        AUIPC_en = 0;
        LUI_en = 0;
        load_type_o = 0;
        fence_en_o = 0;
        case(op_code_i)

            //L-Inst
            7'b00_0011:begin
                write_en_rf_o = 1;
                data_read = 1;
                write_en_DMEM_i = 0;
                store_type = 0;
                ALU_rd2_select_o = 1;
                branch_en = 0;
                JAL_en_o = 0;
                JALR_en_o = 0;
                ALU_op_o = 0;


                case(funct3_i)
                    3'b000:begin
                        load_type_o = 1;
                        ImmSrc_o = 0;
                    end

                    3'b001:begin
                        load_type_o = 2;
                        ImmSrc_o = 0;
                    end

                    3'b010:begin
                        load_type_o = 3;
                        ImmSrc_o = 0;
                    end

                    3'b100:begin
                        load_type_o = 4;;
                        ImmSrc_o = 1;
                    end

                    3'b101:begin
                        load_type_o = 5;
                        ImmSrc_o = 1;
                    end

                    default:begin
                        load_type_o = 0;
                        ImmSrc_o = 0;

                    end

                endcase
            end

            //I-Type
            7'b001_0011:begin
                data_read = 0;
                write_en_rf_o = 1;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 1;
                branch_en = 0;
                JAL_en_o = 0;
                JALR_en_o = 0;
                load_type_o = 0;

                casez({funct7_i[5] , funct3_i})
                    //ADDI
                    4'bz_000:begin
                        ALU_op_o = 0;
                        ImmSrc_o = 0;
                    end
                    //SLLI
                    4'bz_001:begin
                        ALU_op_o = 2;
                        ImmSrc_o = 0;
                    end
                    //SLTI
                    4'bz_010:begin
                        ALU_op_o = 5;
                        ImmSrc_o = 1;
                    end
                    //SLTIU
                    4'bz_011:begin
                        ALU_op_o = 6;
                        ImmSrc_o = 0;
                    end
                    //XORI
                    4'bz_100:begin
                        ALU_op_o = 7;
                        ImmSrc_o = 0;
                    end
                    //SRLI
                    4'b0_101:begin
                        ALU_op_o = 3;
                        ImmSrc_o = 0;
                    end
                    //SRAI
                    4'b1_101:begin
                        ALU_op_o = 4;
                        ImmSrc_o = 0;
                    end
                    //ORI
                    4'bz_110:begin
                        ALU_op_o = 8;
                        ImmSrc_o = 0;
                    end
                    //ANDI
                    4'bz_111:begin
                        ALU_op_o = 9;
                        ImmSrc_o = 0;
                    end
                endcase
            end
            //AUIPC
            7'b001_0111:begin
            data_read = 0;
                write_en_rf_o = 1;
                MemWrite_o = 0;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 1;
                branch_en = 0;
                JAL_en_o = 0;
                JALR_en_o = 0;
                load_type_o = 0;
                ALU_op_o = 0;
                AUIPC_en = 1;
            end
            //S-TYPE
            7'b010_0011:begin
            data_read = 0;
                write_en_rf_o = 0;
                write_en_DMEM_i = 1; 
                ALU_rd2_select_o = 1;
                branch_en = 0;
                JAL_en_o = 0;
                JALR_en_o = 0;
                load_type_o = 0;
                ALU_op_o = 0;
                case(funct3_i)
                    3'b000:begin
                        store_type = 1;
                    end

                    3'b001:begin
                        store_type = 2;
                    end

                    3'b010:begin
                        store_type = 3;
                    end
                    default:begin
                        store_type = 0;
                    end
                endcase
            end
            //LUI
            7'b011_0111:begin
                LUI_en = 1;
                data_read = 0;
                write_en_rf_o = 1;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 1;
                branch_en = 0;
                JAL_en_o = 0;
                ImmSrc_o = 1;
                JALR_en_o = 0;
                ALU_op_o = 0;
                load_type_o = 0;
            end
            //R-Type
            7'b011_0011:begin
            data_read = 0;
                write_en_rf_o = 1;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 0;
                branch_en = 0;
                JAL_en_o = 0;
                ImmSrc_o = 0;
                JALR_en_o = 0;
                load_type_o = 0;

                casez({funct7_i[5] , funct3_i})
                    //ADD
                    4'b0_000:begin
                        ALU_op_o = 0;
                    end
                    //SUB
                    4'b1_000:begin
                        ALU_op_o = 1;
                        
                    end
                    //SLL
                    4'bz_001:begin
                        ALU_op_o = 2;
        
                    end
                    //SLT
                    4'bz_010:begin
                        ALU_op_o = 5;
                  
                    end
                    //SLTU
                    4'bz_011:begin
                        ALU_op_o = 6;
               
                    end
                    //XOR
                    4'bz_100:begin
                        ALU_op_o = 7;
                  
                    end
                    //SRL
                    4'b0_101:begin
                        ALU_op_o = 3;
      
                    end
                    //SRA
                    4'b1_101:begin
                        ALU_op_o = 4;
      
                    end
                    //OR
                    4'bz_110:begin
                        ALU_op_o = 8;

                    end
                    //AND
                    4'bz_111:begin
                        ALU_op_o = 9;

                    end
                    default:begin
                        ALU_op_o = 0;

                    end
                endcase
            end

            //B-Type
            7'b1100011:begin
                data_read = 0;
                write_en_rf_o = 0;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 0;
                branch_en = 1;
                JAL_en_o = 0;
                ImmSrc_o = 0;
                JALR_en_o = 0; 
                load_type_o = 0;
                case(funct3_i)
                    3'b000:begin
                        ALU_op_o = 10;
                    end
                    
                    3'b001:begin
                        ALU_op_o = 11;
                    end

                    3'b100:begin
                        ALU_op_o = 12;
                    end

                    3'b101:begin
                        ALU_op_o = 13;
                    end

                    3'b110:begin
                        ALU_op_o = 14;
                    end

                    3'b111:begin
                        ALU_op_o = 15;
                    end

                    default:begin
                        ALU_op_o = 0;
                    end
                endcase
            end

            //JALR
            7'b1100111:begin
                    data_read = 0;
                    write_en_rf_o = 1;
                    write_en_DMEM_i = 0; 
                    store_type = 0;
                    ALU_rd2_select_o = 1;
                    branch_en = 0;
                    JAL_en_o = 0;
                    ImmSrc_o = 1;
                    JALR_en_o = 1;
                    ALU_op_o = 0;
                    load_type_o = 0;
            end

            //JALR
            7'b1101111:begin
                    data_read = 0;
                    write_en_rf_o = 1;
                    write_en_DMEM_i = 0; 
                    store_type = 0;
                    ALU_rd2_select_o = 1;
                    branch_en = 0;
                    JAL_en_o = 1;
                    ImmSrc_o = 0;
                    JALR_en_o = 0;
                    ALU_op_o = 0;
            end

            //FENCE
            7'b0001111:begin
                    case(funct3_i)
                        3'b000:begin
                            data_read = 0;
                            write_en_rf_o = 1;
                            write_en_DMEM_i = 0; 
                            store_type = 0;
                            ALU_rd2_select_o = 1;
                            branch_en = 0;
                            JAL_en_o = 1;
                            ImmSrc_o = 0;
                            JALR_en_o = 0;
                            ALU_op_o = 0;
                        end 

                        3'b001:begin
                            data_read = 0;
                            write_en_rf_o = 1;
                            write_en_DMEM_i = 0; 
                            store_type = 0;
                            ALU_rd2_select_o = 1;
                            branch_en = 0;
                            JAL_en_o = 1;
                            ImmSrc_o = 0;
                            JALR_en_o = 0;
                            ALU_op_o = 0;
                        end 

                        default:begin
                            data_read = 0;
                            write_en_rf_o = 1;
                            write_en_DMEM_i = 0; 
                            store_type = 0;
                            ALU_rd2_select_o = 1;
                            branch_en = 0;
                            JAL_en_o = 1;
                            ImmSrc_o = 0;
                            JALR_en_o = 0;
                            ALU_op_o = 0;
                        end
                    endcase
            end


            default:begin
                data_read = 0;
                write_en_rf_o = 0;
                write_en_DMEM_i = 0; 
                store_type = 0;
                ALU_rd2_select_o = 0;
                branch_en = 0;
                JAL_en_o = 0;
                ImmSrc_o = 0;
                JALR_en_o = 0;
                ALU_op_o = 0;
            end
        endcase
    end

endmodule
