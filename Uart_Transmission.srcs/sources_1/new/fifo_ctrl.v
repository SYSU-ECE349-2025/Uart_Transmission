module fifo_ctrl(
    sys_clk, sys_rstn,
    rx_start, rx_done, tx_start, tx_done,
    tx_en,
    fifo_full, fifo_wren, fifo_din,
    fifo_empty, fifo_rden, fifo_dout
);

// 系统端口
input wire sys_clk; // 系统时钟
input wire sys_rstn; // 系统复位
output reg tx_en; // 发送使能控制
input wire rx_start; // 接收开始指示
input wire rx_done; // 接收完成指示
input wire tx_start; // 发送开始指示
input wire tx_done; // 发送完成指示
output wire [0:0] fifo_full; // UART-满标志FIFO
output reg [0:0] fifo_wren; // UART-写使能FIFO
input wire [7:0] fifo_din; // UART-写数据FIFO
output wire [0:0] fifo_empty; // UART-空标志FIFO
output reg [0:0] fifo_rden; // UART-读使能FIFO
output reg [7:0] fifo_dout; // UART-读数据FIFO
wire [7:0] fifo_dout_reg;

// 内部变量
reg rx_done_reg; // 接收完成信号寄存器
reg tx_start_reg; // 发送数据锁定寄存器
reg tx_done_reg; // 发送数据锁定寄存器
wire rx_done_rise; // 接收完成信号上升沿
wire tx_start_rise; // 发送状态锁定下降沿
wire tx_done_rise; // 发送数据完成寄存器

reg [2:0] rx_cstate, rx_nstate; // 状态机
reg [2:0] tx_cstate, tx_nstate; // 状态机
reg [7:0] rx_num, rx_cnt; // 接收数量及接收进度
reg [7:0] tx_num, tx_cnt; // 发送数量及发送进度
reg wrong_len;

// 参数定义
parameter [2:0] IDLE = 3'b000, RLEN = 3'b001, RECV = 3'b010, DONE = 3'b011;
parameter [2:0] SEND = 3'b100;

