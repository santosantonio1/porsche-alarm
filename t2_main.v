//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

`define SET 0               //Armado
`define OFF 1               //Desarmado
`define TRIGGER 2           //Acionando
`define ON 3                //Fazendo 'barulho'

`define DOOR_CLOSED       2'b00
`define DOOR_OPEN         2'b01
`define DOOR_CLOSED_AGAIN 2'b10

//---------------------------------
//--                             --
//--         M O D U L E         --
//--                             --
//---------------------------------

module top(
    input clock, reset, ignition, door_driver, door_pass, hidden_sw, pedal, reprogram,
    input[1:0] time_select_param,
    input[3:0] time_value,
    output status, fuel_pump_status,
    output[2:0] siren
);

//---------------------------------
//--                             --
//--   R E G I S T E R S         --
//--                             --
//---------------------------------

    //FSM States Update
    reg[1:0] EA, PE;

    //Debouncers Outputs
    reg c_ignition, c_door_driver, c_door_pass, c_hidden_sw, c_pedal, c_reprogram;
    reg tsp1, tsp0, t3, t2, t1, t0;

    //Register for Interval
    reg [1:0] interval;

    //Register to Enable Siren
    reg enable_siren;
    wire half_hz_enable;

    //Wires
    wire [3:0] value;
    wire [3:0] value_display;

//---------------------------------
//--                             --
//--   D E B O U N C E R S       --
//--                             --
//---------------------------------

debouncer DEB_IG(
    clock, reset, ignition, c_ignition
);

debouncer DEB_DOOR_DRIVER(
    clock, reset, door_driver, c_door_driver
);

debouncer DEB_DOOR_PASS(
    clock, reset, door_pass, c_door_pass
);

debouncer DEB_HIDDEN_SW(
    clock, reset, hidden_sw, c_hidden_sw
);

debouncer DEB_PEDAL(
    clock, reset, pedal, c_pedal
);

debouncer DEB_REPROGRAM(
    clock, reset, reprogram, c_reprogram
);

debouncer DEB_TIME_SELECT_PARAM_1(
    clock, reset, time_select_param[1], tsp1
);

debouncer DEB_TIME_SELECT_PARAM_0(
    clock, reset, time_select_param[0], tsp0
);

debouncer DEB_TIME_VALUE_3(
    clock, reset, time_value[3], t3
);

debouncer DEB_TIME_VALUE_2(
    clock, reset, time_value[2], t2
);

debouncer DEB_TIME_VALUE_1(
    clock, reset, time_value[1], t1
);

debouncer DEB_TIME_VALUE_0(
    clock, reset, time_value[0], t0
);

//-----------------------------------------------------------------------

//---------------------------------
//--                             --
//--         D R I V E R S       --
//--                             --
//---------------------------------

fuel_pump FUEL_PUMP_DRIVER(
    clock, reset, c_ignition, c_hidden_sw, c_pedal, fuel_pump_status
);

time_parameters TIME_PARAMETERS_DRIVER(
    clock, reset, time_param_sel, time_value, reprogram, interval, value
);

siren_generator SIREN_GENERATOR_DRIVER(
    enable_siren, half_hz_enable, siren
);

timer TIMER_DRIVER(
    clock, reset, start_timer, value, expired, one_hz_enable, half_hz_enable, value_display
);

//-----------------------------------------------------------------------

//---------------------------------
//--                             --
//--            F S M            --
//--                             --
//---------------------------------

//Inicialização Padrão da FSM
always @(posedge clock, posedge reset) begin
    if(reset) begin     
        EA <= `SET;
        D_EA <= 2'b0;       //Disarm_EA

        EA_DD <= 2'b0;
        EA_DP <= 2'b0;
    end else begin
        EA <= PE;
        D_EA <= D_PE;       //Disarm_PE

        EA_DD <= PE_DD;
        EA_DP <= PE_DP;
    end 
end 

