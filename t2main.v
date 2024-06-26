//------------------------------------------------------------
//
//
//                        TOP DRIVER
//
//      authors: Antônio dos Santos, Nathan Cidal
//      github: @santosantonio1, @NathanCidal
//      version: 26/06/2024
//
//------------------------------------------------------------

// Dont forget to rename to t2_main.v

module top(
    input clock, reset, ignition, door_driver, door_pass, hidden_sw, pedal, reprogram,
    input[1:0] time_select_param,
    input[3:0] time_value,
    output status, fuel_pump_status,
    output[2:0] siren,
    output[7:0] an, dec_cat
);

// State display
wire[2:0] EA, PE;

//--------------
//  Clean outputs from debouncer
wire c_ignition, c_door_driver, c_door_pass, c_hidden_sw, c_pedal, c_reprogram;
wire tsp1, tsp0, t3, t2, t1, t0; 
//-------------

// State display and time selector
wire[1:0] ARM_EA, TIMER_EA, interval;

// Status period, siren period, waited delay, ...
wire one_hz_enable, half_hz_enable, expired, start_timer, arm, enable_siren;

// Time sent to TIMER_DRIVER and time shown on 7 seg display
wire[3:0] value, value_display;

//-----------------------------------------------------------------------
//                          DEBOUNCERS
//-----------------------------------------------------------------------
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

//-------------------------------------------------------------------------------------------
//                                  DRIVERS
//-------------------------------------------------------------------------------------------
fuel_pump FUEL_PUMP_DRIVER(
    clock, reset, c_ignition, c_hidden_sw, c_pedal, fuel_pump_status
);

siren_generator SIREN_GENERATOR_DRIVER(
    enable_siren, half_hz_enable, siren
);

time_parameters TIME_CONTROL_DRIVER(
    clock, reset, {tsp1, tsp0}, {t3, t2, t1, t0}, c_reprogram, interval, value
);

timer TIMER_DRIVER(
    clock, reset, start_timer, value, expired, one_hz_enable, half_hz_enable, value_display, TIMER_EA
);

display DISPLAY_DRIVER(
    .clock(clock), .reset(reset), 
    .d1({1'b1, 1'b0, EA, 1'b0}), 
    .d2({1'b1, 2'b00, ARM_EA, 1'b0}), 
    .d3(0),
    .d4({1'b1, 2'b0, {tsp1, tsp0}, 1'b0}), 
    .d5({1'b1, {t3,t2,t1,t0}, 1'b0}), 
    .d6(0), 
    .d7({1'b1, 2'b00, TIMER_EA, 1'b0}), 
    .d8({1'b1, value_display, 1'b0}),
    .an(an), .dec_cat(dec_cat)
);

fsm FSM_DRIVER(
    .clock(clock), 
    .reset(reset), 
    .ignition(c_ignition), 
    .door_driver(c_door_driver), 
    .door_pass(c_door_pass), 
    .one_hz_enable(one_hz_enable), 
    .expired(expired), 
    .reprogram(c_reprogram),
    .start_timer(start_timer), 
    .status(status), 
    .enable_siren(enable_siren), 
    .interval(interval), 
    .ARM_EA_DISPLAY(ARM_EA),
    .EA_DISPLAY(EA)
);
//-------------------------------------------------------------------------------------------------------------

endmodule