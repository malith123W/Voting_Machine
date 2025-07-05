// File: voting_machine.v

// Button Debounce and Valid Vote Detection (Active High)
module buttonControl(
    input clock,                 // System clock input
    input reset,                 // Active high synchronous reset input
    input button,                // Active high button input for voting
    output reg valid_vote        // Output: high for one clock when a valid vote is detected
);
    reg [6:0] counter;          // Counter to measure button press duration

    always @(posedge clock) begin
        if (reset)               // If reset is high (reset active)
            counter <= 0;        //   Reset counter to zero
        else begin
            if (button && counter < 101) // If button is pressed (active high) and counter not maxed
                counter <= counter + 1;  //   Increment counter
            else if (!button)            // If button is released (not pressed)
                counter <= 0;            //   Reset counter
        end
    end

    always @(posedge clock) begin
        if (reset)               // If reset is high (reset active)
            valid_vote <= 1'b0;  //   Clear valid_vote output
        else begin
            if (counter == 100)  // If button held for 1us second (at 100MHz)
                valid_vote <= 1'b1;   //   Set valid_vote high for one clock
            else
                valid_vote <= 1'b0;   //   Otherwise, keep valid_vote low
        end
    end
endmodule

// Vote Counting Module
module voteLogger(
    input clock,                  // System clock input
    input reset,                  // Active high synchronous reset input
    input mode,                   // Mode: 0 = voting, 1 = result display
    input cand1_vote_valid,       // Valid vote for candidate 1
    input cand2_vote_valid,       // Valid vote for candidate 2
    input cand3_vote_valid,       // Valid vote for candidate 3
    input cand4_vote_valid,       // Valid vote for candidate 4
    output reg [7:0] cand1_vote_recvd, // Vote count for candidate 1
    output reg [7:0] cand2_vote_recvd, // Vote count for candidate 2
    output reg [7:0] cand3_vote_recvd, // Vote count for candidate 3
    output reg [7:0] cand4_vote_recvd  // Vote count for candidate 4
);
    always @(posedge clock) begin
        if (reset) begin                // If reset is high (reset active)
            cand1_vote_recvd <= 0;
            cand2_vote_recvd <= 0;
            cand3_vote_recvd <= 0;
            cand4_vote_recvd <= 0;
        end else if (mode == 0) begin   // If in voting mode
            if (cand1_vote_valid)
                cand1_vote_recvd <= cand1_vote_recvd + 1;
            else if (cand2_vote_valid)
                cand2_vote_recvd <= cand2_vote_recvd + 1;
            else if (cand3_vote_valid)
                cand3_vote_recvd <= cand3_vote_recvd + 1;
            else if (cand4_vote_valid)
                cand4_vote_recvd <= cand4_vote_recvd + 1;
        end
    end
endmodule

// LED and Mode Control Module
module modeControl(
    input clock,                      // System clock input
    input reset,                      // Active high synchronous reset input
    input mode,                       // Mode: 0 = voting, 1 = result display
    input valid_vote_casted,          // High for one clock when any valid vote is cast
    input [7:0] candidate1_vote,      // Vote count for candidate 1
    input [7:0] candidate2_vote,      // Vote count for candidate 2
    input [7:0] candidate3_vote,      // Vote count for candidate 3
    input [7:0] candidate4_vote,      // Vote count for candidate 4
    input candidate1_button_press,    // Button press for candidate 1 (active high)
    input candidate2_button_press,    // Button press for candidate 2 (active high)
    input candidate3_button_press,    // Button press for candidate 3 (active high)
    input candidate4_button_press,    // Button press for candidate 4 (active high)
    output reg [7:0] leds             // Output: 8-bit LED display
);
    reg [6:0] counter;               // Counter for feedback timing
    wire any_button_pressed;

    assign any_button_pressed = candidate1_button_press | candidate2_button_press |
                               candidate3_button_press | candidate4_button_press;

    always @(posedge clock) begin
        if (reset) begin
            counter <= 0;
        end else if (mode == 0) begin
            if (any_button_pressed) begin
                if (counter == 0)
                    counter <= 1; // Start counter on button press
                else if (counter < 100) // Set your desired duration here
                    counter <= counter + 1;
                // else counter holds at max value until button released
            end else begin
                counter <= 0; // Reset counter when no button is pressed
            end
        end else begin
            counter <= 0; // Reset counter in result mode
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            leds <= 8'h00;
        end else if (mode == 0) begin
            if (any_button_pressed && counter < 100)
                leds <= 8'hFF; // All LEDs on immediately when button pressed
            else
                leds <= 8'h00; // LEDs off after counter expires or no button pressed
        end else begin
            // Result display mode logic
            if (candidate1_button_press)
                leds <= candidate1_vote;
            else if (candidate2_button_press)
                leds <= candidate2_vote;
            else if (candidate3_button_press)
                leds <= candidate3_vote;
            else if (candidate4_button_press)
                leds <= candidate4_vote;
            else
                leds <= 8'h00;
        end
    end
endmodule


// Top-Level Voting Machine Module
module Voting_Machine(
    input clock,                  // System clock input
    input reset,                  // Active high synchronous reset input
    input mode,                   // Mode: 0 = voting, 1 = result display
    input button1,                // Active high button input for candidate 1
    input button2,                // Active high button input for candidate 2
    input button3,                // Active high button input for candidate 3
    input button4,                // Active high button input for candidate 4
    output [7:0] led              // Output: 8-bit LED display
);

    wire valid_vote_1;
    wire valid_vote_2;
    wire valid_vote_3;
    wire valid_vote_4;
    wire [7:0] cand1_vote_recvd;
    wire [7:0] cand2_vote_recvd;
    wire [7:0] cand3_vote_recvd;
    wire [7:0] cand4_vote_recvd;
    wire anyValidVote;

    assign anyValidVote = valid_vote_1 | valid_vote_2 | valid_vote_3 | valid_vote_4;

    buttonControl bc1(
        .clock(clock),
        .reset(reset),
        .button(button1),
        .valid_vote(valid_vote_1)
    );

    buttonControl bc2(
        .clock(clock),
        .reset(reset),
        .button(button2),
        .valid_vote(valid_vote_2)
    );

    buttonControl bc3(
        .clock(clock),
        .reset(reset),
        .button(button3),
        .valid_vote(valid_vote_3)
    );

    buttonControl bc4(
        .clock(clock),
        .reset(reset),
        .button(button4),
        .valid_vote(valid_vote_4)
    );

    voteLogger VL(
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .cand1_vote_valid(valid_vote_1),
        .cand2_vote_valid(valid_vote_2),
        .cand3_vote_valid(valid_vote_3),
        .cand4_vote_valid(valid_vote_4),
        .cand1_vote_recvd(cand1_vote_recvd),
        .cand2_vote_recvd(cand2_vote_recvd),
        .cand3_vote_recvd(cand3_vote_recvd),
        .cand4_vote_recvd(cand4_vote_recvd)
    );

    modeControl MC(
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .valid_vote_casted(anyValidVote),
        .candidate1_vote(cand1_vote_recvd),
        .candidate2_vote(cand2_vote_recvd),
        .candidate3_vote(cand3_vote_recvd),
        .candidate4_vote(cand4_vote_recvd),
        .candidate1_button_press(button1), // Active high: pressed when 1
        .candidate2_button_press(button2),
        .candidate3_button_press(button3),
        .candidate4_button_press(button4),
        .leds(led)
    );
endmodule
