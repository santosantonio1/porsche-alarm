`define OFF 0
`define ON 1

module fuel_pump(
    input clock, reset, ignition, switch, pedal,
    output status
);

reg EA, PE;

always @(posedge clock, posedge reset) 
begin
    if(reset) begin
        EA <= `OFF;
    end else begin
        EA <= PE;
    end
end

always @* 
begin
    case(EA)
        `OFF:
            if(switch && pedal && ignition)     PE <= `ON;
            else            PE <= `OFF;
        
        `ON:
            if(!ignition)   PE <= `OFF;
            else            PE <= `ON;
    endcase    
end

assign status = (EA == `ON) ? 1 : 0;

endmodule