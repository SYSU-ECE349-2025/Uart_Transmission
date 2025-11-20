module uart_rx #
(
    parameter  PARITY_EN       = 0,
    parameter  PARITY_ODDEVEN  = 0,
    parameter  UART_CLOCK      = 25_000_000,
    parameter  BAUD            = 115200,           // 波特率
    parameter  BAUD_FACTOR     = UART_CLOCK / BAUD,   // 系统时钟下该波特率的分频系数
    parameter  BAUD_FACTOR_HALF = BAUD_FACTOR / 2     // 分频系数的一半
)
(
    uart_clk, sys_rstn, odd_parity, even_parity,
    rx, rx_data, rx_start, rx_done
);
    // 端口定义
    input  uart_clk;         // 串口时钟
    input  sys_rstn;         // 复位信号
    input  rx;               // 串行输入端口
    output wire [7:0] rx_data; // 接收数据
    output reg  rx_start;    // 接收开始指示
    output reg  rx_done;     // 接收完成指示
    output reg  odd_parity;  // 奇偶指示
    output reg  even_parity; // 奇偶指示

    // 变量定义
    reg  [7:0] rx_data_reg;
    reg  [DATA_BIT-1:0] rx_shift;
    reg  [2:0] rx_cstate;    // 状态寄存器变量
    reg  [2:0] rx_nstate;    // 状态寄存器变量
    reg  [3:0] data_num;     // 传输数据接收位计数
    reg  [31:0] baud_cnt;    // 波特率计数
    reg  rx_reg;
    wire rx_rise;
    wire rx_fall;
    reg  parity_bit;
    reg  parity_error;
    reg  frame_error;

    // 参数定义
    localparam DATA_BIT = 8;
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam PARITY   = 3'b011;
    localparam STOP     = 3'b100;
    localparam DONE     = 3'b101;
    localparam integer BAUD_EDGE  = (BAUD_FACTOR > 0) ? (BAUD_FACTOR - 1) : 0;
    localparam integer START_EDGE = (BAUD_FACTOR_HALF > 0) ? (BAUD_FACTOR_HALF - 1) : 0;
    wire odd_calc  = ~(^rx_shift);
    wire even_calc =  ^rx_shift;

    // 下降沿检测
    always@(posedge uart_clk or negedge sys_rstn) begin
        if(!sys_rstn) begin
            rx_reg <= 1'b0;
        end
        else begin
            rx_reg <= rx;
        end
    end

    assign rx_fall = ((!rx) && (rx_reg));
    assign rx_rise = ((rx) && (!rx_reg));

    // 状态跳转
    always@(posedge uart_clk or negedge sys_rstn) begin
        if(!sys_rstn) begin
            rx_cstate <= IDLE;
        end
        else begin
            rx_cstate <= rx_nstate;
        end
    end

    // 转移条件
    always@(*) begin
        rx_nstate = rx_cstate;
        case(rx_cstate)
            IDLE: begin
                if(rx_fall) begin
                    rx_nstate = START;
                end
                else begin
                    rx_nstate = IDLE;
                end
            end
            START: begin
                if(baud_cnt == START_EDGE) begin
                    if(!rx) begin
                        rx_nstate = DATA;
                    end
                    else begin
                        rx_nstate = IDLE;
                    end
                end
                else begin
                    rx_nstate = START;
                end
            end
            DATA: begin
                if(baud_cnt == BAUD_EDGE) begin
                    if(data_num == DATA_BIT - 1) begin
                        rx_nstate = (PARITY_EN) ? PARITY : STOP;
                    end
                    else begin
                        rx_nstate = DATA;
                    end
                end
                else begin
                    rx_nstate = DATA;
                end
            end
            PARITY: begin
                if(baud_cnt == BAUD_EDGE) begin
                    rx_nstate = STOP;
                end
                else begin
                    rx_nstate = PARITY;
                end
            end
            STOP: begin
                if(baud_cnt == BAUD_EDGE) begin
                    rx_nstate = DONE;
                end
                else begin
                    rx_nstate = STOP;
                end
            end
            DONE: begin
                rx_nstate = IDLE;
            end
            default: begin
                rx_nstate = IDLE;
            end
        endcase
    end

    // 状态机逻辑
    always@(posedge uart_clk or negedge sys_rstn) begin
        if(!sys_rstn) begin
            baud_cnt   <= 0;
            data_num   <= 0;
            rx_shift   <= 0;
            rx_data_reg<= 0;
            rx_start   <= 0;
            rx_done    <= 0;
            odd_parity <= 0;
            even_parity<= 0;
            parity_bit <= 0;
            parity_error <= 0;
            frame_error  <= 0;
        end
        else begin
            case(rx_cstate)
                IDLE: begin
                    baud_cnt <= 0;
                    data_num <= 0;
                    rx_done  <= 0;
                    parity_bit   <= 0;
                    parity_error <= 0;
                    frame_error  <= 0;
                    if(rx_fall) begin
                        rx_start <= 1'b1;
                    end
                    else begin
                        rx_start <= 1'b0;
                    end
                end
                START: begin
                    rx_start <= 1'b0;
                    rx_done  <= 0;
                    if(baud_cnt == START_EDGE) begin
                        baud_cnt <= 0;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                DATA: begin
                    rx_start <= 1'b0;
                    rx_done  <= 0;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                        rx_shift[data_num] <= rx;
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
                    rx_start <= 1'b0;
                    rx_done  <= 0;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                        parity_bit   <= rx;
                        if(PARITY_EN) begin
                            parity_error <= (PARITY_ODDEVEN) ? (rx != even_calc) : (rx != odd_calc);
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                STOP: begin
                    rx_start <= 1'b0;
                    rx_done  <= 0;
                    if(baud_cnt == BAUD_EDGE) begin
                        baud_cnt <= 0;
                        frame_error <= (~rx);
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
                DONE: begin
                    rx_start   <= 1'b0;
                    rx_done    <= (frame_error == 0) && (!parity_error);
                    baud_cnt   <= 0;
                    data_num   <= 0;
                    rx_data_reg<= rx_shift;
                    odd_parity <= odd_calc;
                    even_parity<= even_calc;
                end
                default: begin
                    rx_start <= 1'b0;
                    rx_done  <= 0;
                end
            endcase
        end
    end

    assign rx_data = rx_data_reg;
endmodule
