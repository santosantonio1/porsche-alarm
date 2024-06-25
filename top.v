`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3
`define STOP_ALARM 4

`define WAIT_IGNITION_OFF 0
`define WAIT_DOOR_OPEN 1
`define WAIT_DOOR_CLOSE 2
`define START_ARM_DELAY 3

module top(
    input clock, reset, ignition, door_driver, door_pass, hidden_sw, pedal, reprogram,
    input[1:0] time_select_param,
    input[3:0] time_value,
    output status, fuel_pump_status,
    output[2:0] siren
);

reg[2:0] EA, PE, interval;

wire c_ignition, c_door_driver, c_door_pass, c_hidden_sw, c_pedal, c_reprogram;
wire tsp1, tsp0, t3, t2, t1, t0; 
// reg enable_siren;
wire enable_siren;

wire one_hz_enable, half_hz_enable, expired, start_timer, has_pass, arm;
wire[3:0] value, value_display;
wire[7:0] an, dec_cat;

//-----------------------------------------------------------------------
//      DEBOUNCERS
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

//-------------------------------------------------------------------------------------------------------------
//              DRIVERS
//-------------------------------------------------------------------------------------------------------------
fuel_pump FUEL_PUMP_DRIVER(
    clock, reset, c_ignition, c_hidden_sw, c_pedal, fuel_pump_status
);

siren_generator SIREN_GENERATOR_DRIVER(
    enable_siren, half_hz_enable, siren
);

time_parameters TIME_CONTROL_DRIVER(
    clock, reset, {tsp1, tsp10}, {t3, t2, t1, t0}, c_reprogram, interval, value
);

timer TIMER_DRIVER(
    clock, reset, start_timer, value, expired, one_hz_enable, half_hz_enable, value_display
);

display DISPLAY_DRIVER(
    .clock(clock), .reset(reset), .d1({1'b1, 1'b0, EA, 1'b0}), .d2(0), .d3(0),
    .d4(0), .d5(0), .d6(0), .d7(0), .d8({1'b1, value_display, 1'b0}),
    .an(an), .dec_cat(dec_cat)
);
//-------------------------------------------------------------------------------------------------------------

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        EA <= `SET;
    end else begin
        EA <= PE;
    end
end

always @*
begin
    // if(c_reprogram) begin
    //     PE <= `SET;
    // end else begin
        case(EA)
            `SET: begin
                if(c_ignition) begin                     
                    PE <= `OFF; 
                end else begin 
                    if(c_door_driver || c_door_pass) begin
                        PE <= `TRIGGER; 
                    end else  begin
                        PE <= `SET; 
                    end
                end
            end
            `OFF: begin
                if(arm && expired) begin  
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
                        PE <= `ON; 
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
                        PE <= `ON;
                        end
                    end
                end

            `STOP_ALARM: begin
                if(c_ignition)  begin PE <= `OFF; end
                else if(c_door_driver || c_door_pass) begin   PE <= `ON; end
                else if(expired) begin   PE <= `OFF; end
                else   begin PE <= `STOP_ALARM; end
            end

            default:    PE <= `SET;
        endcase
    // end
end

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        interval <= 1;
    end else begin
        case(EA) 
            `SET:   if(has_pass) interval <= 2; 
                    else interval <= 1;
            `OFF:       interval <= 0;
            `ON:        interval <= 3;
            default:    interval <= 1; 
        endcase
    end
end

reg[1:0] ARM_EA, ARM_PE;

always @(posedge clock, posedge reset)
begin
    if(reset) begin
        ARM_EA <= `WAIT_IGNITION_OFF;
    end else begin
        ARM_EA <= ARM_PE;
    end
end

always @*
begin
    case(ARM_EA)
        `WAIT_DOOR_OPEN:
            if(!c_ignition)     ARM_PE <= `WAIT_DOOR_OPEN;
            else    ARM_PE <= `WAIT_IGNITION_OFF;
        
        `WAIT_DOOR_OPEN:
            if(c_ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(c_door_driver)   ARM_PE <= `WAIT_DOOR_CLOSE;
            else    ARM_PE <= `WAIT_DOOR_OPEN;

        `WAIT_DOOR_CLOSE:
            if(!c_door_driver && !c_door_pass)  ARM_PE <= `START_ARM_DELAY;
            else    ARM_PE <= `WAIT_DOOR_CLOSE;

        `START_ARM_DELAY:
            if(c_door_driver || c_door_pass)    ARM_PE <= `WAIT_DOOR_CLOSE;
            else    ARM_PE <= `START_ARM_DELAY;

    endcase
end

assign start_timer = (EA == `SET && (c_door_driver || c_door_pass)) ||
                     (EA == `OFF && ARM_EA == `WAIT_DOOR_CLOSE && ARM_PE == `START_ARM_DELAY) ||
                     (EA == `ON && PE == `STOP_ALARM);

assign has_pass = (EA == `SET && c_door_pass);

assign arm = (ARM_EA == `START_ARM_DELAY);

assign status = (EA == `SET);

assign enable_siren = (EA == `ON);

endmodule