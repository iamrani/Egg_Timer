`timescale 1ns / 1ps



module Display_controller(
    input refresh_clk, one_hz_clk, ready,[3:0] v_sec1,[3:0] v_sec2, [3:0] v_min1, [3:0] v_min2, [1:0] v_select, v_flash,
    output reg rdy_flash, reg [6:0] seg, reg [7:0] an // seg and an goes to BCD controller
    );
    //There are only 4 anodes in use, so anum goes from 0 to 3
    reg v_toggle;
    integer display;
    integer v_flash_count;
    
    //1st digit for seconds (connects count for digit to BCD digit)
    wire [6:0] seg_sec1;
    wire [7:0] an_sec1;
    
    BCD_Decoder s1_bcd(
        .v      (v_sec1),
        .anum   (3'd0),
        .seg    (seg_sec1),
        .an     (an_sec1)
    );
     //2nd digit for seconds
    wire [6:0] seg_sec2;
    wire [7:0] an_sec2;
    BCD_Decoder s2_bcd( 
        .v      (v_sec2),
        .anum   (3'd1),
        .seg    (seg_sec2),
        .an     (an_sec2)
    );
     //1st digit for minutes
    wire [6:0] seg_min1;
    wire [7:0] an_min1;
    BCD_Decoder m1_bcd(
        .v      (v_min1),
        .anum   (3'd2),
        .seg    (seg_min1),
        .an     (an_min1)
    );
     //2nd digit for minutes
    wire [6:0] seg_min2;
    wire [7:0] an_min2;
    BCD_Decoder m2_bcd(
        .v      (v_min2),
        .anum   (3'd3),
        .seg    (seg_min2),
        .an     (an_min2)
    );
    
    
    
    //Controls the 7 segment display
    
    //flashes digit if v_flash_count
    always @(posedge refresh_clk) begin
        if(v_flash_count == 300) begin
            v_flash_count = 0;
            v_toggle = !v_toggle; //turns anode on or off. (flashes it)
        end
        case(display)
        5: display = 0; //if display is 5, display becomes 0.
        4: begin
            if(v_flash & v_select == 2'b11) begin //if changing 2nd digit of minutes & flashing anode
                 if(v_toggle) seg[6:0] <= seg_min2[6:0]; //if anode is lit up during flash sequence,
                                                         // enter 2nd digit of minutes into BCD seg
                 else seg[6:0] <= 7'b1111111; //if not, anode is off (creates flashing)
            end
            else begin
                seg[6:0] <= seg_min2[6:0]; // if not changing 2nd digit of minutes & flashing anode, enter 2nd digit of minutes into BCD seg
            end
            an[7:0] <= an_min2[7:0]; //2nd anode of minutes is fed into an of BCD_Decoder.
        end
        3: begin
             if(v_flash & v_select == 2'b10) begin //if changing 1st digit of minutes & flashing anode
                if(v_toggle) seg[6:0] <= seg_min1[6:0]; //if anode is lit up during flash sequence,
                                                        // enter 1st digit of minutes into BCD seg
                else seg[6:0] <= 7'b1111111; //if not, anode is off (creates flashing)
            end
            else begin
                seg[6:0] <= seg_min1[6:0]; // if not changing 1st digit of minutes & flashing anode, enter 2nd digit of minutes into BCD seg
            end
                an[7:0] <= an_min1[7:0]; //1st anode of minutes is fed into an of BCD_Decoder.
        end
        2: begin
            if(v_flash & v_select == 2'b01) begin
                if(v_toggle) seg[6:0] <= seg_sec2[6:0]; //if anode is lit up during flash sequence,
                                                        // enter 2nd digit of seconds into BCD seg
                else seg[6:0] <= 7'b1111111; //if not, anode is off (creates flashing)
            end
            else begin
                seg[6:0] <= seg_sec2[6:0]; // if not changing 2nd digit of seconds & flashing anode, enter 2nd digit of seconds into BCD seg
            end
                an[7:0] <= an_sec2[7:0]; //2nd anode of seconds is fed into an of BCD_Decoder.
        end
        1: begin
            if(v_flash & v_select == 2'b00) begin
                if(v_toggle) seg[6:0] <= seg_sec1[6:0]; //if anode is lit up during flash sequence,
                                                        // enter 1st digit of seconds into BCD seg
                else seg[6:0] <= 7'b1111111; //if not, anode is off (creates flashing)
            end
            else begin
                seg[6:0] <= seg_sec1[6:0]; // if not changing 1st digit of seconds & flashing anode, enter 2nd digit of seconds into BCD seg
            end
                an[7:0] <= an_sec1[7:0]; //1st anode of seconds is fed into an of BCD_Decoder.
            end
      
        endcase
        display <= display + 1; //add 1 to display
        v_flash_count <= v_flash_count + 1; //add 1 to v_flash_count
    end
    // Ready On Flash
    always @ (posedge one_hz_clk) begin 
        if(ready) begin // if ready to LED flash
            rdy_flash <= !rdy_flash; //rdy_flash turns on and off every 1 Hz
        end
        else rdy_flash <= 'b0; // if LED flash not ready, just leave at 0.
    end
endmodule
`timescale 1ns / 1ps
