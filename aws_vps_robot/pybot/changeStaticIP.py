"""
Change Static IP for Lightsail VPS automatically and update respective DNS settings
"""
import boto3
import json
from datetime import datetime
from time import sleep
import numpy as np
import os
import logging

### Parameters ###
log_file = r'~/logs/changeStaticIP.log' 
debug_level = logging.INFO

vHostedZoneId = '/hostedzone/Z04791493QXIP3UOKM5E2'
vIpHistoryFilename = r'~/logs/static_ip_history.csv'
vIpHistoryFileColumn = 3

# New Application Parameters 
vpn_servers = [
    {
        'instance_name': 'Ubuntu-AU1-2GB', 
        'static_ip_name': 'StaticIp-AU-Auto', 
        'DNS_names': ['sanpingshui.com'],
        #'DNS_names': ['pxie.info','us.pxie.info'],
        'region_name': 'ap-southeast-2'
    },
    ] 

def ensure_file_exists(filename):
    """ expanduser ~ and convert to current folder if the parent folder does not exist.
    
    filename: Full path, e.g. ~/a.py
    """
    newfile = os.path.expanduser(filename) 
    # if the folder does not exist, convert into current folder
    file_folder = os.path.dirname(newfile)
    if not os.path.exists(file_folder):
        newfile = os.path.basename(newfile)
    return newfile

log_file = ensure_file_exists(log_file)
vIpHistoryFilename = ensure_file_exists(vIpHistoryFilename) 

# logging
logging.basicConfig(filename=log_file, level=debug_level, filemode='w', format='%(asctime)s ln-%(lineno)d %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
log = logging.getLogger('')

# App root path
root_path=os.path.dirname(os.path.realpath(__file__))

# boto3.setup_default_session(region_name='us-west-2')
# lsclient = boto3.client('lightsail')
# lsclient = boto3.client('lightsail', region_name='us-west-2')
rtclient = boto3.client('route53')


def writeFile(filename, strText):
    f = open(filename,'w') # nuke or create the file !
    f.write(strText)
    f.close()

def getStaticIp(vStaticIpName_,lsclient):
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
    

def getStaticIps(lsclient):            
    static_ips_response = lsclient.get_static_ips()
    print ( 'static_ips_response:\n',static_ips_response )
    
# Allocate a new static IP
def allocateStaticIp( vStaticIpName_, lsclient ):
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
def attachStaticIp( vStaticIpName_, vInstanceName_, lsclient):            
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
def releaseStaticIp( vStaticIpName_, lsclient):
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
            log.info ( 'DNS is being updated: ' + vDNS_name_ + ' - ' + vIpAddress_ )

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
                    log.info('Checking DNS setting: ' + record['Name'] + ' - ' + record['ResourceRecords'][0]['Value'])
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

def writeIpHistoryFile(vFilename_,vIpAddress_,vTries_): 
    cur_dt = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    f = open(vFilename_,"a") 
    f.write( ','.join( [vIpAddress_, cur_dt, vTries_] ) + '\n')
    # f.write(vIpAddress_ + ',' + cur_dt + ',' + vTries_ +  '\n')
    f.close()    
                
def main():
    # cur_dt = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    max_retry=3
    for server in vpn_servers:
        vStaticIpName = server['static_ip_name'] 
        vInstanceName = server['instance_name']
        vRegionName = server['region_name']
        vDNS_names = server['DNS_names']
        lsclient = boto3.client('lightsail', region_name=vRegionName )
        for i in range(max_retry):
            # log.info ('Time: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            log.info ('======================================')
            log.info ('*****Static IP before relocation:*****')
            getStaticIp(vStaticIpName,lsclient)
            releaseStaticIp(vStaticIpName, lsclient)
            sleep(1)
            allocateStaticIp(vStaticIpName, lsclient)
            attachStaticIp(vStaticIpName, vInstanceName, lsclient)
            sleep(1)
            log.info ('****Static IP after relocation:*****')
            vStaticIP = getStaticIp(vStaticIpName, lsclient) 
            # Update respective DNS mapping
            if (vStaticIP != None and isIpAddressExist(vIpHistoryFilename,vStaticIP) == False):
                log.info('Static IP is re-allocated successfully.')
                writeIpHistoryFile(vIpHistoryFilename, vStaticIP, str(i+1))
                for dns in vDNS_names:
                    changeDNS( vHostedZoneId, dns, vStaticIP)
                sleep(1)
                # check
                for dns in vDNS_names:
                    listDNS_A_record( vHostedZoneId, dns)
                break
            # wait for some time for next loop
            sleep(1)
        else:
            log.error('Failed to get a new static IP in ' + str(max_retry) + ' attempts.' )
            
if __name__ == '__main__':
    main()
    