// 接收完成信号上升沿检测及发送数据锁定上升沿检测
always@(posedge sys_clk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        rx_done_reg <= 0;
        tx_done_reg <= 0;
        tx_start_reg <= 0;
    end
    else begin
        rx_done_reg <= rx_done;
        tx_done_reg <= tx_done;
        tx_start_reg <= tx_start;
    end
end

assign rx_done_rise = ((rx_done) && (!rx_done_reg));
assign tx_done_rise = ((tx_done) && (!tx_done_reg));
assign tx_start_rise = ((tx_start) && (!tx_start_reg));

// 接收控制- 三段式状态机
// 状态机转移
always@(posedge sys_clk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        rx_cstate <= IDLE;
    end
    else begin
        rx_cstate <= rx_nstate;
    end
end

// 转移条件
always@(*)begin
    rx_nstate = IDLE;
    case (rx_cstate)
        IDLE: begin
            if (rx_done_rise)begin
                rx_nstate = RLEN;
            end
            else begin
                rx_nstate = IDLE;
            end
        end
        RLEN: begin
            if((fifo_din == 0) || (fifo_din == 1)) begin
                rx_nstate = IDLE;
            end
            else begin
                rx_nstate = RECV;
            end
        end
        RECV: begin
            if (rx_cnt < rx_num) begin
                rx_nstate = RECV;
            end
            else begin
                rx_nstate = DONE;
            end
        end
        DONE: begin
            rx_nstate = IDLE;
        end
        default:
        ;
    endcase
end

// 状态处理逻辑
always@(posedge sys_clk or negedge sys_rstn) begin
    if (!sys_rstn) begin
        rx_num <= 0;
        rx_cnt <= 0;
        fifo_wren <= 0;
        wrong_len <= 0;
    end
    else begin
        case (rx_cstate)
            IDLE: begin
                rx_cnt <= 0;
                fifo_wren <= 0;
                wrong_len <= 0;
            end
            RLEN: begin
                if((fifo_din == 0) || (fifo_din == 1)) begin
                    rx_num <= 0;
                    fifo_wren <= 0;
                    wrong_len <= 1;
                    rx_cnt <= 0;
                end
                else begin
                    rx_cnt <= 0;  // 从0开始计数，长度字节不写入FIFO
                    rx_num <= fifo_din;
                    fifo_wren <= 0;  // 长度字节不写入FIFO
                    wrong_len <= 0;
                end
            end
            RECV: begin
                if ((rx_done_rise) && (!fifo_full) && (rx_cnt < rx_num)) begin
                    rx_cnt <= rx_cnt + 1;
                    fifo_wren <= 1;  // 只写入数据字节到FIFO
                    wrong_len <= 0;
                end
                else begin
                    rx_cnt <= rx_cnt;
                    fifo_wren <= 0;
                    wrong_len <= 0;
                end
            end
            DONE: begin
                rx_cnt <= 0;
                fifo_wren <= 0;
                wrong_len <= 0;
            end
            default:begin
                ;
            end
        endcase
    end
end

// 发送控制 - 三段式状态机
// 状态机转移
always@(posedge sys_clk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        tx_cstate <= IDLE;
    end
    else begin
        tx_cstate <= tx_nstate;
    end
end

// 转移条件
always@(*)begin
    tx_nstate = IDLE;
    case (tx_cstate)
        IDLE: begin
            //接收完成后立刻发送
            if (rx_cstate == DONE) begin
                tx_nstate = SEND;
            end
            else begin
                tx_nstate = IDLE;
            end
        end
        SEND: begin
            // 发送完成后结束：当最后一个需要发送的字节发送完成时退出
            // tx_cnt==0 表示正在发送长度字节；tx_cnt==tx_num 表示最后一个数据字节
            if ((tx_cnt == tx_num) && (tx_done_rise)) begin
                tx_nstate = DONE;
            end
            else begin
                tx_nstate = SEND;
            end
        end
        DONE: begin
            tx_nstate = IDLE;
        end
        default:
            ;
    endcase
end

// 状态处理逻辑
always@(posedge sys_clk or negedge sys_rstn) begin
    if (!sys_rstn) begin
        tx_num <= 0;
        tx_cnt <= 0;
        fifo_rden <= 0;
        tx_en <= 1;
        fifo_dout <= 0;
    end
    else begin
        case(tx_cstate)
            // 静态:读取要发送的数据长度当需要开始发送时将读使能置fifol
            IDLE: begin
                if (wrong_len) begin
                    tx_cnt <= 0;
                    fifo_rden <= 0;
                    tx_num <= 0;
                    tx_en <= 0;
                    fifo_dout <= fifo_din;
                end
                else begin
                    if (tx_done_rise) begin
                        tx_cnt <= 0;
                        fifo_rden <= 0;
                        tx_num <= 0;
                        fifo_dout <= fifo_dout_reg;
                        tx_en <= 1;
                    end
                    else begin
                        tx_num <= rx_num;
                        tx_cnt <= 0;
                        tx_en <= tx_en;
                        fifo_rden <= 0;
                        fifo_dout <= fifo_dout;
                    end
                end
            end
            SEND: begin
                tx_en <= 0;
                // tx_cnt == 0: 发送长度字节（rx_num）
                // tx_cnt >= 1: 发送FIFO数据字节
                if (tx_cnt == 0) begin
                    // 发送长度字节
                    fifo_dout <= rx_num;
                    if (tx_done_rise) begin
                        // 长度字节发送完成，拉取第一个数据字节
                        fifo_rden <= (tx_num > 0) ? 1 : 0;
                        tx_cnt <= tx_cnt + 1;
                    end
                    else begin
                        fifo_rden <= 0;
                        tx_cnt <= tx_cnt;
                    end
                end
                else if (tx_cnt <= tx_num) begin
                    // 发送数据字节
                    fifo_dout <= fifo_dout_reg;
                    if (tx_done_rise) begin
                        if (tx_cnt < tx_num) begin
                            // 还有数据，读取下一个
                            fifo_rden <= 1;
                            tx_cnt <= tx_cnt + 1;
                        end
                        else begin
                            // 最后一个数据字节发送完成
                            fifo_rden <= 0;
                            tx_cnt <= tx_cnt + 1;
                        end
                    end
                    else begin
                        fifo_rden <= 0;
                        tx_cnt <= tx_cnt;
                    end
                end
                else begin
                    // 所有数据发送完成，保持状态
                    fifo_rden <= 0;
                    fifo_dout <= fifo_dout_reg;
                    tx_cnt <= tx_cnt;
                end
            end
            DONE:begin
                tx_num <= 0;
                tx_cnt <= 0;
                tx_en <= 1;
                fifo_rden <= 0;
                fifo_dout <= fifo_dout_reg;
            end
            default:begin
                ;
            end
        endcase
    end
end

// RAM
uart_fifo ul_uart_fifo(
    .full(fifo_full),
    .din(fifo_din),
    .wr_en(fifo_wren),
    .empty(fifo_empty),
    .dout(fifo_dout_reg),
    .rd_en(fifo_rden),
    .clk(sys_clk),
    .srst(!sys_rstn)
);

endmodule