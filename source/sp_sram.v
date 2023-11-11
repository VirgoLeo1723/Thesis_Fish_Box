module sp_sram 
# (
    parameter WIDTH  = 10,
    parameter DEPTH  = 128,
    parameter ADDRB  = $clog2(DEPTH)
)
(
    input                   clk,
    input                   ena,
    input                   wea,
    input                   rea,
    input       [ADDRB-1:0] addr_i,
    input       [ADDRB-1:0] addr_o,
    input       [WIDTH-1:0] dina_0,
    input       [WIDTH-1:0] dina_1,
    input       [WIDTH-1:0] dina_2,
    input       [WIDTH-1:0] dina_3,
    output reg  [WIDTH-1:0] douta
);


//===============================================================================
// REGISTER/WIRE
//===============================================================================
reg     [WIDTH-1:0] mem [DEPTH-1:0];

//===============================================================================
// MODULE BODY
//===============================================================================
always @ (posedge clk)
begin
    if (ena & rea) begin
        if (addr_o < DEPTH) begin
            douta <= mem[addra];
        end
    end
end

always @ (posedge clk)
begin
    if (ena & wea) begin
        if (addr_i < DEPTH) begin
            mem[addra]    <= dina_0;
            mem[addra+1]  <= dina_1;
            mem[addra+2]  <= dina_2;
            mem[addra+3]  <= dina_3;
        end
    end
end

endmodule
