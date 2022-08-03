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

public class AyatanaCompatibility.MainIndicator : Wingpanel.Indicator {
    private IndicatorFactory indicator_loader;
    private Gtk.Stack main_stack;
    private Gtk.Grid icons_grid;

    public MainIndicator () {
        Object (code_name: "namarupa");

        indicator_loader = new IndicatorFactory ();

        var indicators = indicator_loader.get_indicators ();

        visible = true;
        init_ui ();

        foreach (var indicator in indicators) {
            icons_grid.add (indicator);
        }

        indicator_loader.entry_added.connect (create_entry);
        indicator_loader.entry_removed.connect (delete_entry);
    }

    private void init_ui () {
        /*creates an empty box with no entry */

        var no_icons_label = new Gtk.Label ("No tray icons") {
            sensitive = false,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_top = 2,
            margin_bottom = 2,
            margin_start = 6,
            margin_end = 6
        };
        no_icons_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        no_icons_label.show_all ();

        icons_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            margin_start = 6,
            margin_end = 6,
        };
        icons_grid.show_all ();

        main_stack = new Gtk.Stack () {
            hexpand = true
        };
        main_stack.add_named (icons_grid, "icons_grid");
        main_stack.add_named (no_icons_label, "no_icons_label");
        main_stack.get_style_context ().add_class (Gtk.STYLE_CLASS_SIDEBAR);

        switch_stack (false); /* show label */
    }

    private void create_entry (TrayIcon icon) {
        icons_grid.add (icon);
        icons_grid.show_all ();

        switch_stack (true);
    }

    private void delete_entry (TrayIcon icon) {
        foreach (var child in icons_grid.get_children ()) {
            if (child is TrayIcon && ((TrayIcon)child).code_name == icon.code_name) {
                child.destroy ();
                break;
            }
        }

        switch_stack (icons_grid.get_children ().length () != 0);
    }

    private void switch_stack (bool show) {
        //switch between label "No tray icons" and icons grid
        if (show) {
            main_stack.set_visible_child_name ("icons_grid");
        } else {
            main_stack.set_visible_child_name ("no_icons_label");
        }
    }

    public override Gtk.Widget get_display_widget () {
        return new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
    }

    public override Gtk.Widget? get_widget () {
        return main_stack;
    }

    public override void opened () {

    }

    public override void closed () {

    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION)
        return null;

    debug ("Activating AyatanaCompatibility Meta Indicator");
    var indicator = new AyatanaCompatibility.MainIndicator ();
    return indicator;
}
