
# DNS Configuration

This code aims to quickly and easily configure DNS.

It uses the 'zenity' program to have a more user friendly interface, making it easier to use and thus reducing the chances of errors.

# What do you need to use this software?
- You will need the 'zenity' program installed on your machine.<br/>
Zenity is a program used to design user-friendly interfaces, with buttons and menus, from a Shell Script.

# How to use it?
You should first check if you have the dialog installed.<br/>
Call the program by its terminal like command:<br/>
`$zenity`<br/>

If you have a return as:<br/>
`$ Unknown command zenity`<br/>
So you do not have the program installed<br/>

To install it on Debian-based distributions simply use the command:<br/>
`$sudo apt install zenity`<br/>

To install it on Arch-based distributions simply use the command:<br/>
`sudo pacman -S zenity`<br/>

Execution permission to DNS_Config with the command<br/>
`$sudo chmod +x DNS_Config.sh`<br/>

After that you just run the program:<br/>
`./DNS_config.sh`

