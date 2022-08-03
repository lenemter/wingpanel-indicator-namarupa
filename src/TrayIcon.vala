//  /*-
//   * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
//   *
//   * This program is free software: you can redistribute it and/or modify
//   * it under the terms of the GNU Library General Public License as published by
//   * the Free Software Foundation, either version 2.1 of the License, or
//   * (at your option) any later version.
//   *
//   * This program is distributed in the hope that it will be useful,
//   * but WITHOUT ANY WARRANTY; without even the implied warranty of
//   * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   * GNU Library General Public License for more details.
//   *
//   * You should have received a copy of the GNU Library General Public License
//   * along with this program.  If not, see <http://www.gnu.org/licenses/>.
//   */

public class AyatanaCompatibility.TrayIcon : IndicatorButton {
    public string code_name { get; construct; }
    public string display_name { get; construct; }
    public string description { get; construct; }

    private Gtk.Stack main_stack;
    private Gtk.Box main_box;

    private unowned IndicatorAyatana.ObjectEntry entry;
    public string name_hint { get { return entry.name_hint; } }

    private Gee.HashMap<Gtk.Widget, Gtk.Widget> menu_map;

    const int MAX_ICON_SIZE = 22;

    //group radiobuttons
    private Gtk.RadioButton? radio_group = null;

    public TrayIcon (IndicatorAyatana.ObjectEntry entry) {
        var name_hint = entry.name_hint;  // Without this line:
                                          // ayatana_compatibility_tray_icon_get_name_hint: assertion 'self != NULL' failed

        Object (code_name: "%s%s".printf ("ayatana-", name_hint),
                display_name: "%s%s".printf ("ayatana-", name_hint),
                description: _("Ayatana compatibility indicator"));

        this.entry = entry;
        menu_map = new Gee.HashMap<Gtk.Widget, Gtk.Widget> ();

        if (entry.menu == null) {
            critical ("TrayIcon: %s has no menu widget.", name_hint);
            return;
        }

        setup_tray_icon ();

        /*
         * Workaround for buggy indicators: this menu may still be part of
         * another panel entry which hasn't been destroyed yet. Those indicators
         * trigger entry-removed after entry-added, which means that the previous
         * parent is still in the panel when the new one is added.
         */
        if (entry.menu.get_attach_widget () != null) {
            entry.menu.detach ();
        }
    }

