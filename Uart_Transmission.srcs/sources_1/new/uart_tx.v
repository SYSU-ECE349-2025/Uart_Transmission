module uart_tx #
(
    parameter  PARITY_EN        = 0,
    parameter  PARITY_ODDEVEN   = 0,
    parameter  UART_CLOCK       = 25_000_000,
    parameter  BAUD             = 115200,          // 波特率
    parameter  BAUD_FACTOR      = UART_CLOCK / BAUD,   // 系统时钟下该波特率的分频系数
    parameter  BAUD_FACTOR_HALF = BAUD_FACTOR / 2      // 分频系数的一半
)
(
    tx_en, uart_clk, sys_rstn, odd_parity, even_parity,
    tx, tx_data, tx_start, tx_done
);
    // 端口定义
    input  uart_clk;           // 串口时钟
    input  sys_rstn;           // 复位信号
    input  tx_en;              // 串行输入端口
    input  [7:0] tx_data;      // 发送数据
    output reg  tx_start;      // 发送开始指示
    output reg  tx_done;       // 发送完成指示
    output reg  odd_parity;    // 奇偶指示
    output reg  even_parity;   // 奇偶指示
    output reg  tx;

    // 变量定义
    reg  [2:0] tx_cstate;      // 状态寄存器变量
    reg  [2:0] tx_nstate;      // 状态寄存器变量
    reg  [3:0] data_num;       // 传输数据发送位计数
    reg  [31:0] baud_cnt;      // 波特率计数
    reg  [DATA_BIT-1:0] tx_data_buf;

    // 参数定义
    localparam DATA_BIT = 8;
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam PARITY   = 3'b011;
    localparam DONE     = 3'b100;
    localparam integer BAUD_EDGE = (BAUD_FACTOR > 0) ? (BAUD_FACTOR - 1) : 0;

    // 状态跳转
    always@(posedge uart_clk or negedge sys_rstn) begin
        if(!sys_rstn) begin
            tx_cstate <= IDLE;
        end
        else begin
            tx_cstate <= tx_nstate;
        end
    end

    // 转移条件
    always@(*) begin
        tx_nstate = tx_cstate;
        case(tx_cstate)
            IDLE: begin
                if(!tx_en) begin
                    tx_nstate = START;
                end
                else begin
                    tx_nstate = IDLE;
                end
            end
            START: begin
                if(baud_cnt == BAUD_EDGE) begin
                    tx_nstate = DATA;
                end
                else begin
                    tx_nstate = START;
                end
            end
            DATA: begin
                if(baud_cnt == BAUD_EDGE) begin
                    if(data_num == DATA_BIT - 1) begin
                        tx_nstate = (PARITY_EN) ? PARITY : DONE;
                    end
                    else begin
                        tx_nstate = DATA;
                    end
                end
                else begin
                    tx_nstate = DATA;
                end
            end
            PARITY: begin
                if(baud_cnt == BAUD_EDGE) begin
                    tx_nstate = DONE;
                end
                else begin
                    tx_nstate = PARITY;
                end
            end
            DONE: begin
                if(baud_cnt == BAUD_EDGE) begin
                    tx_nstate = IDLE;
                end
                else begin
                    tx_nstate = DONE;
                end
            end
            default: begin
                tx_nstate = IDLE;
            end
        endcase
    end

    // 状态机逻辑
    always@(posedge uart_clk or negedge sys_rstn) begin
        if(!sys_rstn) begin
            data_num   <= 0;
            baud_cnt   <= 0;
            tx_data_buf<= 0;
            tx         <= 1'b1;
            tx_start   <= 1'b1;
            tx_done    <= 1'b0;
            odd_parity <= 1'b0;
            even_parity<= 1'b0;
        end
        else begin
            case(tx_cstate)
                IDLE: begin
                    baud_cnt <= 0;
                    data_num <= 0;
                    tx       <= 1'b1;
                    tx_start <= 1'b1;
                    tx_done  <= 1'b0;
                    if(!tx_en) begin
                        tx_data_buf <= tx_data;
                        odd_parity  <= ~(^tx_data);
                        even_parity <=  ^tx_data;
                    end
                end
                START: begin
                    tx_start <= 1'b0;
                    tx_done  <= 1'b0;
                    tx       <= 1'b0;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                DATA: begin
                    tx_start <= 1'b0;
                    tx_done  <= 1'b0;
                    tx       <= tx_data_buf[data_num];
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                        if(data_num == DATA_BIT - 1) begin
                            data_num <= 0;
                        end
                        else begin
                            data_num <= data_num + 1;
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                PARITY: begin
                    tx_start <= 1'b0;
                    tx_done  <= 1'b0;
                    tx       <= (PARITY_ODDEVEN) ? even_parity : odd_parity;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                DONE: begin
                    tx_start <= 1'b0;
                    tx       <= 1'b1;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                        tx_done  <= 1'b1;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                        tx_done  <= 1'b0;
                    end
                end
                default: begin
                    tx_start <= 1'b1;
                    tx_done  <= 1'b0;
                    baud_cnt <= 0;
                    data_num <= 0;
                    tx       <= 1'b1;
                end
            endcase
        end
    end

endmodule
