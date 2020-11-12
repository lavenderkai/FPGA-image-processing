//==================================================================================================//
//FileName: RGB2YCrCb.v
/*
    官方给的RGB888 to YCbCr的计算公式：
    Y     = 0.299R + 0.587G + 0.114B
    Cb     = 0.568(B - Y) + 128 = -0.172R - 0.339G + 0.511B + 128
    Cr     = 0.713(R -Y) + 128 = 0.511R - 0.428G - 0.083B + 128

    =>

    Y     = ((77*R + 150*G + 29*B)>>8);
    Cb     = ((-43*R - 85*G + 128*B)>>8) + 128;
    Cr = ((128*R - 107*G - 21*B)>>8) + 128;
*/
//Date: 2020-02-28
//==================================================================================================//
`timescale 1ps/1ps

module RGB2YCrCb(
    RESET,            //异步复位信号

    RGB_CLK,        //输入像素时钟
    RGB_VSYNC,        //输入场同步信号
    RGB_DVALID,        //输入数据有信号
    RGB_DAT,        //输入RGB通道像素流，24位

    YCbCr_CLK,        //输出像素时钟
    YCbCr_VSYNC,    //输出场同步信号
    YCbCr_DVALID,    //输出数据有效信号
    Y_DAT,            //输出Y分量
    Cb_DAT,            //输出Cb分量
    Cr_DAT            //输出Cr分量
);

    parameter RGB_DW = 24;        //输入像素宽度
    parameter YCbCr_DW = 8;        //输出像素宽度

    //Port Declared
    input RESET;
    input RGB_CLK;
    input RGB_VSYNC;
    input RGB_DVALID;
    input [RGB_DW-1:0]RGB_DAT;

    output YCbCr_CLK;
    output YCbCr_VSYNC;
    output YCbCr_DVALID;
    output reg [YCbCr_DW-1:0] Y_DAT;
    output reg [YCbCr_DW-1:0] Cb_DAT;
    output reg [YCbCr_DW-1:0] Cr_DAT;

    reg [2*YCbCr_DW-1:0] RGB_R1,RGB_R2,RGB_R3;
    reg [2*YCbCr_DW-1:0] RGB_G1,RGB_G2,RGB_G3;
    reg [2*YCbCr_DW-1:0] RGB_B1,RGB_B2,RGB_B3;

    reg [2*YCbCr_DW-1:0] IMG_Y,IMG_Cb,IMG_Cr;

    reg [2:0] VSYNC_R;
    reg [2:0] DVALID_R;

    //Step1: Consume 1Clk
    always@(posedge RGB_CLK or negedge RESET)begin
        if(!RESET)begin
            RGB_R1 <= {2*YCbCr_DW{1'b0}};
            RGB_R2 <= {2*YCbCr_DW{1'b0}};
            RGB_R3 <= {2*YCbCr_DW{1'b0}};
            RGB_G1 <= {2*YCbCr_DW{1'b0}};
            RGB_G2 <= {2*YCbCr_DW{1'b0}};
            RGB_G3 <= {2*YCbCr_DW{1'b0}};
            RGB_B1 <= {2*YCbCr_DW{1'b0}};
            RGB_B2 <= {2*YCbCr_DW{1'b0}};
            RGB_B3 <= {2*YCbCr_DW{1'b0}};
        end
        else begin
            RGB_R1 <= RGB_DAT[23:16] * 8'd77;
            RGB_G1 <= RGB_DAT[15:8] * 8'd150;
            RGB_B1 <= RGB_DAT[7:0] * 8'd29;
            RGB_R2 <= RGB_DAT[23:16] * 8'd43;
            RGB_G2 <= RGB_DAT[15:8] * 8'd85;
            RGB_B2 <= RGB_DAT[7:0] * 8'd128;
            RGB_R3 <= RGB_DAT[23:16] * 8'd128;
            RGB_G3 <= RGB_DAT[15:8] * 8'd107;
            RGB_B3 <= RGB_DAT[7:0] * 8'd21;
        end
    end

    //Step2: Consume 1Clk
    always@(posedge RGB_CLK or negedge RESET)begin
        if(!RESET)begin
            IMG_Y     <= {2*YCbCr_DW{1'b0}};
            IMG_Cr     <= {2*YCbCr_DW{1'b0}};
            IMG_Cb    <= {2*YCbCr_DW{1'b0}};
        end
        else begin
            IMG_Y     <= RGB_R1 + RGB_G1 + RGB_B1;
            IMG_Cb     <= RGB_B2 - RGB_R2 - RGB_G2 + 16'd32768;
            IMG_Cr    <= RGB_R3 - RGB_G3 - RGB_B3 + 16'd32768;
        end
    end

    //Step3: Consume 1Clk
    always@(posedge RGB_CLK or negedge RESET)begin
        if(!RESET)begin
            Y_DAT     <= {YCbCr_DW{1'b0}};
            Cb_DAT     <= {YCbCr_DW{1'b0}};
            Cr_DAT    <= {YCbCr_DW{1'b0}};
        end
        else begin
            Y_DAT     <= IMG_Y[15:8];
            Cr_DAT     <= IMG_Cr[15:8];
            Cb_DAT     <= IMG_Cb[15:8];
        end
    end

    assign YCbCr_CLK = RGB_CLK;

    always@(posedge RGB_CLK or negedge RESET)begin
        if(!RESET)begin
            VSYNC_R        <= 4'd0;
            DVALID_R     <= 4'd0;
        end
        else begin
            VSYNC_R <= {VSYNC_R[1:0],RGB_VSYNC};
            DVALID_R <= {DVALID_R[1:0],RGB_DVALID};
        end
    end

    assign YCbCr_DVALID = DVALID_R[2];
    assign YCbCr_VSYNC     = VSYNC_R[2];


endmodule