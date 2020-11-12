/*
***********************************************************************************************************
**    Input file: None
**    Component name: image_src.v
**    Author:    zhengXiaoliang
**  Company: WHUT
**    Description: to simulate dvd stream
***********************************************************************************************************
*/

`timescale 1ns/1ns

`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2

module image_src(
    reset_l,        //全局复位
    clk,            //同步时钟
    src_sel,        //数据源通道选择
    test_vsync,        //场同步输出
    test_dvalid,     //像素有效输出
    test_data,        //像素数据输出
    clk_out            //像素时钟输出
);

parameter iw = 640;        //默认视频宽度
parameter ih = 512;        //默认视频高度
parameter dw = 8;        //默认像素数据位宽

parameter h_total = 1440;    //行总数
parameter v_total = 600;    //垂直总数

parameter sync_b = 5;        //场前肩
parameter sync_e = 55;        //场同步脉冲
parameter vld_b = 65;        //场后肩

//port decleared
input reset_l,clk;
input [3:0] src_sel;    //to select the input file
output test_vsync, test_dvalid,clk_out;
output [dw-1:0] test_data;


//variable decleared
reg [dw-1:0] test_data_reg;
reg test_vsync_temp;
reg test_dvalid_tmp;
reg [1:0] test_dvalid_r;

reg [10:0] h_cnt;
reg [10:0] v_cnt;

integer fp_r;
integer cnt = 0;

//输出像素时钟
assign clk_out = clk;    //output the dv clk

//输出像素数据
assign test_data = test_data_reg; //test data output

//当行同步有效时，从文件读取像素数据输出到数据线上
always@(posedge clk or posedge test_vsync_temp)begin
    if(((~(test_vsync_temp))) == 1'b0) //场同步清零文件指针
        cnt <= 0; //clear file pointer when a new frame comes
    else begin
        if(test_dvalid_tmp == 1'b1)begin //行同步有效，说明当前时钟数据有效
            case(src_sel) //选择不同的数据源
                4'b0000: fp_r = $fopen("D:/Desktop/FPGA/vivado_prj/rgb2gray/src/lena_rgb_3.txt","r");
                4'b0001: fp_r = $fopen("txt_source/test_scr1.txt","r");
                4'b0010: fp_r = $fopen("txt_source/test_scr2.txt","r");
                4'b0011: fp_r = $fopen("txt_source/test_scr3.txt","r");
                4'b0100: fp_r = $fopen("txt_source/test_scr4.txt","r");
                4'b0101: fp_r = $fopen("txt_source/test_scr5.txt","r");
                4'b0110: fp_r = $fopen("txt_source/test_scr6.txt","r");
                4'b0111: fp_r = $fopen("txt_source/test_scr7.txt","r");
                4'b1000: fp_r = $fopen("txt_source/test_scr8.txt","r");
                4'b1001: fp_r = $fopen("txt_source/test_scr9.txt","r");
                4'b1010: fp_r = $fopen("txt_source/test_scr10.txt","r");
                4'b1011: fp_r = $fopen("txt_source/test_scr11.txt","r");
                4'b1100: fp_r = $fopen("txt_source/test_scr12.txt","r");
                4'b1101: fp_r = $fopen("txt_source/test_scr13.txt","r");
                4'b1110: fp_r = $fopen("txt_source/test_scr14.txt","r");
                4'b1111: fp_r = $fopen("txt_source/test_scr15.txt","r");
                default: fp_r = $fopen("txt_source/test_src3.txt","r");
            endcase

            $fseek(fp_r,cnt,0); //查找当前需要读取的文件位置
            $fscanf(fp_r,"%02x\n",test_data_reg); //将数据按指定格式读入test_data_reg寄存器

            cnt <= cnt + 4; //移动文件指针到下一个数据
            $fclose(fp_r); //关闭文件
            //$display("h_cnt = %d,v_cnt = %d, pixdata = %d",h_cnt,v_cnt,test_data_reg); //for debug use
        end
    end
end

//水平计数器，每来一个时钟就＋1，加到h_total置零重新计数
always@(posedge clk or negedge reset_l)begin
    if(((~(reset_l))) == 1'b1)
        h_cnt <= #1 {11{1'b0}};
    else begin
        if(h_cnt == ((h_total -1)))
            h_cnt <= #1 {11{1'b0}};
        else
            h_cnt <= #1 h_cnt + 11'b00000000001;
    end
end

//垂直计数器：水平计数器计满后+1，计满后清零
always@(posedge clk or negedge reset_l)begin
    if(((~(reset_l))) == 1'b1)
        v_cnt <= #1 {11{1'b0}};
    else begin
        if(h_cnt == ((h_total - 1)))begin
            if(v_cnt == ((v_total - 1)))
                v_cnt <= #1 {11{1'b0}};
            else
                v_cnt <= #1 v_cnt + 11'b00000000001;
        end
    end
end

//场同步信号生成
always@(posedge clk or negedge reset_l)begin
    if(((~(reset_l))) == 1'b1)
        test_vsync_temp <= #1 1'b1;
    else begin
        if(v_cnt >= sync_b & v_cnt <= sync_e)
            test_vsync_temp <= #1 1'b1;
        else
            test_vsync_temp <= #1 1'b0;
    end
end

assign test_vsync = (~test_vsync_temp);

//水平同步信号生成
always@(posedge clk or negedge reset_l)begin
    if(((~(reset_l))) == 1'b1)
        test_dvalid_tmp <= #1 1'b0;
    else begin
        if(v_cnt >= vld_b & v_cnt < ((vld_b + ih)))begin
            if(h_cnt == 10'b0000000000)
                test_dvalid_tmp <= #1 1'b1;
            else if(h_cnt == iw)
                test_dvalid_tmp <= #1 1'b0;
        end
        else
            test_dvalid_tmp <= #1 1'b0;
    end
end

//水平同步信号输出
assign test_dvalid = test_dvalid_tmp;

always@(posedge clk or negedge reset_l)begin
    if(((~(reset_l))) == 1'b1)
        test_dvalid_r <= #1 2'b00;
    else
        test_dvalid_r <= #1 ({test_dvalid_r[0],test_dvalid_tmp});
end

endmodule