`define IDLE 0
`define COUNT_DOWN 1

module disarm(
    input clock, reset, ignition, d_door, p_door, en,
    output start_count
);

reg[3:0] EA, PE;

always @(posedge clock, posedge reset) begin
    if(reset)
        EA <= `IDLE;
    else
        if(!en) EA <= `IDLE;
        else EA <= PE;
end

always @* begin
    case(EA)
        `IDLE:
            if(d_door || p_door) PE <= `COUNT_DOWN;
            else PE <= `IDLE;

        `COUNT_DOWN:
            if(ignition) PE <= `IDLE;
            else PE <= `COUNT_DOWN;
    endcase
end

assign start_count = (EA == `COUNT_DOWN) ? 1 : 0;

endmodule