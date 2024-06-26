`define IDLE 0
`define LOAD 1
`define OPERATE 2
`define DONE 3

module timer(
    input clock, reset, start_timer, 
    input[3:0] value,
    output expired, one_hz_enable, half_hz_enable,
    output[3:0] value_display
);

reg[1:0] EA, PE;

reg[30:0] t, hz_counter;
reg[3:0] t_seg;

reg ohze, hhze;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        EA <= `IDLE;
    end else begin
        EA <= PE;
    end
end

always @*
begin
    case(EA)

    `IDLE: 
    begin
        if(start_timer) PE <= `LOAD;
        else PE <= `IDLE;
    end
    `LOAD:      
    begin
            PE <= `OPERATE;
    end
    `OPERATE: 
    begin
            if(start_timer)      PE <= `LOAD;
            else if(t_seg<=0)    PE <= `DONE;
            else                 PE <= `OPERATE;
    end
    `DONE:
    begin
            PE <= `IDLE;
    end
    endcase
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        t_seg <= 0;
    end else begin
        case(EA)
        
        `LOAD:
        begin
            t_seg <= value;
            t <= 0;     
        end

        `OPERATE: 
        begin
            if(t < 100_000_000) begin
                t <= t + 1;
            end else begin
                t <= 0;
                t_seg <= t_seg - 1;
            end    
        end

        default:
        begin
            t <= 0;
            t_seg <= 0;
        end
        endcase
    end
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        hhze <= 0;
        ohze <= 0;
        hz_counter <= 0;
    end else begin
        if(hz_counter < 100_000_000) begin
            hz_counter <= hz_counter + 1;
            if(hz_counter == 50_000_000)
                hhze <= 1;
        end else begin
            hhze <= 0;
            ohze <= !ohze;
            hz_counter <= 0;
        end
    end
end

assign expired = (EA == `DONE);
assign one_hz_enable = ohze;
assign half_hz_enable = hhze;

assign value_display = t_seg;

endmodule