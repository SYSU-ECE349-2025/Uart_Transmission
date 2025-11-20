`timescale 1ns / 1ps
module testbench();
    // 系统时钟
    reg sys_clk = 0;
    wire fpga_tx, fpga_rx;
    wire pc_tx, pc_rx;
    // 时钟模块时钟周期为 40，频率为25MHz
    always @ (*) begin
        #20 sys_clk <= ~sys_clk;
    end
    // 传输UART
    top test_top(.sys_clk(sys_clk), .tx(fpga_tx), .rx(fpga_rx));
    top_pc test_top_pc(.sys_clk(sys_clk), .tx(pc_tx), .rx(pc_rx));
    assign pc_rx = fpga_tx;
    assign fpga_rx = pc_tx;
endmodule