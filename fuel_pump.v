//------------------------------------------------------------
//
//
//                      FUEL PUMP DRIVER
//
//      authors: Antônio dos Santos, Nathan Cidal
//      github: @santosantonio1, @NathanCidal
//      version: 26/06/2024
//
//------------------------------------------------------------

`define OFF 0
`define ON 1

module fuel_pump(
    input clock, reset, ignition, switch, pedal,
    output status
);

reg EA, PE;

//-----------------------------------------
//           STATE TRANSITION
//-----------------------------------------
always @(posedge clock, posedge reset) 
begin
    if(reset) begin
        EA <= `OFF;
    end else begin
        EA <= PE;
    end
end

//-------------------------------------------------------------
//                      FSM DEFINITION
//-------------------------------------------------------------
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