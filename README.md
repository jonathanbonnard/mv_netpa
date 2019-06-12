# mv_netpa
A multi-view CNN adapted to a FPGA multi-camera system based on the **MVCNN paper from Su et al (2015)**

This work explores the sensibility of the AlexNet architecture in front of severe degradation.

# modification list
- Convolution kernel of the first layer is downsized to 9,7,5 and finally 3
- Convolution Kernel of all layer set at 3
- TanH is used in the first layer so that the mapping is easier on embedded target (8 bits)
- Max or Mean pooling layer is placed at the output of the first layer (central node processing)
- Feature maps of all layers are cut in half

# Observations
It shows that forced pruning of all layers (2x less feature maps) and downsizing convolution kernel degrades the accuracy of the original CNN by 4.8%. However, these degradations can be counteracted when providing supplementary views (max 4 at the moment) to reach the original accuracy of AlexNet.

This lightweight MVCNN requires 3x less computation and is therefore, more adpapted to be embedeed on a FPGA.
The first layer of this CNN can be diretly mapped onto the logic (8bits) of the 4 smart cameras composing the multi view system.
Last layers are embedded in central node running a CNN Accelerator (ARRIA10 FPGA)
