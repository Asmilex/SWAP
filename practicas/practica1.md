# Práctica 1

> Autor: Andrés Millán Muñoz

En esta práctica instalaremos y configuraremos dos máquinas virtuales de Ubuntu Server mediante VMWare. En particular, pondremos a punto una instalación de Apache, PHP, MySQL, SSH, así como la interfaz de red necesaria para comunicar ambas máquinas.

Para ver que todo funciona correctamente, usaremos la herramienta `curl` para solicitar una pequeña página web que crearemos. De esa forma, comprobaremos que Apache está listo. Esta página web estará alojada en las máquinas respectivas.

## Arrancando la máquina virtual

Antes de comenzar, debemos instalar ambos sistemas en VMWare. Se intentó hacerlo en VirtualBox, pero un `Kernel panic - not syncing: Attempted to kill the idle task` no me permitía iniciarlo. ¿Quizás sea debido a que estoy en Windows 11 insiders, y no se lleva bien con VirtualBox? Además, probé con Hyper-V, pero los 8GB de RAM en mi portátil no permitía iniciar la máquina.

Empecemos con la creación de las máquinas. Como el proceso es análogo, mostraremos únicamente fotos de la segunda máquina, la correspondiente a `m2-amilmun`.
