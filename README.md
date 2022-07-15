# fpga-isp
#### 本Demo基于Altera EP4CE6(黑金AX301+OV5640+AN430)实现了ISP图像处理(将ov5640的isp关闭，在EP4CE6上实现ISP功能)，输出到LCD，软件基于NIOS2裸机开发
#### 过时的项目，已转https://github.com/bxinquan/zynq_cam_isp_demo

## ISP Lite IP
### 位置: xil_ip_repo/xil_isp_lite_1.0
### 处理模块:
    isp_blc - 黑电平校正 (RGGB四通道分别减去配置好的黑电平值)
    isp_bnr - 拜耳降噪 (可选择的高斯滤波器)
    isp_dgain - 数字增益 (直接乘以配置好增益值)
    isp_demosaic - 去马赛克 (双线性插值)
    isp_wb - 白平衡增益 (RGB三通道乘以配置的增益值)
    isp_ccm - 色彩校正矩阵 (RGB三通道乘以配置的3x3矩阵)
    isp_csc - 色彩空间转换 (基于整数优化的RGB2YUV转换公式)
    isp_gamma - Gamma校正 (对亮度基于查表的Gamma校正)
    isp_ee - 边缘增强 (基于特定的3x3滤波器)
### 统计模块:
    isp_stat_ae - 自动曝光统计 (支持统计选取区域内亮度总和与像素个数)
    isp_stat_awb - 自动白平衡统计 (支持符合白点限定条件的RGB三通道数值总和与白像素个数)
### 注：接口时序为DVP(参考tb_dvp_helper)

## VIP IP
### 位置: xil_ip_repo/xil_vip_1.0
### 处理模块:
    vip_hist_equ - 直方图均衡 (可配置上下限的均衡器)
    vip_sobel - sobel边缘检测 (固定的sobel 3x3卷积核)
    vip_yuv2rgb - YUV2RGB色彩空间转换 (基于整数优化的转换公式)
    vip_dscale - 图像缩小 (宽高分别支持1/N倍缩小)
