#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import numpy as np
import sys
sys.path.insert(0,'/home/user/dream/mvcnn/src')
import MVCNNDataLayerPreTrain
import caffe
import scipy.io as sio
import h5py
import os
caffe.set_mode_gpu()
caffe.set_device(0)
solver = caffe.SGDSolver('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel55/prototxt/custom_alexnet_solver.prototxt')
#solver.net.copy_from('/home/user/dream/mvcnn/experiments/topology/custom_alexnet/kernel33/caffemodel_relu/netpa_iter_300000.caffemodel')
solver.solve()

