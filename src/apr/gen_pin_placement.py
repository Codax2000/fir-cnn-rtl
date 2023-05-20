#!/usr/bin/python 
import sys
import os
import re
from argparse import ArgumentParser
import pdb

#Example
# pinplacement -t <templateFile> -o <outputTclFile> 


parser = ArgumentParser()
parser.add_argument("-t", "--templateFile", default="pin_placement.txt", dest="inFile", help="The template file where you have specified your pin placements [default: pin_placement.txt]")
parser.add_argument("-o", "--outputFile", default="pin_placement.tcl", dest="outFile", help="The file name where the resulting tcl commands corrosponding to the input file are placed [default: pin_placement.tcl]")


faceDict = {"W":1, "N":2, "E":3, "S":4, "w":1, "n":2, "e":3, "s":4}
defaultMetalDict = {"W":"metal2", "N":"metal3", "E":"metal2", "S":"metal3"}

def readInputFile(inFile):
    pinList=[]
    mode=""
    defaultOffset=0.2
    pos=0    
    incr=0
    with open(inFile) as rfh:
        lines=rfh.readlines()
        for line in lines:
            line=line.strip()
            if re.search('^\s*$',line) or re.search('^//',line):
                continue
            ################3 Identify the type of mapping. Offset of direct-map ############
            elif re.search ('^\s*type\s*=\s*(\w+)', line): #type=offset or #type=map
                m=re.search ('^\s*type\s*=\s*(?P<mode>\w+)', line)
                mode=m.group('mode')
                if not( mode=='offset' or mode=='map'):
                    print("Invalid mode. Mode must be either offset or map. {0} selected. Please specify a valid mode".format(mode))
                ###################### Identify the default Offset #############################
                # elif re.search ('\s*defaultOffset', line): #default_offset=245.52
            elif re.search ('\s*defaultOffset\s*=\s*[0-9.]+', line): #default_offset=245.52
                m=re.search ('\s*defaultOffset\s*=\s*(?P<offset>[0-9.]+)', line)
                defaultOffset=float(m.group('offset'))
                ###################### Identify new "signpost" #############################
            elif re.search('^#[ENWSenws],\s*[0-9.]*',line): #You have a marker #E, #W, #N, #S
                line=re.sub('^#','',line)
                line=re.split(',',line)
                side=faceDict[line[0]]
                currentPos=float(line[1]) if len(line)>1 else 0
                ###################### Pin statement #############################
            else: #Regular pin assignment nnnn
                signal = "INVALID"
                line=re.sub('\s+', '',line)
                lineList=line.split(r',') #Break on a comma
                #######Get the metal layer and the offset for the line###########
                m=re.search(r'layer\s*=\s*(?P<metalLayer>metal[0-9]+)',lineList[1])
                metalLayer=m.group('metalLayer')
                m=re.search(r'\+(?P<offset>[0-9.]+)',lineList[-1])
                offset = float(m.group('offset')) if m else defaultOffset
                #Look for offset
                ################# Is there a bus statement ###################
                if(re.search('[\<\[]',lineList[0])):  #Check if signal is a bus
                    if(re.search(':',lineList[0])):   #If bus, is it a range
                        m=re.search('(?P<prefix>.*?)[\<\[]\s*(?P<max>[0-9]+):(?P<min>[0-9]+)\s*[\<\]]',lineList[0])
                        prefix,left,right =m.group('prefix'), int(m.group('max')), int(m.group('min'))
                        # (stop,start)=(right,left) if left>right else (left,right)
                        incr = 1 if right>left else -1
                        ##Get the pitch for the bus
                        m=re.search(r'pitch\s*=\s*(?P<pitch>[0-9.]+)',line)
                        pitch=float(m.group('pitch'))
                        # stop= m if m>n else n
                        ################# Is there a  ###################
                    else:
                        m=re.search('(?P<prefix>.*?)[\<\[]\s*(?P<val>[0-9]+)\s*[\]\]]',lineList[0])
                        prefix,m =m.group('prefix'), int(m.group('val'))
                        left=m
                        right= m
                    for i in range(left,right+incr,incr):
                        last=1 if i==right else 0
                        signal=prefix + "[" + str(i) + "]"
                        currentPos,pinInfoList=unpackLine(lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side)
                        pinList.append(pinInfoList)
                else:
                    currentPos,pinInfoList=unpackLine(lineList,lineList[0],metalLayer,0,1,mode,currentPos,offset,side)
                    pinList.append(pinInfoList)

    return pinList
                            

def unpackLine (lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side):
    signalList=[]
    nextPos="invalid"
    if mode=='offset':
        nextPos= float(currentPos)+ offset if(pitch==0 or last==1) else float(currentPos)+ pitch            
    else:
        currentPos = float(lineList[-1])
    signalList.extend((signal,metalLayer,currentPos,side))
    return nextPos,signalList
    

args = parser.parse_args()
wfh=open(args.outFile,'w')
pinList=readInputFile(args.inFile)
for pin in pinList:
    wfh.write("set_pin_physical_constraints -pin_name {%s} -layers {%s} -width 0.1 -depth 0.1 -side %s -offset %.2f\n" %(pin[0],pin[1],pin[3],pin[2]))
wfh.close()
    # print pinList
