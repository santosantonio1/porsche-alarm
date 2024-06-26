//------------------------------------------------------------
//
//
//                FINITE STATE MACHINE DRIVER
//
//
//------------------------------------------------------------

`define SET 0
`define OFF 1
`define TRIGGER 2
`define ON 3
`define STOP_ALARM 4

`define WAIT_IGNITION_OFF 0
`define WAIT_DOOR_OPEN 1
`define WAIT_DOOR_CLOSE 2
`define START_ARM_DELAY 3

module fsm(
    input clock, reset, ignition, door_driver, door_pass, one_hz_enable, expired, reprogram,
    output start_timer, status, enable_siren, 
    output[1:0] interval, ARM_EA_DISPLAY,
    output[2:0] EA_DISPLAY
);

// Main fsm
reg[2:0] EA, PE;

// FSM for setting up the alarm and time selector
reg[1:0] ARM_EA, ARM_PE, time_sel;

// Ready or not for set up
wire arm;

//--------------------------------------------
//              STATE TRANSITION
//--------------------------------------------
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        EA <= `SET;
    end else begin
        EA <= PE;
    end
end

//----------------------------------------------------------------------
//                       MAIN FSM DEFINITION
//----------------------------------------------------------------------
always @*
begin
    if(reprogram) begin 
        PE <= `SET;
    end else begin 
    if(ignition)  PE <= `OFF;
    else begin
        case(EA)
            // Alarm set up
            `SET:
            begin
                if(door_driver || door_pass)    PE <= `TRIGGER;
                else        PE <= `SET;
            end

            // Alarm disarmed
            `OFF:
            begin
                if(expired && arm)  PE <= `SET;
                else PE <= `OFF;
            end

            // Trigger alarm (count down)
            `TRIGGER:
            begin
                if(expired)     PE <= `ON;
                else            PE <= `TRIGGER;
            end

            // Alarm on
            `ON:
            begin
                if(!door_driver && !door_pass)     PE <= `STOP_ALARM;
                else    PE <= `ON;
            end

            // Wait for  T_ALARM_ON
            `STOP_ALARM:
            begin
                if(expired)     PE <= `SET;
                else if(door_driver || door_pass)   PE <= `ON;
                else    PE <= `STOP_ALARM;
            end

            default: PE <= `SET;

        endcase
        end
    end
end

//--------------------------------------------
//      INNER FSM STATE TRANSITION
//--------------------------------------------
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        ARM_EA <= `WAIT_IGNITION_OFF;
    end else begin
        ARM_EA <= ARM_PE;
    end
end

//------------------------------------------------------------------------------
//                       INNER FSM TO SETUP ALARM
//------------------------------------------------------------------------------
always @*
begin
    case(ARM_EA)
        `WAIT_IGNITION_OFF:
        begin
            if(!ignition)     ARM_PE <= `WAIT_DOOR_OPEN;
            else        ARM_PE <= `WAIT_IGNITION_OFF;
        end 

        `WAIT_DOOR_OPEN:
        begin
            if(door_driver)       ARM_PE <= `WAIT_DOOR_CLOSE;
            else        ARM_PE <= `WAIT_DOOR_OPEN;
        end

        `WAIT_DOOR_CLOSE:
        begin
            if(ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(!door_driver && !door_pass)      ARM_PE <= `START_ARM_DELAY;
            else        ARM_PE <= `WAIT_DOOR_CLOSE;
        end 

        `START_ARM_DELAY:
        begin
            if(ignition)      ARM_PE <= `WAIT_IGNITION_OFF;
            else if(door_driver || door_pass)   ARM_PE <= `WAIT_DOOR_CLOSE;
            else        ARM_PE <= `START_ARM_DELAY;
        end 
    endcase
end

//--------------------------------------------------
//              TIMER DELAY SELECTOR
//--------------------------------------------------
always @(posedge clock, posedge reset)
begin
    if(reset) begin
        time_sel <= 1;
    end else begin
        case(EA)
            `SET:
            begin
                if(door_pass) time_sel <= 2;
                else time_sel <= 1;
            end
            `OFF:   time_sel <= 0;

            `TRIGGER:   time_sel <= 3;
        endcase
    end
end

// START TIMER WHEN APPROPRIATE
assign start_timer = (EA == `TRIGGER && expired)        || 
                     (EA == `OFF && ARM_EA == `WAIT_DOOR_CLOSE && ARM_PE == `START_ARM_DELAY)  ||
                     (EA == `SET && PE == `TRIGGER)     ||
                     (EA == `ON && PE == `STOP_ALARM);

// SIGNAL TO SET UP THE ALARM
assign arm = (ARM_EA == `START_ARM_DELAY);

// 2 SEC PERIOD ALARM STATUS
assign status = ((EA == `SET && (one_hz_enable)) || (EA == `TRIGGER) || (EA == `ON) || EA == (`STOP_ALARM));

// ALARM ITSELF
assign enable_siren = (EA == `ON || EA == `STOP_ALARM);

//...
assign interval = time_sel;
assign EA_DISPLAY = EA;
assign ARM_EA_DISPLAY = ARM_EA;

endmodule