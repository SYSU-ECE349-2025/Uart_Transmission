module uart_baud #
(
    parameter BAUD                = 9600,    // 波特率9600bps
    parameter BAUD_FACTOR         = 5208,    // 50MHZ时钟下波特率的分频系数
    parameter BAUD_FACTOR_HALF    = 2604,    // 电平中间采样点的计数分频值
    parameter SAMPLE_FACTOR       = 326,     // 16倍于波特率的采样时钟的分频系数
    parameter SAMPLE_FACTOR_HALF  = 163      // 16倍于波特率的采样时钟的分频系数的一半
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
    reg [15:0] cnt;      // 内部计数器, 循环产生clk_bps;
    reg [15:0] cnt_16x;  // 用来16倍baud的计数器
    
    // 使能计数器生成9600Hz时钟
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)
            cnt <= 16'd0;
        else if((cnt == BAUD_FACTOR - 1) || (!bps_start))
            cnt <= 16'd0;
        else
            cnt <= cnt + 1'd1;
    end
    
    // 计数器生成9600Hz时钟的高电平的中间脉冲用于稳定采样
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)
            clk_bps_r <= 1'd0;
        else if(cnt == BAUD_FACTOR_HALF - 1)
            clk_bps_r <= 1'd1;
        // 脉冲持续周期为一个clk_16x的时钟周期
        else if((cnt == BAUD_FACTOR_HALF + SAMPLE_FACTOR - 2) || (!bps_start))
            clk_bps_r <= 1'd0;
        else
            clk_bps_r <= clk_bps_r;
    end
    
    // 计数器用于生成clk_16x时钟
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)begin
            cnt_16x <= 16'd0;
            clk_16x_r <= 1'd0;
        end
        else if(cnt_16x == SAMPLE_FACTOR_HALF - 1)begin
            clk_16x_r <= ~clk_16x_r;
            cnt_16x <= 16'd0;
        end
        else begin
            cnt_16x <= cnt_16x + 1'd1;
        end
    end
    
    //把内部寄存器的值分配至端口；
    assign clk_bps = clk_bps_r;
    assign clk_16x = clk_16x_r;
endmodule
