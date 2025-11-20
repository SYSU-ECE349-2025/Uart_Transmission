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
    reg  tx_en_reg;
    wire tx_en_fall;
    wire tx_en_rise;

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
            tx_en_reg <= 1'b1;
        end
        else begin
            tx_en_reg <= tx_en;
        end
    end

    assign tx_en_fall = ((!tx_en) && (tx_en_reg));
    assign tx_en_rise = ((tx_en) && (!tx_en_reg));

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

endmodule
