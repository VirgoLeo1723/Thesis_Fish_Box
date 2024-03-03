`include "gan_common_define.vh"
module  overlap_prcs
 #(
  	parameter PIX_WIDTH      = 8 ,
  	parameter SIZE_OF_INPUT  = 5 ,
  	parameter SIZE_OF_FEATURE= 2 ,
    parameter SIZE_OF_WEIGHT = 5 ,
    parameter STRIDE         = 2     
	)(
    input                                       clk_i               ,   // clock signal
    input                                       rst_i               ,   // reset signal : active low
    input [31:0]                                i_param_cfg_weight  ,   // runtime weight configuration                     (size, channel, num )
    input [31:0]                                i_param_cfg_feature ,   // runtime feature configuration                    (size, channel      )
    input [31:0]                                i_param_cfg_output  ,   // runtime output of each component configuration   (size, channel,     )
    input                                       valid_i             ,   // valid signal which indicate valid input  
    input                                       wr_en_i             ,   //  
    input       [SIZE_OF_INPUT*PIX_WIDTH-1:0]   buffer_i            ,   // input of the buffer
    output  reg [SIZE_OF_INPUT*PIX_WIDTH-1:0]   buffer_o            ,   // output of the buffer
    output  reg                                 valid_o 
	);

    //------------------------------------------------------
    //  				Local variable 
    //------------------------------------------------------
  	reg [5:0] 						 	                    i_wr_ptr       ; 
  	reg [5:0]                                               i_col_count    ;
    reg [(SIZE_OF_WEIGHT-1)*SIZE_OF_INPUT*PIX_WIDTH-1:0] 	internal_buffer;
    
    //------------------------------------------------------
    //                  related task 
    //------------------------------------------------------
    task internal_buffer_reset();
        automatic integer loop_var;
        begin
            i_wr_ptr <= 0;
            i_col_count <= 0;
            for (loop_var = 0; loop_var<(`WEIGHT_SIZE-1)*`SHIFT_REGISTER_RESULT_SIZE; loop_var = loop_var + 1)
            begin
                internal_buffer[loop_var*PIX_WIDTH+:PIX_WIDTH] <= {PIX_WIDTH{1'b0}};
            end
        end
    endtask // internal_buffer_reset

    // execute pixel1 + pixel2 -> save into vector2
    task plus_two_pixel(input [PIX_WIDTH-1:0]pixel_1, inout [PIX_WIDTH-1:0] pixel_2);
        begin
            if ({1'b0,pixel_1} + {1'b0, pixel_2} >= 1<<PIX_WIDTH)
            begin
                pixel_2 <= ({1'b0,pixel_1} + {1'b0, pixel_2}) >>1;
            end 
            else 
            begin
                pixel_2 <= pixel_1 + pixel_2;
            end
        end
    endtask // plus_2_pixel 
    
    // execute vector1 + vector2 -> save into vector2
    task plus_two_vector (input [SIZE_OF_INPUT*PIX_WIDTH-1:0]vector_1, inout [SIZE_OF_INPUT-1:0]vector_2);
        automatic integer loop_var;
        begin
            for (loop_var= 0; loop_var< `SHIFT_REGISTER_RESULT_SIZE; loop_var = loop_var + 1)
            begin
                plus_two_pixel(
                    .pixel_1(vector_1[loop_var*PIX_WIDTH+:PIX_WIDTH]),
                    .pixel_2(vector_2[loop_var*PIX_WIDTH+:PIX_WIDTH])
                ); 
            end
        end 
    endtask // plus_two_vector

    task internal_buffer_process();
        automatic integer loop_var;
        begin
            if (i_col_count < `FEATURE_SIZE*`WEIGHT_SIZE-1) 
            begin 
                i_col_count     <= i_col_count +1 ;
            end
            else 
            begin 
                i_col_count <= 0;
            end
            if (i_wr_ptr < `WEIGHT_SIZE-1 && valid_i)
            begin
                i_wr_ptr <= i_wr_ptr + 1;
                plus_two_vector(
                    .vector_1 (buffer_i),
                    .vector_2 (internal_buffer[i_wr_ptr * SIZE_OF_INPUT * PIX_WIDTH])
                );
            end
            else
            begin 
                i_wr_ptr        <= 0;
                if (i_col_count < SIZE_OF_FEATURE*SIZE_OF_WEIGHT-1) 
                begin 
                    internal_buffer <= {buffer_i, internal_buffer} >> STRIDE*SIZE_OF_INPUT*PIX_WIDTH;
                end
                else
                begin
                    for (loop_var = 0; loop_var<(`WEIGHT_SIZE-1)*`SHIFT_REGISTER_RESULT_SIZE; loop_var = loop_var + 1)
                    begin
                        internal_buffer[loop_var*PIX_WIDTH+:PIX_WIDTH] <= {PIX_WIDTH{1'b0}};
                    end
                end
            end
        end
    endtask // internal_buffer_process 

    task internal_buffer_idle ();
        begin
            i_wr_ptr        <= i_wr_ptr;
            i_col_count     <= i_col_count ;
            internal_buffer <= internal_buffer;
        end
    endtask // internal_buffer_idle
    
    task output_reset();
        begin
            buffer_o <= 0;
            valid_o <= 0;
        end
    endtask // output_reset

    task output_process();
        begin
            if (i_col_count<SIZE_OF_FEATURE*SIZE_OF_WEIGHT-1)
            begin
                if ({1'b0,buffer_i} + {1'b0,internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT]} >= 1<<(PIX_WIDTH*SIZE_OF_INPUT))
                begin
                    buffer_o    <= ({1'b0,buffer_i} + {1'b0,internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT]}) >>1;
                    valid_o     <= 1'b1;
                end
                else 
                begin
                    buffer_o    <= buffer_i + internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT];
                    valid_o     <= 1'b1;
                end
            end
            else
            begin
                buffer_o <= buffer_i;
                valid_o <= 1'b1;
            end
        end
    endtask // output_process

    //------------------------------------------------------
    //  	   Write to internal memory            
    //------------------------------------------------------
    always @(posedge clk_i, negedge rst_i) 
    begin
        if (!rst_i)
        begin
            internal_buffer_reset(); 
        end    
        else
        begin
            if (wr_en_i) 
                internal_buffer_process();
            else
                internal_buffer_idle();
        end
    end
    //------------------------------------------------------
    //  	      Push out the result            
    //------------------------------------------------------
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            output_reset();
        end
        else
        begin
            if ((i_wr_ptr<STRIDE || i_col_count/SIZE_OF_WEIGHT >= SIZE_OF_FEATURE-1) && valid_i)
                output_process();
            else
                valid_o <= 1'b0;
        end
    end
endmodule
