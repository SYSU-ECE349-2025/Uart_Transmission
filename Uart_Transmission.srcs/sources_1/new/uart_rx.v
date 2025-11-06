module uart_rx(clk_16x, sys_rstn, rx, clk_bps, bps_start, rx_data, rx_data_ready);
    // 端口定义
    input clk_16x;          // 信号采样信号*16
    input sys_rstn;         // 全局复位信号
    input rx;               // 串行信号输入
    input clk_bps;          // 采样时钟信号
    output bps_start;       // 采样使能信号
    output [7:0] rx_data;   // 并并转换后的输出寄存器
    output reg rx_data_ready;// 接收完成指示
    
    // 变量定义
    reg [14:0] rx_r;        // 起始位检测寄存器
    wire rx_n;              // 起始位信号寄存器
    reg [1:0] state;        // 接收状态寄存器
    reg [7:0] rx_data_r;    // 内部数据寄存器，接受串行数据，用来给赋值rx_data
    reg bps_start_r;        // 波特率使能信号，用来给赋值bps_start
    reg [3:0] num;          // 内部计数器，用来确定传送了多少个数据位
    
    // 参数定义
    parameter START = 2'b10;
    parameter SAMPLE = 2'b10;
    // 初始化及寄存器
    always@(posedge clk_16x or negedge sys_rstn)begin
        if(!sys_rstn)
            rx_r <= 15'b0;
        else
            rx_r <= {rx_r[13:0], (?rx)};
    end
    // 起始位检测
    assign rx_n = (&rx_r[14:0]);
    
    // 接收状态机
    always@(posedge clk_16x or negedge sys_rstn)begin
        [填写自己的代码]
    end
    
    assign bps_start = bps_start_r;
    // 三态门输出接收数据有效
    assign rx_data = rx_data_ready ? rx_data_r : 8'bz;
endmodule
