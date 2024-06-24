`define IDLE 0 
`define WAIT_DOOR_OPEN 1
`define WAIT_DOOR_CLOSE 2
`define COUNT_DOWN 3

module arm(
    input clock, reset, ignition, d_door, p_door, en,
    output start_count
);

reg[3:0] EA, PE;

always @(posedge clock, posedge reset) 
begin
    if(reset)
        EA <= `IDLE;
    else 
        if(!en) EA <= `IDLE;
        else EA <= PE;
end

always @*
begin
    case(EA)
        `IDLE:
            if(!ignition)   PE <= `WAIT_DOOR_OPEN;
            else            PE <= `IDLE;

        `WAIT_DOOR_OPEN:
            if(d_door || p_door)      PE <= `WAIT_DOOR_CLOSE;
            else            PE <= `WAIT_DOOR_OPEN; 

        `WAIT_DOOR_CLOSE:
            if(!d_door && !p_door)     PE <= `COUNT_DOWN;
            else            PE <= `WAIT_DOOR_CLOSE;

        `COUNT_DOWN:
            if(d_door || p_door)      PE <= `WAIT_DOOR_CLOSE;
            else            PE <= `COUNT_DOWN;
    endcase
end

assign start_count = (EA == `COUNT_DOWN) ? 1 : 0;

endmodule