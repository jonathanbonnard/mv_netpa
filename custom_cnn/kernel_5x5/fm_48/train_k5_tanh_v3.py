#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import numpy as np
import sys
sys.path.insert(0,'/home/user/dream/mvcnn/src')
import MVCNNDataLayer
import caffe
import scipy.io as sio
import h5py
import os
caffe.set_mode_gpu()
caffe.set_device(0)
solver = caffe.SGDSolver('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/prototxt/k5_tanh_v2_solver.prototxt')
solver.net.copy_from('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/caffemodel_relu/k5_relu_v1_8195.caffemodel')
solver.solve()

