`timescale 1ns / 1ps

module dspl_drv_NexysA7(
    input reset,
    input clock,
    input [5:0] d1,
    input [5:0] d2,
    input [5:0] d3,
    input [5:0] d4,
    input [5:0] d5,
    input [5:0] d6,
    input [5:0] d7,
    input [5:0] d8,
    output [7:0] dec_cat,
    output [7:0] an
    );    
    
    // seleciona o display a ser mostrado
    reg [2:0] selected;
    always @(posedge clock) begin
        if(reset) begin
            selected <= 3'd0;
        end
        else begin
            if(timer1ms) begin
                selected <= selected + 3'd1;
            end
        end
    end

    reg [7:0] cathode;
    always @* begin
        case(selected)
            3'b000:  cathode = {segments[d1[4:1]], ~d1[0]};
            3'b001:  cathode = {segments[d2[4:1]], ~d2[0]};
            3'b010:  cathode = {segments[d3[4:1]], ~d3[0]};
            3'b011:  cathode = {segments[d4[4:1]], ~d4[0]};
            3'b100:  cathode = {segments[d5[4:1]], ~d5[0]};
            3'b101:  cathode = {segments[d6[4:1]], ~d6[0]};
            3'b110:  cathode = {segments[d7[4:1]], ~d7[0]};
            default: cathode = {segments[d8[4:1]], ~d8[0]}; //3'b111: 
        endcase
    end

    reg [7:0] anode;
    always @* begin
        case(selected)
            3'b000:  anode = (d1[5] == 1'b1) ? 8'b0111_1111 : 8'b1111_1111; 
            3'b001:  anode = (d2[5] == 1'b1) ? 8'b1011_1111 : 8'b1111_1111;
            3'b010:  anode = (d3[5] == 1'b1) ? 8'b1101_1111 : 8'b1111_1111;
            3'b011:  anode = (d4[5] == 1'b1) ? 8'b1110_1111 : 8'b1111_1111;
            3'b100:  anode = (d5[5] == 1'b1) ? 8'b1111_0111 : 8'b1111_1111;
            3'b101:  anode = (d6[5] == 1'b1) ? 8'b1111_1011 : 8'b1111_1111;
            3'b110:  anode = (d7[5] == 1'b1) ? 8'b1111_1101 : 8'b1111_1111;
            default: anode = (d8[5] == 1'b1) ? 8'b1111_1110 : 8'b1111_1111; //3'b111: 
        endcase
    end

    // possiveis valores a serem desenhados nos displays
    wire [6:0] segments [15:0];
    assign segments[0] = 7'b1000000;
    assign segments[1] = 7'b1111001;
    assign segments[2] = 7'b0100100;
    assign segments[3] = 7'b0110000;
    assign segments[4] = 7'b0011001;
    assign segments[5] = 7'b0010010;
    assign segments[6] = 7'b0000010;
    assign segments[7] = 7'b1111000;
    assign segments[8] = 7'b0000000;
    assign segments[9] = 7'b0010000;
    assign segments[10] = 7'b0001000;
    assign segments[11] = 7'b0000011;
    assign segments[12] = 7'b1000110;
    assign segments[13] = 7'b0100001;
    assign segments[14] = 7'b0000110;
    assign segments[15] = 7'b0001110;

    // passagem do tempo
    reg timer1ms;
    reg [16:0] counter;
    
    always @(posedge clock) begin
        if(reset) begin
            timer1ms <=  1'b0;
            counter  <= 17'd0;
        end
        else begin
            if(counter == 17'd100_000) begin
                timer1ms <= 1'b1;
                counter <= 17'd0;
            end
            else begin
                timer1ms <= 1'b0;
                counter <= counter + 17'd1;
            end
        end
    end

    assign an = anode;
    assign dec_cat = cathode;
    
endmodule
