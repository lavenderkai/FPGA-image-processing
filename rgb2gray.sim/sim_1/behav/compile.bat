@echo off
set bin_path=D:\Xilinx\modelsim\modeltech64_10.4\win64
call %bin_path%/vsim  -c -do "do {rgb2gray_tb_compile.do}" -l compile.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
