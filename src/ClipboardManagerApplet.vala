using Gtk;
/*
 * Clipboard Manager
 *
 * Copyright © 2020 Prateek SU
 * Copyright © 2026 Ubuntu Budgie Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

namespace ClipboardManagerApplet {

  public class ClipboardManagerSettings : Gtk.Grid {
	public ClipboardManagerSettings(GLib.Settings? settings) {
		set_row_spacing(10);

		var historyLabel = new Gtk.Label(_("History Size"));
		historyLabel.set_halign(Gtk.Align.START);
		historyLabel.set_hexpand(true);
		var historySpin = new Gtk.SpinButton.with_range(2, 100, 1);
		historySpin.set_value(settings.get_int("historylength"));
		historySpin.set_halign(Gtk.Align.END);
		historySpin.set_hexpand(true);

		var selClipLabel = new Gtk.Label(_("Get Selection to Clipboard"));
		selClipLabel.set_halign(Gtk.Align.START);
		selClipLabel.set_hexpand(true);
		var selClipTggle = new Gtk.Switch();
		selClipTggle.set_active(settings.get_boolean("selectclip"));
		selClipTggle.set_halign(Gtk.Align.END);
		selClipTggle.set_hexpand(true);

		var copySelLabel = new Gtk.Label(_("Copy Selection to Clipboard"));
		copySelLabel.set_halign(Gtk.Align.START);
		copySelLabel.set_hexpand(true);
		var copySelTggle = new Gtk.Switch();
		copySelTggle.set_active(settings.get_boolean("copyselected"));
		copySelTggle.set_sensitive(settings.get_boolean("selectclip"));
		copySelTggle.set_halign(Gtk.Align.END);
		copySelTggle.set_hexpand(true);

		var caseSenLabel = new Gtk.Label(_("Case Sensitive Search"));
		caseSenLabel.set_halign(Gtk.Align.START);
		caseSenLabel.set_hexpand(true);
		var caseSenTggle = new Gtk.Switch();
		caseSenTggle.set_active(settings.get_boolean("searchsensitive"));
		caseSenTggle.set_halign(Gtk.Align.END);
		caseSenTggle.set_hexpand(true);

		var saveHistLabel = new Gtk.Label(_("Save History to File"));
		saveHistLabel.set_halign(Gtk.Align.START);
		saveHistLabel.set_hexpand(true);
		var saveHistTggle = new Gtk.Switch();
		saveHistTggle.set_active(settings.get_boolean("savehistory"));
		saveHistTggle.set_halign(Gtk.Align.END);
		saveHistTggle.set_hexpand(true);

		var pastClipsLabel = new Gtk.Label(
			_("Paste after Clicking (Requires ydotool/wtype)"));
		pastClipsLabel.set_halign(Gtk.Align.START);
		pastClipsLabel.set_hexpand(true);
		var pastClipsTggle = new Gtk.Switch();
		pastClipsTggle.set_active(settings.get_boolean("pastefromclipboard"));
		pastClipsTggle.set_halign(Gtk.Align.END);
		pastClipsTggle.set_hexpand(true);

		var heightLabel = new Gtk.Label(_("Clipboard Height"));
		heightLabel.set_halign(Gtk.Align.START);
		heightLabel.set_hexpand(true);
		var heightSpin = new Gtk.SpinButton.with_range(50, 2000, 1);
		heightSpin.set_value(settings.get_int("clipheight"));
		heightSpin.set_halign(Gtk.Align.END);
		heightSpin.set_hexpand(true);

		var resetBtn = new Gtk.Button.with_label(_("Restore Defaults"));
		resetBtn.set_halign(Gtk.Align.CENTER);
		resetBtn.set_hexpand(true);

		attach(historyLabel,  0, 0, 1, 1);
		attach(historySpin,   1, 0, 1, 1);
		attach(selClipLabel,  0, 1, 1, 1);
		attach(selClipTggle,  1, 1, 1, 1);
		attach(copySelLabel,  0, 2, 1, 1);
		attach(copySelTggle,  1, 2, 1, 1);
		attach(caseSenLabel,  0, 3, 1, 1);
		attach(caseSenTggle,  1, 3, 1, 1);
		attach(saveHistLabel, 0, 4, 1, 1);
		attach(saveHistTggle, 1, 4, 1, 1);
		attach(pastClipsLabel,0, 5, 1, 1);
		attach(pastClipsTggle,1, 5, 1, 1);
		attach(heightLabel,   0, 6, 1, 1);
		attach(heightSpin,    1, 6, 1, 1);
		attach(resetBtn,      0, 7, 1, 1);

		historySpin.value_changed.connect((curr) => {
			int val = curr.get_value_as_int();
			if (ClipboardManagerPopover.HISTORY_LENGTH != val) {
				settings.set_int("historylength", val);
				ClipboardManagerPopover.HISTORY_LENGTH = val;
				ClipboardManagerPopover.show_all_except();
			}
		});

		selClipTggle.state_set.connect((curr_act) => {
			settings.set_boolean("selectclip", curr_act);
			copySelTggle.set_sensitive(curr_act);
			ClipboardManager.attach_monitor_clipboard();
			return false;
		});

		copySelTggle.state_set.connect((curr_act) => {
			settings.set_boolean("copyselected", curr_act);
			ClipboardManagerPopover.copyselected = curr_act;
			return false;
		});

		caseSenTggle.state_set.connect((curr_act) => {
			settings.set_boolean("searchsensitive", curr_act);
			ClipboardManagerPopover.searchsensitive = curr_act;
			return false;
		});

		saveHistTggle.state_set.connect((curr_act) => {
			settings.set_boolean("savehistory", curr_act);
			ClipboardManagerPopover.savehistory = curr_act;
			return false;
		});

		pastClipsTggle.state_set.connect((curr_act) => {
			settings.set_boolean("pastefromclipboard", curr_act);
			ClipboardManagerPopover.pasteFromClipboard = curr_act;
			return false;
		});

		heightSpin.value_changed.connect((curr) => {
			int val = curr.get_value_as_int();
			settings.set_int("clipheight", val);
			ClipboardManagerPopover.realContent.set_min_content_height(val);
			ClipboardManagerPopover.show_all_except();
		});

		resetBtn.clicked.connect(() => {
			string[] keys = {
				"historylength", "selectclip", "copyselected",
				"searchsensitive", "savehistory", "pastefromclipboard",
				"clipheight", "privatemode"
			};
			foreach (string key in keys) {
				settings.reset(key);
			}
			historySpin.set_value(settings.get_int("historylength"));
			selClipTggle.set_active(settings.get_boolean("selectclip"));
			copySelTggle.set_active(settings.get_boolean("copyselected"));
			copySelTggle.set_sensitive(false);
			caseSenTggle.set_active(settings.get_boolean("searchsensitive"));
			saveHistTggle.set_active(settings.get_boolean("savehistory"));
			pastClipsTggle.set_active(settings.get_boolean("pastefromclipboard"));
			heightSpin.set_value(settings.get_int("clipheight"));
			ClipboardManagerPopover.privateModeTggle.set_active(
				settings.get_boolean("privatemode"));
		});
	}
  }

  public class Plugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new Applet();
	}
  }

  public class ClipboardManagerPopover : Budgie.Popover {
	public static EventBox      indicatorBox;
	public static Image         indicatorIcon;
	public static GLib.Settings settings          = Applet.settings;
	public static Box           mainContent       = new Box(Gtk.Orientation.VERTICAL, 0);
	public static Box           search_container  = new Box(Gtk.Orientation.HORIZONTAL, 0);
	public static Entry         search_box        = new Entry();
	public static Paned         contentPaned      = new Paned(Gtk.Orientation.HORIZONTAL);
	public static Box           scrbox            = new Box(Gtk.Orientation.VERTICAL, 10);
	public static ScrolledWindow realContent      = new ScrolledWindow(null, null);
	public static Stack         previewStack      = new Stack();
	public static ScrolledWindow previewScroll    = new ScrolledWindow(null, null);
	public static Label         previewLabel      = new Label("");
	public static Box           privateMode       = new Box(Gtk.Orientation.HORIZONTAL, 0);
	public static Box           notifyMe          = new Box(Gtk.Orientation.HORIZONTAL, 0);
	public static Box           setContent        = new Box(Gtk.Orientation.VERTICAL, 8);
	public static Box           hBox              = new Box(Gtk.Orientation.HORIZONTAL, 0);
	public static Box           settingsBox       = new Box(Gtk.Orientation.VERTICAL, 8);
	public static Label         pagerCont         = new Label("");
	public static ToggleButton  setDropdown       = new ToggleButton();
	public static Switch        privateModeTggle  = new Switch();
	public static ListBox       listbax           = new ListBox();

	public static string   text;
	public static string[] history          = {};
	public static bool     primode          = settings.get_boolean("privatemode");
	public static bool     sendNotifications = settings.get_boolean("notifications");
	public static bool     copyselected     = settings.get_boolean("copyselected");
	public static bool     searchsensitive  = settings.get_boolean("searchsensitive");
	public static bool     savehistory      = settings.get_boolean("savehistory");
	public static bool     pasteFromClipboard = settings.get_boolean("pastefromclipboard");
	public static bool     row_activated_flag = false;
	public static int      clipheight       = settings.get_int("clipheight");
	public static int      HISTORY_LENGTH   = settings.get_int("historylength");
	public static int      ttyped           = 0;
	public static int      specialMark      = 0;
	public static int      currentPreviewIndex = -1;

	public ClipboardManagerPopover(Gtk.EventBox indicatorBox) {
		Object(relative_to: indicatorBox);

		indicatorIcon = new Image.from_icon_name(
			primode ? "clipboard-outline-broken-symbolic"
					: "clipboard-outline-symbolic",
			Gtk.IconSize.MENU);
		indicatorBox.add(indicatorIcon);

		if (savehistory) {
			history = ClipboardManager.get_clipstext(settings, "custompath");
			remove_index_from_history(-1);
		}

		add(mainContent);

		// Setup preview pane
		setup_preview_pane();

		// Setup main content with paned view
		realContent.set_overlay_scrolling(true);
		realContent.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		realContent.set_min_content_height(clipheight);

		contentPaned.pack1(realContent, true, false);
		contentPaned.pack2(previewStack, false, false);
		contentPaned.set_position(300); // Initial split position

		scrbox.add(contentPaned);
		mainContent.add(search_container);
		mainContent.add(scrbox);
		mainContent.add(setContent);

		hBox.pack_start(pagerCont, true, true, 0);
		hBox.pack_end(setDropdown, false, false, 0);
		setDropdown.set_image(
			new Image.from_icon_name("pan-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
		setDropdown.toggled.connect(show_all_except);
		setContent.pack_start(hBox, false, false, 6);
		setContent.pack_end(settingsBox, false, false, 0);

		update_pager();

		var emptyCliptext = _("Clear All");
		var emptyClip = new Button();
		emptyClip.clicked.connect(remove_all_rows);
		var emptyClipLabel = new Label(@"<b>$emptyCliptext</b>");
		emptyClipLabel.set_xalign(0);
		emptyClipLabel.use_markup = true;
		emptyClip.add(emptyClipLabel);
		settingsBox.add(emptyClip);

		var privateModeLabel = new Label(_("Private Mode"));
		privateModeLabel.set_halign(Gtk.Align.START);
		privateModeLabel.set_hexpand(true);
		privateModeTggle.set_active(primode);
		privateModeTggle.set_halign(Gtk.Align.END);
		privateModeTggle.set_hexpand(true);
		privateModeTggle.state_set.connect(() => {
			bool curr_act = privateModeTggle.get_active();
			settings.set_boolean("privatemode", curr_act);
			primode = curr_act;
			ClipboardManager.attach_monitor_clipboard();
			if (curr_act) {
				indicatorIcon.set_from_icon_name(
					"clipboard-outline-broken-symbolic", Gtk.IconSize.MENU);
			} else {
				indicatorIcon.set_from_icon_name(
					history.length != 0
						? "clipboard-text-outline-symbolic"
						: "clipboard-outline-symbolic",
					Gtk.IconSize.MENU);
			}
			return false;
		});
		privateMode.set_tooltip_text(
			_("Enabling this will stop Clipboard Manager to save any Clips"));
		privateMode.add(addHSpacer());
		privateMode.add(privateModeLabel);
		privateMode.add(privateModeTggle);
		privateMode.add(addHSpacer());
		settingsBox.add(privateMode);

		var notifyMeLabel = new Label(_("Notifications"));
		notifyMeLabel.set_halign(Gtk.Align.START);
		notifyMeLabel.set_hexpand(true);
		var notifyMeTggle = new Switch();
		notifyMeTggle.set_active(sendNotifications);
		notifyMeTggle.set_halign(Gtk.Align.END);
		notifyMeTggle.set_hexpand(true);
		notifyMeTggle.state_set.connect(() => {
			bool curr_act = notifyMeTggle.get_active();
			settings.set_boolean("notifications", curr_act);
			sendNotifications = curr_act;
			return false;
		});
		notifyMe.set_tooltip_text(
			_("Enabling this will Notify you about every clips you copy"));
		notifyMe.add(addHSpacer());
		notifyMe.add(notifyMeLabel);
		notifyMe.add(notifyMeTggle);
		notifyMe.add(addHSpacer());
		settingsBox.add(notifyMe);

		search_box.set_placeholder_text(_("Search Clipboard History") + "…");
		search_box.set_hexpand(true);
		search_box.changed.connect(() => {
			text = search_box.get_text();
			if (text.chug().length != 0 && history.length != 0) {
				on_search_activate(search_box);
			} else {
				remove_and_create_listbax();
				add_marked_text_in_loop();
				realContent.add(listbax);
				update_pager();
				show_all_except();
			}
		});
		search_container.add(search_box);
	}

	private static void setup_preview_pane() {
		// Create empty state
		var emptyBox = new Box(Gtk.Orientation.VERTICAL, 10);
		emptyBox.set_valign(Gtk.Align.CENTER);
		emptyBox.set_halign(Gtk.Align.CENTER);
		var emptyIcon = new Image.from_icon_name("edit-select-all-symbolic", Gtk.IconSize.DIALOG);
		emptyIcon.set_opacity(0.3);
		var emptyText = new Label(_("Select a clip to preview"));
		emptyText.get_style_context().add_class("dim-label");
		emptyBox.add(emptyIcon);
		emptyBox.add(emptyText);

		// Setup preview label
		previewLabel.set_line_wrap(false);
		previewLabel.set_selectable(true);
		previewLabel.set_xalign(0);
		previewLabel.set_yalign(0);
		previewLabel.set_margin_start(10);
		previewLabel.set_margin_end(10);
		previewLabel.set_margin_top(10);
		previewLabel.set_margin_bottom(10);

		// Setup scrolled window for preview
		previewScroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		previewScroll.set_min_content_width(200);
		previewScroll.add(previewLabel);

		// Add both to stack
		previewStack.add_named(emptyBox, "empty");
		previewStack.add_named(previewScroll, "preview");
		previewStack.set_visible_child_name("empty");
	}

	public static void show_preview(int index) {
		if (index >= 0 && index < history.length) {
			currentPreviewIndex = index;
			string content = history[index];

			// Format the preview text with some basic info
			string preview_text = content;
			int char_count = content.char_count();
			int line_count = content.split("\n").length;

			// Add metadata header
			string metadata = @"<small><b>Characters:</b> $char_count  |  <b>Lines:</b> $line_count</small>\n\n";
			previewLabel.set_markup(metadata + Markup.escape_text(preview_text));

			previewStack.set_visible_child_name("preview");
		} else {
			currentPreviewIndex = -1;
			previewStack.set_visible_child_name("empty");
		}
	}

	public static void clear_preview() {
		currentPreviewIndex = -1;
		previewStack.set_visible_child_name("empty");
	}

	public static Gtk.Label addHSpacer() {
		return new Gtk.Label("     ");
	}

	public static void addRow(int ttype) {
		// For ttype==2 (called from watcher), text is already set correctly
		// by the Idle.add closure in read_next_clip — do not re-fetch.
		if (!row_activated_flag && ttype != 2) {
			text = ClipboardManager.get_text();
		}
		remove_and_create_listbax();
		if (ttype == 0) {
			text = ClipboardManager.get_text();
		} else if (ttype == 1) {
			text = ClipboardManager.get_text(true);
		} else if (ttype == 2) {
			ttyped = (history.length == 0 && (text == null || text.chug().length == 0))
				? 0 : 1;
		} else {
			text = "";
		}

		if (ttype != 2 || ttyped == 1) {
			if (copyselected && ttype == 1) {
				ClipboardManager.set_text(text);
			}
			add_marked_text_in_loop(0, text);
		} else {
			clip_curr_empty();
		}
		realContent.add(listbax);
		update_pager();
		show_all_except();
	}

	public static void remove_all_rows() {
		if (history.length > 0) {
			remove_and_create_listbax();
			remove_range_from_history(0);
			indicatorIcon.set_from_icon_name(
				"clipboard-outline-symbolic", Gtk.IconSize.MENU);
			Applet.popover.hide();
			ClipboardManager.set_text("");
			clip_curr_empty();
			realContent.add(listbax);
			clear_preview();
			update_pager();
			show_all_except();
		}
	}

	public static void add_marked_text_in_loop(int copy = 0,
											   string? text = null) {
		if (text != null) {
			delete_duplicates_from_history(text);
		}
		if (history.length > 0) {
			specialMark = copy;
			row_activated_flag = false;
			for (int j = 0; j < history.length; j++) {
				add_element_to_listbax(j);
			}
		} else {
			clip_curr_empty();
			clear_preview();
		}
		update_history();
	}

	public static void add_element_to_listbax(int j) {
		text = history[j];
		string subtext = text.replace("\t", " ").strip();
		if (subtext.length > 100) {
			subtext = text.strip().slice(0, 100) + "...";
		}
		text = text.replace("\n", " ").strip();
		if (text.length > 30) {
			text = text.slice(0, 30) + "...";
		}

		int copy = j;
		var btnlist = new Box(Gtk.Orientation.HORIZONTAL, 0);

		// Preview button
		var previewBtn = new Button();
		previewBtn.set_image(
			new Image.from_icon_name("document-preview-symbolic", Gtk.IconSize.BUTTON));
		previewBtn.clicked.connect(() => {
			show_preview(copy);
		});
		btnlist.add(previewBtn);

		var clipMgr = new Button();
		var clipMgrLabel = new Label(text);
		if (specialMark == j) {
			text = Markup.escape_text(text);
			clipMgrLabel.set_label(@"<i><b><u>$text</u></b></i>");
			clipMgrLabel.use_markup = true;
		}
		clipMgrLabel.set_xalign(0);
		clipMgr.add(clipMgrLabel);
		clipMgr.set_hexpand(true);
		clipMgr.clicked.connect(() => __on_row_activated(copy));
		btnlist.add(clipMgr);

		var dismissbtn = new Button();
		dismissbtn.set_image(
			new Image.from_icon_name("edit-delete-symbolic", Gtk.IconSize.BUTTON));
		dismissbtn.clicked.connect(() => {
			if (currentPreviewIndex == copy) {
				clear_preview();
			} else if (currentPreviewIndex > copy) {
				// Adjust preview index if an earlier item was deleted
				currentPreviewIndex--;
			}
			remove_index_from_history(copy);
			row_activated_flag = true;
			remove_and_create_listbax();
			add_marked_text_in_loop();
			realContent.add(listbax);
			update_pager();
			show_all_except();
		});
		btnlist.add(dismissbtn);
		listbax.add(btnlist);
	}

	public static void remove_and_create_listbax() {
		int z = 0;
		realContent.@foreach((widget) => { z++; });
		if (z != 0) {
			realContent.remove(listbax);
		}
		listbax = new ListBox();
	}

	public static void update_history(string? text = null) {
		string[] newHistory = {};
		if (text != null) {
			newHistory += text;
		}
		for (int i = 0; i < history.length; i++) {
			newHistory += history[i];
		}
		history = newHistory;
		if (history.length >= 1 && !primode) {
			indicatorIcon.set_from_icon_name(
				"clipboard-text-outline-symbolic", Gtk.IconSize.MENU);
		}
		if (history.length > HISTORY_LENGTH) {
			if (history.length == HISTORY_LENGTH + 1) {
				remove_index_from_history(HISTORY_LENGTH);
			} else {
				remove_range_from_history(HISTORY_LENGTH - 1);
			}
		}
		if (savehistory) {
			ClipboardManager.writefile(
				ClipboardManager.get_filepath(settings, "custompath"), history);
		}
	}

	public static void remove_index_from_history(int idx) {
		string[] newArray = {};
		for (int i = 0; i < history.length; i++) {
			if (i != idx && history[i].chug().length != 0) {
				newArray += history[i];
			}
		}
		history = newArray;
	}

	public static void remove_range_from_history(int idx) {
		string[] newArray = {};
		for (int i = 0; i < history.length; i++) {
			if (i < idx) {
				newArray += history[i];
			}
		}
		history = newArray;
	}

	public static void delete_duplicates_from_history(string text) {
		for (int j = 0; j < history.length; j++) {
			if (text == history[j]) {
				remove_index_from_history(j);
				break;
			}
		}
		update_history(text);
	}

	public static void show_all_except() {
		Applet.popover.get_child().show_all();
		if (setDropdown.get_active()) {
			settingsBox.show();
		} else {
			settingsBox.hide();
		}
	}

	public static void update_pager() {
		pagerCont.set_label(@"$(history.length) / $HISTORY_LENGTH");
	}

	public static void clip_curr_empty(
			string emptyText = "No Clipboard Items Found") {
		if (emptyText.contains("Found")) {
			indicatorIcon.set_from_icon_name(
				"clipboard-outline-symbolic", Gtk.IconSize.MENU);
		}
		listbax.add(new Label(_(emptyText)));
	}

	public static void on_search_activate(Gtk.Entry entry) {
		remove_and_create_listbax();
		string gotText = entry.get_text();
		int j = 0;
		for (int i = 0; i < history.length; i++) {
			if (history[i].contains(gotText)) {
				add_element_to_listbax(i);
				j++;
			} else if (!searchsensitive &&
					   history[i].down().contains(gotText.down())) {
				add_element_to_listbax(i);
				j++;
			}
		}
		if (j == 0) {
			clip_curr_empty(_("Try changing search terms") + ".");
		}
		realContent.add(listbax);
		update_pager();
		show_all_except();
	}

	public static void __on_row_activated(int copy) {
		Applet.popover.hide();
		row_activated_flag = true;
		string text = history[copy];
		ClipboardManager.set_text(text);
		if (primode) {
			remove_and_create_listbax();
			add_marked_text_in_loop(copy);
			realContent.add(listbax);
			update_pager();
			show_all_except();
		}
		if (sendNotifications) {
			text = text.replace("\t", "  ");
			if (text.length > 250) {
				text = text.slice(0, 250) + "...";
			}
			ClipboardManager.send_notification_now(_("Copied") + "!", text);
		}
		specialMark = copy;
	}
  }

  public class Applet : Budgie.Applet {
	private Gtk.EventBox indicatorBox;
	public static ClipboardManagerPopover popover = null;
	private unowned Budgie.PopoverManager? manager = null;
	public static GLib.Settings settings =
		new GLib.Settings("com.prateekmedia.clipboardmanager");
	public string uuid { public set; public get; }

	public override bool supports_settings() { return true; }
	public override Gtk.Widget? get_settings_ui() {
		return new ClipboardManagerSettings(settings);
	}

	public Applet() {
		indicatorBox = new Gtk.EventBox();
		add(indicatorBox);

		popover = new ClipboardManagerPopover(indicatorBox);

		indicatorBox.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			if (popover.get_visible()) {
				popover.hide();
			} else {
				this.manager.show_popover(indicatorBox);
			}
			return Gdk.EVENT_STOP;
		});

		ClipboardManagerPopover.addRow(2);
		ClipboardManager.attach_monitor_clipboard();
		popover.get_child().show_all();
		show_all();
		ClipboardManagerPopover.show_all_except();
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(indicatorBox, popover);
	}
  }
}

// =============================================================================

[ModuleInit]
public void peas_register_types(TypeModule module) {
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(
		typeof(Budgie.Plugin),
		typeof(ClipboardManagerApplet.Plugin));
}
