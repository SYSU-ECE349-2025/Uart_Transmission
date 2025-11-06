module uart_tx(clk_16x, sys_rstn, clk_bps, tx_en, bps_start, tx, tx_data, tx_data_locked);
    // 端口定义
    input clk_16x;           // 16倍过采样信号
    input sys_rstn;          // 全局复位信号
    input clk_bps;           // 中间点采样信号
    input tx_en;             // 数据帧发送命令；低电平有效
    input [7:0] tx_data;     // 并串转换前的输入寄存器
    output bps_start;        // 采样数据置位信号
    output tx;               // 串行输出数据
    output reg tx_data_locked;
    
    // 变量定义
    reg tx0, tx1, tx2, tx3;
    wire tx_n;
    reg [2:0] state;         // 状态寄存器变量
    reg [7:0] tx_data_r;     // 接受保存并行数据
    reg bps_start_r;         // 用来给bps_start赋值
    reg [3:0] num;           // 内部计数器, 用来确定传送了多少个数据位
    reg tx_r;                // 串行输出缓冲寄存器
    
    // 参数定义
    parameter IDLE  = 3'b001;
    parameter START = 3'b010;
    parameter SHIFT = 3'b100;
    
    // 排除毛刺干扰检测使能信号
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
        if(!sys_rstn)begin
            state <= IDLE;
            tx_data_r <= 8'd0;
            bps_start_r <= 0;
            num <= 4'd0;
            tx_r <= 1'b1;
            tx_data_locked <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(tx_n)begin
                        state <= START;
                        tx_data_r[0] <= tx_data[0];
                        tx_data_r[1] <= tx_data[1];
                        tx_data_r[2] <= tx_data[2];
                        tx_data_r[3] <= tx_data[3];
                        tx_data_r[4] <= tx_data[4];
                        tx_data_r[5] <= tx_data[5];
                        tx_data_r[6] <= tx_data[6];
                        tx_data_r[7] <= tx_data[7];
                        bps_start_r <= 1'b1;
                        tx_data_locked <= 1'b1;
                    end
                    else begin
                        state <= IDLE;
                        tx_data_r <= 8'd0;
                        bps_start_r <= 0;
                        num <= 4'd0;
                        tx_r <= 1'b1;
                        tx_data_locked <= 1'b0;
                    end
                end
                START:begin
                    if(clk_bps)begin
                        state <= SHIFT;
                        tx_r <= 1'b0;
                        num <= num + 1'd1;
                    end
                    else if(!tx_en)begin
                        state <= START;
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                SHIFT:begin
                    tx_data_locked <= 1'b0;
                    if((num == 10) && (clk_bps))begin
                        bps_start_r <= 1'd0;
                        state <= IDLE;
                        num <= 4'd0;
                    end
                    else begin
                        if(clk_bps)begin
                            num <= num + 1'd1;
                            case(num)
                                4'd1: tx_r <= tx_data_r[0];
                                4'd2: tx_r <= tx_data_r[1];
                                4'd3: tx_r <= tx_data_r[2];
                                4'd4: tx_r <= tx_data_r[3];
                                4'd5: tx_r <= tx_data_r[4];
                                4'd6: tx_r <= tx_data_r[5];
                                4'd7: tx_r <= tx_data_r[6];
                                4'd8: tx_r <= tx_data_r[7];
                                4'd9: tx_r <= 1;
                                default: tx_r <= 1'b1;
                            endcase
                        end
                        else begin
                            state <= state;
                            num <= num;
                        end
                    end
                end
            endcase
        end
    end
    
    assign bps_start = bps_start_r;
    assign tx = tx_r;
endmodule
