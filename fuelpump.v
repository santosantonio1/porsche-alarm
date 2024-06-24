`define OFF 0
`define ON 1

module fuelpump(
    input clock, reset, ignition, switch, pedal,
    output status
);

reg EA, PE;

always @(posedge clock, posedge reset) begin
    if(reset)
        EA <= `OFF;
    else
        EA <= PE;
end

always @* begin
    case(EA)
        `OFF:
            if(switch && pedal && ignition) PE <= `ON;
            else    PE <= `OFF;

        `ON:
            if(!ignition)   PE <= `OFF;
            else    PE <= `ON;
    endcase
end

assign status = (EA == `ON) ? 1 : 0;

endmodule