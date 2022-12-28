#!/usr/bin/python3
import re
import sys

if len(sys.argv) < 3:
    exit("Usage: {} <api.js> <apiurl>".format(sys.argv[0]))

regex = r"https:.*\.execute-api\..*\.amazonaws\.com/"
apiurl = sys.argv[2]
with open(sys.argv[1],"r") as infile:
    content = infile.read() 
    newcontent = re.sub(regex, apiurl, content, 0, re.MULTILINE)
    if not newcontent:
        exit("Regex fail!")
with open(sys.argv[1],"w") as outfile:
    outfile.write(newcontent)
