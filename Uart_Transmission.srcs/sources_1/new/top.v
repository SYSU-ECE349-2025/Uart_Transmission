`timescale 1ns / 1ps
module top(sys_clk, tx, rx);
    // 系统端口
    input sys_clk;              // 系统时钟，25MHz
    (*mark_debug="true"*)input rx;      // 串行输入端口
    (*mark_debug="true"*)output wire tx; // 串行输出端口
    // 内部变量定义
    (*mark_debug="true"*)reg sys_rstn;          // 复位信号
    (*mark_debug="true"*)reg [15:0] rstn_cnt = 0; // 复位计数
    (*mark_debug="true"*)wire tx_en;           // 帧发送信号
    (*mark_debug="true"*)wire [7:0] rx_data;   // 接收数据
    (*mark_debug="true"*)wire [7:0] tx_data;   // 发送数据
    (*mark_debug="true"*)wire rx_start;        // 接受开始
    (*mark_debug="true"*)wire rx_done;         // 接收完成指示
    (*mark_debug="true"*)wire tx_start;        // 接收完成指示
    (*mark_debug="true"*)wire tx_done;         // 发送数据锁定指示
    wire tx_odd_parity, tx_even_parity;
    wire rx_odd_parity, rx_even_parity;
    wire uart_clk;
    wire [0:0] fifo_full;   // UART-满标志FIFO
    wire [0:0] fifo_wren;   // UART-写使能FIFO
    wire [7:0] fifo_din;    // UART-写数据FIFO
    wire [0:0] fifo_empty;  // UART-空标志FIFO
    wire [0:0] fifo_rden;   // UART-读使能FIFO
    wire [7:0] fifo_dout;   // UART-读数据FIFO
    // 参数定义
    parameter PARITY_EN        = 0;          // 奇偶校验使能
    parameter PARITY_ODDEVEN   = 0;          // 奇偶校验0-ODD 1-EVEN
    parameter UART_CLOCK       = 25_000_000; // 串口时钟
    parameter RST_COUNT        = 25000;      // 复位1ms
    parameter BAUD             = 115200;     // 波特率
    parameter BAUD_FACTOR      = UART_CLOCK / BAUD;      // 25时钟下波特率的分频系数MHZ
    parameter BAUD_FACTOR_HALF = BAUD_FACTOR / 2;        // 电平中间采样点的计数分频值
    // 复位模块
    always@(posedge sys_clk)begin
        if(rstn_cnt <= RST_COUNT)begin
            rstn_cnt <= rstn_cnt + 1;
            sys_rstn <= 1'b0;
        end
        else begin
            rstn_cnt <= rstn_cnt;
            sys_rstn <= 1'b1;
        end
    end
    assign uart_clk = sys_clk;
    // 串口模块
    uart_top #(
        .PARITY_EN(PARITY_EN),
        .PARITY_ODDEVEN(PARITY_ODDEVEN),
        .UART_CLOCK(UART_CLOCK),
        .BAUD(BAUD),
        .BAUD_FACTOR(BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF)
    ) u1_uart_top (
        .uart_clk(uart_clk),
        .sys_rstn(sys_rstn),
        .tx(tx),
        .rx(rx),
        .tx_en(tx_en),
        .rx_data(rx_data),
        .tx_data(tx_data),
        .rx_start(rx_start),
        .rx_done(rx_done),
        .tx_start(tx_start),
        .tx_done(tx_done),
        .tx_odd_parity(tx_odd_parity),
        .tx_even_parity(tx_even_parity),
        .rx_odd_parity(rx_odd_parity),
        .rx_even_parity(rx_even_parity)
    );
    // 控制模块FIFO
    assign fifo_din = rx_data;
    assign tx_data  = fifo_dout;
    fifo_ctrl u2_fifo_ctrl(
        .sys_clk(sys_clk),
        .sys_rstn(sys_rstn),
        .rx_start(rx_start),
        .rx_done(rx_done),
        .tx_start(tx_start),
        .tx_done(tx_done),
        .tx_en(tx_en),
        .fifo_full(fifo_full),
        .fifo_wren(fifo_wren),
        .fifo_din(fifo_din),
        .fifo_empty(fifo_empty),
        .fifo_rden(fifo_rden),
        .fifo_dout(fifo_dout)
    );
endmodule