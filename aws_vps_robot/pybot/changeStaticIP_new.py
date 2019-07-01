'''
Change Static IP for Lightsail VPS automatically and update respective DNS settings
'''
# Indent: 4 spaces (Enable tab for 4 spaces in Notepad++ in settings/Preferenes/Languages )

import boto3
import json
from datetime import datetime, time, date
from time import sleep
import numpy as np
import os
import logging

# Parameters
# DEBUG_OPTION=1
log_file = 'changeStaticIP.log' # r'~/logs/changeStaticIP.log' 
debug_level = logging.INFO

# Application Parameters 
vInstanceName = 'Ubuntu-1GB-Oregon-1'
vStaticIpName = 'StaticIp-Oregon-Auto'

vHostedZoneId = '/hostedzone/Z2ZVCN3CYRFI7N'
vDNS_name_us = 'us.petersvpn.com'
vDNS_name_main = 'petersvpn.com'
vDNS_name_web = 'www.petersvpn.com'
vIpHistoryFilename = 'static_ip_history.csv'
vIpHistoryFileColumn = 3

# New Application Parameters 
vpn_servers = [
    {
        'instance_name': 'Ubuntu-1GB-Oregon-1',
        'static_ip_name': 'StaticIp-Oregon-Auto',
        'DNS_name': 'us.petersvpn.com'
    },
    {
    }
    ] 

# logging
# convert ~ to real path
log_file = os.path.expanduser(log_file) 
# if log file folder does not exist, log in current folder
log_folder = os.path.dirname(log_file)
if not os.path.exists(log_folder):
    log_file = os.path.basename(log_file)

