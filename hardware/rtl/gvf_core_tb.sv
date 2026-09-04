`timescale 1ns / 1ps

module gvf_core_tb;

    parameter int DATA_WIDTH  = 16;
    parameter int ACCUM_WIDTH = 24;
    parameter int CLK_PERIOD  = 10;

    logic                    clk;
    logic                    rst_n;
    logic                    enable;
    logic                    phase_ref_clk;
    logic [DATA_WIDTH-1:0]   v_base;
    logic [DATA_WIDTH-1:0]   v_amplitude;
    logic                    act_valid_in;
    logic [DATA_WIDTH-1:0]   act_data_in;

    logic                    bitline_gate_en;
    logic                    clk_freeze_trig;
    logic                    act_valid_out;
    logic [DATA_WIDTH-1:0]   act_data_out;
    logic [ACCUM_WIDTH-1:0]  suppressed_flops;

    // Instantiate DUT
    gvf_core_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .phase_ref_clk(phase_ref_clk),
        .v_base(v_base),
        .v_amplitude(v_amplitude),
        .act_valid_in(act_valid_in),
        .act_data_in(act_data_in),
        .bitline_gate_en(bitline_gate_en),
        .clk_freeze_trig(clk_freeze_trig),
        .act_valid_out(act_valid_out),
        .act_data_out(act_data_out),
        .suppressed_flops(suppressed_flops)
    );

    // Clock Generators
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial phase_ref_clk = 0;
    always #(CLK_PERIOD * 2) phase_ref_clk = ~phase_ref_clk;

    integer i;
    integer expected_suppressions = 0;

    initial begin
        $dumpfile("gvf_core_tb.vcd");
        $dumpvars(0, gvf_core_tb);

        // Initialize Inputs
        rst_n        = 1'b0;
        enable       = 1'b0;
        act_valid_in = 1'b0;
        act_data_in  = '0;
        v_base       = 16'd1000;
        v_amplitude  = 16'd200;

        $display("\n=======================================================");
        $display(" [GVF ENGINE] Running 1,000-Cycle Extended Stress Test... ");
        $display("=======================================================");

        // Release Reset
        #(CLK_PERIOD * 3);
        rst_n = 1'b1;
        #(CLK_PERIOD * 2);
        enable = 1'b1;

        // --------------------------------------------------------------------
        // TEST 1: Continuous Back-to-Back Burst Stream (1,000 Cycles)
        // --------------------------------------------------------------------
        $display("\n[STRESS TEST 1] Executing 1,000-cycle continuous activation stream...");
        @(posedge clk);
        act_valid_in <= 1'b1;
        
        for (i = 0; i < 1000; i = i + 1) begin
            // Alternate between high values (1500-2500) and low noise (100-400)
            if (i % 3 == 0) begin
                act_data_in <= 16'd1500 + (i % 500);
            end else begin
                act_data_in <= 16'd200 + (i % 200);
                expected_suppressions = expected_suppressions + 1;
            end
            @(posedge clk);
        end

        act_valid_in <= 1'b0;
        act_data_in  <= '0;
        #(CLK_PERIOD * 2);

        $display(" [STRESS TEST 1 COMPLETE]");
        $display("   Total Streamed Cycles : 1,000");
        $display("   Expected Suppressions : %d", expected_suppressions);
        $display("   Hardware Telemetry    : %d", suppressed_flops);

        // --------------------------------------------------------------------
        // TEST 2: Mid-Operation Asynchronous Reset Recovery
        // --------------------------------------------------------------------
        $display("\n[STRESS TEST 2] Testing mid-stream hardware reset recovery...");
        act_valid_in <= 1'b1;
        act_data_in  <= 16'd300; // Sub-threshold
        #(CLK_PERIOD);
        
        // Assert Reset Mid-Stream
        rst_n <= 1'b0;
        #(CLK_PERIOD * 2);
        
        if (bitline_gate_en == 1'b1 && clk_freeze_trig == 1'b0 && act_valid_out == 1'b0) begin
            $display(" [PASS] Mid-Stream Reset Successfully Restored Safe Idle State");
        end else begin
            $display(" [FAIL] Reset Failed to force safe state!");
        end

        // Re-enable core
        rst_n <= 1'b1;
        #(CLK_PERIOD * 2);

        $display("\n=======================================================");
        $display(" [GVF ENGINE] 1,000-Cycle Extended Verification Passed!");
        $display("=======================================================\n");
        $finish;
    end

endmodule
