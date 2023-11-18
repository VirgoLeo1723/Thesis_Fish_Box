module  overlap_pcsr
 #(
  	parameter PIX_WIDTH      = 8 ,
  	parameter SIZE_OF_INPUT  = 5 ,
  	parameter SIZE_OF_FEATURE= 2 ,
    parameter SIZE_OF_WEIGHT = 5 ,
    parameter STRIDE         = 2     
	)(
    input                                     clk_i   ,   // clock signal
    input                                     rst_i   ,   // reset signal : active low
    input                                     valid_i , 
    input                                     wr_en_i ,   //  
  	input   	[SIZE_OF_INPUT*PIX_WIDTH-1:0] buffer_i,   // input of the buffer
  	output  reg [SIZE_OF_INPUT*PIX_WIDTH-1:0] buffer_o,   // output of the buffer
  	output  reg					              valid_o 
	);
    //------------------------------------------------------
    //  				Local variable 
    //------------------------------------------------------
  	reg [5:0] 						 	                    i_wr_ptr       ; 
  	reg [5:0]                                               i_col_count    ;
    reg [(SIZE_OF_WEIGHT-1)*SIZE_OF_INPUT*PIX_WIDTH-1:0] 	internal_buffer;
  
    //------------------------------------------------------
    //  	   Write to internal memory            
    //------------------------------------------------------
    always @(posedge clk_i, negedge rst_i) 
    begin
        if (!rst_i)
        begin
            i_wr_ptr <= 0;
            i_col_count <= 0;
            internal_buffer <= {(SIZE_OF_WEIGHT-1)*(PIX_WIDTH*SIZE_OF_INPUT){1'b0}};
        end    
        else
        begin
            if (wr_en_i)
            begin
                if (i_col_count < SIZE_OF_FEATURE*SIZE_OF_WEIGHT-1) i_col_count     <= i_col_count +1 ;
                else i_col_count <= 0;
                
              	if (i_wr_ptr < SIZE_OF_WEIGHT-1 && valid_i)
                begin
                    i_wr_ptr <= i_wr_ptr + 1;
                    
                  	if ({1'b0,buffer_i} + {1'b0,internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT]} >= 1<<(PIX_WIDTH*SIZE_OF_INPUT))
                    begin
                        internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr+:PIX_WIDTH*SIZE_OF_INPUT] <= ({1'b0,buffer_i} + {1'b0,internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT]}) >>1;
                    end
                    else
                    begin
                    	internal_buffer[i_wr_ptr*PIX_WIDTH*SIZE_OF_INPUT +: PIX_WIDTH*SIZE_OF_INPUT] <= buffer_i + internal_buffer[PIX_WIDTH*SIZE_OF_INPUT*i_wr_ptr +: PIX_WIDTH*SIZE_OF_INPUT];
                    end
                end
                else
                begin 
                    i_wr_ptr        <= 0;
                    if (i_col_count < SIZE_OF_FEATURE*SIZE_OF_WEIGHT-1) internal_buffer <= {buffer_i, internal_buffer} >> STRIDE*SIZE_OF_INPUT*PIX_WIDTH;
                    else  internal_buffer <= {(SIZE_OF_WEIGHT-1)*(PIX_WIDTH*SIZE_OF_INPUT){1'b0}};
                end
            end
            else
            begin
                i_wr_ptr        <= i_wr_ptr;
                i_col_count     <= i_col_count ;
                internal_buffer <= internal_buffer;
            end
        end
    end
    //------------------------------------------------------
    //  	      Push out the result            
    //------------------------------------------------------
    always @(posedge clk_i, negedge rst_i)
    begin
        if (!rst_i)
        begin
            buffer_o <= 0;
            valid_o     <= 1'b0 ;
        end
        else
        begin
            if ((i_wr_ptr<STRIDE || i_col_count/SIZE_OF_WEIGHT >= SIZE_OF_FEATURE-1) && valid_i)
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
            else
            begin
                valid_o <= 1'b0;
            end        
        end
    end
endmodule