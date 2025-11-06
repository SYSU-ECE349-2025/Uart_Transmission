module uart_rx(clk_16x, sys_rstn, rx, clk_bps, bps_start, rx_data, rx_data_ready);
    // 端口定义
    input clk_16x;          // 16倍过采样信号
    input sys_rstn;         // 全局复位信号
    input rx;               // 串行输入信号
    input clk_bps;          // 中间点采样信号
    output bps_start;       // 采样数据置位信号
    output [7:0] rx_data;   // 串并转换后的输出寄存器
    output reg rx_data_ready;// 接收完成指示
    
    // 变量定义
    reg [14:0] rx_r;        // 起始位检测寄存器
    wire rx_n;              // 起始位有效信号
    reg [1:0] state;        // 状态寄存器变量
    reg [7:0] rx_data_r;    // 内部缓冲寄存器, 接受串行数据, 用来给rx_data赋值
    reg bps_start_r;        // 内部缓冲寄存器, 用来给bps_start赋值
    reg [3:0] num;          // 内部计数器, 用来确定传送了多少个数据位
    
    // 参数定义
    parameter START = 2'b01;
    parameter SAMPLE = 2'b10;
    
    // 初始化及变量节拍
    always@(posedge clk_16x or negedge sys_rstn)begin
        if(!sys_rstn)
            rx_r <= 15'b0;
        else
            rx_r <= {rx_r[13:0], (~rx)};
    end
    
    // 起始位检测
    assign rx_n = (&rx_r[14:0]);
    
    // 接收状态机
    always@(posedge clk_16x or negedge sys_rstn)begin
        if(!sys_rstn)begin
            state <= START;
            num <= 4'd0;
            rx_data_r <= 8'd0;
            rx_data_ready <= 0;
            bps_start_r <= 1'b0;
        end
        else begin
            case(state)
                // 接收开始
                START:
                    if(rx_n)begin
                        bps_start_r <= 1'b1;
                        state <= SAMPLE;
                    end
                    else begin
                        state <= state;
                        num <= 4'd0;
                        rx_data_r <= 8'd0;
                        rx_data_ready <= 0;
                        bps_start_r <= 1'b0;
                    end
                // 进行接收
                SAMPLE:
                    if((num == 8) && (clk_bps))begin
                        bps_start_r <= 1'd0;
                        state <= START;
                        num <= 4'd0;
                        rx_data_ready <= 1;
                    end
                    else begin
                        if(clk_bps)begin
                            num <= num + 1'd1;
                            case(num)
                                4'd0: rx_data_r[0] <= rx;
                                4'd1: rx_data_r[1] <= rx;
                                4'd2: rx_data_r[2] <= rx;
                                4'd3: rx_data_r[3] <= rx;
                                4'd4: rx_data_r[4] <= rx;
                                4'd5: rx_data_r[5] <= rx;
                                4'd6: rx_data_r[6] <= rx;
                                4'd7: rx_data_r[7] <= rx;
                                default: rx_data_r <= rx_data_r;
                            endcase
                        end
                        else begin
                            num <= num;
                            state <= state;
                        end
                    end
            endcase
        end
    end
    
    assign bps_start = bps_start_r;
    // 三态门输出接收数据有效
    assign rx_data = rx_data_ready ? rx_data_r : 8'bz;
endmodule
