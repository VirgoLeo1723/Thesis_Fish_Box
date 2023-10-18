module  overlap_pcsr
 #(
  	parameter BIT_WIDTH    = 8 ,
  	parameter INPUT_WIDTH  = 5 ,
    parameter KERNEL_WIDTH = 5 ,
    parameter STRIDE       = 2     
	)(
    input                                   clk_i   ,   // clock signal
    input                                   rst_i   ,   // reset signal : active low 
    input                                   wr_en_i ,   //  
  	input   	[INPUT_WIDTH*BIT_WIDTH-1:0] buffer_i,   // input of the buffer
  	output  reg [INPUT_WIDTH*BIT_WIDTH-1:0] buffer_o,   // output of the buffer
  	output  reg					            valid_o 
	);
    //------------------------------------------------------
    //  				Local variable 
    //------------------------------------------------------
  	reg [5:0] 						 	                i_wr_ptr       ; 
    reg [(KERNEL_WIDTH-1)*INPUT_WIDTH*BIT_WIDTH-1:0] 	internal_buffer;
  
    //------------------------------------------------------
    //  	   Write to internal memory            
    //------------------------------------------------------
    always @(posedge clk_i, negedge rst_i) 
    begin
        if (!rst_i)
        begin
            i_wr_ptr <= 0;
            internal_buffer <= {KERNEL_WIDTH*BIT_WIDTH{1'b0}};
        end    
        else
        begin
            if (wr_en_i )
            begin
              	if (i_wr_ptr < KERNEL_WIDTH-1)
                begin
                    i_wr_ptr <= i_wr_ptr + 1;
                  	if ({1'b0,buffer_i} + {1'b0,internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH]} >= 1<<BIT_WIDTH)
                    begin
                        internal_buffer[BIT_WIDTH*i_wr_ptr+:BIT_WIDTH] <= ({1'b0,buffer_i} + {1'b0,internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH]}) >>1;
                    end
                    else
                    begin
                    	internal_buffer[i_wr_ptr*BIT_WIDTH +: BIT_WIDTH] <= buffer_i + internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH];
                    end
                end
                else
                begin 
                    i_wr_ptr        <= 0;
                    internal_buffer <= {buffer_i, internal_buffer} >> STRIDE*BIT_WIDTH;
                end
            end
            else
            begin
                i_wr_ptr        <= i_wr_ptr;
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
            valid_o     <= 1'b1;
        end
        else
        begin
            if (i_wr_ptr<STRIDE)
            begin
                if ({1'b0,buffer_i} + {1'b0,internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH]} >= 1<<BIT_WIDTH)
                begin
                    buffer_o    <= ({1'b0,buffer_i} + {1'b0,internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH]}) >>1;
                    valid_o     <= 1'b1;
                end
                else 
                begin
                    buffer_o    <= buffer_i + internal_buffer[BIT_WIDTH*i_wr_ptr +: BIT_WIDTH];
                    valid_o     <= 1'b1;
                end
            end 
            else
            begin
                valid_o <= 1'b0;
            end        
        end
    end
endmodule