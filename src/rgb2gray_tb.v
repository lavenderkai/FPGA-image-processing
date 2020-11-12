`timescale 1ps/1ps

module rgb2gray_tb;


    /*image para*/
    parameter iw             = 640;        //image width
    parameter ih            = 512;        //image height
    parameter trig_value    = 400;     //250

    /*video parameter*/
    parameter h_total        = 2000;
    parameter v_total        = 600;
    parameter sync_b        = 5;
    parameter sync_e        = 55;
    parameter vld_b            = 65;

    parameter clk_freq         = 72;

    /*data width*/
    parameter dvd_dw     = 8;    //image source data width
    parameter dvd_chn    = 3;    //channel of the dvd data: when 3 it's rgb or 4:4:YCbCr
    parameter local_dw    = dvd_dw * dvd_chn;    //local algorithem process data width
    parameter cmd_dw    = dvd_dw * dvd_chn;    //local algorithem process data width

    /*test module enable*/
    parameter cap_en    = 1;

    /*signal group*/
    reg clk = 1'b0;
    reg reset_l;
    reg [3:0] src_sel;


    /*input dv group*/
    wire dv_clk;
    wire dvsyn;
    wire dhsyn;
    wire [dvd_dw-1:0] dvd;

    /*dvd source data generated for simulation*/
    image_src //#(iw*dvd_chn, ih+1, dvd_dw, h_total, v_total, sync_b, sync_e, vld_b)
    u1(
        .clk(clk),
        .reset_l(reset_l),
        .src_sel(src_sel),
        .test_data(dvd),
        .test_dvalid(dhsyn),
        .test_vsync(dvsyn),
        .clk_out(dv_clk)
    );

    defparam u1.iw = iw*dvd_chn;
    defparam u1.ih = ih + 1;
    defparam u1.dw = dvd_dw;
    defparam u1.h_total = h_total;
    defparam u1.v_total = v_total;
    defparam u1.sync_b = sync_b;
    defparam u1.sync_e = sync_e;
    defparam u1.vld_b = vld_b;


    /*local clk: also clk of all local modules*/
    reg cap_clk = 1'b0;

    /*output data*/
    wire GRAY_CLK;
    wire GRAY_VSYNC;
    wire GRAY_DVALID;
    wire [dvd_dw-1:0] Y_DAT;
    wire [dvd_dw-1:0] Cb_DAT;
    wire [dvd_dw-1:0] Cr_DAT;

    /*video capture: capture image src and transfer it into local timing*/

    rgb2gray u2(
        .RSTn(reset_l),
        .CLOCK(cap_clk),

        .IMG_CLK(dv_clk),
        .IMG_DVD(dvd),
        .IMG_DVSYN(dvsyn),
        .IMG_DHSYN(dhsyn),

        .GRAY_CLK(GRAY_CLK),
        .GRAY_VSYNC(GRAY_VSYNC),
        .GRAY_DVALID(GRAY_DVALID),
        .Y_DAT(Y_DAT),
        .Cb_DAT(Cb_DAT),
        .Cr_DAT(Cr_DAT)
    );

    initial
    begin: init
        reset_l <= 1'b1;
        src_sel <= 4'b0000;
        #(100);            //reset the system
        reset_l <= 1'b0;
        #(100);
        reset_l <= 1'b1;
    end

    //dv_clk generate
    always@(reset_l or clk)begin
        if((~(reset_l)) == 1'b1)
            clk <= 1'b0;
        else
        begin
            if(clk_freq == 48)            //48MHz
                clk <= #10417 (~(clk));

            else if(clk_freq == 51.84)    //51.84MHz
                clk <= #9645 (~(clk));

            else if(clk_freq == 72)        //72MHz
                clk <= #6944 (~(clk));
        end
    end

    //cap_clk generate: 25MHz
    always@(reset_l or cap_clk)begin
        if((~(reset_l)) == 1'b1)
            cap_clk <= 1'b0;
        else
            cap_clk <= #20000 (~(cap_clk));
    end

    generate
    if(cap_en != 0) begin :capture_operation
        integer fid1, fid2, fid3, cnt_cap=0;

        always@(posedge GRAY_CLK or posedge GRAY_VSYNC)begin
            if(((~(GRAY_VSYNC))) == 1'b0)
                cnt_cap = 0;
            else
                begin
                    if(GRAY_DVALID == 1'b1)
                    begin
                        //Y
                        fid1 = $fopen("D:/Desktop/FPGA/vivado_prj/rgb2gray/output/gray_image_Y.txt","r+");
                        $fseek(fid1,cnt_cap,0);
                        $fdisplay(fid1,"%02x\n",Y_DAT);
                        $fclose(fid1);

                        //Cb
                        fid2 = $fopen("D:/Desktop/FPGA/vivado_prj/rgb2gray/output/gray_image_Cb.txt","r+");
                        $fseek(fid2,cnt_cap,0);
                        $fdisplay(fid2,"%02x\n",Cb_DAT);
                        $fclose(fid2);

                        //Cr
                        fid3 = $fopen("D:/Desktop/FPGA/vivado_prj/rgb2gray/output/gray_image_Cr.txt","r+");
                        $fseek(fid3,cnt_cap,0);
                        $fdisplay(fid3,"%02x\n",Cr_DAT);
                        $fclose(fid3);

                        cnt_cap<=cnt_cap+4;
                    end
                end
        end
    end
    endgenerate

endmodule