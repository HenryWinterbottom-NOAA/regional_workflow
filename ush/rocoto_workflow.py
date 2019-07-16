"""
SCRIPT:   

   rocoto_workflow.py

AUTHOR: 

   Henry R. Winterbottom; 15 July 2019

ABSTRACT:

USAGE:

NOTES:


HISTORY:

   2019-07-15: Henry R. Winterbottom -- Initial implementation.

"""

#----

import argparse
import collections
import datetime
import os

#----

__author__ = "Henry R. Winterbottom"
__copyright__ = "2019 Henry R. Winterbottom, NOAA/NCEP/EMC"
__version__ = "1.0.0"
__maintainer__ = "Henry R. Winterbottom"
__email__ = "henry.winterbottom@noaa.gov"
__status__ = "Development"

#----

class bcolors:
    """ """
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

#----

def true_or_false(argval):
    """
    DESCRIPTION:

    This method checks whether an argument is a Boolean-type value; if
    so, this method defines the appropriate Python boolean-type;
    otherwise, this method returns NoneType.

    INPUT VARIABLES:

    * argval; a value corresponding to an argument.

    OUTPUT VARIABLES:

    * pytype; a Python boolean-type value if the argument is a boolean
      variable; otherwise, NoneType.

    """
    ua=str(argval).upper()
    if 'TRUE'.startswith(ua):
        pytype=True
    elif 'FALSE'.startswith(ua):
        pytype=False
    else:
        pytype=None
    return pytype

#----

class ENTFilelist(object):
    """ """
    def __init__(self,opts_obj):
        """ """
    def run(self):
        """ """

#----

class MachineName(object):
    """
    DESCRIPTION:

    This is the base class object to establish the machine name from
    which the Rocoto workflow attributes and directives are
    established.

    """
    def __init__(self):
        """
        DESCRIPTION:

        Creates a new MachineName object.

        """
    def check(self,opts_obj):
        """
        DESCRIPTION:

        This method checks whether the user has specified a machine
        name from which to establish the machine name related
        attributes for the Rocoto workflow; if none has been
        specified, this method attempts to identify the machine via
        known directory paths; if the machine name still cannot be
        established, this method throws a RocotoWorkflowError.

        INPUT VARIABLES:

        * opts_obj; a Python object containing the user command line
          options.

        OUTPUT VARIABLES:

        * opts_obj; a Python object containing the user command line
          options (now) including the machine_name attribute.

        """
        if getattr(opts_obj,'machine_name') is None:
            machine_dict={'rdhpcs_jet':'/mnt/lfs1',\
                'rdhpcs_theia':'/scratch3/NCEPDEV',\
                'wcoss':'/gpfs/gp1/nco'}
            machine_name=None
            for key in machine_dict.keys():
                machine_path=machine_dict[key]
                if os.path.isdir(machine_path):
                    machine_name=key
                    setattr(opts_obj,'machine_name',machine_name)
                    break
            if machine_name is None:
                msg=('The machine for which to construct the Rocoto workflow cannot '\
                    'be identified; please consider adding the machine_name to the '\
                    'command line arguments. Aborting!!!')
                raise RocotoWorkflowError(msg=msg)
        return opts_obj
    def run(self,opts_obj):
        """ """
        opts_obj=self.check(opts_obj=opts_obj)
        return opts_obj
    
#----

class RocotoWorkflow(object):
    """ """
    def __init__(self,opts_obj):
        """ """
        self.opts_obj=opts_obj
    def run(self):
        """ """
        machinename=MachineName()
        machinename.run(opts_obj=self.opts_obj)
        if getattr(self.opts_obj,'ent_filelist') is not None:
            workflowbuilder=ENTFilelist(opts_obj=self.opts_obj)
        if getattr(self.opts_obj,'xml_template') is not None:
            workflowbuilder=XMLTemplate(opts_obj=self.opts_obj)
        workflowbuilder.run()
            
#----

class RocotoWorkflowError(Exception):
   """
   DESCRIPTION:

   This is the base-class for all exceptions; it is a sub-class of
   Exceptions.

   OPTIONAL INPUT VARIABLES:

   * msg; a Python string to accompany the raised exception.

   """
   def __init__(self,msg=None):
      """
      DESCRIPTION:

      Creates a new RocotoWorkflowError object.

      """
      super(RocotoWorkflowError,self).__init__(bcolors.FAIL+msg+bcolors.ENDC)

