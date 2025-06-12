# Ограничитель скорости для xray vpn

## Скачать этот репозиторий

```
git clone https://github.com/bruch-alex/traffic-control.git
```

Команда для получения записей из логов 3x-ui по всем клиентам
```
docker exec -it 3x-ui grep 'email:' access.log
```

Отфильтровать из команды выше только айпишники клиентов 

```
docker exec -it 3x-ui grep 'email:' access.log | grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
```