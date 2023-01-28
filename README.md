# ![icon](data/icon.png) Wingpanel Namarupa Indicator

![Screenshot](data/screenshot.png)

## Name Inspiration

The name Namarupa is used for the forces at play that govern the Ayatana, in Buddhism. Since this indicator manages the system tray icons which are under the Ayatana project, it seems clever to name this Namarupa.

## Before Installation

You need to add Pantheon to the list of desktops abled to work with indicators:  

- With autostart (thanks to JMoerman)  

System settings -> Applications -> Startup -> Add Startup App… -> Type in a custom command

Add `/usr/lib/x86_64-linux-gnu/indicator-application/indicator-application-service` as custom command to the autostart applications in the System Settings

- OR Open Terminal and run the following commands:

```bash
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/indicator-application.desktop ~/.config/autostart/
sed -i 's/^OnlyShowIn.*/OnlyShowIn=Unity;GNOME;Pantheon;/' ~/.config/autostart/indicator-application.desktop
```

## Installation for users

TODO: Finish this

Install the latest debian file:

- Download [com.github.*odin.deb (broken)](https://github.com/lenemter/wingpanel-indicator-namarupa/blob/master/com.github.lenemter.wingpanel-indicator-namarupa_1.0.2_odin.deb-broken)</a>
- Open your Downloads folder in Files
- Right click -> Open in -> Terminal

```bash
sudo apt install ./com.github.lenemter.wingpanel*.deb (broken)
```

Easy uninstall after easy install:

```bash
sudo apt remove com.github.lenemter.wingpanel-indicator-namarupa
```

Reboot
  
## For developers

You'll need the following dependencies:

- libglib2.0-dev
- libgranite-dev
- libindicator3-dev
- libwingpanel-dev
- valac
- meson (>= 0.58)

Install them with:

```bash
sudo apt install libglib2.0-dev libgranite-dev libwingpanel-dev libindicator3-dev valac meson
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
- Run `sudo ninja uninstall`

Reboot (`reboot`) or kill Wingpanel (`killall io.elementary.wingpanel`)

## Credits

Forked from: [Lafydev/wingpanel-indicator-namarupa](https://github.com/Lafydev/wingpanel-indicator-namarupa)  
Original idea: [donadigo/wingpanel-indicator-namarupa](https://github.com/donadigo/wingpanel-indicator-namarupa)  
Original indicator: [elementary/wingpanel-indicator-ayatana](https://github.com/elementary/wingpanel-indicator-ayatana)
