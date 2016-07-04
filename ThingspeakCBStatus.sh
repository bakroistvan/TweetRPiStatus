#!/usr/bin/env python

import sys
import os
import httplib, urllib
import ConfigParser

os.environ['TERM'] = "bash"

# Return CPU temperature as a float
def getCPUtemperature():
#    try:
#        s = subprocess.check_output(["/opt/vc/bin/vcgencmd","measure_temp"], shell=False)
#        return float(s.split('=')[1][:-3])
#    except:
#        return 0
    if os.path.isfile('/sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/temp1_input'):
        res = float(os.popen("cat /sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/temp1_input").readline())/1000
        return(str(res))
    else:
        return 'N/A'

# Return RAM information (unit=kb) in a list
# Index 0: total RAM
# Index 1: used RAM
# Index 2: free RAM
def getRAMinfo():
    p = os.popen('free')
    i = 0
    while 1:
        i = i + 1
        line = p.readline()
        if i==3:
            return(line.split()[1:4])

# Return % of CPU used by user as a character string
def getCPUuse():
    # Return the inverse of CPU idle, instead of part of usage
    cpuUsePrc=str(100-float(os.popen("top -n1 -b | awk '/Cpu\(s\):/ {print $8}'").readline().strip()))
    return(cpuUsePrc)

# Return information about disk space as a list (unit included)
# Index 0: total disk space
# Index 1: used disk space
# Index 2: remaining disk space
# Index 3: percentage of disk used
def getUsersCount():
    p = os.popen("who | wc -l").readline()
    return(p)

def getDiskSpace():
    p = os.popen("df /")
    line = p.readline()
    line = p.readline()
    return(line.split()[1:5])

def getDiskSpace():
    p = os.popen("sudo hddtemp /dev/sda -n")
    line = p.readline()
    return(line)


#Main program
if __name__ == "__main__":
    ramInfo = getRAMinfo()
    usedMem = int(ramInfo[1])
    freeMem = int(ramInfo[2])
    #calculate the free memory percentage
    freeMemPerc = int((float(freeMem)/(usedMem+freeMem))*100)
    #get hostname
    hostname = os.popen('hostname').readline().rstrip()
    #build the info string
    sysInfoString = hostname + ": CPUTemp " + getCPUtemperature() + ", CPU U " + getCPUuse()+ "%, FreeDisk " + getDiskSpace()[2] + ", FreeMemPrc " + str(freeMemPerc) + "%" + ", Users " + getUsersCount()
    print(sysInfoString)

    #read config file for twitter keys (so not to include them on github)
    try:
        config = ConfigParser.ConfigParser()
        if config.read(os.path.dirname(os.path.realpath(__file__)) + "/rpi_status.conf"):
            api_key = config.get('ThingspeakAccount', 'api_key')
            
            headers = {"Content-type": "application/x-www-form-urlencoded","Accept": "text/plain"}
            params = urllib.urlencode({
                'field1': getCPUtemperature(),
                'field2': getCPUuse(),
                'field3': getDiskSpace()[2],
                'field4': str(freeMemPerc),
                'field5': getUsersCount(),
                'field6': getDiskSpace(),
                'key': api_key
            })
            
            conn = httplib.HTTPConnection("api.thingspeak.com:80")
            conn.request("POST", "/update", params, headers)
            response = conn.getresponse()
            conn.close()

        else:
            print('Error reading config file')
    except Exception:
        print(Exception)
        exit()

