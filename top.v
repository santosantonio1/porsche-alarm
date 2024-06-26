//---------------------------------
//--                             --
//--       D E F I N E S         --
//--                             --
//---------------------------------

`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3
`define STOP_ALARM 4

`define WAIT_IGNITION_OFF 0
`define WAIT_DOOR_OPEN 1
`define WAIT_DOOR_CLOSE 2
`define START_ARM_DELAY 3

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
    output[2:0] siren,
    output[7:0] an, dec_cat
);

//---------------------------------
//--                             --
//--     R E G I S T E R S       --
//--                             --
//---------------------------------

//Registradores para poder controlar a FSM principal
reg[2:0] EA, PE;

//Registrador que é responsável por mandar o Intervalo que vai ser utilizado pelo Time_Parameters
reg[2:0] interval;

//Wires conectados nos Debouncers
wire c_ignition, c_door_driver, c_door_pass, c_hidden_sw, c_pedal, c_reprogram;
wire tsp1, tsp0, t3, t2, t1, t0; 

//Wire conectado com a entrada do Driver Siren_Generator
wire enable_siren;

reg enable_siren_register;      // Registrador que recebe enable_siren
reg half_hz_register;           // Periodo de 1 Segundos
reg one_hz_register;            // Periodo de 2 Segundos

//Wires que se conectam com o Driver de Tempo
wire one_hz_enable, half_hz_enable, expired, start_timer;

//Wires conectado com o value para conectar no Driver de Tempo. E o Value_Display para "Debuggar" na FPGA
wire[3:0] value, value_display;

//---------------------------------
//--                             --
//--    D E B O U N C E R S      --
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
//--       D R I V E R S         --
//--                             --
//---------------------------------

fuel_pump FUEL_PUMP_DRIVER(
    clock, reset, c_ignition, c_hidden_sw, c_pedal, fuel_pump_status
);

siren_generator SIREN_GENERATOR_DRIVER(
    enable_siren, half_hz_register, siren
);

time_parameters TIME_CONTROL_DRIVER(
    clock, reset, {tsp1, tsp0}, {t3, t2, t1, t0}, c_reprogram, interval, value
);

timer TIMER_DRIVER(
    .clock(clock), .reset(reset), .start_timer(start_timer), 
    .value(value), .expired(expired), .one_hz_enable(one_hz_enable),
    .half_hz_enable(half_hz_enable), 
    .value_display(value_display)
);

