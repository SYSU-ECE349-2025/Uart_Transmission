module uart_top #(
    parameter PARITY_EN = 0,
    parameter PARITY_ODDEVEN = 0,
    parameter UART_CLOCK = 25_000_000,
    parameter BAUD = 115200,                 // 波特率
    parameter BAUD_FACTOR = UART_CLOCK / BAUD, // 系统时钟下波特率的分频系数
    parameter BAUD_FACTOR_HALF = BAUD_FACTOR / 2 // 分频系数的一半
) (
    input  wire        uart_clk,        // 串口时钟
    input  wire        sys_rstn,        // 全局复位信号
    input  wire        rx,              // 串行输入端口
    input  wire        tx_en,           // 发送使能信号
    input  wire [7:0]  tx_data,         // 传输数据
    output wire        tx,              // 串行输出端口
    output wire [7:0]  rx_data,         // 接收数据
    output wire        rx_start,        // 接收开始指示
    output wire        rx_done,         // 接收完成指示
    output wire        tx_start,        // 发送开始指示
    output wire        tx_done,         // 发送完成指示
    output wire        tx_odd_parity,
    output wire        tx_even_parity,
    output wire        rx_odd_parity,
    output wire        rx_even_parity
);

    // 发送端
    uart_tx u1_uart_tx #(
        .PARITY_EN       (PARITY_EN),
        .PARITY_ODDEVEN  (PARITY_ODDEVEN),
        .UART_CLOCK      (UART_CLOCK),
        .BAUD            (BAUD),
        .BAUD_FACTOR     (BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF)
    ) (
        .tx_en      (tx_en),
        .uart_clk   (uart_clk),
        .sys_rstn   (sys_rstn),
        .odd_parity (tx_odd_parity),
        .even_parity(tx_even_parity),
        .tx         (tx),
        .tx_data    (tx_data),
        .tx_start   (tx_start),
        .tx_done    (tx_done)
    );

    // 接收端
    uart_rx u2_uart_rx #(
        .PARITY_EN       (PARITY_EN),
        .PARITY_ODDEVEN  (PARITY_ODDEVEN),
        .UART_CLOCK      (UART_CLOCK),
        .BAUD            (BAUD),
        .BAUD_FACTOR     (BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF)
    ) (
        .uart_clk   (uart_clk),
        .sys_rstn   (sys_rstn),
        .odd_parity (rx_odd_parity),
        .even_parity(rx_even_parity),
        .rx         (rx),
        .rx_data    (rx_data),
        .rx_start   (rx_start),
        .rx_done    (rx_done)
    );

endmodule