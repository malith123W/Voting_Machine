`timescale 1ns / 1ps // Set simulation time unit and precision

// Button Debounce and Valid Vote Detection
module buttonControl(
    input clock,                 // System clock input
    input reset,                 // Synchronous reset input
    input button,                // Button input for voting
    output reg valid_vote        // Output: high for one clock when a valid vote is detected
);
    reg [30:0] counter;          // Counter to measure button press duration

    always @(posedge clock) begin // Trigger on rising edge of clock
        if (reset)                // If reset is active
            counter <= 0;         //   Reset counter to zero
        else begin
            if (button && counter < 100000001) // If button is pressed and counter not maxed
                counter <= counter + 1;        //   Increment counter
            else if (!button)                  // If button is released
                counter <= 0;                  //   Reset counter
        end
    end

    always @(posedge clock) begin // Trigger on rising edge of clock
        if (reset)                // If reset is active
            valid_vote <= 1'b0;   //   Clear valid_vote output
        else begin
            if (counter == 100000000) // If button held for 1 second (at 100MHz)
                valid_vote <= 1'b1;   //   Set valid_vote high for one clock
            else
                valid_vote <= 1'b0;   //   Otherwise, keep valid_vote low
        end
    end
endmodule



// Vote Counting Module
module voteLogger(
    input clock,                  // System clock input
    input reset,                  // Synchronous reset input
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
        if (reset) begin             // If reset is active
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
    input reset,                      // Synchronous reset input
    input mode,                       // Mode: 0 = voting, 1 = result display
    input valid_vote_casted,          // High for one clock when any valid vote is cast
    input [7:0] candidate1_vote,      // Vote count for candidate 1
    input [7:0] candidate2_vote,      // Vote count for candidate 2
    input [7:0] candidate3_vote,      // Vote count for candidate 3
    input [7:0] candidate4_vote,      // Vote count for candidate 4
    input candidate1_button_press,    // Button press for candidate 1 (for result display)
    input candidate2_button_press,    // Button press for candidate 2 (for result display)
    input candidate3_button_press,    // Button press for candidate 3 (for result display)
    input candidate4_button_press,    // Button press for candidate 4 (for result display)
    output reg [7:0] leds             // Output: 8-bit LED display
);
    reg [30:0] counter;               // Counter for feedback timing

    always @(posedge clock) begin     // Trigger on rising edge of clock
        if (reset)                    // If reset is active
            counter <= 0;             //   Reset counter
        else if (valid_vote_casted)   // If a valid vote was just cast
            counter <= 1;             //   Start feedback counter
        else if (counter > 0 && counter < 100000000) // If counter active and not maxed
            counter <= counter + 1;   //   Increment counter
        else
            counter <= 0;             //   Otherwise, reset counter
    end    

    always @(posedge clock) begin     // Trigger on rising edge of clock
        if (reset)                    // If reset is active
            leds <= 0;                //   Turn off all LEDs
        else begin
            if (mode == 0) begin          // If in voting mode
                if (counter > 0)          //   If feedback counter active
                    leds <= 8'hFF;        //     Turn on all LEDs for feedback
                else
                    leds <= 8'h00;        //     Otherwise, turn off all LEDs
            end else begin                // Else, in result mode
                if (candidate1_button_press)       //   If candidate 1's button is pressed
                    leds <= candidate1_vote;       //     Show candidate 1's vote count
                else if (candidate2_button_press)  //   Else if candidate 2's button is pressed
                    leds <= candidate2_vote;       //     Show candidate 2's vote count
                else if (candidate3_button_press)  //   Else if candidate 3's button is pressed
                    leds <= candidate3_vote;       //     Show candidate 3's vote count
                else if (candidate4_button_press)  //   Else if candidate 4's button is pressed
                    leds <= candidate4_vote;       //     Show candidate 4's vote count
                else
                    leds <= 8'h00;                 //     Otherwise, turn off all LEDs
            end
        end  
    end
endmodule



// Top-Level Voting Machine Module
module votingMachine(
    input clock,                  // System clock input
    input reset,                  // Synchronous reset input
    input mode,                   // Mode: 0 = voting, 1 = result display
    input button1,                // Button input for candidate 1
    input button2,                // Button input for candidate 2
    input button3,                // Button input for candidate 3
    input button4,                // Button input for candidate 4
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
        .reset(reset),
        .button(button1),
        .valid_vote(valid_vote_1)
    );

    buttonControl bc2(            // Debounce and detect valid vote for candidate 2
        .clock(clock),
        .reset(reset),
        .button(button2),
        .valid_vote(valid_vote_2)
    );

    buttonControl bc3(            // Debounce and detect valid vote for candidate 3
        .clock(clock),
        .reset(reset),
        .button(button3),
        .valid_vote(valid_vote_3)
    );

    buttonControl bc4(            // Debounce and detect valid vote for candidate 4
        .clock(clock),
        .reset(reset),
        .button(button4),
        .valid_vote(valid_vote_4)
    );

    voteLogger VL(                // Count votes for all candidates
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

    modeControl MC(               // Handle LED feedback and result display
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .valid_vote_casted(anyValidVote),
        .candidate1_vote(cand1_vote_recvd),
        .candidate2_vote(cand2_vote_recvd),
        .candidate3_vote(cand3_vote_recvd),
        .candidate4_vote(cand4_vote_recvd),
        .candidate1_button_press(valid_vote_1),
        .candidate2_button_press(valid_vote_2),
        .candidate3_button_press(valid_vote_3),
        .candidate4_button_press(valid_vote_4),
        .leds(led)
    );
endmodule
