### EAF Browser
<p align="center">
  <img width="800" src="./screenshot.png">
</p>

Browser application for the [Emacs Application Framework](https://github.com/emacs-eaf/emacs-application-framework).

### Load application

[Install EAF](https://github.com/emacs-eaf/emacs-application-framework#install) first, then add below code in your emacs config:

```Elisp
(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
(require 'eaf)
(require 'eaf-browser)
```

### Dependency List

| Package   | Description                 |
| :-------- | :------                     |
| aria2     | Download files from the web |

### The keybinding of EAF Browser.

| Key   | Event   |
| :---- | :------ |
| `C--` | zoom_out |
| `C-=` | zoom_in |
| `C-0` | zoom_reset |
| `C-s` | search_text_forward |
| `C-r` | search_text_backward |
| `C-n` | scroll_up |
| `C-p` | scroll_down |
| `C-f` | scroll_right |
| `C-b` | scroll_left |
| `C-v` | scroll_up_page |
| `C-y` | yank_text |
| `C-w` | kill_text |
| `M-e` | atomic_edit |
| `M-c` | caret_toggle_browsing |
| `M-D` | select_text |
| `M-s` | open_link |
| `M-S` | open_link_new_buffer |
| `M-B` | open_link_background_buffer |
| `C-/` | undo_action |
| `M-_` | redo_action |
| `M-w` | copy_text |
| `M-f` | history_forward |
| `M-b` | history_backward |
| `M-q` | delete_cookie |
| `M-Q` | delete_all_cookies |
| `C-t` | toggle_password_autofill |
| `C-d` | save_page_password |
| `M-a` | toggle_adblocker |
| `C-M-q` | clear_history |
| `C-M-i` | import_chrome_history |
| `C-M-s` | import_safari_history |
| `M-v` | scroll_down_page |
| `M-<` | watch-other-window-up-line |
| `M->` | watch-other-window-down-line |
| `M-p` | scroll_down_page |
| `M-t` | new_blank_page |
| `M-d` | toggle_dark_mode |
| `SPC` | insert_or_scroll_up_page |
| `J` | insert_or_select_left_tab |
| `K` | insert_or_select_right_tab |
| `j` | insert_or_scroll_up |
| `k` | insert_or_scroll_down |
| `h` | insert_or_scroll_left |
| `l` | insert_or_scroll_right |
| `f` | insert_or_open_link |
| `F` | insert_or_open_link_background_buffer |
| `O` | insert_or_open_link_new_buffer_other_window |
| `B` | insert_or_open_link_background_buffer |
| `c` | insert_or_caret_at_line |
| `u` | insert_or_scroll_down_page |
| `d` | insert_or_scroll_up_page |
| `H` | insert_or_history_backward |
| `L` | insert_or_history_forward |
| `t` | insert_or_new_blank_page |
| `T` | insert_or_recover_prev_close_page |
| `i` | insert_or_focus_input |
| `I` | insert_or_open_downloads_setting |
| `r` | insert_or_refresh_page |
| `g` | insert_or_scroll_to_begin |
| `x` | insert_or_close_buffer |
| `G` | insert_or_scroll_to_bottom |
| `-` | insert_or_zoom_out |
| `=` | insert_or_zoom_in |
| `0` | insert_or_zoom_reset |
| `m` | insert_or_save_as_bookmark |
| `o` | insert_or_open_browser |
| `y` | insert_or_download_youtube_video |
| `Y` | insert_or_download_youtube_audio |
| `p` | insert_or_toggle_device |
| `P` | insert_or_duplicate_page |
| `1` | insert_or_save_as_pdf |
| `2` | insert_or_save_as_single_file |
| `3` | insert_or_save_as_screenshot |
| `v` | insert_or_view_source |
| `e` | insert_or_edit_url |
| `n` | insert_or_export_text |
| `,` | insert_or_switch_to_reader_mode |
| `.` | insert_or_translate_text |
| `;` | insert_or_translate_page |
| `C-M-c` | copy_code |
| `C-M-l` | copy_link |
| `C-a` | select_all_or_input_text |
| `M-u` | clear_focus |
| `C-j` | open_downloads_setting |
| `M-o` | eval_js |
| `M-O` | eval_js_file |
| `<escape>` | eaf-browser-send-esc-or-exit-fullscreen |
| `M-,` | eaf-send-down-key |
| `M-.` | eaf-send-up-key |
| `M-m` | eaf-send-return-key |
| `<f5>` | emacs-session-save |
| `<f12>` | open_devtools |
| `<C-return>` | eaf-send-ctrl-return-sequence |
| `C-<left>` | eaf-send-ctrl-left-sequence |
| `C-<right>` | eaf-send-ctrl-right-sequence |
| `C-<delete>` | eaf-send-ctrl-delete-sequence |
| `C-<backspace>` | eaf-send-ctrl-backspace-sequence |