//---------------------------------------------------------------------------------------------------
//--                            
//--            D E T E C Ç Ã O     -   A B R E    E    F E C H A       
//--                             
//---------------------------------------------------------------------------------------------------

reg[1:0] EA_DD;     //Estado Atual Motorista
reg[1:0] PE_DD;     //Proximo Estado Motorista

reg[1:0] EA_DP;     //Estado Atual   Passageiro
reg[1:0] PE_DP;     //Proximo Estado Passageiro

always@* begin
    case(EA_DD)
        `DOOR_CLOSED:  if(door_driver == 1'b1) PE_DD = `DOOR_OPEN; else PE_DD = `DOOR_CLOSED;
        `DOOR_OPEN:    if(door_driver == 1'b0) PE_DD = `DOOR_CLOSED; else PE_DD = `DOOR_CLOSED;
        `DOOR_CLOSED_AGAIN: PE_DD = `DOOR_CLOSED;
        default: PE_DD = `DOOR_CLOSED;
    endcase

    case(EA_DP)
        `DOOR_CLOSED:  if(door_pass == 1'b1) PE_DP = `DOOR_OPEN; else PE_DP = `DOOR_CLOSED;
        `DOOR_OPEN:    if(door_pass == 1'b0) PE_DP = `DOOR_CLOSED; else PE_DP = `DOOR_CLOSED;
        `DOOR_CLOSED_AGAIN: PE_DP = `DOOR_CLOSED;
        default: PE_DP = `DOOR_CLOSED;
    endcase
end
                                                        
//---------------------------------------------------------------------------------------------------

//Alteração da Nossa FSM Principal, a TOP
    
always @* begin
    if(c_reprogram) begin 
        PE <= `SET;             //Se o C_Reprogram Ativar, significa que vai direto para Armado
    end
    else begin
        case(EA)
            `SET:           //Armado
                if(c_ignition) PE <= `OFF;
                else if(c_door_driver == 1 ||c_door_pass == 1) PE <= `TRIGGER;
                else PE <= `SET;
                    
            `OFF:           //Desarmado     
                if(signalDisarm_To_Arm == 1) PE <= `SET;
                else PE <= `OFF;

            `TRIGGER:       //Acionando (Contando para Acionar) (Acionado)
                if(c_ignition) PE <= `OFF;
                else if(expired) PE <= `ON;
                else PE <= `TRIGGER;

            `ON:            //Tá ligado, BRUHHHHHHHHH           (Ativar Alarme)

            default:
        endcase
    end
end

//---------------------------------------------------------------------------------------------------
                
//FSM para Poder atualizar o OFF
reg [2:0] D_EA;
reg [2:0] D_PE;

reg signalDisarm_To_Arm;

always @(posedge clock, posedge reset) begin
    if(reset) begin
        signalDisarm_To_Arm <= 0;
    end else begin
        if(D_EA == 3'd4) begin
            signalDisarm_To_Arm <= 1;
        end else begin
            signalDisarm_To_Arm <= 0;
        end
    end
end

always @* begin
    if(EA != `OFF && c_reprogram == 0) begin
        D_PE <= 3'b0;
    end 
    else begin  
        case(D_EA)
            3'd0:  D_PE <= 3'd1;

            3'd1:  begin
                if(ignition == 1'd1) D_PE <= 3'd1;
                else D_PE <= 3'd2;
            end
            3'd2:
                if(ignition == 1'd1) D_PE <= 3'd1; else
                begin
                    if(EA_DD == `DOOR_CLOSED_AGAIN) D_PE <= 3'd3;
                    else D_PE <= 3'd2;
                end

            3'd3:
                if(ignition == 1'd1) D_PE <= 3'd1; else
                begin
                   if(EA_DD == `DOOR_OPEN) D_PE <= 3'd2;
                   else begin
                     if(expired == 1'b1) D_PE <= 3'd4;
                     else D_PE <= 3'd3;
                   end
                end

            3'd4:
                D_PE <= 3'd0;

            default: D_PE <= 3'b0;
        endcase
    end
end

endmodule