display DISPLAY_DRIVER(
    .clock(clock), .reset(reset), 
    .d1({1'b1, 1'b0, EA, 1'b0}), 
    .d2({1'b1, 3'b000, expired, 1'b0}), 
    .d3({1'b1, 1'b0, ARM_EA, 1'b0}),
    .d4({1'b1, 2'b0, {tsp1, tsp0}, 1'b0}), 
    .d5({1'b1, {t3,t2,t1,t0}, 1'b0}), 
    .d6(0), 
    .d7(0), 
    .d8({1'b1, value_display, 1'b0}),
    .an(an), .dec_cat(dec_cat)
);
//-------------------------------------------------------------------------------------------------------------

//---------------------------------
//--                             --
//--  F S M   -  P R O C E S S   --
//--                             --
//---------------------------------

//Atualiza a Maquina de Estados Principais (Estado "Inicial" é Armado)
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        EA <= `SET;
    end else begin
        EA <= PE;
    end
end

always @(posedge clock, posedge reset) begin
    if(reset) begin
        half_hz_register <= 0;
        one_hz_register <= 0;
    end else begin
        if(one_hz_enable) begin one_hz_register <= ! one_hz_register; end
 
        if(half_hz_enable) begin half_hz_register <= ! half_hz_register; end
    end
end 

//Atualiza o PE que será recebido pelo EA (Ou seja, atualizador de Próximo Estado)
always @*
begin
    if(c_reprogram) begin
        PE <= `SET;
    end else begin
        case(EA)
            `SET: begin //Estado de Armado: C_IGNITION (Desarma Sempre) || C_DOOR_DRIVER or C_DOOR_PASS (Vai para o Estado de tempo que espera a Ignição)
                if(c_ignition) begin                     
                    PE <= `OFF; 
                end else begin 
                    if(c_door_driver || c_door_pass)
                        PE <= 3'd5; 
                    else 
                        PE <= `SET; 
                end
            end

            `OFF: begin
                if(ARM_EA == 3'd4 && expired && !c_ignition) begin  
                    PE <= `SET; 
                end else begin 
                    PE <= `OFF; 
                end
            end

            `TRIGGER: begin
                if(c_ignition) begin
                    PE <= `OFF; 
                end
                else begin 
                    if(expired) begin   
                        PE <= 3'd6; 
                    end
                    else  begin             
                        PE <= `TRIGGER;
                    end
                end
            end

            `ON: begin
                if(c_ignition)  begin
                    PE <= `OFF;
                end else begin
                    if(!c_door_driver && !c_door_pass) begin     
                        PE <= `STOP_ALARM;
                    end else begin
                        PE <= 3'd6;
                        end
                    end
                end

            `STOP_ALARM: begin
                if(c_ignition)  begin PE <= `OFF; end
                else if(c_door_driver || c_door_pass) begin   PE <= `ON; end
                else if(expired) begin   PE <= `SET; end
                else   begin PE <= `STOP_ALARM; end
            end

            3'd5: begin
                PE <= `TRIGGER;
            end

            3'd6: begin
                //Ir para o estado de Ativa Alarme
                PE <= `ON;
            end

            default:    PE <= `SET;
        endcase
    end
end

//---------------------------------
//--                             --
//--   Value's of Interval       --
//--                             --
//---------------------------------

//Always responsável pela inserção do valor de "Intervalo" no Timer_Driver
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        interval <= 1; // T_DRIVER_DELAY    
    end else begin
        case(EA) 
            `SET:   begin                                           //Armado
                    if(c_door_pass) 
                        interval <= 2; //T_PASS_DELAY   
                    else 
                        interval <= 1; //T_DRIVER_DELAY
            end

            `OFF:     begin  interval <= 0; end                     //Desarmado - T_ARM_DELAY

            `ON:      begin  interval <= 3; end     //Estado 5      //Ativar_Alarme - T_ALARM_ON

            `STOP_ALARM: begin interval <= 3; end   //Estado 4  - T_ALARM_ON

            `TRIGGER: begin interval <= 3; end                      //Acionado - T_ALARM_ON

            default:  begin interval <= 1;  end                     // T_DRIVER_DELAY (Como Default)
        endcase
    end
end

//-------------------------------------------------
//--                             
//--     State of ARM_EA (FSM do Armado)       
//--                             
//-------------------------------------------------

//Registrador para controlar essa FSM Paralela
reg[2:0] ARM_EA, ARM_PE;

//Atualiza o Estado_Atual do Detector de Armar
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        ARM_EA <= `WAIT_IGNITION_OFF;
    end else begin
        ARM_EA <= ARM_PE;
    end
end

//Condições de troca para o ARM_PE (Importante para detecção)
always @* begin
case(ARM_EA)
        `WAIT_IGNITION_OFF:
            if(!c_ignition)     ARM_PE <= `WAIT_DOOR_OPEN;
            else    ARM_PE <= `WAIT_IGNITION_OFF;
        
        `WAIT_DOOR_OPEN:
            if(c_ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(c_door_driver)   ARM_PE <= `WAIT_DOOR_CLOSE;
            else    ARM_PE <= `WAIT_DOOR_OPEN;

        `WAIT_DOOR_CLOSE:
            if(!c_door_driver && !c_door_pass)  ARM_PE <= `START_ARM_DELAY;
            else    ARM_PE <= `WAIT_DOOR_CLOSE;

        `START_ARM_DELAY: begin
                ARM_PE <= 3'd4;
        end

        3'd4: begin
            if(c_ignition) ARM_PE <= `WAIT_IGNITION_OFF; 
            else begin
            if(expired) begin ARM_PE <= 3'd5; end
            else begin
                if(c_door_driver || c_door_pass) begin ARM_PE <= `WAIT_DOOR_CLOSE; end 
                else ARM_PE <= 3'd4;
            end
        end
        end

        3'd5:
            ARM_PE <= 3'd0;
            
        default: ARM_PE <= `WAIT_DOOR_OPEN;
    endcase
end

//-------------------------------------------------------------------------------------------------------------

//---------------------------------
//--                             --
//--       A S S I G N s         --
//--                             --
//---------------------------------

assign start_timer = (EA == `SET && (c_door_driver || c_door_pass)) ||
                     (EA == `OFF && ARM_EA == `START_ARM_DELAY) ||
                     //(EA == `ON && PE == `STOP_ALARM) || 
                     (EA == 3'd5) ||
                     (EA == 3'd6);

assign status = ((EA == `SET && (one_hz_register == 1'b1)) || (EA == `TRIGGER) || (EA == `ON) || (EA == `STOP_ALARM));

assign enable_siren = (EA == `ON || (EA == `STOP_ALARM && (!c_door_driver && !c_door_pass)));

endmodule