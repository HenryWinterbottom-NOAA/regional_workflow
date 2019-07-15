"""
SCRIPT:   

   rocoto_xml.py

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

#----

__author__ = "Henry R. Winterbottom"
__copyright__ = "2019 Henry R. Winterbottom, NOAA/NCEP/EMC"
__version__ = "1.0.0"
__maintainer__ = "Henry R. Winterbottom"
__email__ = "henry.winterbottom@noaa.gov"
__status__ = "Development"

#----

class RocotoXMLOptions(object):
    """ """
    def __init__(self):
        """ """
        self.parser=argparse.ArgumentParser()
        self.parser.add_argument('-t','--xml_template',help='The XML template '\
            'file for the user workflow.')
        self.parser.add_argument('-w','--workflow_xml',help='The XML formatted file '\
            'to contain the Rocoto workflow.')
        self.parser.add_argument('-c','--cycle',help='The 


#----

def main():
    """
    DESCRIPTION:

    This is the driver-level method to invoke the tasks within this
    script.

    """
    options=RocotoXMLOptions()
    opts_obj=options.run()

#----

if __name__=='__main__':
    main()
