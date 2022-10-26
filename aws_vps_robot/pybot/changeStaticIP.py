#!/usr/bin/env python3
"""
Change Static IP for Lightsail VPS automatically and update respective DNS settings
"""
import boto3
from datetime import datetime
from time import sleep
import numpy as np
import os
import logging
import traceback

### Parameters ###
log_file = r'~/logs/changeStaticIP.log' 
debug_level = logging.INFO

vHostedZoneId = '/hostedzone/Z04791493QXIP3UOKM5E2'
vIpHistoryFilename = r'~/logs/static_ip_history.csv'
vIpHistoryFileColumn = 3
Wait_Secs_Before_Retry = 2

# New Application Parameters 
vpn_servers = [
    {
        'instance_name': 'Ubuntu-1', 
        'static_ip_name': 'StaticIp-AU-Auto', 
        'DNS_names': ['sanpingshui.com'],
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

def send_email(to, subject, contents):
    """  send email with gmail account defined in ~/.yagmail.

    contents: e.g. 'body content' or ['mail body content','pytest.ini','a.py']
    to: e.g. 'peter.jp.xie@gmail.com'
    
    https://github.com/kootenpv/yagmail
    """
    import yagmail
    user = 'xiejiping@gmail.com'
    
    # read password
    gmail_config = {}
    with open(os.path.expanduser('~/.yagmail'))as f:
        for line in f:
            if '=' in line:
                key, value = line.split('=')
                key, value = key.strip(), value.strip()
                gmail_config[key] = value
    assert 'token' in gmail_config

    password = gmail_config['token']

    try:
        with yagmail.SMTP(user, password) as yag:
            yag.send(to,subject,contents)
        log.info('Sent email successfully')
    except Exception as e:
       log.error(traceback.format_exc())
       log.error('***Failed to send email***')

def getStaticIp(vStaticIpName_,lsclient):
    static_ip_response = ''
    try: 
        static_ip_response = lsclient.get_static_ip( 
        # staticIpName = 'StaticIp-Oregon-New' 
        staticIpName = vStaticIpName_
        )
    except Exception as ex:
        log.error('Call to get_static_ip failed with exception as below:') 
        log.error(str(ex))
        return ex
    
    log.debug(static_ip_response)
    if static_ip_response != '':
        if str(static_ip_response['ResponseMetadata']['HTTPStatusCode']) == '200':
            log.info ( 'staticIp name: ' + static_ip_response['staticIp']['name'] )
            log.info ( 'staticIp ipAddress: ' + static_ip_response['staticIp']['ipAddress'] )
            log.info ( 'Attached to: ' + static_ip_response['staticIp']['attachedTo'] ) 
            return static_ip_response['staticIp']['ipAddress'] 
        else:
            log.error('Failed to get static ip with response: %s' % static_ip_response )  
    
# Allocate a new static IP
def allocateStaticIp( vStaticIpName_, lsclient ):
    allocate_static_ip_resp = ''
    try:
        allocate_static_ip_resp = lsclient.allocate_static_ip(
            staticIpName = vStaticIpName_ 
        )
    except Exception as ex:
        log.error('Call to allocate_static_ip failed with exception as below:') 
        log.error(str(ex))
        return ex
    
    log.debug(allocate_static_ip_resp)
    
    if allocate_static_ip_resp != '':
        if (str(allocate_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(allocate_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            # log.info ( 'region Name: ' + allocate_static_ip_resp['operations'][0]['location']['regionName'] )
            log.info ( 'StaticIp is created: ' + allocate_static_ip_resp['operations'][0]['resourceName'] )
        else:
            log.error('Failed to allocate static ip with response: %s' % allocate_static_ip_resp )

# Attach a new static IP
def attachStaticIp(vStaticIpName_, vInstanceName_, lsclient):            
    attach_static_ip_resp = ''
    try:
        attach_static_ip_resp = lsclient.attach_static_ip(
            staticIpName = vStaticIpName_,
            instanceName = vInstanceName_ 
        )
    except Exception as ex:
        log.error('Call to attach_static_ip failed with exception as below:') 
        log.error(str(ex))
        return ex
    
    log.debug(attach_static_ip_resp)

    if attach_static_ip_resp != '':
        if (str(attach_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(attach_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            # log.info ( 'region Name: ' + allocate_static_ip_resp['operations'][0]['location']['regionName'] )
            log.info ( 'StaticIp is attached to: ' + attach_static_ip_resp['operations'][0]['operationDetails'] )
        else:
            log.error('Failed to attach static ip with response: %s' % attach_static_ip_resp )

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
        return ex
    
    log.debug(release_static_ip_resp)
 
    if release_static_ip_resp != '':
        if (str(release_static_ip_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(release_static_ip_resp['operations'][0]['status']) == 'Succeeded'):
            log.info ( 'StaticIp is released: ' + release_static_ip_resp['operations'][0]['resourceName'] )
        else:
            log.error('Failed to release static ip with response: %s' % release_static_ip_resp )

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
        log.error('changeDNS failed.')
        log.error('Call to change_resource_record_sets failed with exception as below:') 
        log.error(str(ex))
        return ex
    
    # log.info (change_resource_record_sets_resp)
    if change_resource_record_sets_resp != '':
        if (str(change_resource_record_sets_resp['ResponseMetadata']['HTTPStatusCode']) == '200' and
            str(change_resource_record_sets_resp['ChangeInfo']['Status']) == 'PENDING'):
            log.info ( 'DNS is being updated: ' + vDNS_name_ + ' - ' + vIpAddress_ )
        else:
            log.error('Failed to update DNS with response: %s' % change_resource_record_sets_resp )

# List DNS A record
def listDNS_A_record( vHostedZoneId_, vSubDomainName_):  
    vDomainName = vSubDomainName_ + '.'
    list_resource_record_sets_resp = ''
    try:
        list_resource_record_sets_resp = rtclient.list_resource_record_sets(
            HostedZoneId = vHostedZoneId_        
        ) 
    except Exception as ex:
        log.error('Call to list_resource_record_sets failed with exception as below:') 
        log.error(str(ex))
        return ex
    
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
    print('Start changing IP')
    # cur_dt = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    max_retry=3
    for server in vpn_servers:
        vStaticIpName = server['static_ip_name'] 
        vInstanceName = server['instance_name']
        vRegionName = server['region_name']
        vDNS_names = server['DNS_names']
        lsclient = boto3.client('lightsail', region_name=vRegionName)
        change_ip_success = False # update to True once successful
        for i in range(max_retry):
            # log.info ('Time: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
            log.info ('=================Attempt %s=====================' % (i+1))
            log.info ('*****Static IP before relocation:*****')
            ret = getStaticIp(vStaticIpName,lsclient)
            if isinstance(ret,Exception):
                log.error('Failed to rotate IP with exception at getStaticIp.')
                sleep(Wait_Secs_Before_Retry)
                continue
            ret = releaseStaticIp(vStaticIpName, lsclient)
            if isinstance(ret,Exception):
                log.error('Failed to rotate IP with exception at releaseStaticIp.')
                sleep(Wait_Secs_Before_Retry)
                continue            
            sleep(5) # sleep to avoid previous static ip name not fully ready
            ret = allocateStaticIp(vStaticIpName, lsclient)
            if isinstance(ret,Exception):
                log.critical('Failed to allocate static ip for %s, give up!' % vInstanceName) 
                break                
            ret = attachStaticIp(vStaticIpName, vInstanceName, lsclient)
            if isinstance(ret,Exception):
                log.critical('Failed to attach static ip %s to instace %s, give up!' % (vStaticIpName,vInstanceName))
                break
            sleep(2) # wait to take effect
            log.info ('****Static IP after relocation:*****')
            vStaticIP = getStaticIp(vStaticIpName, lsclient) 
            # Update respective DNS mapping
            if (vStaticIP != None and isIpAddressExist(vIpHistoryFilename,vStaticIP) == False):
                log.info('Static IP is re-allocated successfully.')
                change_ip_success = True
                writeIpHistoryFile(vIpHistoryFilename, vStaticIP, str(i+1))
                for dns in vDNS_names:
                    changeDNS( vHostedZoneId, dns, vStaticIP)
                sleep(2)
                # check
                for dns in vDNS_names:
                    listDNS_A_record( vHostedZoneId, dns)
                break
            # wait for some time for next attempt
            sleep(Wait_Secs_Before_Retry)

        # fails to change ip
        if change_ip_success is False:
            # still need to update DNS if new IP is allocated but exists in the history
            if (vStaticIP != None and isIpAddressExist(vIpHistoryFilename,vStaticIP) == True):
                log.info('Static IP is re-allocated but exists in the history.')
                for dns in vDNS_names:
                    changeDNS( vHostedZoneId, dns, vStaticIP)
                sleep(2)
                # check
                for dns in vDNS_names:
                    listDNS_A_record( vHostedZoneId, dns)

            log.error('Failed to get a new static IP in %s attempts.' % max_retry)
                      
    # send email for failures
    with open(os.path.expanduser(log_file)) as f:
        log_content = f.read()
        if 'error' in log_content.lower() or 'critical' in log_content.lower():
            send_email('peter.jp.xie@gmail.com','Static IP Relocation Failed', log_content)
    print('Done')

if __name__ == '__main__':
    main()
