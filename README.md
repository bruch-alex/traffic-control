# Ограничитель скорости для xray vpn

```
sudo aiptables-A INPUT -p tcp -m tcp --dport 443 -m state --state NEW -j LOG --log-prefix "xray " --log-level 1
```

```
sudo docker exec -it 3x-ui grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}' access.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
```

or 

```
sudo docker exec -it 3x-ui grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' access.log | cut -d ' ' -f 2 | sort -u
```