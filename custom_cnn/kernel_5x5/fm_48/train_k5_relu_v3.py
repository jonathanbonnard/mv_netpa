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
caffe.set_device(1)
solver = caffe.SGDSolver('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/prototxt/k5_relu_v3_solver.prototxt')
#solver.net.copy_from('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/caffemodel_relu/k5_relu_v1_8195.caffemodel')
solver.restore('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/temp_caffemodel/k5_relu_v3_iter_20000.solverstate')
solver.solve()

