module uart_baud #
(
    parameter BAUD                = 9600,    // 波特率9600bps
    parameter BAUD_FACTOR         = 5208,    // 50M时钟下波特率的分频系数MHz
    parameter BAUD_FACTOR_HALF    = 2604,    // 也平中间采样点的计数分频值
    parameter SAMPLE_FACTOR       = 326,     // 倍于波特率的采样时钟的分频系数16
    parameter SAMPLE_FACTOR_HALF  = 163      // 倍于波特率的采样时钟的分频系数的一半16
)
(
    sys_clk, sys_rstn, bps_start, clk_bps, clk_16x
);
    // 端口定义
    input sys_clk;       // 系统时钟
    input sys_rstn;      // 全局复位信号，下降沿有效
    input bps_start;     // 波特率时钟使能信号
    output clk_bps;      // 输出的采样中点信号
    output clk_16x;      // 波特率发生器的过采样分频

    // 变量定义
    reg clk_bps_r;       // 内部缓冲寄存器
    reg clk_16x_r;       // 内部缓冲寄存器
    reg [15:0] cnt;      // 内部计数器，循环产生clk_bps;
    reg [15:0] cnt_16x;  // 内部16倍计数器baud

    // 计数器产生波特率9600时钟Hz
    always@(posedge sys_clk or negedge sys_rstn)begin
        [填写自己的代码]
    end

    // 计数器生成波特9600时钟的高电平的中间脉冲用于稳定采样Hz
    always@(posedge sys_clk or negedge sys_rstn)begin
        [填写自己的代码]
    end

    // 计数器用于生成时钟clk_16x
    [填写自己的代码]

    // 把内部寄存器的信号分配至输出
    assign clk_bps = clk_bps_r;
    assign clk_16x = clk_16x_r;
endmodule
