# Docker image for meterN
A self-configuring multi-arch Docker image to run [Jean-Marc Louviaux](https://github.com/jeanmarc77) [meterN](https://github.com/jeanmarc77/meterN) energy metering and monitoring.

[![](https://img.shields.io/github/license/EdoFede/123Solar-meterN-Docker.svg)](https://github.com/EdoFede/123Solar-meterN-Docker/blob/master/LICENSE)

## Introduction
[meterN](https://metern.org) is a metering and monitoring app for energy management, that can be used also for monitoring others meters like: water, gas, temperature, etc...

## Why this Docker image
Just a meterN enviroment with already available additional tools like [jq](https://github.com/stedolan/jq) command-line JSON processor and [mosquitto](https://mosquitto.org/) mqtt client.

## Credits
The original docker image work was done by [EdoFede](https://github.com/EdoFede) in [123Solar-meterN-Docker](https://github.com/EdoFede/123Solar-meterN-Docker)

Both 123Solar and meterN apps are developed by Jean-Marc Louviaux and are based on Web interfaces with PHP and shell scripts backend.

The [SDM120C](https://github.com/gianfrdp/SDM120C) script used to read meter data via ModBus is developed by [Gianfranco Di Prinzio](https://github.com/gianfrdp).

Some of the interface scripts used to get data inside the Web apps are written and maintained by [Flavio Anesi](http://www.flanesi.it/blog/about/).
Flavio has also published many very detailed and well done [guides](http://www.flanesi.it/doku/doku.php?id=start) (in Italian) about the whole setup for these apps.  Since these are the most detailed guides you find online about this topic, I suggest you read them.

### meterN ModBus setup
As the original docker image, it's included a `config_daemon.php` template file (provided by [Flavio](http://www.flanesi.it/doku/doku.php?id=metern_mono_modbus#avvio_file_pooler485_per_lettura_consumi) that points to meter address 2.
If your meter address, USB device address or communication speed are different, edit this line:

```php
exec("pooler485 2 9600 /dev/ttyUSB0 > /dev/null 2>/dev/null &");
```
If you have more than one meter on a single RS485 line, you can add the meter IDs, separated by commas, in the `config_daemon.php` file, as explained by Flavio in [his tutorial](http://www.flanesi.it/doku/doku.php?id=aggiunta_contatori#lettura_contatori), for example:

```php
exec('pooler485 1,2,3 9600 /dev/ttyUSB0 > /dev/null 2>/dev/null &');
```

## Docker image details
The image is based on Alpine linux for lightweight distribution and mainly consist of:

* [runit](http://smarden.org/runit/) init scheme and service supervision
* [Nginx](https://nginx.org/en/) web server
* [PHP-FPM](https://php-fpm.org) FastCGI process manager for PHP interpeter

All components are automatically configured by the Docker image
 
## Limitation & future enhancement
At the moment, the image supports only one USB>RS485 communication interface, so you must have all meters on the same RS485 bus.

