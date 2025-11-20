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
    reg  [2:0] rx_cstate;    // 状态寄存器变量
    reg  [2:0] rx_nstate;    // 状态寄存器变量
    reg  [3:0] data_num;     // 传输数据接收位计数
    reg  [31:0] baud_cnt;    // 波特率计数
    reg  rx_reg;
    wire rx_rise;
    wire rx_fall;

    // 参数定义
    localparam DATA_BIT = 8;
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam PARITY   = 3'b011;
    localparam DONE     = 3'b100;

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
        [代码请自行完成
        ]

    end

    // 转移条件
    always@(*) begin

        [代码请自行完成
        ]

    end

    // 状态机逻辑
    always@(posedge uart_clk or negedge sys_rstn) begin

        [代码请自行完成
        ]

    end

    assign rx_data = (rx_done) ? rx_data_reg : rx_data;
endmodule
