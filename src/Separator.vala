/*-
 * Copyright 2022-2023 lenemter <lenemter@gmail.com>
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

class AyatanaCompatibility.Widgets.Separator : Gtk.Separator {
    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        margin_top = 3;
        margin_bottom = 3;
    }
}