#----

class RocotoWorkflowOptions(object):
    """ """
    def __init__(self):
        """ """
        self.parser=argparse.ArgumentParser()
        self.parser.add_argument('-s','--cycle_start',help='',default=None)
        self.parser.add_argument('-e','--cycle_end',help='',default=None)
        self.parser.add_argument('-i','--cycle_interval',help='',default=None)
        self.parser.add_argument('-f','--ent_filelist',help='The XML entity file '\
            'list for the user workflow.',default=None)
        self.parser.add_argument('-m','--machine_name',help='',default=None)
        self.parser.add_argument('-rt','--realtime',help='',default=None)
        self.parser.add_argument('-d','--workflow_db',help='The XML formatted file '\
            'to contain the Rocoto database.',default=None)
        self.parser.add_argument('-w','--workflow_xml',help='The XML formatted file '\
            'to contain the Rocoto workflow.') 
        self.parser.add_argument('-x','--xml_template',help='The XML template file '\
            'containing the user workflow.',default=None)
        self.opts_obj=lambda:None
    def check(self,opts_obj):
        """
        DESCRIPTION:

        This method checks the user command line arguments to ensure sanity.

        INPUT VARIABLES:

        * opts_obj; a Python object containing the user command line
          options.

        OUTPUT VARIABLES:

        * opts_obj; a Python object containing the user command line
          options.        

        """
        if (getattr(opts_obj,'ent_filelist') is None) and \
           (getattr(opts_obj,'xml_template') is None):
            msg=('The user has specified neither an list of entity files from '\
                'which to construct the workflow (ent_filelist) or an XML '\
                'template file (xml_template); the workflow cannot be constructed '\
                'unless this information is provided. Aborting!!!')
            raise RocotoWorkflowError(msg=msg)
        if (getattr(opts_obj,'ent_filelist') is not None) and \
           (getattr(opts_obj,'xml_template') is not None):
            msg=('The user is attempting to create a Rocoto workflow file using '\
                'both a template file (xml_template) and a list of entity files '\
                '(ent_filelist); please choose either the xml_template or '\
                'ent_filelist option and try again. Aborting!!!')
            raise RocotoWorkflowError(msg=msg)
        timeattr_list=['cycle_start','cycle_end','cycle_interval','realtime']
        for item in timeattr_list:
            if (getattr(opts_obj,'ent_filelist') is not None) and \
               (getattr(opts_obj,item) is None):
                msg=('The user has not specified the command line argument %s. '\
                    'Aborting!!!'%item)
                raise RocotoWorkflowError(msg=msg)
        cmd_list=['workflow_xml']
        for item in cmd_list:
            if (getattr(opts_obj,item) is None):
                msg=('The command line argument %s cannot be NoneType. Aborting!!!'\
                    %item)
                raise RocotoWorkflowError(msg=msg)
        if (getattr(opts_obj,'workflow_db') is None):
            xml_filename=os.path.splitext(getattr(opts_obj,'workflow_xml'))[0]
            db_filename=xml_filename+'.db'
            setattr(opts_obj,'workflow_db',db_filename)
        return opts_obj
    def run(self):
        """
        DESCRIPTION:

        This method collects the user-specified command-line
        arguments; the available command line arguments are as
        follows:

        -xml; The XML template list file for the user workflow.

        -w; The XML formatted file to contain the Rocoto workflow.

        -c; 

        """
        opts_obj=self.opts_obj
        args_list=['cycle_start','cycle_end','cycle_interval','ent_filelist',\
            'machine_name','realtime','workflow_db','workflow_xml','xml_template']
        args=self.parser.parse_args()
        for item in args_list:
            value=getattr(args,item)
            boolval=true_or_false(value)
            if boolval is not None:
                setattr(opts_obj,item,boolval)
            else:
                setattr(opts_obj,item,value)
        opts_obj=self.check(opts_obj=opts_obj)
        return opts_obj

#----

class XMLTemplate(object):
    """ """
    def __init__(self,opts_obj):
        """ """
    def run(self):
        """ """
        pass

#----

def main():
    """
    DESCRIPTION:

    This is the driver-level method to invoke the tasks within this
    script.

    """
    options=RocotoWorkflowOptions()
    opts_obj=options.run()
    rocotoworkflow=RocotoWorkflow(opts_obj=opts_obj)
    rocotoworkflow.run()

#----

if __name__=='__main__':
    main()
