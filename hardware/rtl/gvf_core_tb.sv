`timescale 1ns/1ps

module gvf_core_tb;

    // Parameters matching gvf_core_top defaults
    parameter DATA_WIDTH  = 16;
    parameter ACCUM_WIDTH = 32;
    parameter CYCLE_COUNT = 10_000_000;
    
    // Testbench Signals
    logic clk;
    logic rst_n;
    logic enable;
    logic phase_ref_clk;
    logic [DATA_WIDTH-1:0] v_base;
    logic [DATA_WIDTH-1:0] v_amplitude;
    logic act_valid_in;
    logic [DATA_WIDTH-1:0] act_data_in;
    
    // Core Outputs
    logic bitline_gate_en;
    logic clk_freeze_trig;
    logic act_valid_out;
    logic [DATA_WIDTH-1:0] act_data_out;
    logic [ACCUM_WIDTH-1:0] suppressed_flops;
    
    // Telemetry Counters
    longint total_cycles;
    longint gated_cycles;
    longint active_cycles;
    longint async_resets_count;

    // Instantiate Unit Under Test (UUT) with exact port mapping
    gvf_core_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) uut (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable           (enable),
        .phase_ref_clk    (phase_ref_clk),
        .v_base           (v_base),
        .v_amplitude      (v_amplitude),
        .act_valid_in     (act_valid_in),
        .act_data_in      (act_data_in),
        .bitline_gate_en  (bitline_gate_en),
        .clk_freeze_trig  (clk_freeze_trig),
        .act_valid_out    (act_valid_out),
        .act_data_out     (act_data_out),
        .suppressed_flops (suppressed_flops)
    );

    // 100MHz Main Clock (10ns Period)
    always #5 clk = ~clk;
    
    // Phase Reference Clock (50MHz)
    always #10 phase_ref_clk = ~phase_ref_clk;

    // Constrained Random Verification (CRV) Loop
    initial begin
        // Initialize Signals
        clk = 0;
        phase_ref_clk = 0;
        rst_n = 0;
        enable = 1;
        act_valid_in = 1;
        v_base = 16'h0400;      // Dynamic threshold base offset
        v_amplitude = 16'h0200; // AC threshold modulation amplitude
        act_data_in = 0;
        
        total_cycles = 0;
        gated_cycles = 0;
        active_cycles = 0;
        async_resets_count = 0;

        $display("==========================================================");
        $display("  STARTING 10,000,000-CYCLE CONSTRAINED RANDOM VERIFICATION ");
        $display("==========================================================");

        // Assert initial reset for 50ns
        #50 rst_n = 1;

        // Execute 10-Million Cycles
        for (int i = 0; i < CYCLE_COUNT; i++) @(posedge clk) begin
            total_cycles++;

            // 1. Constrained Random Activation Generation (66.6% Sub-threshold Sparsity)
            if ($urandom_range(0, 99) < 66) begin
                act_data_in <= $urandom_range(16'h0000, 16'h03FF); // Sub-threshold activation
            end else begin
                act_data_in <= $urandom_range(16'h0401, 16'hFFFF); // Active activation
            end

            // 2. Inject Random Asynchronous Reset Stress (1 in 500,000 chance)
            if ($urandom_range(0, 500000) == 42) begin
                rst_n <= 0;
                async_resets_count++;
                #12; // Asynchronous de-assertion
                rst_n <= 1;
            end

            // 3. Telemetry Collection
            if (bitline_gate_en == 1'b0) begin
                gated_cycles++;
            end else begin
                active_cycles++;
            end

            // Progress Telemetry Tracker (Every 2.5M Cycles)
            if (total_cycles % 2_500_000 == 0) begin
                $display("[CRV PROGRESS] %0d M Cycles Complete | SRAM Gating Ratio: %0.2f%%", 
                    total_cycles / 1_000_000, (real'(gated_cycles) / real'(total_cycles)) * 100.0);
            end
        end

        // Final Telemetry Reporting
        $display("\n==========================================================");
        $display("        10-MILLION CYCLE CRV SIMULATION COMPLETE           ");
        $display("==========================================================");
        $display(" Total Cycles Run        : %0d", total_cycles);
        $display(" SRAM Reads Gated        : %0d", gated_cycles);
        $display(" SRAM Reads Active       : %0d", active_cycles);
        $display(" Suppressed Flops Counter: %0d", suppressed_flops);
        $display(" Async Resets Tested     : %0d", async_resets_count);
        $display(" Exact Suppression Ratio : %0.4f%%", (real'(gated_cycles) / real'(total_cycles)) * 100.0);
        $display("==========================================================");
        
        $finish;
    end

endmodule