    private void setup_tray_icon () {
        var image = entry.image;
        if (image != null) {
            // images holding pixbufs are quite frequently way too large, so we whenever a pixbuf
            // is assigned to an image we need to check whether this pixbuf is within reasonable size
            if (image.storage_type == Gtk.ImageType.PIXBUF) {
                image.notify["pixbuf"].connect (() => {
                    ensure_max_size (image);
                });

                ensure_max_size (image);
            }

            image.pixel_size = MAX_ICON_SIZE;

            set_widget (IndicatorButton.WidgetSlot.IMAGE, image);
        }

        var label = entry.label;
        if (label != null) {
            set_widget (IndicatorButton.WidgetSlot.LABEL, label);
        }

        visible = true;

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);  // Listen to clicks
        button_press_event.connect (on_button_press);
    }

    public bool on_button_press (Gdk.EventButton event) {
        generate_new_popover ().show_all ();

        return Gdk.EVENT_PROPAGATE;
    }

    private Gtk.Popover generate_new_popover () {
        // Generating new popover every time fixes some issues with submenus

        menu_map.clear ();

        main_stack = new Gtk.Stack ();
        main_stack.map.connect (() => {
            main_stack.set_visible_child (main_box);
        });
        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 3,
            margin_bottom = 3
        };
        main_stack.add (main_box);

        foreach (var item in entry.menu.get_children ()) {
            on_menu_widget_insert (item);
        }

        entry.menu.insert.connect (on_menu_widget_insert);
        entry.menu.remove.connect (on_menu_widget_remove);

        var popover = new Gtk.Popover (this);
        popover.add (main_stack);

        return popover;
    }

    private void on_menu_widget_insert (Gtk.Widget item) {
        var widget = convert_menu_widget (item);  // Separator or Box
        if (widget != null) {
            menu_map[item] = widget;
            main_box.add (widget);

            /* menuitem not visible */
            if (!item.visible) {
                widget.no_show_all = true;
                widget.hide ();
            } else {
                widget.show ();
            }
        }
    }

    private void on_menu_widget_remove (Gtk.Widget item) {
        var widget = menu_map.get (item);
        if (widget != null) {
            main_box.remove (widget);
            menu_map.unset (item);
        }
    }

    private Gtk.Image? check_for_image (Gtk.Container container) {
        foreach (var c in container.get_children ()) {
            if (c is Gtk.Image) {
                return (c as Gtk.Image);
            } else if (c is Gtk.Container) {
                return check_for_image (c as Gtk.Container);
            }
        }

        return null;
    }

    private void connect_signals (Gtk.Widget item, Gtk.Widget button) {
        item.show.connect (() => {
            button.no_show_all = false;
            button.show ();
        });
        item.hide.connect (() => {
            button.no_show_all = true;
            button.hide ();
        });
        item.state_flags_changed.connect ((type) => {
            button.set_state_flags (item.get_state_flags (), true);
        });
    }

    /* convert the menuitems to widgets that can be shown in popovers */
    private Gtk.Widget? convert_menu_widget (Gtk.Widget item) {
        /* separator are GTK.SeparatorMenuItem, return a separator */
        if (item is Gtk.SeparatorMenuItem) {
            var separator = new AyatanaCompatibility.Widgets.Separator ();
            connect_signals (item, separator);

            return separator;
        }

        /* all other items are genericmenuitems */
        var label = ((Gtk.MenuItem)item).label;
        label = label.replace ("_", "");  // Remove accels

        /*
         * get item type from atk accessibility
         * 34 = MENU_ITEM  8 = CHECKBOX  32 = SUBMENU 44 = RADIO
         */
        const int ATK_CHECKBOX = 8;
        const int ATK_RADIO = 44;

        var atk = item.get_accessible ();
        Value val = Value (typeof (int));
        atk.get_property ("accessible_role", ref val);
        var item_type = val.get_int ();

        var state = item.get_state_flags ();

        // Clear radio_group
        if (item_type != ATK_RADIO) {
            radio_group = null;
        }

        // detect if it has a image
        Gtk.Image? image = null;
        var child = ((Gtk.Bin)item).get_child ();
        if (child != null) {
            if (child is Gtk.Image) {
                image = child as Gtk.Image;
            } else if (child is Gtk.Container) {
                image = check_for_image (child as Gtk.Container);
            }
        }
        if (image != null && image.pixbuf == null && image.icon_name != null) {
            try {
                image.pixbuf = Gtk.IconTheme.get_default ().load_icon (image.icon_name, 16, 0);
            } catch (Error e) {
                warning (e.message);
            }
        }
        Gtk.Image? icon = null;
        if (image != null && image.pixbuf != null) {
            // I have no idea why it needs a new image
            icon = new Gtk.Image.from_pixbuf (image.pixbuf);
        }

        // Item with checkbox
        if (item_type == ATK_CHECKBOX) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 12,
                margin_end = 12,
            };

            var active = ((Gtk.CheckMenuItem)item).get_active ();
            var button = new Gtk.CheckButton.with_label (label) {
                active = active
            };

            box.pack_start (button, false, false, 0);
            if (icon != null) {
                box.pack_end (icon, false, false, 0);
            }

            button.toggled.connect ((b) => {
                var is_active = b.active;
                ((Gtk.CheckMenuItem)item).set_active (is_active);
            });

            connect_signals (item, button);
            ((Gtk.CheckMenuItem)item).toggled.connect (() => {
                button.active = ((Gtk.CheckMenuItem)item).get_active ();
            });

            return box;
        }

        // Item with radio button
        if (item_type == ATK_RADIO) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 12,
                margin_end = 12,
            };

            var active = ((Gtk.CheckMenuItem)item).get_active ();
            var button = new Gtk.RadioButton.with_label_from_widget (radio_group, label) {
                active = active
            };

            box.pack_start (button, false, false, 0);
            if (icon != null) {
                box.pack_end (icon, false, false, 0);
            }

            radio_group = button;

            // do not remove
            button.clicked.connect (() => {
                item.activate ();
            });

            button.activate.connect (() => {
                item.activate ();
                ((Gtk.RadioMenuItem)item).set_active (button.get_active ());
            });

            return box;
        }

        // Convert menuitem to a indicatorbutton
        if (item is Gtk.MenuItem) {
            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var lbl = new Gtk.Label (label);
            button_box.pack_start (lbl, false, false, 0);
            if (icon != null) {
                button_box.pack_end (icon, false, false, 0);
            }

            var button = new Gtk.ModelButton ();
            button.get_child ().destroy ();
            button.child = button_box;

            item.notify["label"].connect (() => {
                lbl.label = ((Gtk.MenuItem)item).get_label ().replace ("_", "");  // Remove accels
            });

            button.set_state_flags (state, true);

            var submenu = ((Gtk.MenuItem)item).submenu;
            if (submenu != null) {
                var scroll_window = new Gtk.ScrolledWindow (null, null);
                scroll_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
                main_stack.add (scroll_window);

                var sub_list = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                    margin_top = 3,
                    margin_bottom = 3
                };
                scroll_window.add (sub_list);

                var back_button = new Gtk.ModelButton () {
                    text = _("Back"),
                    inverted = true,
                    menu_name = "main_box"
                };
                sub_list.add (back_button);
                sub_list.add (new AyatanaCompatibility.Widgets.Separator ());

                //adding submenu items
                foreach (var sub_item in submenu.get_children ()) {
                    var sub_menu_item = convert_menu_widget (sub_item);
                    connect_signals (sub_item, sub_menu_item);
                    sub_list.add (sub_menu_item);
                }

                submenu.insert.connect ((sub_item) => {
                    var sub_menu_item = convert_menu_widget (sub_item);
                    if (sub_menu_item != null) {
                        connect_signals (sub_item, sub_menu_item);
                        sub_list.add (sub_menu_item);
                    }
                });

                submenu.remove.connect ((sub_item) => {
                    var sub_menu_item = menu_map.get (sub_item);
                    if (sub_menu_item != null) {
                        sub_list.remove (sub_menu_item);
                    }
                });

                //Button opening the submenu
                button.menu_name = "submenu";

                // Switch to default
                back_button.clicked.connect (() => {
                    scroll_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
                    main_stack.set_visible_child (main_box);
                });
                // Switch to submenu
                button.clicked.connect (() => {
                    scroll_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);
                    main_stack.set_visible_child (scroll_window);
                });
            } else {
                button.clicked.connect (() => {
                    item.activate ();
                });
            }

            connect_signals (item, button);
            return button;
        }

        return null;
    }

    private void ensure_max_size (Gtk.Image image) {
        var pixbuf = image.pixbuf;

        if (pixbuf != null && pixbuf.get_height () > MAX_ICON_SIZE) {
            var dest_width = (int)((double)MAX_ICON_SIZE / pixbuf.get_height () * pixbuf.get_width ());
            image.pixbuf = pixbuf.scale_simple (dest_width, MAX_ICON_SIZE, Gdk.InterpType.HYPER);
        }
    }
}
