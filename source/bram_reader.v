`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/24/2023 03:46:09 PM
// Design Name: 
// Module Name: bram_reader
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
module bram_reader #(
    ADDRESS_WIDTH  = 13,
    DATA_IN_WIDTH  = 32,
    DATA_OUT_WIDTH = 8
)(
    input                               clk_i       ,
    input                               rst_i       ,
    input                               en_i        ,
    input       [DATA_IN_WIDTH-1:0]     data_i      ,
    output reg  [DATA_OUT_WIDTH-1:0]    data_o      ,
    output reg                          valid_o     ,
    output reg  [ADDRESS_WIDTH-1:0]     bram_addr   ,
    output                              bram_en     ,
    output      [3:0]                   bram_we          
);
    // Code your design here
    reg [31:0]  bram_data       ; 
    reg         bram_init = 1'b1;
    integer     masking_counter ;
    
    assign bram_we = 4'd0;
    assign bram_en = en_i;
    
 	always @(posedge clk_i, negedge rst_i)
  	begin
		if (!rst_i)
      	begin
            bram_data       <= {DATA_IN_WIDTH{1'b0}} ;
            bram_addr       <= {DATA_OUT_WIDTH{1'b0}};
            data_o          <= {DATA_OUT_WIDTH{1'b0}};
            masking_counter <= 4'd0                  ;
            valid_o         <= 1'b0                  ;
        end
        else
        begin
            if (bram_en)
          	begin
            	if (bram_init==1'b1)
             	begin
             	    masking_counter <= masking_counter + 1;  
                	if (masking_counter == 0 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                    begin
                      	valid_o <= 1'b0;
                    end
                    else if (masking_counter == 1 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                 	begin
                      	valid_o   <= 1'b1;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, data_i};
                  	end
                  	else if ( masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-2 )
                    begin
                      	bram_addr           <= bram_addr + 1                      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	if ((DATA_IN_WIDTH/DATA_OUT_WIDTH)>2) 
                      	begin
                      	     {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};
                      	     valid_o    	     <= 1'b1							      ;
                      	end
                      	else
                      	begin
                    	 	 {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, data_i};
                      	end                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-1)
                    begin
                    	if ((DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                    	begin
                      	     masking_counter    <= masking_counter + 1   			  ;
                            {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};   
                            valid_o             <= 1'b1;
                        end
                        else
                        begin
                            masking_counter     <= 0                      			  ;
                            bram_init           <= 1'b0                               ;
                            bram_data           <= data_i                             ;
                            data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ; 
                        end                   
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH))
                  	begin
                        valid_o             <= 1'b1								  ;
                      	masking_counter     <= 0                      			  ;
                      	bram_init           <= 1'b0                               ;
                        bram_data           <= data_i                             ;
                      	data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ;  	     
                  	end
                  	else
                    begin
                    	valid_o 			<= 1'b1								  ;
                      	masking_counter     <= masking_counter + 1				  ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
              	end
              	else
                begin
                  	if (masking_counter == 0 && (DATA_IN_WIDTH/DATA_OUT_WIDTH)>2)
                   	begin
                      	valid_o             <= 1'b1                               ;
                      	masking_counter     <= masking_counter + 1                ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                    else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-3)
                    begin
                      	valid_o    			<= 1'b1							      ;
                      	bram_addr           <= bram_addr + 1                      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-2)
                    begin
                      	valid_o    			<= 1'b1	;			
                      	if ( (DATA_IN_WIDTH/DATA_OUT_WIDTH) <=2) bram_addr <= bram_addr+ 1			      ;
                      	masking_counter		<= masking_counter + 1                ;
                      	{bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                  	else if (masking_counter == (DATA_IN_WIDTH/DATA_OUT_WIDTH)-1)
                    begin
                    	valid_o             <= 1'b1								  ;
                      	masking_counter     <= 0                      			  ;
                        bram_data           <= data_i                             ;
                      	data_o              <= bram_data[0+:DATA_OUT_WIDTH]       ;                     
                    end
                  	else
                    begin
                    	valid_o 			<= 1'b1								  ;
                      	masking_counter     <= masking_counter + 1				  ;
                        {bram_data ,data_o} <= {{DATA_OUT_WIDTH{1'b0}}, bram_data};                      
                    end
                end
          	end
          	else
          	begin
              	valid_o     <= 1'b0;
         	  	bram_addr   <= bram_addr;
        	  	bram_data   <= bram_data;
          	end
        end
    end
endmodule 
