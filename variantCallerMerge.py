#!/usr/bin/env python

# Copyright (C) 2019 Thermo Fisher Scientific. All Rights Reserved
# Author: Haktan Suren

# This has been tested only on S5XL, S5 Prime with 5.10 and 5.12. 

import common
from glob import glob
import sys
import subprocess
import json
import os
import re
import shutil
from ion.plugin import *

from django.conf import settings
from django.template.loader import render_to_string

class AgriSumToolkit(IonPlugin):
  """ A plugin to create an aggregated report from variantCaller and coverageAnalysis plugin """
  
  # Plugin Configuration
  version = "1.0"
  allow_autorun = True
  runtypes = [RunType.FULLCHIP, RunType.THUMB, RunType.COMPOSITE]
  runlevels = [RunLevel.LAST]
  
  def setup_webpage_support(self,results_directory):
    # Create symlinks to js/css folders and php scripts # static data
    # command_line = 'ln -sf %s/resources/* "%s"' % (os.environ['DIRNAME'],results_directory)
    command_line = 'cp -r %s/resources/* "%s"' % (os.environ['DIRNAME'],results_directory)
    common.printtime(command_line)
    subprocess.call(command_line, shell=True)
    
  def CalculateRunSummary(self):
    resultDir = self.startplugin['runinfo']['results_dir']
    
    #Get the latest variantCaller ID
    vids = glob('%s/../variantCaller_out.*' % resultDir)
    vidsIDs = []
    for vidR in vids:
      vidsIDs.append(re.sub(".+\.(\d+)$","\\1",vidR))
    vidsIDs.sort()
    vid = vidsIDs.pop()
    
    #Get the latest variantCaller ID
    cids = glob('%s/../coverageAnalysis_out.*' % resultDir)
    cidsIDs = []
    for cidR in cids:
      cidsIDs.append(re.sub(".+\.(\d+)$","\\1",cidR))
    cidsIDs.sort()
    cid = cidsIDs.pop()
    
    command_line = "python %s/pipeline.py %s %s %s 0 %s" % ( self.startplugin['runinfo']['plugin_dir'], resultDir, vid, cid, self.startplugin['runinfo']['plugin_dir'] ) 
    common.printtime(command_line)
    return subprocess.call(command_line, shell=True)
  
  def launch(self):

    DIRNAME = ''
    result_dir = self.startplugin['runinfo']['results_dir'];
    plugin_dir = self.startplugin['runinfo']['plugin_dir'];
    pk = self.startplugin['runinfo']['pk'];
      
    exit_code = self.CalculateRunSummary()
    self.setup_webpage_support(result_dir)
    
    sys.exit(exit_code)
    
if __name__ == "__main__": PluginCLI()
