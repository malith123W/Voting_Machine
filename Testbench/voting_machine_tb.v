`timescale 1ns/1ps
`include "voting_machine.v"

module Voting_Machine_tb;

    // Testbench signals
    reg clock;
    reg reset;
    reg mode;
    reg button1, button2, button3, button4;
    wire [7:0] led;

    // Instantiate the DUT
    Voting_Machine uut (
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .button1(button1),
        .button2(button2),
        .button3(button3),
        .button4(button4),
        .led(led)
    );

    // Clock generation: 50MHz (20ns period)
    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end

    initial begin
        $dumpfile("voting_machine_tb.vcd");
        $dumpvars(0, Voting_Machine_tb);
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        mode = 0; // Voting mode
        button1 = 0;
        button2 = 0;
        button3 = 0;
        button4 = 0;

        // Apply reset
        #50;
        reset = 0;

        // Wait for system to stabilize
        #100;

        // Simulate voting for candidate 1 (hold button for >100 clocks)
        button1 = 1;
        #2200; // 110 clock cycles (20ns * 110 = 2200ns)
        button1 = 0;
        #500;

        // Unvalid vote 
        button1 = 1;
        #1200; 
        button1 = 0;
        #500;


        // Simulate voting for candidate 2
        button2 = 1;
        #2200;
        button2 = 0;
        #500;

        // Simulate voting for candidate 3
        button3 = 1;
        #2200;
        button3 = 0;
        #500;

        // Simulate voting for candidate 4
        button4 = 1;
        #2200;
        button4 = 0;
        #500;

        // Simulate a second vote for candidate 1
        button1 = 1;
        #2200;
        button1 = 0;
        #500;

        // Switch to result display mode
        mode = 1;
        #200;

        // Display candidate 1's vote count
        button1 = 1;
        #200;
        button1 = 0;
        #200;

        // Display candidate 2's vote count
        button2 = 1;
        #200;
        button2 = 0;
        #200;

        // Display candidate 3's vote count
        button3 = 1;
        #200;
        button3 = 0;
        #200;

        // Display candidate 4's vote count
        button4 = 1;
        #200;
        button4 = 0;
        #200;

        // End simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | mode=%b | btn1=%b btn2=%b btn3=%b btn4=%b | led=%h", 
                 $time, mode, button1, button2, button3, button4, led, "\n");
    end

endmodule
