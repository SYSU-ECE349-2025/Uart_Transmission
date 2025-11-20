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
    reg rx_data_ready_reg;    // 接收完成指示寄存器
    reg tx_data_locked_reg;   // 发送数据锁定指示寄存器
    
    // 数据缓冲和序列检测相关
    reg [7:0] data_buffer [0:1023];  // 数据缓冲区，1024字节
    reg [10:0] write_ptr;             // 写指针
    reg [10:0] read_ptr;              // 读指针
    reg [10:0] buffer_count;          // 缓冲区数据计数
    reg [2:0] seq_state;              // 序列检测状态机
    reg trigger_detected;             // 触发标志
    reg send_state;                   // 发送状态机
    reg [7:0] last_rx_data;           // 上一个接收的数据
    
    // 参数定义
    parameter RST_COUNT      = 25000;  // 复位1ms
    parameter BAUD           = 115200; // 波特率
    parameter BAUD_FACTOR    = 217;    // 25时钟下波特率的分频系数MHZ
    parameter BAUD_FACTOR_HALF = 109;  // 电平中间采样点的计数分频值
    parameter SAMPLE_FACTOR  = 14;     // 倍于波特率的采样时钟的分频系数16
    parameter SAMPLE_FACTOR_HALF = 7;  // 倍于波特率的采样时钟的分频系数的一半16
    
    // 序列检测参数
    parameter SEQ_IDLE = 3'b000;
    parameter SEQ_FE   = 3'b001;
    parameter SEQ_DC   = 3'b010;
    parameter SEQ_BA   = 3'b011;
    
    // 发送状态参数
    parameter SEND_IDLE = 1'b0;
    parameter SEND_DATA = 1'b1;
    
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
    
    // 数据接收和缓冲逻辑
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)begin
            write_ptr <= 11'd0;
            buffer_count <= 11'd0;
            seq_state <= SEQ_IDLE;
            trigger_detected <= 1'b0;
            last_rx_data <= 8'd0;
        end
        else begin
            rx_data_ready_reg <= rx_data_ready;
            // 检测接收数据有效
            if((rx_data_ready) && (!rx_data_ready_reg))begin
                // 存储接收到的数据
                if(buffer_count < 11'd1024)begin
                    data_buffer[write_ptr] <= rx_data;
                    write_ptr <= write_ptr + 1'b1;
                    buffer_count <= buffer_count + 1'b1;
                end
                
                // 序列检测：FEDCBA (0xFE, 0xDC, 0xBA)
                case(seq_state)
                    SEQ_IDLE: begin
                        if(rx_data == 8'hFE)begin
                            seq_state <= SEQ_FE;
                        end
                    end
                    SEQ_FE: begin
                        if(rx_data == 8'hDC)begin
                            seq_state <= SEQ_DC;
                        end
                        else if(rx_data == 8'hFE)begin
                            seq_state <= SEQ_FE;
                        end
                        else begin
                            seq_state <= SEQ_IDLE;
                        end
                    end
                    SEQ_DC: begin
                        if(rx_data == 8'hBA)begin
                            seq_state <= SEQ_BA;
                            trigger_detected <= 1'b1;  // 检测到完整序列
                        end
                        else if(rx_data == 8'hFE)begin
                            seq_state <= SEQ_FE;
                        end
                        else begin
                            seq_state <= SEQ_IDLE;
                        end
                    end
                    SEQ_BA: begin
                        seq_state <= SEQ_IDLE;
                    end
                    default: seq_state <= SEQ_IDLE;
                endcase
                
                last_rx_data <= rx_data;
            end
        end
    end
    
    // 数据发送控制逻辑
    always@(posedge sys_clk or negedge sys_rstn)begin
        if(!sys_rstn)begin
            tx_en <= 1'b1;
            tx_data <= 8'b0;
            read_ptr <= 11'd0;
            send_state <= SEND_IDLE;
            tx_data_locked_reg <= 1'b0;
        end
        else begin
            tx_data_locked_reg <= tx_data_locked;
            
            case(send_state)
                SEND_IDLE: begin
                    if(trigger_detected && (buffer_count > 0))begin
                        send_state <= SEND_DATA;
                        read_ptr <= 11'd0;
                        tx_en <= 1'b0;  // 低电平有效，启动发送
                        tx_data <= data_buffer[0];
                    end
                    else begin
                        tx_en <= 1'b1;
                        tx_data <= 8'b0;
                    end
                end
                SEND_DATA: begin
                    if((tx_data_locked) && (!tx_data_locked_reg))begin
                        // 数据已被锁定，可以释放tx_en
                        tx_en <= 1'b1;
                    end
                    else if((!tx_data_locked) && (tx_data_locked_reg))begin
                        // 上一个字节发送完成
                        if((read_ptr + 1'b1) < buffer_count)begin
                            read_ptr <= read_ptr + 1'b1;
                            tx_en <= 1'b0;  // 启动发送下一个字节
                            tx_data <= data_buffer[read_ptr + 1'b1];
                        end
                        else begin
                            // 所有数据发送完成
                            tx_en <= 1'b1;
                            tx_data <= 8'b0;
                            send_state <= SEND_IDLE;
                            read_ptr <= 11'd0;
                            buffer_count <= 11'd0;
                            write_ptr <= 11'd0;
                            trigger_detected <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end
    // 串口模块
    uart_top #(
        .BAUD(BAUD),
        .BAUD_FACTOR(BAUD_FACTOR),
        .BAUD_FACTOR_HALF(BAUD_FACTOR_HALF),
        .SAMPLE_FACTOR(SAMPLE_FACTOR),
        .SAMPLE_FACTOR_HALF(SAMPLE_FACTOR_HALF)
    ) u1_uart_top1(
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