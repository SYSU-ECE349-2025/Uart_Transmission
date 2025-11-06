module uart_top #
(
    parameter BAUD                = 9600, // 波特率9600bps
    parameter BAUD_FACTOR         = 2604, // 25时钟下波特率的分频系数MHz
    parameter BAUD_FACTOR_HALF    = 1302, // 电平中间采样的计数分频值
    parameter SAMPLE_FACTOR       = 163,  // 倍于波特率的采样时钟的分频系数16
    parameter SAMPLE_FACTOR_HALF  = 82    // 倍于波特率的采样时钟的分频系数的一半16
)
(
    sys_clk, sys_rstn,
    tx, rx,
    rx_data, tx_data,
    rx_data_ready, tx_data_locked
);

    // 端口定义
    input sys_clk;              // 系统时钟，25MHz
    input sys_rstn;             // 全局复位信号
    input rx;                   // 串行输入端口
    input tx_en;                // 帧发送信号
    output wire tx;             // 串行输出端口
    output wire [7:0] rx_data;  // 接收数据
    input wire [7:0] tx_data;   // 传输数据
    output wire rx_data_ready;  // 接收完成指示
    output wire tx_data_locked; // 发送数据锁定指示
    
    // 变量定义
    wire bps_start_rx, bps_start_tx;
    wire clk_bps_rx, clk_bps_tx;
    wire clk16x_rx, clk16x_tx;
    
    // 接收端波特率发生器
    uart_baud #
    (
        .BAUD(BAUD),
        .BAUD_FACTOR(BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF),
        .SAMPLE_FACTOR(SAMPLE_FACTOR),
        .SAMPLE_FACTOR_HALF(SAMPLE_FACTOR_HALF)
    )
    u1_baud_rx
    (
        .sys_clk(sys_clk),
        .sys_rstn(sys_rstn),
        .bps_start(bps_start_rx),
        .clk_bps(clk_bps_rx),
        .clk_16x(clk16x_rx)
    );
    
    // 接收端
    uart_rx u2_uart_rx
    (
        .clk_16x(clk16x_rx),
        .sys_rstn(sys_rstn),
        .bps_start(bps_start_rx),
        .clk_bps(clk_bps_rx),
        .rx(rx),
        .rx_data(rx_data),
        .rx_data_ready(rx_data_ready)
    );
    
    // 发送端波特率发生器
    uart_baud #
    (
        .BAUD(BAUD),
        .BAUD_FACTOR(BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF),
        .SAMPLE_FACTOR(SAMPLE_FACTOR),
        .SAMPLE_FACTOR_HALF(SAMPLE_FACTOR_HALF)
    )
    u3_baud_tx
    (
        .sys_clk(sys_clk),
        .sys_rstn(sys_rstn),
        .bps_start(bps_start_tx),
        .clk_bps(clk_bps_tx),
        .clk_16x(clk16x_tx)
    );
    
    // 发送端
    uart_tx u4_uart_tx
    (
        .clk_16x(clk16x_tx),
        .sys_rstn(sys_rstn),
        .bps_start(bps_start_tx),
        .clk_bps(clk_bps_tx),
        .tx(tx),
        .tx_data(tx_data),
        .tx_en(tx_en),
        .tx_data_locked(tx_data_locked)
    );

endmodule