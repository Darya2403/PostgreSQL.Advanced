# etcd-1
yc compute instance create `
  --name etcd-1 `
  --hostname etcd-1 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 2 `
  --create-boot-disk size=20G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,ipv4-address=10.128.0.10 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# etcd-2
yc compute instance create `
  --name etcd-2 `
  --hostname etcd-2 `
  --zone ru-central1-b `
  --cores 2 `
  --memory 2 `
  --create-boot-disk size=20G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-b,ipv4-address=10.129.0.11 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# etcd-3
yc compute instance create `
  --name etcd-3 `
  --hostname etcd-3 `
  --zone ru-central1-d `
  --cores 2 `
  --memory 2 `
  --create-boot-disk size=20G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-d,ipv4-address=10.130.0.12 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"


# citus-coord-1
yc compute instance create `
  --name citus-coord-1 `
  --hostname citus-coord-1 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,ipv4-address=10.128.0.20 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# citus-coord-2
yc compute instance create `
  --name citus-coord-2 `
  --hostname citus-coord-2 `
  --zone ru-central1-b `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-b,ipv4-address=10.129.0.21 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"


# citus-w1
yc compute instance create `
  --name citus-worker-1 `
  --hostname citus-worker-1 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,ipv4-address=10.128.0.30 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# citus-w2
yc compute instance create `
  --name citus-worker-2 `
  --hostname citus-worker-2 `
  --zone ru-central1-b `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-ssd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-b,ipv4-address=10.129.0.31 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# citus-w3
yc compute instance create `
  --name citus-worker-3 `
  --hostname citus-worker-3 `
  --zone ru-central1-d `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-d,ipv4-address=10.130.0.32 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# citus-w4
yc compute instance create `
  --name citus-worker-4 `
  --hostname citus-worker-4 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 4 `
  --create-boot-disk size=30G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,ipv4-address=10.128.0.33 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"

# haproxy-1 (с внешним IP)
yc compute instance create `
  --name haproxy-1 `
  --hostname haproxy-1 `
  --zone ru-central1-a `
  --cores 2 `
  --memory 2 `
  --create-boot-disk size=20G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-a,ipv4-address=10.128.0.100,nat-ip-version=ipv4 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"


# haproxy-2 (с внешним IP)
yc compute instance create `
  --name haproxy-2 `
  --hostname haproxy-2 `
  --zone ru-central1-b `
  --cores 2 `
  --memory 2 `
  --create-boot-disk size=20G,type=network-hdd,image-id=fd81gsj7pb9oi8ks3cvo `
  --network-interface subnet-name=default-ru-central1-b,ipv4-address=10.129.0.101,nat-ip-version=ipv4 `
  --ssh-key "C:\Users\дарья\.ssh\bananaflow.pub"
