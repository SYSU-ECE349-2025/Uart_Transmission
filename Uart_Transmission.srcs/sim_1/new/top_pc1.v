`timescale 1ns / 1ps
module top_pc(
    input  sys_clk,     // 系统时钟
    input  rx,          // 串行输入端口
    output wire tx      // 串行输出端口
);
    // 内部变量
    reg        sys_rstn;
    reg [15:0] rstn_cnt = 0;
    reg        tx_en;
    wire [7:0] rx_data;
    reg  [7:0] tx_data = 8'd0;
    wire       rx_done;
    wire       tx_done;
    wire       rx_start;
    wire       tx_start;
    wire       tx_odd_parity, tx_even_parity;
    wire       rx_odd_parity, rx_even_parity;
    reg  [7:0] tx_cnt;

    // 参数定义
    parameter PARITY_EN        = 0;
    parameter PARITY_ODDEVEN   = 0;
    parameter UART_CLOCK       = 25_000_000;
    parameter RST_COUNT        = 25000;
    parameter BAUD             = 115200;
    parameter BAUD_FACTOR      = UART_CLOCK / BAUD;
    parameter BAUD_FACTOR_HALF = BAUD_FACTOR / 2;

    // 复位模块
    always @(posedge sys_clk) begin
        if (rstn_cnt <= RST_COUNT) begin
            rstn_cnt <= rstn_cnt + 1;
            sys_rstn <= 1'b0;
        end else begin
            rstn_cnt <= rstn_cnt;
            sys_rstn <= 1'b1;
        end
    end

    wire uart_clk = sys_clk;

    // 串口发送使能控制
    always @(posedge sys_clk or negedge sys_rstn) begin
        if (!sys_rstn) begin
            tx_en  <= 1'b0;
            tx_cnt <= 8'd0;
            tx_data <= 8'd0;
        end else begin
            if (tx_done) begin
                tx_en  <= (tx_cnt >= 8'd15);
                tx_cnt <= tx_cnt + 1;
                tx_data <= tx_data + 1;
            end else begin
                tx_en  <= tx_en;
                tx_data <= tx_data;
            end
        end
    end

    // 串口模块
    uart_top #(
        .PARITY_EN      (PARITY_EN),
        .PARITY_ODDEVEN (PARITY_ODDEVEN),
        .UART_CLOCK     (UART_CLOCK),
        .BAUD           (BAUD),
        .BAUD_FACTOR    (BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF)
    ) u1_uart_top (
        .uart_clk  (uart_clk),
        .sys_rstn  (sys_rstn),
        .tx        (tx),
        .rx        (rx),
        .tx_en     (tx_en),
        .tx_data   (tx_data),
        .rx_data   (rx_data),
        .rx_start  (rx_start),
        .rx_done   (rx_done),
        .tx_start  (tx_start),
        .tx_done   (tx_done),
        .tx_odd_parity (tx_odd_parity),
        .tx_even_parity(tx_even_parity),
        .rx_odd_parity (rx_odd_parity),
        .rx_even_parity(rx_even_parity)
    );
endmodule