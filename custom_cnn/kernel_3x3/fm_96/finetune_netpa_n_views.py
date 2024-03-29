#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import numpy as np
import sys
sys.path.insert(0,'../../../src')
import MVCNNDataLayer
import caffe
import scipy.io as sio
import h5py
import os
caffe.set_mode_gpu()
caffe.set_device(0)
#change to the *solver.prototxt you wish to finetune
solver = caffe.SGDSolver('prototxt/netpa_relu_v2_solver.prototxt')
solver.net.copy_from('caffemodel_relu/netpa_iter_300000.caffemodel')#copy the caffemodel of the pretrained(1 view) network 
solver.solve()
