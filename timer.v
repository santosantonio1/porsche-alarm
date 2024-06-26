//------------------------------------------------------------
//
//
//                      TIMER DRIVER
//
//
//------------------------------------------------------------
`define IDLE 0
`define LOAD 1
`define OPERATE 2
`define DONE 3

module timer(
    input clock, reset, start_timer, 
    input[3:0] value,
    output expired, one_hz_enable, half_hz_enable,
    output[3:0] value_display,
    output[1:0] EA_DISPLAY
);

// State, next state
reg[1:0] EA, PE;

// Counters
reg[30:0] t, hz_counter;

// Time in seconds
reg[3:0] t_seg;

// one_hz_enable, half_hz_enable
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
    
    // Load value
    `LOAD:      
    begin
            PE <= `OPERATE;
    end
    // Count down 
    `OPERATE: 
    begin
            if(start_timer)      PE <= `LOAD;
            else if(t_seg<=0)    PE <= `DONE;
            else                 PE <= `OPERATE;
    end

    // Waited delay
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
        t <= 0; // Maybe remove
    end else begin
        case(EA)
        
        `LOAD:
        begin
            t_seg <= value;
            t <= 0;     
        end

        `OPERATE: 
        begin
            // clock period = 10 ns ---> 100_000_000 ns = 1 s counted
            if(t < 100_000_000) begin
                t <= t + 1;
            end else begin
                t <= 0;
                // Decrement display
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

// Decrement routine for one_hz_enable and half_hz_enable (always running)
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        hhze <= 0;
        ohze <= 0;
        hz_counter <= 0;
    end else begin
        // 1 s
        if(hz_counter < 100_000_000) begin
            hz_counter <= hz_counter + 1;
            // 0.5 s
            if(hz_counter == 50_000_000)
                hhze <= 1;
        end else begin
            hhze <= 0;
            ohze <= !ohze;
            hz_counter <= 0;
        end
    end
end

// Waited delay
assign expired = (EA == `DONE);

assign one_hz_enable = ohze;
assign half_hz_enable = hhze;
assign value_display = t_seg;
assign EA_DISPLAY = EA;

endmodule