// File: voting_machine.v


// Button Debounce and Valid Vote Detection (Active Low)
module buttonControl(
    input clock,                 // System clock input
    input reset_n,               // Active low synchronous reset input
    input button_n,              // Active low button input for voting
    output reg valid_vote        // Output: high for one clock when a valid vote is detected
);
    reg [25:0] counter;          // Counter to measure button press duration

    always @(posedge clock) begin // Trigger on rising edge of clock
        if (!reset_n)             // If reset_n is low (reset active)
            counter <= 0;         //   Reset counter to zero
        else begin
            if (!button_n && counter < 50000001) // If button is pressed (active low) and counter not maxed
                counter <= counter + 1;           //   Increment counter
            else if (button_n)                    // If button is released (not pressed)
                counter <= 0;                     //   Reset counter
        end
    end

    always @(posedge clock) begin // Trigger on rising edge of clock
        if (!reset_n)             // If reset_n is low (reset active)
            valid_vote <= 1'b0;   //   Clear valid_vote output
        else begin
            if (counter == 50000000) // If button held for 1 second (at 50MHz)
                valid_vote <= 1'b1;   //   Set valid_vote high for one clock
            else
                valid_vote <= 1'b0;   //   Otherwise, keep valid_vote low
        end
    end
endmodule



// Vote Counting Module
module voteLogger(
    input clock,                  // System clock input
    input reset_n,                // Active low synchronous reset input
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
    always @(posedge clock) begin    // Trigger on rising edge of clock
        if (!reset_n) begin          // If reset_n is low (reset active)
            cand1_vote_recvd <= 0;   //   Reset candidate 1 vote count
            cand2_vote_recvd <= 0;   //   Reset candidate 2 vote count
            cand3_vote_recvd <= 0;   //   Reset candidate 3 vote count
            cand4_vote_recvd <= 0;   //   Reset candidate 4 vote count
        end else if (mode == 0) begin // If in voting mode
            if (cand1_vote_valid)         // If candidate 1's vote is valid
                cand1_vote_recvd <= cand1_vote_recvd + 1; //   Increment candidate 1's count
            else if (cand2_vote_valid)    // Else if candidate 2's vote is valid
                cand2_vote_recvd <= cand2_vote_recvd + 1; //   Increment candidate 2's count
            else if (cand3_vote_valid)    // Else if candidate 3's vote is valid
                cand3_vote_recvd <= cand3_vote_recvd + 1; //   Increment candidate 3's count
            else if (cand4_vote_valid)    // Else if candidate 4's vote is valid
                cand4_vote_recvd <= cand4_vote_recvd + 1; //   Increment candidate 4's count
        end
    end
endmodule



// LED and Mode Control Module
module modeControl(
    input clock,                      // System clock input
    input reset_n,                    // Active low synchronous reset input
    input mode,                       // Mode: 0 = voting, 1 = result display
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
    reg [25:0] counter; // 26 bits is enough for 50 million
    wire any_button_pressed;

    assign any_button_pressed = candidate1_button_press | candidate2_button_press |
                               candidate3_button_press | candidate4_button_press;

    always @(posedge clock) begin
        if (!reset_n) begin
            counter <= 0;
        end else if (mode == 0) begin
            if (any_button_pressed) begin
                if (counter == 0)
                    counter <= 1; // Start counter on button press
                else if (counter < 50000000)
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
        if (!reset_n) begin
            leds <= 8'h00;
        end else if (mode == 0) begin
            if (any_button_pressed && counter <= 50000000)
                leds <= 8'hFF; // All LEDs on immediately when button pressed, for 1 second
            else
                leds <= 8'h00; // LEDs off after 1 second or if no button pressed
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
    input reset_n,                // Active low synchronous reset input
    input mode,                   // Mode: 0 = voting, 1 = result display
    input button1_n,              // Active low button input for candidate 1
    input button2_n,              // Active low button input for candidate 2
    input button3_n,              // Active low button input for candidate 3
    input button4_n,              // Active low button input for candidate 4
    output [7:0] led              // Output: 8-bit LED display
);

    wire valid_vote_1;            // Valid vote pulse for candidate 1
    wire valid_vote_2;            // Valid vote pulse for candidate 2
    wire valid_vote_3;            // Valid vote pulse for candidate 3
    wire valid_vote_4;            // Valid vote pulse for candidate 4
    wire [7:0] cand1_vote_recvd;  // Vote count for candidate 1
    wire [7:0] cand2_vote_recvd;  // Vote count for candidate 2
    wire [7:0] cand3_vote_recvd;  // Vote count for candidate 3
    wire [7:0] cand4_vote_recvd;  // Vote count for candidate 4
    wire anyValidVote;            // High if any valid vote is detected

    assign anyValidVote = valid_vote_1 | valid_vote_2 | valid_vote_3 | valid_vote_4; // Combine all valid vote signals

    buttonControl bc1(            // Debounce and detect valid vote for candidate 1
        .clock(clock),
        .reset_n(reset_n),
        .button_n(button1_n),
        .valid_vote(valid_vote_1)
    );

    buttonControl bc2(            // Debounce and detect valid vote for candidate 2
        .clock(clock),
        .reset_n(reset_n),
        .button_n(button2_n),
        .valid_vote(valid_vote_2)
    );

    buttonControl bc3(            // Debounce and detect valid vote for candidate 3
        .clock(clock),
        .reset_n(reset_n),
        .button_n(button3_n),
        .valid_vote(valid_vote_3)
    );

    buttonControl bc4(            // Debounce and detect valid vote for candidate 4
        .clock(clock),
        .reset_n(reset_n),
        .button_n(button4_n),
        .valid_vote(valid_vote_4)
    );

    voteLogger VL(                // Count votes for all candidates
        .clock(clock),
        .reset_n(reset_n),
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

    modeControl MC(               // Handle LED feedback and result display
        .clock(clock),
        .reset_n(reset_n),
        .mode(mode),
        .candidate1_vote(cand1_vote_recvd),
        .candidate2_vote(cand2_vote_recvd),
        .candidate3_vote(cand3_vote_recvd),
        .candidate4_vote(cand4_vote_recvd),
        .candidate1_button_press(!button1_n), // Active low: pressed when 0
        .candidate2_button_press(!button2_n),
        .candidate3_button_press(!button3_n),
        .candidate4_button_press(!button4_n),
        .leds(led)
    );
endmodule
