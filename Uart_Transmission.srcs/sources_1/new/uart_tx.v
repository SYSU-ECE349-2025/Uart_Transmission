module uart_tx(clk_16x, sys_rstn, clk_bps, tx_en, bps_start, tx, tx_data, tx_data_locked);
    // 端口定义
    input clk_16x;           // 倍过采样信号*16
    input sys_rstn;          // 全局复位信号
    input clk_bps;           // 中间采样信号
    input tx_en;             // 发送命令，低电平有效
    input [7:0] tx_data;     // 并并转换前的输入寄存器
    output bps_start;        // 使能位信号
    output tx;               // 串行输出数据
    output reg tx_data_locked; // 串行输出数据寄存器
    
    // 变量定义
    reg tx0, tx1, tx2, tx3;
    wire tx_n;               // 状态寄存器变量
    reg [2:0] state;         // 接收状态寄存器
    reg [7:0] tx_data_r;     // 内部寄存器，用来锁值tx_data
    reg bps_start_r;         // 波特率使能信号，用来赋值bps_start
    reg [3:0] num;           // 内部计数器，用来确定传送了多少个数据位
    reg tx_r;                // 串行输出缓冲寄存器
    
    // 参数定义
    parameter IDLE  = 3'b001;
    parameter START = 3'b010;
    parameter SHIFT = 3'b100;
    // 排除毛刺干扰检测发送使能信号
    always@(posedge clk_16x or negedge sys_rstn)begin
        if(!sys_rstn)begin
            tx0 <= 1;
            tx1 <= 1;
            tx2 <= 1;
            tx3 <= 1;
        end
        else begin
            tx0 <= tx_en;
            tx1 <= tx0;
            tx2 <= tx1;
            tx3 <= tx2;
        end
    end
    assign tx_n = (~tx0) & (~tx1) & (~tx2) & (~tx3);
    
    // 发送状态机
    always@(posedge clk_16x or negedge sys_rstn)begin
        [填写自己的代码]
    end
    
    assign bps_start = bps_start_r;
    assign tx = tx_r;
endmodule
