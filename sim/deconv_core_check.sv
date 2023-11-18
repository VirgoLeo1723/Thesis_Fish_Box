`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 01:16:48 PM
// Design Name: 
// Module Name: deconv_core_tb
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

`define  m_display(message)  $write("[%10t][%s]:  %s",$time, "Deconv_core_tb", message);
module deconv_core_check(

    );
    parameter SIZE_OF_GATHER_RESULT = 512;
    parameter DATA_IN_WIDTH         = 512;                                                                          
    parameter BRAM_DATA_WIDTH       = 32 ;                                                                          
    parameter ADDRESS_WIDTH         = 13 ;                                                                          
    parameter SIZE_OF_FEATURE       = 4  ;                                                                          
    parameter SIZE_OF_WEIGHT        = 3  ;                                                                          
    parameter PIX_WIDTH             = 16 ;                                                                          
    parameter STRIDE                = 1  ;                                                                          
    parameter N_PIX_IN              = SIZE_OF_FEATURE*SIZE_OF_WEIGHT;                                            
    parameter STRB_WIDTH            = 2*PIX_WIDTH*N_PIX_IN/4 ;                                                      
    parameter N_PIX_OUT             = SIZE_OF_FEATURE*SIZE_OF_WEIGHT - 
                                    (SIZE_OF_WEIGHT-STRIDE)*(SIZE_OF_FEATURE-1);
                                    
    parameter NUM_OF_CHANNEL_EACH_KERNEL = 1;
                                    
    reg i_clk;
    reg i_rst_n;
    
    wire [3:0]                                  weight_reader_en           ;       
    wire [3:0]                                  weight_reader_valid        ;    
    wire [PIX_WIDTH*4-1:0]                      weight_reader_data_out     ; 
    wire [3:0]                                  feature_reader_en          ;      
    wire [3:0]                                  feature_reader_valid       ;   
    wire [PIX_WIDTH*4-1:0]                      feature_reader_data_out    ;
    wire [3:0]                                  feature_writer_valid       ;   
    wire [3:0]                                  feature_writer_data_in     ; 
    wire [3:0]                                  feature_writer_finish      ;
    
    wire [ADDRESS_WIDTH-1:0]                    feature_bram_addr     [0:3];      
    wire [3:0]                                  feature_bram_en            ;
    wire [3:0]                                  feature_bram_we            ;
    wire [BRAM_DATA_WIDTH-1:0]                  feature_bram_data_out [0:3];
    wire [BRAM_DATA_WIDTH-1:0]                  feature_bram_data_in  [0:3];      
    
    wire [ADDRESS_WIDTH-1:0]                    weight_bram_addr      [0:3];      
    wire [3:0]                                  weight_bram_en             ;
    wire [3:0]                                  weight_bram_we             ;
    wire [BRAM_DATA_WIDTH-1:0]                  weight_bram_data_out  [0:3];
    wire [3:0]                                  weight_writer_finish       ;
    wire [SIZE_OF_GATHER_RESULT*PIX_WIDTH-1:0]  weight_bram_data_in        ;
    initial
    begin
        i_clk = 1'b0;
        forever #1 i_clk = ~i_clk; 
    end
    
    initial
    begin
        i_rst_n = 1'b0;
        #2 i_rst_n = 1'b1;
    end
    
    deconv_core#(
        .SIZE_OF_GATHER_RESULT  (SIZE_OF_GATHER_RESULT  ),
        .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH        ),                                                                         
        .ADDRESS_WIDTH          (ADDRESS_WIDTH          ),                                                                         
        .SIZE_OF_FEATURE        (SIZE_OF_FEATURE        ),                                                                         
        .SIZE_OF_WEIGHT         (SIZE_OF_WEIGHT         ),                                                                         
        .PIX_WIDTH              (PIX_WIDTH              ),                                                                         
        .STRIDE                 (STRIDE                 )                                                                       
    )deconv_core_inst(
        .i_clk                  (i_clk                  ),
        .i_rst_n                (i_rst_n                ),
        .weight_reader_en       (weight_reader_en       ),
        .weight_reader_valid    (weight_reader_valid    ),
        .weight_reader_data_out (weight_reader_data_out ),
        .feature_reader_en      (feature_reader_en      ),
        .feature_reader_valid   (feature_reader_valid   ),
        .feature_reader_data_out(feature_reader_data_out),
        .feature_writer_en      (feature_writer_en      ),
        .feature_writer_valid   (feature_writer_valid   ),
        .feature_writer_data_in (feature_writer_data_in ),
        .feature_writer_finish  (feature_writer_finish  )
    );
        
    task print_weight_channel( input bit [PIX_WIDTH-1:0] weight_fifo [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1], input int channel_index);
        foreach (weight_fifo[fifo_index])
        begin
            `m_display($sformatf("===== weight_kernel[%0d] channel[%0d]\n", fifo_index, channel_index))
            for (int row=0; row<SIZE_OF_WEIGHT; row++)
            begin
                for (int column=0; column<SIZE_OF_WEIGHT; column++)
                begin
                    $write($sformatf("  %h  ", weight_fifo[fifo_index][row][column]));
                end 
                $display("");
            end
        end
    endtask : print_weight_channel
    
    task print_feature_channel( input bit [PIX_WIDTH-1:0] feature_fifo [0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1], input int channel_index);
        `m_display($sformatf("===== Feature input channel[%0d]\n", channel_index))
        for (int row=0; row<SIZE_OF_FEATURE; row++)
        begin
            for (int column=0; column<SIZE_OF_FEATURE; column++)
            begin
                $write($sformatf("  %h  ", feature_fifo[row][column]));
            end 
            $display("");
        end
    endtask : print_feature_channel
    
    task print_result_channel (input bit [2*PIX_WIDTH-1:0] result_channel[0:N_PIX_OUT-1][0:N_PIX_OUT-1], 
                                    input int kernel_index, input int channel_index);
        `m_display($sformatf("===== Deconv output kernel[%0d] channel[%0d] \n", kernel_index, channel_index))
        for (int row=0; row<N_PIX_OUT; row++)
        begin
            for (int column=0; column<N_PIX_OUT; column++)
            begin
                $write($sformatf("  %h  ", result_channel[row][column]));
            end 
            $display("");
        end
    endtask : print_result_channel
    
    task deconv_operation(
                            input bit [PIX_WIDTH-1:0] weight_channel [0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1],
                            input bit [PIX_WIDTH-1:0] feature_channel[0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1],
                            input int kernel_index, 
                            inout int channel_index,
                            input int stride=1
                         );
        localparam SIZE_OF_OUTPUT = N_PIX_OUT;
        automatic bit [2*PIX_WIDTH-1:0] result [0:SIZE_OF_OUTPUT-1][0:SIZE_OF_OUTPUT-1];
        for (int feature_row=0; feature_row<SIZE_OF_FEATURE; feature_row++)
        begin
            for (int feature_column=0; feature_column<SIZE_OF_FEATURE; feature_column++)
            begin
                for (int weight_row=0; weight_row<SIZE_OF_FEATURE; weight_row++)
                begin
                    for (int weight_column=0; weight_column<SIZE_OF_FEATURE; weight_column++)
                    begin
                        result[feature_row*stride+weight_row][feature_column*stride+weight_column] = result[feature_row*stride+weight_row][feature_column*stride+weight_column] + feature_channel[feature_row][feature_column] * weight_channel[weight_row][weight_column];
                    end 
                end
            end    
        end
        print_result_channel(result, kernel_index, channel_index);
    endtask : deconv_operation
    
    
    bit [PIX_WIDTH-1:0] weight_channel [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];
    bit [PIX_WIDTH-1:0] weight_fifo[$][0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];
    bit [PIX_WIDTH-1:0] exe_weight_channel [0:3][0:SIZE_OF_WEIGHT-1][0:SIZE_OF_WEIGHT-1];

    int weight_channel_counter;
    int col_each_weight_channel;
    
    bit [PIX_WIDTH-1:0] feature_channel[0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    bit [PIX_WIDTH-1:0] feature_fifo[$][0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    bit [PIX_WIDTH-1:0] exe_feature_channel[0:SIZE_OF_FEATURE-1][0:SIZE_OF_FEATURE-1];
    int feature_channel_counter;
    int col_each_feature_channel;
    
    bit done_deconv_operation;
    
    always @(posedge i_clk)
    begin
        if (|weight_reader_valid)
        begin
            for (int index=0; index<4; index++)
            begin
                weight_channel[index][col_each_weight_channel/SIZE_OF_WEIGHT][col_each_weight_channel%SIZE_OF_WEIGHT] = weight_reader_data_out[index*PIX_WIDTH+:PIX_WIDTH];
            end
            col_each_weight_channel ++;
            if (col_each_weight_channel == SIZE_OF_WEIGHT**2) 
            begin 
                print_weight_channel(weight_channel, weight_channel_counter);
                col_each_weight_channel = 0;
                weight_channel_counter ++;
                weight_fifo[$+1] = weight_channel;
                if (weight_channel_counter % NUM_OF_CHANNEL_EACH_KERNEL==0) 
                begin
                    `m_display("----- Waiting for the feature map \n")
                    fork
                        begin
                            wait (feature_channel_counter >= NUM_OF_CHANNEL_EACH_KERNEL);
                            exe_weight_channel = weight_fifo.pop_front();
                            exe_feature_channel = feature_fifo.pop_front();
                            deconv_operation(exe_weight_channel[0], exe_feature_channel, 0, weight_channel_counter);
                            deconv_operation(exe_weight_channel[1], exe_feature_channel, 1, weight_channel_counter);
                            deconv_operation(exe_weight_channel[2], exe_feature_channel, 2, weight_channel_counter);
                            deconv_operation(exe_weight_channel[3], exe_feature_channel, 3, weight_channel_counter);
                            done_deconv_operation = 1'b1;
                            wait (deconv_core_inst.tilling_machine_valid[0] );
                            `m_display("----- tilling machine has valid result \n")
                            repeat(4) @(posedge i_clk);
                            `m_display($sformatf("---------- %h", deconv_core_inst.tilling_machine_out[0]))
                       end
                    join_none
                end
            end 
        end 
    end
        

    always @(posedge i_clk)
    begin
     if (|feature_reader_valid)
        begin
            feature_channel[0+col_each_feature_channel/(SIZE_OF_FEATURE/2)][0+col_each_feature_channel%(SIZE_OF_FEATURE/2)] = feature_reader_data_out[0*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[0+col_each_feature_channel/(SIZE_OF_FEATURE/2)][2+col_each_feature_channel%(SIZE_OF_FEATURE/2)] = feature_reader_data_out[1*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[2+col_each_feature_channel/(SIZE_OF_FEATURE/2)][0+col_each_feature_channel%(SIZE_OF_FEATURE/2)] = feature_reader_data_out[2*PIX_WIDTH+:PIX_WIDTH];
            feature_channel[2+col_each_feature_channel/(SIZE_OF_FEATURE/2)][2+col_each_feature_channel%(SIZE_OF_FEATURE/2)] = feature_reader_data_out[3*PIX_WIDTH+:PIX_WIDTH];

            col_each_feature_channel ++;
            if (col_each_feature_channel == (SIZE_OF_FEATURE/2)*2) 
            begin 
                print_feature_channel(feature_channel, feature_channel_counter);
                feature_channel_counter    ++;
                col_each_feature_channel    = 0;
                feature_fifo[$+1]           = feature_channel;
                if (feature_channel_counter >= NUM_OF_CHANNEL_EACH_KERNEL) 
                begin
                    fork
                        begin
                        wait (done_deconv_operation==1'b1);
                        done_deconv_operation=1'b0;
                        feature_channel_counter --;
                        end 
                    join_none
                end
           end 
        end 
    
    end 
   
    
    genvar weight_bram_index;
    generate 
        for (weight_bram_index=0; weight_bram_index<4; weight_bram_index = weight_bram_index+1)
        begin
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                             ),
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                           ),
                .WRITER_DATA_IN_WIDTH   (BRAM_DATA_WIDTH                           ),
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                 )  
            ) weight_bram_controller (
                .clk_i                  (i_clk                                     ),
                .rst_i                  (i_rst_n                                   ),
                .rd_en_i                (weight_reader_en[weight_bram_index]       ),
                .wr_en_i                (1'b0                                      ),
                .wr_valid_i             (1'b0                                      ),
                .wr_data_i              ({DATA_IN_WIDTH{1'b0}}                     ),
                .wr_finish_o            (weight_writer_finish[weight_bram_index]   ),
                .rd_valid_o             (weight_reader_valid[weight_bram_index]    ),
                .rd_data_o              (weight_reader_data_out [weight_bram_index*PIX_WIDTH+:PIX_WIDTH]),
                .bram_addr              (weight_bram_addr       [weight_bram_index]),
                .bram_en                (weight_bram_en         [weight_bram_index]),
                .bram_we                (weight_bram_we         [weight_bram_index]),
                .bram_data_out          (weight_bram_data_out   [weight_bram_index]),
                .bram_data_in           (weight_bram_data_in    [weight_bram_index])
            );
        end
    endgenerate
    //====================================================================//
    blk_mem_gen_1 weight_bram_1 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [0]),
        .wea          (weight_bram_we       [0]),
        .addra        (weight_bram_addr     [0]),
        .douta        (weight_bram_data_out [0]) 
    );    
    blk_mem_gen_2 weight_bram_2 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [1]),
        .wea          (weight_bram_we       [1]),
        .addra        (weight_bram_addr     [1]),
        .douta        (weight_bram_data_out [1]) 
    );   
    blk_mem_gen_3 weight_bram_3 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [2]),
        .wea          (weight_bram_we       [2]),
        .addra        (weight_bram_addr     [2]),
        .douta        (weight_bram_data_out [2]) 
    );    
    blk_mem_gen_4 weight_bram_4 (
        .clka         (i_clk                ),
        .ena          (weight_bram_en       [3]),
        .wea          (weight_bram_we       [3]),
        .addra        (weight_bram_addr     [3]),
        .douta        (weight_bram_data_out [3]) 
    ); 
    //====================================================================//

    genvar feature_bram_index;
    generate
        for (feature_bram_index=0; feature_bram_index < 4; feature_bram_index = feature_bram_index + 1)
        begin
            bram_controller #(
                .ADDRESS_WIDTH          (ADDRESS_WIDTH                              ), 
                .BRAM_DATA_WIDTH        (BRAM_DATA_WIDTH                            ), 
                .WRITER_DATA_IN_WIDTH   (DATA_IN_WIDTH                              ), 
                .READER_DATA_OUT_WIDTH  (PIX_WIDTH                                  ) 
            ) feature_bram_controller (
                .clk_i                  (i_clk                                      ),
                .rst_i                  (i_rst_n                                    ),    
                .rd_en_i                (feature_reader_en      [feature_bram_index]),    
                .wr_en_i                (1'b0                                       ),    
                .wr_valid_i             (feature_writer_valid   [feature_bram_index]),    
                .wr_data_i              (feature_writer_data_in [feature_bram_index]),    
                .wr_finish_o            (feature_writer_finish  [feature_bram_index]),    
                .rd_valid_o             (feature_reader_valid   [feature_bram_index]),    
                .rd_data_o              (feature_reader_data_out[feature_bram_index*PIX_WIDTH+:PIX_WIDTH]),    
                .bram_addr              (feature_bram_addr      [feature_bram_index]),    
                .bram_en                (feature_bram_en        [feature_bram_index]),    
                .bram_we                (feature_bram_we        [feature_bram_index]),    
                .bram_data_out          (feature_bram_data_out  [feature_bram_index]),    
                .bram_data_in           (feature_bram_data_in   [feature_bram_index])    
            );          
        end
    endgenerate
    //====================================================================//
    blk_mem_gen_5 feature_bram_1 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [0]),
        .wea          (feature_bram_we       [0]),
        .addra        (feature_bram_addr     [0]),
        .douta        (feature_bram_data_out [0]) 
    );    
    blk_mem_gen_6 feature_bram_2 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [1]),
        .wea          (feature_bram_we       [1]),
        .addra        (feature_bram_addr     [1]),
        .douta        (feature_bram_data_out [1]) 
    );   
    blk_mem_gen_7 feature_bram_3 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [2]),
        .wea          (feature_bram_we       [2]),
        .addra        (feature_bram_addr     [2]),
        .douta        (feature_bram_data_out [2]) 
    );    
    blk_mem_gen_8 feature_bram_4 (
        .clka         (i_clk                ),
        .ena          (feature_bram_en       [3]),
        .wea          (feature_bram_we       [3]),
        .addra        (feature_bram_addr     [3]),
        .douta        (feature_bram_data_out [3]) 
    ); 
    //====================================================================//

endmodule