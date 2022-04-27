---
title: Seguridad de la granja web
author: Andrés Millán Muñoz (*amilmun@correo.ugr.es*)
keywords: [SWAP, servidores, servers, cloud computing, vm]
link-citations: true
date: \today

titlepage: true,
titlepage-color: "22a6b3"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "FFFFFF"
titlepage-rule-height: 2

book: true
classoption: [oneside]

toc: true
numbersections: true

header-left: "\\textcolor{gray}{\\thetitle}"
header-right: "Andrés Millán"
footer-left: "\\hspace{1cm}"
footer-center: "\\thepage"
footer-right: "\\hspace{1cm}"

colorlinks: true
linkcolor: RoyalBlue
urlcolor: RoyalBlue
---

<!-- LTeX: language=es -->

En esta práctica, vamos a poner a punto la seguridad de la granja web. Para conseguirlo, instalaremos un certificado SSL para el acceso de HTTPS, y configuraremos un cortafuegos.

Como siempre, las IPs de las máquinas son las siguientes:

- **M1**: `192.168.49.128`.
- **M2**: `192.168.49.129`.
- **M3**: `192.168.49.130`.

# Certificado SSL


Generaremos un certificado SSL autofirmado desde la máquina M1, copiándolo a M2 mediante ssh.

## Emisión del certificado

Primero, debemos activar el módulo SSL de Apache:

```bash
sudo a2enmod ssl
sudo systemctl restart apache2 # Debemos reiniciar el servicio
```

Creamos el directorio de certificados:

```bash
sudo mkdir /etc/apache2/ssl
```

Generemos un certificado autofirmado, llamado `apache_amilmun.crt`, con clave `apache_amilmun.key` y con una duración de 1 año. Debemos introducir también los datos del certificado apropiados en la creación:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 –keyout /etc/apache2/ssl/apache_amilmun.key -out /etc/apache2/ssl/apache_amilmun.crt
```

![Para los datos del certificado, hemos usado la ciudad de Granada, con organización UGR, sección P4, y datos personales propios](img/4/generar_ssl.png)

Ahora debemos configurar correctamente apache para que use el certificado. Para lograrlo, editamos el archivo `/etc/apache2/sites-available/default-ssl.conf`, y agregamos:


```bash
SSLCertificateFile /etc/apache2/ssl/apache_amilmun.crt
SSLCertificateKeyFile /etc/apache2/ssl/apache_amilmun.key
```

![](img/4/ssl_config.png)

Finalmente, debemos activar `default-ssl` y reiniciar apache:

```bash
sudo a2ensite default-ssl
sudo systemctl reload apache2
```

Accediendo desde el navegador, podemos ver que se ha cargado correctamente la página

![](img/4/ssl_acceso.png)

## Puesta a punto de M2 y M3

Ahora, debemos copiar el certificado generado a las máquinas M2 y M3. Usamos `scp` para lograrlo:

```bash
# M1 -> M2
sudo scp /etc/apache2/ssl/apache_amilmun.crt amilmun@192.168.49.129:/etc/apache2/ssl/apache_amilmun.crt
sudo scp /etc/apache2/ssl/apache_amilmun.key amilmun@192.168.49.129:/etc/apache2/ssl/apache_amilmun.key

# M1 -> M3
```

# Configuración del firewall

## Ejecución automática del script al arrancar

https://www.ubuntuleon.com/2016/10/cargar-un-script-al-inicio-del-sistema.html

# Referencias

- https://www.ubuntuleon.com/2016/10/cargar-un-script-al-inicio-del-sistema.html