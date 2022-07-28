# ![icon](data/icon.png) Wingpanel Namarupa Indicator

![Screenshot](data/shot.png)

## Name Inspiration

The name Namarupa is used for the forces at play that govern the Ayatana, in Buddhism. Since this indicator manages the system tray icons which are under the Ayatana project, it seems clever to name this Namarupa.

## Before Installation

You need indicator-application:

```bash
sudo apt install indicator-application
```

You need to add Pantheon to the list of desktops abled to work with indicators:  

- With autostart (thanks to JMoerman)  

System settings -> "Applications" -> "Startup" -> "Add Startup App…" -> "Type in a custom command"

Add `/usr/lib/x86_64-linux-gnu/indicator-application/indicator-application-service` as custom command to the auto start applications in the system settings  

- With a terminal
Open Terminal and run the following commands.

```bash
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/indicator-application.desktop ~/.config/autostart/
sed -i 's/^OnlyShowIn.*/OnlyShowIn=Unity;GNOME;Pantheon;/' ~/.config/autostart/indicator-application.desktop
```

### Easy install for users

Install the latest debian file :

- Download <a href="https://github.com/Lafydev/wingpanel-indicator-namarupa/blob/master/com.github.donadigo.wingpanel-indicator-namarupa_1.0.2_odin.deb">com.github.*odin.deb (broken)</a>
- Open your Downloads folder in Files
- Right click -> Open in -> Terminal

```bash
sudo apt install ./com.github.donadigo.wingpanel*.deb (broken)
```

Easy uninstall after easy install:

```bash
sudo apt remove com.github.donadigo.wingpanel-indicator-namarupa
```

Reboot (`reboot`) or kill Wingpanel (`killall io.elementary.wingpanel`)
  
### For developers

You'll need the following dependencies:

- libglib2.0-dev
- libgranite-dev
- libindicator3-dev
- libwingpanel-dev
- valac
- meson
- gcc

Install them with:

```bash
sudo apt install libglib2.0-dev libgranite-dev libwingpanel-dev libindicator3-dev valac meson gcc
```

Run meson to configure the build environment and then ninja to build and install:

```bash
meson build --prefix=/usr
cd build
ninja
ninja install
```

Reboot (`reboot`) or kill Wingpanel (`killall io.elementary.wingpanel`)

To uninstall with ninja:

- Open a terminal in the build folder.
- `sudo ninja uninstall`

Reboot (`reboot`) or kill Wingpanel (`killall io.elementary.wingpanel`)
