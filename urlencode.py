#!/usr/bin/python

#Import necessary libs to do work,
import urllib
import sys

#grab UA to be encoded from system arguments (ie python urlencode.py systemArgument)
encodedUA = sys.argv[1]
encodedUA = urllib.quote_plus(encodedUA)

#print the UA url encoded for the bash script to grab
print encodedUA
