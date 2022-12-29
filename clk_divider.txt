`timescale 1ns / 1ps

module clk_divider(
    input five_mhz_clk,
    output reg five_Hundred_hz_clk,
    output reg one_hz_clk
    );
    integer five_Hundred_hz_count, one_hz_count;
    
    always @ (posedge five_mhz_clk) begin
 
        if(one_hz_count == 2500000) begin
            one_hz_count = 0;
            one_hz_clk = ~one_hz_clk;
        end
        if(five_Hundred_hz_count == 5000) begin
            five_Hundred_hz_count = 0;
            five_Hundred_hz_clk = ~five_Hundred_hz_clk;
        end
        five_Hundred_hz_count = five_Hundred_hz_count + 1;
        one_hz_count = one_hz_count + 1;
   end

endmodule
