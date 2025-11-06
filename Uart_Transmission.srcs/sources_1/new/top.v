`timescale 1ns / 1ps
module top(sys_clk, tx, rx);
    // 系统端口
    input sys_clk;            // 系统时钟,25MHz
    input rx;                 // 串行输入端口
    output wire tx;           // 串行输出端口
    // 内部变量定义
    reg sys_rstn;             // 复位信号
    reg [15:0] rstn_cnt = 0;  // 复位计数
    reg tx_en;                // 帧发送信号
    wire [7:0] rx_data;       // 接收数据
    reg [7:0] tx_data;        // 发送数据
    wire rx_data_ready;       // 接收完成指示
    wire tx_data_locked;      // 发送数据锁定指示
    reg rx_data_ready_reg;    // 发送数据锁定指示寄存器
    reg tx_data_locked_reg;   // 发送数据锁定指示寄存器
    // 参数定义
    parameter RST_COUNT      = 25000;  // 复位1ms
    parameter BAUD           = 115200; // 波特率
    parameter BAUD_FACTOR    = 217;    // 25时钟下波特率的分频系数MHZ
    parameter BAUD_FACTOR_HALF = 109;  // 电平中间采样点的计数分频值
    parameter SAMPLE_FACTOR  = 14;     // 倍于波特率的采样时钟的分频系数16
    parameter SAMPLE_FACTOR_HALF = 7;  // 倍于波特率的采样时钟的分频系数的一半16
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
    // 串口发送使能控制
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)begin
            tx_en <= 1'b1;
            tx_data <= 8'b0;
            rx_data_ready_reg <= 1'b0;
            tx_data_locked_reg <= 1'b0;
        end
        else begin
            rx_data_ready_reg <= rx_data_ready;
            tx_data_locked_reg <= tx_data_locked;
            if((rx_data_ready) && (!rx_data_ready_reg))begin
                tx_en <= 1'b0;
                tx_data <= rx_data;
            end
            else begin
                if((!tx_data_locked) && (tx_data_locked_reg))begin
                    tx_en <= 1'b1;
                    tx_data <= 8'b0;
                end
                else begin
                    tx_en <= tx_en;
                    tx_data <= tx_data;
                end
            end
        end
    end
    // 串口模块
    uart_top u1_uart_top1(
        .sys_clk(sys_clk),
        .sys_rstn(sys_rstn),
        .tx(tx),
        .rx(rx),
        .tx_en(tx_en),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .rx_data_ready(rx_data_ready),
        .tx_data_locked(tx_data_locked)
    );
endmodule