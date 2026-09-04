`timescale 1ns / 1ps

module gvf_core_top #(
    parameter int DATA_WIDTH     = 16,
    parameter int ACCUM_WIDTH    = 24,
    parameter int THRESH_STEP    = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    enable,
    input  logic                    phase_ref_clk,
    input  logic [DATA_WIDTH-1:0]   v_base,
    input  logic [DATA_WIDTH-1:0]   v_amplitude,
    input  logic                    act_valid_in,
    input  logic [DATA_WIDTH-1:0]   act_data_in,

    output logic                    bitline_gate_en,
    output logic                    clk_freeze_trig,
    output logic                    act_valid_out,
    output logic [DATA_WIDTH-1:0]   act_data_out,
    output logic [ACCUM_WIDTH-1:0]  suppressed_flops
);

    logic [DATA_WIDTH-1:0] v_th_dynamic;
    logic [2:0]            phase_lut_ptr;
    logic                  sub_threshold_detect;
    logic signed [7:0]     sine_val;

    // Phase Sine Approximation Lookup Table
    always_comb begin
        case (phase_lut_ptr)
            3'b000:  sine_val = 8'sd0;
            3'b001:  sine_val = 8'sd90;
            3'b010:  sine_val = 8'sd127;
            3'b011:  sine_val = 8'sd90;
            3'b100:  sine_val = 8'sd0;
            3'b101:  sine_val = -8'sd90;
            3'b110:  sine_val = -8'sd127;
            3'b111:  sine_val = -8'sd90;
            default: sine_val = 8'sd0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_lut_ptr <= 3'b000;
        end else if (enable && phase_ref_clk) begin
            phase_lut_ptr <= phase_lut_ptr + 1'b1;
        end
    end

    always_comb begin
        logic signed [DATA_WIDTH+7:0] mod_product;
        mod_product = $signed({1'b0, v_amplitude}) * sine_val;
        v_th_dynamic = v_base + (mod_product >>> 7);
    end

    assign sub_threshold_detect = (act_data_in < v_th_dynamic);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bitline_gate_en <= 1'b1;
            clk_freeze_trig <= 1'b0;
            act_valid_out   <= 1'b0;
            act_data_out    <= '0;
        end else if (enable && act_valid_in) begin
            if (sub_threshold_detect) begin
                bitline_gate_en <= 1'b0;
                clk_freeze_trig <= 1'b1;
                act_valid_out   <= 1'b0;
                act_data_out    <= '0;
            end else begin
                bitline_gate_en <= 1'b1;
                clk_freeze_trig <= 1'b0;
                act_valid_out   <= 1'b1;
                act_data_out    <= act_data_in;
            end
        end else begin
            bitline_gate_en <= 1'b1;
            clk_freeze_trig <= 1'b0;
            act_valid_out   <= 1'b0;
            act_data_out    <= '0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            suppressed_flops <= '0;
        end else if (enable && act_valid_in && sub_threshold_detect) begin
            suppressed_flops <= suppressed_flops + 1'b1;
        end
    end

endmodule
