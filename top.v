//--------------------------------------------------------------------
//--                                                                --
//--                    D E F I N E S                               --
//--                                                                --
//--------------------------------------------------------------------

`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3
`define STOP_ALARM 4

//--------------------------------------------------------------------
//--                                                                --
//--                           M O D U L E                          --
//--                                                                --
//--------------------------------------------------------------------

module top(
    input clock, reset, ignition, d_door, p_door, switch, pedal,
    output set, fp_status,
    output[2:0] siren,
    output[7:0] an, dec_cat
);

//Ig - Ignition; DD = DoorDriver; PD = Door Passenger; S = Switch; P = Break
wire ig, dd, pd, s, p;

//Times para serem atribuidos no Timer
reg[3:0] T_ARM_DELAY, T_DRIVER_DELAY, T_PASSENGER_DELAY, T_ALARM_ON;

//--------------------------------------------------------------------
//--                                                                --
//--                    D E B O U N C E R                           --
//--                                                                --
//--------------------------------------------------------------------

debouncer DEB_IG(
    .clock(clock), .reset(reset), .noisy(ignition), .clean(ig)
);

debouncer DEB_DD(
    clock, reset, d_door, dd
);

debouncer DEB_PD(
    clock, reset, p_door, pd
);

debouncer DEB_S(
    clock, reset, switch, s
);

debouncer DEB_P(
    clock, reset, pedal, p
);


//--------------------------------------------------------------------

//Tempo que o DRIVER que Utiliza, Estado Atual, Próximo Estado
reg[3:0] t, EA, PE;

//Waited - Expired; 
wire waited, load, en_timer, en_arm, en_disarm, start_count_1, start_count_2;


wire start_count_3, en_triggered;

wire[2:0] color;
wire[3:0] t_display;

reg has_p;      //Detector de Passageiro
reg door_open;  //Detecta se uma porta abriu

//--------------------------------------------------------------------
//--                                                                --
//--                         D R I V E R S                          --
//--                                                                --
//--------------------------------------------------------------------

rgb RGB_DRIVER(
    color
);

timer COUNTER(
    .clock(clock), .reset(reset), .en(en_timer), .load(load),
    .t_default(t), .waited(waited), .t_display(t_display)
);

arm ARM_DRIVER(
    .clock(clock), .reset(reset), .ignition(ig), .d_door(dd),
    .p_door(pd), .en(en_arm), .start_count(start_count_1)
);

disarm DISARM_DRIVER(
    .clock(clock), .reset(reset), .ignition(ig), .d_door(dd),
    .p_door(pd), .en(en_disarm), .start_count(start_count_2)
);

fuelpump FUEL_PUMP_DRIVER(
    .clock(clock), .reset(reset), .ignition(ig), .switch(s),
    .pedal(p), .status(fp_status)
);

dspl_drv_NexysA7 TIMER_DISPLAY(
    .clock(clock), .reset(reset), .d1({1'b1, EA, 1'b0}), .d2(0), .d3(0),
    .d4(0), .d5(0), .d6(0), .d7(0), .d8({1'b1, t_display, 1'b0}),
    .an(an), .dec_cat(dec_cat)
);

//--------------------------------------------------------------------
//--                                                                --
//--                   A S S I G N S   01                           --
//--                                                                --
//--------------------------------------------------------------------

assign load = (EA == `OFF && !start_count_1 && !en_timer) ? 1 :
              (EA == `TRIGGER && !start_count_2 && !en_timer) ? 1 :
              (EA == `ON && !en_timer) ? 1 : 0;

assign en_timer = (EA == `OFF && start_count_1) ? 1 : 
                  (EA == `TRIGGER && start_count_2) ? 1 : 
                  (EA == `STOP_ALARM) ? 1 : 0;
                  

assign en_arm = (EA == `OFF) ? 1 : 0;
assign en_disarm = (EA == `TRIGGER) ? 1 : 0;

//--------------------------------------------------------------------
//--                                                                --
//--             F S M    P R A    A T U A L I Z A                  --
//--                                                                --
//--------------------------------------------------------------------


//Always para poder atribuir: EA <= PE
always @(posedge clock, posedge reset) begin
    if(reset) begin
        EA <= `SET;
    end
    else
        EA <= PE;
end


//Switch Case para atualizar a Maquina de Estado (PE)
always @* begin
    case(EA) 
        `OFF:
            if(waited)  PE <= `SET;
            else PE <= `OFF;

        `SET:
            if(door_open) PE <= `TRIGGER;
            else PE <= `SET;

        `TRIGGER:
            if(ig) PE <= `OFF;
            else begin
                if(waited) PE <= `ON;   //Waited é o equivalente ao Expired
                else PE <= `TRIGGER;
            end

        `ON:
            if(ig) PE <= `OFF;
            else begin
                if(!dd && !pd) PE <= `STOP_ALARM;
                else PE <= `ON;
            end

        `STOP_ALARM:
            if(ig) PE <= `OFF;
            else if(!dd && !pd && waited) PE <= `SET;
                 else if(dd || pd) PE <= `ON;
                      else PE <= `STOP_ALARM;
                      
        default: PE <= `SET;
    endcase
end

//Process para poder fazer a atribuição de valores de tempos
always @(posedge clock, posedge reset) begin
    if(reset)
    begin
        t <= 0;
        T_ARM_DELAY <= 4'd6;
        T_DRIVER_DELAY <= 4'd8;
        T_PASSENGER_DELAY <= 4'd14;
        T_ALARM_ON <= 4'd10;
    end
    else
        case(EA) 
            `OFF:       t <= T_ARM_DELAY;
            `SET:       if(has_p) t <= T_PASSENGER_DELAY; else t <= T_DRIVER_DELAY;
            `TRIGGER:   if(has_p) t <= T_PASSENGER_DELAY; else t <= T_DRIVER_DELAY;
            `ON:        t <= T_ALARM_ON;
            `STOP_ALARM: t <= T_ALARM_ON;
        endcase
end

//Detector de Passageiro
always @(posedge clock, posedge reset) begin
    if(reset) begin
        has_p <= 0;
        door_open <= 0;
    end
    else begin
        if(EA == `SET && (pd||dd)) begin
             door_open <= 1; 
             if(pd) has_p <= 1;
             else has_p <= 0;
        end
        else begin 
            has_p <= 0;
            door_open <= 0;
        end
    end 
end

//Outros Assigns
assign set = (EA == `SET || EA == `TRIGGER) ? 1 : 0;
// assign siren = (EA == `ON || EA == `STOP_ALARM) ? 1 : 0;
assign siren = (EA == `ON || EA == `STOP_ALARM) ? color : 0;

endmodule
