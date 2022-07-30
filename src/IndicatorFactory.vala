/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class AyatanaCompatibility.IndicatorFactory : Object {
    private Gee.HashMap<unowned IndicatorAyatana.ObjectEntry, TrayIcon> tray_icons;
    private IndicatorAyatana.Object object;

    public signal void entry_added (TrayIcon icon);
    public signal void entry_removed (TrayIcon icon);

    construct {
        tray_icons = new Gee.HashMap<unowned IndicatorAyatana.ObjectEntry, TrayIcon> ();
    }

    public Gee.Collection<TrayIcon> get_indicators () {
        load_indicator (File.new_for_path (Constants.AYATANAINDICATORDIR));

        return tray_icons.values.read_only_view;
    }

    private void load_indicator (File parent_dir) {
        var indicator_path = parent_dir.get_child ("libapplication.so").get_path ();
        if (!FileUtils.test (indicator_path, FileTest.EXISTS)) {
            debug ("No ayatana support possible because there is no Indicator Library: %s", "libapplication.so");
            return;
        }

        object = new IndicatorAyatana.Object.from_file (indicator_path);

        object.entry_added.connect (on_entry_added);
        object.entry_removed.connect (on_entry_removed);
    }

    private void on_entry_added (IndicatorAyatana.Object object, IndicatorAyatana.ObjectEntry entry) {

        // Dont show old network applet
        if (entry.name_hint == "nm-applet") {
            return;
        }

        var entry_widget = new TrayIcon (entry);
        tray_icons[entry] = entry_widget;
        entry_added (entry_widget);
    }

    private void on_entry_removed (IndicatorAyatana.Object object, IndicatorAyatana.ObjectEntry entry) {
        var entry_widget = tray_icons[entry];
        if (entry_widget != null) {
            tray_icons.unset (entry);
            entry_removed (entry_widget);
        }
    }
}
