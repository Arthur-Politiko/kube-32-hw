[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../vault/id_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[master]
k8s-master ansible_host=${master_ip} private_ip=${master_private_ip}

[workers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=ubuntu@${master_ip}'

[workers] 

%{~ for name, ip in worker_ips ~}
${name} ansible_host=${ip}
%{endfor}

[all:children]
master
workers