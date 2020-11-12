//===============================================================================================//
//FileName: rgb2gray.v
//Date:2020-02-28
//===============================================================================================//

`timescale 1ps/1ps

module rgb2gray(
    RSTn,                //全局复位
    CLOCK,                //系统时钟

    IMG_CLK,            //像素时钟
    IMG_DVD,            //像素值
    IMG_DVSYN,            //输入场信号
    IMG_DHSYN,            //输入数据有效信号

    GRAY_CLK,            //输出灰度图像时钟
    GRAY_VSYNC,            //输出灰度图像场信号
    GRAY_DVALID,        //输出灰度图像数据有效信号
    Y_DAT,                //输出图像数据Y分量
    Cb_DAT,                //输出图像数据Cb分量
    Cr_DAT                //输出图像数据Cr分量

);
    /*image parameter*/
    parameter iw             = 640;        //image width
    parameter ih            = 512;        //image height
    parameter trig_value    = 400;         //250

    /*data width*/
    parameter dvd_dw     = 8;    //image source data width
    parameter dvd_chn    = 3;    //channel of the dvd data: when 3 it's rgb or 4:4:YCbCr
    parameter local_dw    = dvd_dw * dvd_chn;    //local algorithem process data width
    parameter cmd_dw    = dvd_dw * dvd_chn;    //local algorithem process data width

    //Port Declared
    input RSTn;
    input CLOCK;
    input IMG_CLK;
    input [dvd_dw-1:0] IMG_DVD;
    input IMG_DVSYN;
    input IMG_DHSYN;

    output GRAY_CLK;
    output GRAY_VSYNC;
    output GRAY_DVALID;
    output [dvd_dw-1:0] Y_DAT;
    output [dvd_dw-1:0] Cb_DAT;
    output [dvd_dw-1:0] Cr_DAT;

    //Variable Declared
    wire [local_dw-1:0] RGB_DAT;
    wire RGB_DVALID;
    wire RGB_VSYNC;

    video_cap u1(
        .reset_l(RSTn),                //异步复位信号
        .DVD(IMG_DVD),                //输入视频流
        .DVSYN(IMG_DVSYN),            //输入场同步信号
        .DHSYN(IMG_DHSYN),            //输入行同步
        .DVCLK(IMG_CLK),            //输入DV时钟
        .cap_dat(RGB_DAT),            //输出RGB通道像素流，24位
        .cap_dvalid(RGB_DVALID),    //输出数据有效
        .cap_vsync(RGB_VSYNC),        //输出场同步
        .cap_clk(CLOCK),            //本地逻辑时钟
        .img_en(),
        .cmd_rdy(),                    //命令行准备好，代表可以读取
        .cmd_rdat(),                //命令行数据输出
        .cmd_rdreq()                //命令行读取请求
    );

    defparam u1.DW_DVD         = dvd_dw;
    defparam u1.DW_LOCAL     = local_dw;
    defparam u1.DW_CMD         = cmd_dw;
    defparam u1.DVD_CHN     = dvd_chn;
    defparam u1.TRIG_VALUE  = trig_value;
    defparam u1.IW             = iw;
    defparam u1.IH             = ih;

    RGB2YCrCb u2(
        .RESET(RSTn),                //异步复位信号

        .RGB_CLK(CLOCK),            //输入像素时钟
        .RGB_VSYNC(RGB_VSYNC),        //输入场同步信号
        .RGB_DVALID(RGB_DVALID),    //输入数据有信号
        .RGB_DAT(RGB_DAT),            //输入RGB通道像素流，24位

        .YCbCr_CLK(GRAY_CLK),        //输出像素时钟
        .YCbCr_VSYNC(GRAY_VSYNC),    //输出场同步信号
        .YCbCr_DVALID(GRAY_DVALID),    //输出数据有效信号
        .Y_DAT(Y_DAT),                //输出Y分量
        .Cb_DAT(Cb_DAT),            //输出Cb分量
        .Cr_DAT(Cr_DAT)                //输出Cr分量
    );

    defparam u2.RGB_DW = local_dw;
    defparam u2.YCbCr_DW = dvd_dw;

endmodule