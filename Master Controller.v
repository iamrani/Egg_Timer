`timescale 1ns / 1ps

module Master_controller(
    input  Hundred_mhz_clk, //CLK100MHZ
    // Control input:  UP,LEFT,RIGHT
    input rst, start, stop, // BTNU, BTNL, BTNR
    // Encoder input: Switch 11 - Increase or decrease by 1,Switch 10 - Increase or decrease, Switch 9 - Program clock
    //Swtich 8 - Enable programming
    input inc_dec_by1, inc_or_dec, switch_switch, enable_program, // Increase Or Decrease By 1(SW11), Increase or Decrease Direction (SW10), Switch the digit (SW9), Enable Time Program (SW8)
    // Display Output: Flash Led, segment , anode
    output rdy_flash,[6:0] seg,[7:0] an
    );
/////////////////////////Declarations of reg, parameters, wire, integer//////////////////////////////////////
    //States
    reg ready;
    reg [1:0] state, nxt_state; //current and next state
    parameter stop_state=0, start_state=1, set_state=2, rst_state=3;
    reg [3:0] setVal_state, setVal_nstate;
    parameter setnone=0, set_s1=5, set_s2=6, set_m1=7, set_m2=8;
    
    // Stopwatch Value registers
    reg [3:0] vs1;
    reg [3:0] vs2;
    reg [3:0] vm1;
    reg [3:0] vm2;
    
    // Set Value registers
    reg [3:0] vSets1;
    reg [2:0] vSets2;
    reg [3:0] vSetm1;
    reg [3:0] vSetm2; 
    
    // Counter Control
    reg counter_load;
    reg enable;
    reg count_finished;
    // Set Control
    reg set;
    
    // Display Control
    integer display;
    reg vflash;
    reg [1:0] vselect;
    
    // Clock Divider
    wire fiveHundred_hz_clk;
    wire one_hz_clk;
    wire five_mhz_clk;
/////////////////////////Clocking//////////////////////////////////////    
    clk_wiz_0 clk_wiz(
      .clk_out1(five_mhz_clk),
      .clk_in1(Hundred_mhz_clk) //CLK100MHZ
    );
      
    clk_divider clk_div(
        .five_mhz_clk       (five_mhz_clk),
        .five_Hundred_hz_clk (fiveHundred_hz_clk),
        .one_hz_clk         (one_hz_clk)
    );
////////////////////Debouncing///////////////////////////////////////////
    // Rotary Encoder Debouncer
    wire enc_inc_dec_by1;     
    wire enc_inc_or_dec;     
    wire enc_btn_db;    
    wire enc_inc_dec_by1_rise;    
    wire enc_inc_or_dec_rise;    
    wire enc_btn_rise;    
    wire enc_inc_dec_by1_fall;     
    wire enc_inc_or_dec_fall;      
    wire enc_btn_fall;   
    //using the debouncer (not that the results can be seen by controlling a GUI)
     debounce #(
           .width(3),
           .bounce_limit(50000)
           ) deb(
         .clk(Hundred_mhz_clk),  //CLK100MHZ
         .switch_in({inc_dec_by1,inc_or_dec,switch_switch}),
         .switch_out({enc_inc_dec_by1,enc_inc_or_dec,enc_btn_db}),
         .switch_rise({enc_inc_dec_by1_rise,enc_inc_or_dec_rise,enc_btn_rise}),
         .switch_fall({enc_inc_dec_by1_fall,enc_inc_or_dec_fall,enc_btn_fall})
     );
     
////////////////////Reset+Next State Control///////////////////////////////////////////     
    // Stopwatch control FSM
    always @(posedge Hundred_mhz_clk or posedge rst) begin  //CLK100MHZ
        if(rst) state <= rst_state;
        else if(enable_program) state <= set_state;
        else state <= nxt_state;
    end
/////////////////////////Value Reset+Value Next State Control//////////////////////////////////////    
    // Set Value control FSM
    always @(posedge Hundred_mhz_clk or posedge rst) begin  //CLK100MHZ
        if(rst) setVal_state <= set_s1;
        else setVal_state <= setVal_nstate;
    end
//////////////////////////Start, Stop, Enable Program Buttons Pressed/////////////////////////////////////

// What state it should go on depending if STOP, START, ProgramEnable are pressed.
    always @(state or start or stop or enable_program or count_finished) begin
        case(state)
            stop_state: begin
                if(start) nxt_state = start_state; //When in STOP state, if START is pressed, next state = start state
                else nxt_state = stop_state; // If no START pressed, next state = stop state
            end
            start_state: begin
                if(stop | count_finished) nxt_state = stop_state; //When in START state, if STOP pressed OR the count is finished, next state = stop state.
                else nxt_state = start_state; // if not, next state = start state
            end
            set_state: begin
                if(!enable_program) nxt_state = stop_state; // When in set-State, when program_enable is NOT pressed, then next state = stop state
                else nxt_state = set_state; // program_enable is ON, then we go into the set state mode (loop)
            end
            rst_state: begin //When in the reset state, the next state = stop state
                nxt_state = stop_state;
            end
            default nxt_state = stop_state; //by default, if no case argumwents have been met, then next state = stop state
        endcase
    end
//////////////////////////When Each Digit Selected to Program SW9/////////////////////////////////////    
    //When program_enable ON, what to do when each digit selected
    //When SW9 on falling to 0, the anode flashing (the digit that is being programmed) is moved onto the next, 
    //if not, then it remains on the same digit
    always @(setVal_state or enc_btn_fall or enable_program or vs1 or vs2 or vm1 or vm2) begin
        case(setVal_state)
            setnone: begin //when @ setnone
                vselect = 2'b00;
                if(enable_program) setVal_nstate = set_s1; //if program_enable ON, setVal_next state = set_s1
                else setVal_nstate = setnone; //if not, loop
            end
            set_s1: begin //when @set_s1 (first digit of seconds)
                vselect = 2'b00;
                if(enc_btn_fall) setVal_nstate = set_s2; //when turning switch_switch OFF (fall) go to next state (2nd seconds digit)
                else if(!enable_program) setVal_nstate = setnone; //if program_enable OFF, go to setnone
                else setVal_nstate = set_s1; //if not, loop
            end
            set_s2: begin//when @set_s2 (2nd digit of seconds)
                vselect = 2'b01;
                if(enc_btn_fall) setVal_nstate = set_m1;//when turning switch_switch OFF (fall) go to next state (1st minutes digit)
                else if(!enable_program) setVal_nstate = setnone; //if program_enable OFF, go to setnone
                else setVal_nstate = set_s2; //if not, loop
            end
            set_m1: begin //when @set_m1 (first digit of minutes)
                vselect = 2'b10;
                if(enc_btn_fall) setVal_nstate = set_m2;//when turning switch_switch OFF (fall) go to next state (2nd minutes digit)
                else if(!enable_program) setVal_nstate = setnone; //if program_enable OFF, go to setnone
                else setVal_nstate = set_m1;  //if not, loop
            end
            set_m2: begin
                vselect = 2'b11; //when @set_m2 (2nd digit of minutes)
                if(enc_btn_fall) setVal_nstate = set_s1;  //when turning switch_switch OFF (fall) go to next state (1st seconds digit)(LOOP)
                else if(!enable_program) setVal_nstate = setnone; //if program_enable OFF, go to setnone
                else setVal_nstate = set_m2; //if not, loop
            end
            default: begin
                vselect = 2'b00;
                setVal_nstate = setnone; //by default, setVal-nextstate = setnone (go to setnone)
            end
        endcase
    end
/////////////////////////Actions prescribed when Program States//////////////////////////////////////


// what to do when state is STOP, START, SET, RST states
// changing the numbers in the BCD if set = 1, change BCD only when set = 1
// enable is when counting down occurs (needs to be off to change the values)????
// ready is for LED flash ON and OFF
// vflash is 1 when SET = 1 (causes BCD to flash when changing the digit.)

    always @(state or set or enable or ready or vflash) begin
        case(state)
            stop_state: begin 
                set = 'b0; // not program time
                enable = 'b0; // not counting down
                ready = 1'b1; // LED flashing ON and OFF (innovation LED1)
                vflash = 'b0; // BCD NOT flashing ON and OFF (anode does not flash in stop state)
            end
            start_state: begin
                set = 'b0; //no program time
                enable = 1'b1; //COUNTING down
                ready = 'b0; //LED NOT flashing ON and OFF
                vflash = 'b0; // BCD NOT flashing ON and OFF
            end
            set_state: begin
                set = 1'b1; //PROGRAM time
                enable = 'b0; // not counting down
                ready = 'b0; //LED NOT flashing ON and OFF
                vflash = 1'b1; //BCD FLASHING ON and OFF (anode is flashing)
            end
            rst_state: begin
                set = 'b0; //no program time
                enable = 'b0; // not counting down
                ready = 'b0; //LED NOT flashing ON and OFF
                vflash = 'b0; // BCD NOT flashing ON and OFF
            end
            default: begin
                set = 'b0; //no program time
                enable = 'b0; // not counting down
                ready = 'b0; //LED NOT flashing ON and OFF
                vflash = 'b0; // BCD NOT flashing ON and OFF
            end
        endcase
    end
 ////////////////////////////Counting Down Looping///////////////////////////////////   
    
    // counting mech
    always@(posedge one_hz_clk or posedge rst) begin
        if(rst) begin //if reset pressed, all displays are 0, and the finished_count is reset to 0
            vs1 <= 'b0;
            vs2 <= 'b0;
            vm1 <= 'b0;
            vm2 <= 'b0;
            count_finished <= 'b0;
        end
        else if(set) begin //if programming time, program time with vSet# AND count not finished
            vs1 <= vSets1;
            vs2 <= vSets2;
            vm1 <= vSetm1;
            vm2 <= vSetm2;
            count_finished <= 'b0;
        end
        else if(enable) begin //if enable, this else if  series makes the numbers decrease by 1 seconds, and when 9->0 is reached it starts it at 9 again. or for the tens digit it is 5->0 and then 5 again
            if(state == stop_state) count_finished <= 'b0; //if stop_state, count not finished (paused)

            //looping of :20 to :19 changes 2 -> 1 and 0 -> 9
            if(vs1 == 4'd0 & vs2 > 4'd0) begin //if 1stDIG seconds is 0 and 2ndDIG is over 0
                vs1 <= 4'd9; // 1stDIG is 9
                vs2 <= vs2 - 4'b0001;
            end
            //looping of 28 to 27 8->7
            else if(vs1 > 4'b0) begin
                vs1 <= vs1 - 4'b0001;
                count_finished <= 'b0;
            end
            //looping of 2:00 to 1:59 2->1 00->59
            else if(vs1 == 4'd0 & vs2 == 4'd0 & vm1 > 4'd0) begin
                vs1 <= 4'd9;
                vs2 <= 4'd5;
                vm1 <= vm1 - 4'b0001;
            end
            
            // looping of 20:00 to 19:59 2->1 0:00->9:59
            else if(vs1 == 4'd0 & vs2 == 4'd0 & vm1 == 4'd0 & vm2 > 4'd0) begin
                vs1 <= 4'd9;
                vs2 <= 4'd5;
                vm1 <= 4'd9;
                vm2 <= vm2 - 4'b0001;
            end
            // if 00:00, then count is finished!
            else if(vs1 == 4'd0 & vs2 == 4'd0 & vm1 == 4'd0 & vm2 == 4'd0) begin
                count_finished <= 1; 
            end
        end
    end
 //////////////////////////Programming the Time/////////////////////////////////////   
    // For programming time (set) when buttons inc_or_dec and inc_or_dec_by1 pressed.
    always@(posedge Hundred_mhz_clk or posedge rst) begin // //CLK100MHZ
		if(rst) begin //if reset, all become 00:00
            vSets1 <= 'b0;
            vSets2 <= 'b0;
            vSetm1 <= 'b0;
            vSetm2 <= 'b0;
        end
        else if(setVal_state == setnone) begin //if setValstate == setnone (figures what to do when enable is ON or OFF)
        // keep the same seconds and minutes if at set-none
            vSets1 <= vs1;
            vSets2 <= vs2;
            vSetm1 <= vm1;
            vSetm2 <= vm2;
        end
		else begin
			if (enc_inc_dec_by1_rise) //if adding 1 or subtracting 1
				if (!enc_inc_or_dec) //if it is in the decreasing direction (!enc_inc_or_dec) (subtracting direction)
					case(setVal_state) // then remove 1 from the selected digit
						set_s1: if(vSets1 > 0) vSets1 <= vSets1-1; 
						set_s2: if(vSets2 > 0) vSets2 <= vSets2-1;
						set_m1: if(vSetm1 > 0) vSetm1 <= vSetm1-1;
						set_m2: if(vSetm2 > 0) vSetm2 <= vSetm2-1;
						default: begin //for default, keep same digits
							vSets1 <= vs1;
							vSets2 <= vs2;
							vSetm1 <= vm1;
							vSetm2 <= vm2;
						end
					endcase
			else if(enc_inc_or_dec) //if it is in the increasing direction (enc_inc_or_dec) (addition direction)
				case(setVal_state) // then add 1 from the selected digit EXCEPT for setnone
					setnone: begin //if at set_none, keep same digits
						vSets1 <= vs1;
						vSets2 <= vs2;
						vSetm1 <= vm1;
						vSetm2 <= vm2;
					end
					set_s1: if(vSets1 < 9) vSets1 <= vSets1+1; 
					set_s2: if(vSets2 < 5) vSets2 <= vSets2+1;
					set_m1: if(vSetm1 < 9) vSetm1 <= vSetm1+1;
					set_m2: if(vSetm2 < 5) vSetm2 <= vSetm2+1;
					default: begin // for default, keep the same digits
						vSets1 <= vs1;
						vSets2 <= vs2;
						vSetm1 <= vm1;
						vSetm2 <= vm2;
					end
				endcase
		end
    end
  //////////////////////Controlling the Display/////////////////////////////////////////  
    //Enter 500Hz, 1Hz, Ready, Digit Counts, selecting which digit to change, flahsing, and seg+an
    //Controls the Display
    Display_controller disp_cont(
        .refresh_clk    (fiveHundred_hz_clk),
        .one_hz_clk     (one_hz_clk),
        .ready          (ready),
        .v_sec1           (v_sec1), //vs1
        .v_sec2           (v_sec2), //vs2
        .v_min1           (vm1),
        .v_min2           (vm2),
        .v_select       (vselect),
        .v_flash        (vflash),
        .rdy_flash    (rdy_flash),
        .seg            (seg),
        .an             (an)
    );

endmodule
