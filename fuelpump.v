//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

`define OFF 0
`define ON 1

//---------------------------------
//--                             --
//--         M O D U L E         --
//--                             --
//---------------------------------

module fuel_pump(
    input clock, reset, ignition, switch, break,
    output status
);

//---------------------------------
//--                             --
//--   R E G I S T E R S         --
//--                             --
//---------------------------------

//States for FSM
reg EA, PE;

//---------------------------------
//--                             --
//--        P R O C E S S        --
//--                             --
//---------------------------------

//FSM Update Base per Clock / Reset
always @(posedge clock, posedge reset) 
begin
    if(reset) begin
        EA <= `OFF;
    end else begin
        EA <= PE;
    end
end

//FSM Update per * Others
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

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------

assign status = (EA == `ON) ? 1 : 0;

endmodule