# Ограничитель скорости для xray vpn

## Скачать этот репозиторий

```
git clone https://github.com/bruch-alex/traffic-control.git
```

## Как использовать?

1. Клонировать этот репозиторий

	```bash
	git clone git@github.com:bruch-alex/traffic-control.git
	```

2. Копировать скрипт в локальную папку

	```bash
	sudo cp xray_logger.sh /	/usr/local/bin/xray_logger.sh
	```

3. Сделать скрипт исполняемым

	```bash
	sudo chmod +x /usr/local/bin/xray_logger.sh 
	```

4. Копировать systemd service

```bash
sudo cp xray-log.service /etc/systemd/system/xray-log.service
```

5. Включить systemd сервис

```bash
sudo systemctl daemon-reload
sudo systemctl enable xray-log.service
sudo systemctl start xray-log.service
```