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

#from django.conf import settings
#from django.template.loader import render_to_string




class variantCallerMerge(IonPlugin):
  version = '1.0.0.0'
  envDict = dict(os.environ)
  author = "longfei.fu@thermofisher.com"
  runtypes = [RunType.FULLCHIP, RunType.THUMB, RunType.COMPOSITE]

  def merge(self):
    report_dir = self.envDict['ANALYSIS_DIR'] # /results/analysis/output/Home/Auto_xxx
    outdir = '/results/analysis' + self.envDict['TSP_URLPATH_PLUGIN_DIR'] # /results/analysis/output/Home/Auto_xxx/plugin_out/variantCallerMerge.x
    this_dir = self.envDict['DIRNAME']
    cmd = "perl %s/vcfMerge.pl %s %s" % (this_dir,report_dir,outdir)

    print "report dir is: %s" % (report_dir)
    print "plugin outdir is: %s" % (outdir)
    print "cmd is: %s" % (cmd)

    os.system(cmd)
    print "Finished the variantCallerMerge plugin."

  def launch(self,data=None):
    print "Start running the variantCallerMerge plugin."

    #start_plugin_json = '/results/analysis' + os.path.join(os.getenv('TSP_URLPATH_PLUGIN_DIR'),'startplugin.json')
    #print(start_plugin_json)
    #with open(start_plugin_json, 'r') as fh:
    #  spj = json.load(fh)
    #  net_location = spj['runinfo']['net_location']

    # /results/analysis/output/Home/S5yanzheng-20211223-chip2-MeanAccuracy_v2_482
    # here report_number is 482
    report_dir = self.envDict['ANALYSIS_DIR'] # /results/analysis/output/Home/Auto_xxx
    report_number = report_dir.split('_')[-1]
    this_plugin_dir = os.getenv('TSP_URLPATH_PLUGIN_DIR').split('/')[-1]
    # ../../../../../report/{{runinfo_pk}}/metal/plugin_out/{{output_dir}}
    full_link = "../../../../../report/%s/metal/plugin_out/%s" % (report_number,this_plugin_dir)
    #print(full_link)

    with open("status_block.html", "w") as html_fp:
      html_fp.write('<html><body><pre>')
      html_fp.write('<tr><td>Output directory:</td>       <a href="%s">%s</a></td></tr>' 
        % (full_link,this_plugin_dir))
      html_fp.write("</pre></body></html>")
    self.merge()

    return True


if __name__ == "__main__":
    PluginCLI()



'''
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
'''