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
    private Gtk.Grid main_grid;
    private Gtk.Popover popover;

    private unowned IndicatorAyatana.ObjectEntry entry;
    public string name_hint { get { return entry.name_hint; } }

    private Gee.HashMap<Gtk.Widget, Gtk.Widget> menu_map;

    const int MAX_ICON_SIZE = 22;

    int position = 0;

    //group radiobuttons
    private Gtk.RadioButton? group_radio = null;

    public TrayIcon (IndicatorAyatana.ObjectEntry entry) {
        var name_hint = entry.name_hint;

        Object (code_name: "%s%s".printf ("ayatana-", name_hint),
                display_name: "%s%s".printf ("ayatana-", name_hint),
                description: _("Ayatana compatibility indicator"));

        this.entry = entry;
        menu_map = new Gee.HashMap<Gtk.Widget, Gtk.Widget> ();

        if (entry.menu == null) {
            critical ("TrayIcon: %s has no menu widget.", entry.name_hint);
            return;
        }

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);

        var image = entry.image;
        if (image != null) {
            /*
             * images holding pixbufs are quite frequently way too large, so we whenever a pixbuf
             * is assigned to an image we need to check whether this pixbuf is within reasonable size
             */
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

        button_press_event.connect (on_button_press);

        /*
         * Workaround for buggy indicators: this menu may still be part of
         * another panel entry which hasn't been destroyed yet. Those indicators
         * trigger entry-removed after entry-added, which means that the previous
         * parent is still in the panel when the new one is added.
         */
        if (entry.menu.get_attach_widget () != null) {
            entry.menu.detach ();
        }

        visible = true;

        // Create popover
        main_stack = new Gtk.Stack ();
        main_stack.map.connect (() => {
            main_stack.set_visible_child (main_grid);
        });
        main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin_top = 3,
            margin_bottom = 3
        };
        main_stack.add (main_grid);

        foreach (var item in entry.menu.get_children ()) {
            on_menu_widget_insert (item);
        }

        entry.menu.insert.connect (on_menu_widget_insert);
        entry.menu.remove.connect (on_menu_widget_remove);

        popover = new Gtk.Popover (this);
        popover.add (main_stack);
    }

    public bool on_button_press (Gdk.EventButton event) {
        popover.show_all ();

        return Gdk.EVENT_PROPAGATE;
    }


    private void on_menu_widget_insert (Gtk.Widget item) {
        var widget = convert_menu_widget (item);
        if (widget != null) {
            menu_map.set (item, widget);
            main_grid.attach (widget, 0, position++);

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
            main_grid.remove (widget);
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
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                margin_top = 3,
                margin_bottom = 3
            };
            connect_signals (item, separator);

            return separator;
        }

        /* all other items are genericmenuitems */
        var label = ((Gtk.MenuItem)item).label;
        label = label.replace ("_", "");

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

        //RAZ group_radio
        if (item_type != ATK_RADIO) {
            group_radio = null;
        }

        /* detect if it has a image */
        Gtk.Image? image = null;
        var child = ((Gtk.Bin)item).get_child ();
        if (child != null) {
            if (child is Gtk.Image) {
                image = child as Gtk.Image;
            } else if (child is Gtk.Container) {
                image = check_for_image (child as Gtk.Container);
            }
        }

        if (item_type == ATK_CHECKBOX) {
            var box_switch = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            var lbl = new Gtk.Label (label) {
                halign = Gtk.Align.START,
                margin_start = 6,
                margin_end = 6
            };
            var active = ((Gtk.CheckMenuItem)item).get_active ();
            var button = new Gtk.Switch () {
                state = active
            };

            box_switch.pack_start (lbl, true, true, 5);
            box_switch.pack_end (button, false, false, 5);

            button.state_set.connect ((b) => {
                ((Gtk.CheckMenuItem)item).set_active (b);
                return false;
            });

            connect_signals (item, button);
            ((Gtk.CheckMenuItem)item).toggled.connect (() => {
                button.active = ((Gtk.CheckMenuItem)item).get_active ();
            });

            return box_switch;
        }

        //RADIO BUTTON
        if (item_type == ATK_RADIO) {
            var active = ((Gtk.CheckMenuItem)item).get_active ();
            var button = new Gtk.RadioButton.with_label_from_widget (group_radio,label) {
                margin = 5,
                margin_start = 10,
                active = active
            };

            if (group_radio == null) {
                group_radio = button;
            }

            // do not remove
            button.clicked.connect (() => {
                item.activate ();
            });

            button.activate.connect (() => {
                item.activate ();
                ((Gtk.RadioMenuItem)item).set_active (button.get_active ());
            });

            return button;
        }

        /* convert menuitem to a indicatorbutton */
        if (item is Gtk.MenuItem) {
            Gtk.ModelButton button;

            if (image != null && image.pixbuf == null && image.icon_name != null) {
                try {
                    Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                    image.pixbuf = icon_theme.load_icon (image.icon_name, 16, 0);
                } catch (Error e) {
                    warning (e.message);
                }
            }
            button = new Gtk.ModelButton () {
                text = label
            };
            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
                margin_end = 12
            };
            if (image != null && image.pixbuf != null) {
                var img = new Gtk.Image.from_pixbuf (image.pixbuf);
                hbox.add (button);
                hbox.add (img);
                //Modelbutton = text OR icon not both
                //button.icon = (image.pixbuf);
            }

            ((Gtk.CheckMenuItem)item).notify["label"].connect (() => {
                button.text = ((Gtk.MenuItem)item).get_label ().replace ("_", "");
            });

            button.set_state_flags (state, true);

            var submenu = ((Gtk.MenuItem)item).submenu;
            var sub_list = new Gtk.ListBox ();

            if (submenu != null) {
                var scroll_sub = new Gtk.ScrolledWindow (null, null);
                scroll_sub.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
                scroll_sub.add (sub_list);

                var back_button = new Gtk.ModelButton () {
                    text = _("Back"),
                    inverted = true,
                    menu_name = "main_grid"
                };
                back_button.clicked.connect (() => {
                    main_stack.set_visible_child (main_grid);
                });
                sub_list.add (back_button);
                sub_list.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

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

                submenu.remove.connect ((item) => {
                    var w = menu_map.get (item);
                    if (w != null) {
                        sub_list.remove (w);
                    }
                });

                main_stack.add (scroll_sub);
                //Button opening the submenu
                button = new Gtk.ModelButton () {
                    text = label,
                    menu_name = "submenu"
                };
                button.clicked.connect (() => {
                    main_stack.set_visible_child (scroll_sub);
                    main_stack.show_all ();
                });
            } else {
                button.clicked.connect (() => {
                    item.activate ();
                });
            }

            connect_signals (item, button);
            if ((image != null && image.pixbuf != null)) {
                return hbox;
            } else {
                return button;
            }
        }

        return null;
    }

    private void ensure_max_size (Gtk.Image image) {
        var pixbuf = image.pixbuf;

        if (pixbuf != null && pixbuf.get_height () > MAX_ICON_SIZE) {
            image.pixbuf = pixbuf.scale_simple ((int)((double)MAX_ICON_SIZE / pixbuf.get_height () * pixbuf.get_width ()),
                                                MAX_ICON_SIZE, Gdk.InterpType.HYPER);
        }
    }
}
