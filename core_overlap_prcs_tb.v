`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2023 11:40:39 PM
// Design Name: 
// Module Name: core_overlap_prcs_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module core_overlap_prcs_tb(

    );
    parameter SIZE_OF_EACH_CORE_INPUT   = 2;
    parameter SIZE_OF_EACH_KERNEL       = 3;
    parameter STRIDE                    = 1; 
    parameter PIX_WIDTH                 = 8;    
    parameter NON_OVERLAPPED_CONST      = SIZE_OF_EACH_CORE_INPUT * STRIDE;
    parameter SIZE_OF_PRSC_INPUT        = STRIDE* (SIZE_OF_EACH_CORE_INPUT-1) + SIZE_OF_EACH_KERNEL;
    parameter SIZE_OF_PRSC_OUTPUT       = SIZE_OF_PRSC_INPUT + NON_OVERLAPPED_CONST;                     

    reg                                     clk_i              ;
    reg                                     rst_i              ;
    reg                                     en_i               ;
    reg                                     valid_i            ;
    reg [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_0_i      ;
    reg [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_1_i      ;
    reg [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_2_i      ;
    reg [PIX_WIDTH*SIZE_OF_PRSC_INPUT-1:0]  core_data_3_i      ;
    wire                                    valid_o            ;
    wire[PIX_WIDTH*SIZE_OF_PRSC_OUTPUT-1:0] overlapped_column_o;

    core_overlap_prsc blk_overlapped_inst_0 (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .en_i               (en_i               ),
        .valid_i            (valid_i            ),
        .core_data_0_i      (core_data_0_i      ),
        .core_data_1_i      (core_data_1_i      ),
        .core_data_2_i      (core_data_2_i      ),
        .core_data_3_i      (core_data_3_i      ),
        .valid_o            (valid_o            ),
        .overlapped_column_o(overlapped_column_o)
    );

    initial 
    begin
        clk_i = 1'b0;
        repeat (500) 
        begin 
            #1 clk_i = ~clk_i; 
        end
    end    

    initial
    begin
        rst_i = 1'b0;
        repeat (5)
        begin
            #1 rst_i = 1'b1;
            #($urandom_range(300,500));
        end
    end

    initial
    begin
        wait(rst_i===1'b0);
        en_i = 1'b1;
    end

    integer block_index = 0;
    initial
    begin
        repeat(10)
        begin          
            core_data_0_i = {$random,$random,$random};
            core_data_1_i = {$random,$random,$random};
            core_data_2_i = {$random,$random,$random};
            core_data_3_i = {$random,$random,$random};
        
            valid_i = 1'b1;
            #2 valid_i = 1'b0;
            #20;
        end
    end
    
    initial
    begin
        repeat(10)
        begin
            wait(valid_i===1'b1);
            $display("core_0=%h, core_1=%h",core_data_0_i,core_data_1_i);
            $display("core_2=%h, core_3=%h",core_data_2_i,core_data_3_i);            
            wait(valid_o===1'b1);
            $display("overlapped_column=%h",overlapped_column_o); 
        end
    end
endmodule
