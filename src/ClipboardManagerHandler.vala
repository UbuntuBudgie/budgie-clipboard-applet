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

public class ClipboardManager : Object {

	private static Subprocess?       watcher_process = null;
	private static Subprocess?       primary_watcher_process = null;
	private static DataInputStream?  watcher_stream = null;
	private static DataInputStream?  primary_watcher_stream = null;

	// -------------------------------------------------------------------------
	// Clipboard monitoring
	// -------------------------------------------------------------------------

	public static bool attach_monitor_clipboard() {
		stop_watcher(ref watcher_process, ref watcher_stream);
		stop_watcher(ref primary_watcher_process, ref primary_watcher_stream);

		if (ClipboardManagerApplet.ClipboardManagerPopover.primode) {
			return false;
		}

		start_clipboard_watcher();

		if (ClipboardManagerApplet.Applet.settings.get_boolean("selectclip")) {
			start_primary_watcher();
		}

		return false;
	}

	private static void stop_watcher(ref Subprocess? proc,
									 ref DataInputStream? stream) {
		if (proc != null) {
			proc.force_exit();
			proc = null;
			stream = null;
		}
	}

	// Watches the Wayland clipboard using zwlr_data_control_v1 via wl-paste.
	// The watched command tries MIME types in preference order:
	//   UTF8_STRING       — XWayland apps (xfce4-terminal, etc.)
	//   text/plain;charset=utf-8 — native Wayland GTK apps
	//   text/plain        — generic fallback
	// A null byte (octal \000) is appended as an event terminator so
	// read_upto_async can cleanly delimit multi-line clipboard content.
	private static void start_clipboard_watcher() {
		try {
			var launcher = new SubprocessLauncher(
				SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
			);
			watcher_process = launcher.spawnv({
				"wl-paste", "--watch",
				"sh", "-c",
				"wl-paste --no-newline --type UTF8_STRING 2>/dev/null || " +
				"wl-paste --no-newline --type 'text/plain;charset=utf-8' 2>/dev/null || " +
				"wl-paste --no-newline --type text/plain 2>/dev/null || " +
				"wl-paste --no-newline 2>/dev/null; " +
				"printf '\\000'"
			});
			watcher_stream = new DataInputStream(watcher_process.get_stdout_pipe());
			read_next_clip.begin(watcher_stream, false,
				(obj, res) => read_next_clip.end(res));
		} catch (Error e) {
			warning("Failed to start clipboard watcher: %s", e.message);
		}
	}

	// Watches the primary selection (middle-click paste).
	private static void start_primary_watcher() {
		try {
			var launcher = new SubprocessLauncher(
				SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
			);
			primary_watcher_process = launcher.spawnv({
				"wl-paste", "--primary", "--watch",
				"sh", "-c",
				"wl-paste --primary --no-newline --type UTF8_STRING 2>/dev/null || " +
				"wl-paste --primary --no-newline --type 'text/plain;charset=utf-8' 2>/dev/null || " +
				"wl-paste --primary --no-newline 2>/dev/null; " +
				"printf '\\000'"
			});
			primary_watcher_stream = new DataInputStream(
				primary_watcher_process.get_stdout_pipe());
			read_next_clip.begin(primary_watcher_stream, true,
				(obj, res) => read_next_clip.end(res));
		} catch (Error e) {
			warning("Failed to start primary watcher: %s", e.message);
		}
	}

	// Reads clipboard events from the watcher pipe. Each event is delimited
	// by a null byte written by the watched sh command. Handles watcher death
	// by restarting after a short delay.
	private static async void read_next_clip(DataInputStream stream,
											 bool is_primary) {
		try {
			while (true) {
				string? chunk = yield stream.read_upto_async(
					"\x00", 1, Priority.DEFAULT, null, null
				);

				// Consume the null byte terminator
				try { stream.read_byte(); } catch (Error e) {}

				if (chunk == null) {
					warning("Clipboard watcher died, restarting...");
					Timeout.add(1000, () => {
						ClipboardManager.attach_monitor_clipboard();
						return false;
					});
					return;
				}

				string text = chunk.strip();
				if (text.length == 0) continue;

				string captured = text;
				Idle.add(() => {
					string[] history =
						ClipboardManagerApplet.ClipboardManagerPopover.history;
					if (history.length > 0 && history[0] == captured) {
						return false;
					}
					if (is_primary &&
						ClipboardManagerApplet.ClipboardManagerPopover.copyselected) {
						set_text(captured);
					}
					ClipboardManagerApplet.ClipboardManagerPopover.text = captured;
					ClipboardManagerApplet.ClipboardManagerPopover
						.delete_duplicates_from_history(captured);
					ClipboardManagerApplet.ClipboardManagerPopover.addRow(2);
					return false;
				});
			}
		} catch (Error e) {
			warning("Clipboard watcher read error: %s", e.message);
		}
	}

	// -------------------------------------------------------------------------
	// Clipboard read/write
	// -------------------------------------------------------------------------

	// Writes text to the Wayland clipboard via wl-copy (stdin pipe).
	public static void set_text(string? item) {
		if (item == null || item.length == 0) return;

		try {
			var launcher = new SubprocessLauncher(
				SubprocessFlags.STDIN_PIPE  |
				SubprocessFlags.STDOUT_SILENCE |
				SubprocessFlags.STDERR_SILENCE
			);
			var proc = launcher.spawnv({"wl-copy"});
			var stdin_pipe = proc.get_stdin_pipe();
			stdin_pipe.write(item.data);
			stdin_pipe.close();
		} catch (Error e) {
			warning("wl-copy failed: %s", e.message);
		}

		if (ClipboardManagerApplet.ClipboardManagerPopover.pasteFromClipboard) {
			paste_to_focused_window.begin(item,
				(obj, res) => paste_to_focused_window.end(res));
		}
	}