logging.basicConfig(filename=log_file, level=debug_level, filemode='w', format='%(asctime)s ln-%(lineno)d %(levelname)s: - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
log = logging.getLogger('')

# App root path
root_path=os.path.dirname(os.path.realpath(__file__))

# boto3.setup_default_session(region_name='us-west-2')
# lsclient = boto3.client('lightsail')
lsclient = boto3.client('lightsail', region_name='us-west-2')
rtclient = boto3.client('route53')

# Obsolete. Use standard logging.
# def debugLog(logString):
#     if DEBUG_OPTION:
#         print (logString)

def writeFile(filename, strText):
    f = open(filename,'w') # nuke or create the file !
    f.write(strText)
    f.close()

def getStaticIp(vStaticIpName_):
    static_ip_response = ''
    try: 
        static_ip_response = lsclient.get_static_ip( 
        # staticIpName = 'StaticIp-Oregon-New' 
        staticIpName = vStaticIpName_
        )
    except Exception as ex:
        print('Call to get_static_ip failed with exception as below:') 
        print(str(ex))
    
    #log.info (static_ip_response)
    if static_ip_response != '':
        if str(static_ip_response['ResponseMetadata']['HTTPStatusCode']) == '200':
            log.info ( 'staticIp name: ' + static_ip_response['staticIp']['name'] )
            log.info ( 'staticIp ipAddress: ' + static_ip_response['staticIp']['ipAddress'] )
            log.info ( 'Attached to: ' + static_ip_response['staticIp']['attachedTo'] ) 
            return static_ip_response['staticIp']['ipAddress'] 
    

def getStaticIps():            
    static_ips_response = lsclient.get_static_ips()
    print ( 'static_ips_response:\n',static_ips_response )
    
# Allocate a new static IP
def allocateStaticIp( vStaticIpName_ ):
    allocate_static_ip_resp = ''
    try:
        allocate_static_ip_resp = lsclient.allocate_static_ip(
            staticIpName = vStaticIpName_ 
        )
    except Exception as ex:
        print('Call to allocate_static_ip failed with exception as below:') 
        print(str(ex))
    
    # log.info (allocate_static_ip_resp)
    
    if allocate_static_ip_resp != '':
        if (str(allocate_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(allocate_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            # log.info ( 'region Name: ' + allocate_static_ip_resp['operations'][0]['location']['regionName'] )
            log.info ( 'StaticIp is created: ' + allocate_static_ip_resp['operations'][0]['resourceName'] )

# Attach a new static IP
def attachStaticIp( vStaticIpName_, vInstanceName_):            
    attach_static_ip_resp = ''
    try:
        attach_static_ip_resp = lsclient.attach_static_ip(
            staticIpName = vStaticIpName_,
            instanceName = vInstanceName_ 
        )
    except Exception as ex:
        print('Call to attach_static_ip failed with exception as below:') 
        print(str(ex))
    
    # log.info (attach_static_ip_resp)

    if attach_static_ip_resp != '':
        if (str(attach_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(attach_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            # log.info ( 'region Name: ' + allocate_static_ip_resp['operations'][0]['location']['regionName'] )
            log.info ( 'StaticIp is attached to: ' + attach_static_ip_resp['operations'][0]['operationDetails'] )

            
# Release the old static IP
def releaseStaticIp( vStaticIpName_):
    release_static_ip_resp = ''
    try:
        release_static_ip_resp = lsclient.release_static_ip(
            staticIpName = vStaticIpName_ 
        )
    except Exception as ex:
        print('Call to release_static_ip failed with exception as below:') 
        print(str(ex))
    
    #log.info (release_static_ip_resp)
 
    if release_static_ip_resp != '':
        if (str(release_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(release_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            log.info ( 'StaticIp is released: ' + release_static_ip_resp['operations'][0]['resourceName'] )

# Change DNS A record
def changeDNS( vHostedZoneId_, vDNS_name_, vIpAddress_):    
    change_resource_record_sets_resp = ''
    try:
        change_resource_record_sets_resp = rtclient.change_resource_record_sets(
            HostedZoneId = vHostedZoneId_,
            ChangeBatch={
                'Comment': 'change DNS A record',
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': vDNS_name_,
                            'Type': 'A',
                            'TTL': 300,
                            'ResourceRecords': [
                                {
                                    'Value': vIpAddress_
                                }
                            ]
                        }
                    }
                ]
            }
        ) 
        
    except Exception as ex:
        print('Call to change_resource_record_sets failed with exception as below:') 
        print(str(ex))
    
    # log.info (change_resource_record_sets_resp)
    if change_resource_record_sets_resp != '':
        if (str(change_resource_record_sets_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(change_resource_record_sets_resp['ChangeInfo']['Status']) == 'PENDING'):
            log.info ( '\nDNS is being updated: ' + vDNS_name_ + ' - ' + vIpAddress_ )

# List DNS A record
def listDNS_A_record( vHostedZoneId_, vSubDomainName_):  
    vDomainName = vSubDomainName_ + '.'
    list_resource_record_sets_resp = ''
    try:
        list_resource_record_sets_resp = rtclient.list_resource_record_sets(
            HostedZoneId = vHostedZoneId_        
        ) 
    except Exception as ex:
        print('Call to list_resource_record_sets failed with exception as below:') 
        print(str(ex))
    
    # log.info (list_resource_record_sets_resp)
    
    if list_resource_record_sets_resp != '':
        if str(list_resource_record_sets_resp['ResponseMetadata']['HTTPStatusCode']) == '200':
            for record in list_resource_record_sets_resp['ResourceRecordSets']:
                if record['Type'] == 'A' and record['Name'] == vDomainName:
                    log.info('Checking DNS setting: ' + record['Name']+' - '+ record['ResourceRecords'][0]['Value'])
                    return record['ResourceRecords'][0]['Value']

def isIpAddressExist(vFilename_,vTargetIp_): 
    # File content format
    # 10.1.1.1,2018-10-01_05-00-00
    if not os.path.exists(vFilename_):
        log.info(vFilename_ + ' does not exits.')
        return False
    try:
        ip_loadtxt = np.loadtxt(vFilename_,dtype=str, delimiter=',')
    #except OSError as ex:
    #    print('Error loading file with error:\n' + str(ex))
    except Exception as ex:
        log.error(str(ex)) 
        return False
    else:       
        #log.info(ip_loadtxt.reshape(-1,2))
        # read IP columne 1
        for i in ip_loadtxt.reshape(-1,vIpHistoryFileColumn)[:,0]:
            #log.info(i)
            if i == vTargetIp_:
                log.info ('Found matched ip:' + i)
                return True
        else: # Empty file will also fall into here.
            # log.info('Don\'t find matched ip.')
            return False

def writeIpHistoryFile(vFilename_,vIpAddress_,vTries_, vDNS_name_): 
    cur_dt = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    f = open(vFilename_,"a") 
    f.write( ','.join( [vIpAddress_, cur_dt, vTries_, vDNS_name_] ) + '\n')
    # f.write(vIpAddress_ + ',' + cur_dt + ',' + vTries_ + ',' + vDNS_name_ + '\n')
    f.close()    
                
def main():
    # cur_dt = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    max_retry=3
    vFull_IpHistoryFilename = str(root_path) + os.sep + vIpHistoryFilename
    for i in range(max_retry):
        log.info ('\nTime: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
        log.info ('======================================')
        log.info ('*****Static IP before relocation:*****')
        getStaticIp(vStaticIpName)
        log.info ('')
        releaseStaticIp(vStaticIpName)
        sleep(1)
        allocateStaticIp(vStaticIpName)
        attachStaticIp(vStaticIpName, vInstanceName)
        sleep(1)
        log.info ('\n****Static IP after relocation:*****')
        vStaticIP = getStaticIp(vStaticIpName) 
        # Update respective DNS mapping
        if (vStaticIP != None and isIpAddressExist(vFull_IpHistoryFilename,vStaticIP) == False):
            log.info('Static IP is re-allocated successfully.')
            writeIpHistoryFile(vFull_IpHistoryFilename, vStaticIP, str(i+1), vDNS_name_us)
            changeDNS( vHostedZoneId, vDNS_name_us, vStaticIP)
            changeDNS( vHostedZoneId, vDNS_name_main, vStaticIP)
            changeDNS( vHostedZoneId, vDNS_name_web, vStaticIP)
            sleep(2)   
            listDNS_A_record( vHostedZoneId, vDNS_name_us)
            listDNS_A_record( vHostedZoneId, vDNS_name_main)
            listDNS_A_record( vHostedZoneId, vDNS_name_web)
            break
        # wait for some time for next loop
        sleep(1)
    else:
        log.error('Failed to get a new static IP in ' + str(max_retry) + ' attempts.' )
        
if __name__ == '__main__':
    main();
        
''' aws cli commands:
aws lightsail allocate-static-ip --static-ip-name StaticIp-Oregon-New
aws lightsail detach-static-ip --static-ip-name StaticIp-Oregon-2
aws lightsail get-static-ips
aws lightsail get-instances
aws lightsail get-instance --instance-name Ubuntu-1GB-Oregon-1
aws lightsail attach-static-ip --static-ip-name StaticIp-Oregon-New --instance-name Ubuntu-1GB-Oregon-1
aws lightsail get-static-ips
aws lightsail get-static-ip --static-ip-name StaticIp-Oregon-New
aws lightsail release-static-ip --static-ip-name StaticIp-Oregon-2
aws lightsail get-static-ips

aws route53 list-hosted-zones 
aws route53 change-resource-record-sets --hosted-zone-id /hostedzone/Z2ZVCN3CYRFI7N --change-batch file://update_A_record.json
aws route53 list-resource-record-sets --hosted-zone-id /hostedzone/Z2ZVCN3CYRFI7N
'''