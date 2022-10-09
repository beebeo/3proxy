# Create Proxy Server with 3proxy.ru

### Pull Script
`wget https://raw.githubusercontent.com/beebeo/3proxy/main/3proxy.sh`

`chmod +x 3proxy.sh`

### Enable ipv6 (with BKNS)
`./3proxy.sh bkns`

### Install 3proxy
`./3proxy.sh install`

### Generate new ipv6
`./3proxy.sh setup -u test -p test -o 3333`

### See process 3proxy
`ps aux | grep 3proxy`

### Check port 3proxy opened
`sudo netstat -tuplan | grep 3proxy`

### Test proxy
`curl -x localhost:3333 -U test:test https://icanhazip.com`
