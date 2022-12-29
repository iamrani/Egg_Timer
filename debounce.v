`timescale 1ns / 1ps

module debounce
  #(
    parameter width = 1,
    parameter bounce_limit = 1024 //10 bits default
    )
  (
   input clk,
   input [width-1:0] switch_in, //IN
   output reg [width-1:0] switch_out, //ON
   output reg [width-1:0] switch_rise, //RISE section
   output reg [width-1:0] switch_fall //FALL section
   );
   // Debounces by checking the input switch reg of size [width-1]
  genvar  i; //generates variable i
  generate
    for (i=0; i<width;i=i+1) //i goes up to width-1
      begin
	reg [$clog2(bounce_limit)-1:0] bounce_count = 0; //$clog2 used for finding limit ceiling, bounce_count is 0 to "bounce_limit ceiling" bits wide
	reg switch_latched = 0;
	reg switch_latched_state = 0;

	reg [1:0] switch_shift = 0;
	always @(posedge clk) 
	  switch_shift <= {switch_shift,switch_in[i]}; //switch_shift is replaced by the concat or switch_shift and switch_in @ i
	always @(posedge clk)
	  if (bounce_count == 0) //when the bounce count is 0
	    begin
	      switch_rise[i] <= switch_shift == 2'b01; //switch rise @ i is equal to switch_shift
	      switch_fall[i] <= switch_shift == 2'b10; //switch fall @ i is equal to switch_shift
	      switch_out[i] <= switch_shift[0]; //switch-out @ i is equal to switch_shift at 0.
	      if (switch_shift[1] != switch_shift[0]) //if the switch shift of the first bit is different than the 0th bit
		bounce_count <= bounce_limit-1; //bounce-count is equal to the bounce limit decremented by 1
	    end
	  else //if the bounce_count is not equal to 0
	    begin
	      switch_rise[i] <= 0; //switch_rise @ i is 0
	      switch_fall[i] <= 0; //switch fall @i is 0
	      bounce_count <= bounce_count-1; //the bounce_count is decremented
	    end
      end
  endgenerate
endmodule