	// Reads the current clipboard text, trying MIME types in preference order.
	// Used at startup and when re-fetching for ttype 0/1 in addRow.
	public static string get_text(bool selectedOne = false) {
		string[] base_args;
		if (selectedOne) {
			base_args = {"wl-paste", "--primary", "--no-newline"};
		} else {
			base_args = {"wl-paste", "--no-newline"};
		}

		string[] types = {"UTF8_STRING", "text/plain;charset=utf-8", "text/plain"};

		foreach (string type in types) {
			try {
				string[] argv = base_args;
				argv += "--type";
				argv += type;
				string output;
				int exit_status;
				Process.spawn_sync(null, argv, null,
					SpawnFlags.SEARCH_PATH, null,
					out output, null, out exit_status);
				if (exit_status == 0 && output.chug().length > 0) {
					return output;
				}
			} catch (Error e) {}
		}

		// Final fallback — no type specified
		try {
			string output;
			Process.spawn_sync(null, base_args, null,
				SpawnFlags.SEARCH_PATH, null,
				out output, null, null);
			return output;
		} catch (Error e) {
			return "";
		}
	}

	// -------------------------------------------------------------------------
	// Auto-paste
	// -------------------------------------------------------------------------

	// Pastes to the currently focused window using the appropriate tool:
	//   ydotool — for XWayland (X11) windows, sends Ctrl+V via uinput
	//   wtype   — for native Wayland windows, types text directly
	private static async void paste_to_focused_window(string text) {
		bool is_xwayland = yield focused_window_is_xwayland();
		try {
			if (is_xwayland) {
				Process.spawn_command_line_async(
					"ydotool key 29:1 47:1 47:0 29:0"
				);
			} else {
				string escaped = Shell.quote(text);
				Process.spawn_command_line_async(
					@"sh -c 'sleep 0.1 && wtype -s 50 $escaped'"
				);
			}
		} catch (Error e) {
			warning("Auto-paste failed: %s", e.message);
		}
	}

	// Detects whether the focused window is an XWayland client by querying
	// the X11 _NET_ACTIVE_WINDOW property. Returns false if xprop is
	// unavailable or no X11 window is focused.
	private static async bool focused_window_is_xwayland() {
		try {
			var launcher = new SubprocessLauncher(
				SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
			);
			var proc = launcher.spawnv({"xprop", "-root", "_NET_ACTIVE_WINDOW"});
			var stream = new DataInputStream(proc.get_stdout_pipe());
			string? line = yield stream.read_line_async(Priority.DEFAULT, null);
			yield proc.wait_async();

			if (line == null) return false;
			var parts = line.split("# ");
			if (parts.length < 2) return false;
			string id = parts[1].strip();
			return id != "0x0" && id != "0";
		} catch (Error e) {
			return false;
		}
	}

	// -------------------------------------------------------------------------
	// History persistence
	// -------------------------------------------------------------------------

	public static string[] readfile(string path) {
		try {
			string read;
			FileUtils.get_contents(path, out read);
			var data = read.split(" : ");
			string[] newdata = {};
			for (int i = 0; i < data.length; i++) {
				newdata += data[i].replace(":;", ":");
			}
			return newdata;
		} catch (FileError error) {
			return {
				_("Welcome to Clipboard Manager"),
				_("Your Clips will be saved Automatically")
			};
		}
	}

	public static void writefile(string path, string[] clips) {
		try {
			string[] newclips = {};
			for (int i = 0; i < clips.length; i++) {
				newclips += clips[i].replace(":", ":;");
			}
			FileUtils.set_contents(path, string.joinv(" : ", newclips));
		} catch (FileError error) {
			warning("Cannot write to file. Is the directory available?");
		}
	}

	public static string get_filepath(GLib.Settings settings, string key) {
		string filename = "clipmgr_data.txt";
		string filepath = settings.get_string(key);
		if (filepath == "") {
			string custompath = GLib.Path.build_path("/",
				Environment.get_home_dir(),
				".config/prateekmedia/clipboardmanger");
			try {
				File.new_for_path(custompath).make_directory_with_parents();
			} catch (Error e) {
				// Directory already exists
			}
			return GLib.Path.build_filename(custompath, filename);
		}
		return GLib.Path.build_filename(filepath, filename);
	}

	public static string[] get_clipstext(GLib.Settings settings, string key) {
		return readfile(get_filepath(settings, key));
	}

	// -------------------------------------------------------------------------
	// Notifications
	// -------------------------------------------------------------------------

	public static void send_notification_now(string title, string body,
			string icon = "clipboard-text-outline-symbolic") {
		var application = new GLib.Application(
			"com.prateekmedia.clipboardmanager",
			GLib.ApplicationFlags.FLAGS_NONE
		);
		try {
			application.register();
		} catch (Error e) {
			warning("Error: %s", e.message);
		}
		var notification = new Notification(title);
		notification.set_icon(new GLib.FileIcon(
			GLib.File.new_for_path(
				"/usr/share/pixmaps/clipboard-text-outline-symbolic.svg")));
		notification.set_body(body);
		notification.set_priority(NotificationPriority.NORMAL);
		application.send_notification(null, notification);
	}
}
