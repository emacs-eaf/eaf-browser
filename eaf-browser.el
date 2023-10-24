;;; eaf-browser.el --- Browser plugins

;; Filename: eaf-browser.el
;; Description: Browser plugins
;; Author: Andy Stewart <lazycat.manatee@gmail.com>
;; Maintainer: Andy Stewart <lazycat.manatee@gmail.com>
;; Copyright (C) 2021, Andy Stewart, all rights reserved.
;; Created: 2021-07-20 22:30:28
;; Version: 0.1
;; Last-Updated: Sun Feb  6 15:25:47 2022 (-0500)
;;           By: Mingde (Matthew) Zeng
;; URL: http://www.emacswiki.org/emacs/download/eaf-browser.el
;; Keywords:
;; Compatibility: GNU Emacs 28.0.50
;;
;; Features that might be required by this library:
;;
;;
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Browser plugins
;;

;;; Installation:
;;
;; Put eaf-browser.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'eaf-browser)
;;
;; No need more.

;;; Customize:
;;
;;
;;
;; All of the above can customize by:
;;      M-x customize-group RET eaf-browser RET
;;

;;; Change log:
;;
;; 2021/07/20
;;      * First released.
;;

;;; Acknowledgements:
;;
;;
;;

;;; TODO
;;
;;
;;

;;; Require


;;; Code:

(defgroup eaf-browser nil
  "The Browser application of Emacs application framework."
  :group 'eaf)

(defcustom eaf-browser-search-engines `(("google" . "http://www.google.com/search?ie=utf-8&oe=utf-8&q=%s")
                                        ("duckduckgo" . "https://duckduckgo.com/?q=%s")
                                        ("bing" . "https://bing.com/search?q=%s"))
  "The default search engines offered by EAF.

Each element has the form (NAME . URL).
 NAME is a search engine name, as a string.
 URL pecifies the url format for the search engine.
  It should have a %s as placeholder for search string."
  :type '(alist :key-type (string :tag "Search engine name")
                :value-type (string :tag "Search engine url")))

(defcustom eaf-browser-default-search-engine "google"
  "The default search engine used by `eaf-open-browser' and `eaf-search-it'.

It must defined at `eaf-browser-search-engines'."
  :type 'string)

(defcustom eaf-browser-extension-list
  '("html" "htm")
  "The extension list of browser application."
  :type 'cons)

(defcustom eaf-browser-continue-where-left-off nil
  "Similar to Chromium's Setting -> On start-up -> Continue where you left off.

If non-nil, all active EAF Browser buffers will be saved before Emacs is killed,
and will re-open them when calling `eaf-browser-restore-buffers' in the future session."
  :type 'boolean)

(defcustom eaf-browser-fullscreen-move-cursor-corner nil
  "If non-nil, move the mouse cursor to the corner when fullscreen in the browser."
  :type 'boolean)

(defcustom eaf-browser-enable-adblocker nil
  "If non-nil, enable adblocker for EAF Browser.

AdBlocker will slow down the loading speed of EAF browser,
because adblocker will check every url request before send to server.
Recommand advertisement blocking on the router or proxy."
  :type 'boolean)

(defcustom eaf-browser-enable-autofill nil
  "If non-nil, enable autofill password for EAF Browser."
  :type 'boolean)

(defcustom eaf-browser-remember-history t
  "If non-nil, remember browsing history for EAF Browser.

The history file is stored in .emacs.d/eaf/browser/history/log.txt"
  :type 'boolean)

(defcustom eaf-browser-ignore-history-list
  '("google.com/search" "file://")
  "A list of case insensitive regexp URL to ignore when saving EAF Browser history."
  :type 'cons)

(defcustom eaf-browser-progress-bar-height "2"
  "Set progress bar height for EAF Browser."
  :type 'int)

(defcustom eaf-browser-progress-bar-color (eaf-get-theme-foreground-color)
  "Color of progress bar in hex code `#hhhhhh'.
Default is the foreground color of EAF buffer."
  :type 'string)

(defcustom eaf-browser-text-selection-color "auto"
  "Possible values are `auto' or a hex code `#hhhhhh' of a color.
If it is set to `auto', then the selection color will be automatically
configured by darkreader.js."
  :type 'string)

(defcustom eaf-browser-dark-mode-theme "dark"
  "Possible values are `dark' or `light' theme of the dark mode."
  :type 'string)

(defcustom eaf-browser-blank-page-url "https://www.google.com"
  "Set the blank page url for EAF Browser."
  :type 'string)

(defcustom eaf-browser-aria2-proxy-host ""
  "Set proxy host for aria2 downloader for EAF Browser."
  :type 'string)

(defcustom eaf-browser-aria2-proxy-port ""
  "Set proxy port for aria2 downloader for EAF Browser."
  :type 'string)

(defcustom eaf-browser-aria2-auto-file-renaming nil
  "If non-nil, aria2 downloader will auto rename files for EAF Browser."
  :type 'boolean)

(defcustom eaf-browser-dark-mode "follow"
  "Configure the dark mode setting for EAF Browser.

Options:
- \"follow\" to follow Emacs theme
- \"force\" to force dark mode
- nil to disable dark mode"
  :type 'string)

(defcustom eaf-browser-chrome-history-file "~/.config/google-chrome/Default/History"
  "Set the chrome history file when exporting chrome history."
  :type 'string)

(defcustom eaf-browser-safari-history-file "~/Library/Safari/History.db"
  "Set the chrome history file when exporting chrome history."
  :type 'string)

(defcustom eaf-browser-translate-language ""
  "EAF browser will use current system locale if this option is empty"
  :type 'string)

(defcustom eaf-browser-reader-mode-style
  "<style> #readability-page-1 { width: 60%; margin: auto; line-height:1.5; font-size: 18px } </style>"
  "The string of css style used by reader-mode."
  :type 'string)

(defcustom eaf-chrome-bookmark-file "~/.config/google-chrome/Default/Bookmarks"
  "The default chrome bookmark file to import."
  :type 'string)

(defcustom eaf-browser-auto-import-chrome-cookies nil
  "If non-nil, import cookies from chrome."
  :type 'boolean)

(defcustom eaf-browser-chrome-browser-name "Chrome"
  "The real chrome execute name, default is Chrome."
  :type 'string)

(defcustom eaf-browser-caret-mode-keybinding
  '(("j"   . "caret_next_line")
    ("k"   . "caret_previous_line")
    ("l"   . "caret_next_character")
    ("h"   . "caret_previous_character")
    ("w"   . "caret_next_word")
    ("b"   . "caret_previous_word")
    (")"   . "caret_next_sentence")
    ("("   . "caret_previous_sentence")
    ("g"   . "caret_to_bottom")
    ("G"   . "caret_to_top")
    ("/"   . "caret_search_forward")
    ("?"   . "caret_search_backward")
    ("."   . "caret_clear_search")
    ("v"   . "caret_toggle_mark")
    ("o"   . "caret_rotate_selection")
    ("y"   . "caret_translate_text")
    ("q"   . "caret_exit")
    ("C-n" . "caret_next_line")
    ("C-p" . "caret_previous_line")
    ("C-f" . "caret_next_character")
    ("C-b" . "caret_previous_character")
    ("M-f" . "caret_next_word")
    ("M-b" . "caret_previous_word")
    ("M-e" . "caret_next_sentence")
    ("M-a" . "caret_previous_sentence")
    ("C-<" . "caret_to_bottom")
    ("C->" . "caret_to_top")
    ("C-s" . "caret_search_forward")
    ("C-r" . "caret_search_backward")
    ("C-." . "caret_clear_search")
    ("C-SPC" . "caret_toggle_mark")
    ("C-o" . "caret_rotate_selection")
    ("C-y" . "caret_translate_text")
    ("C-q" . "caret_exit")
    ("c"   . "insert_or_caret_at_line")
    ("M-c" . "caret_toggle_browsing")
    ("<escape>" . "caret_exit"))
  "The keybinding of EAF Browser Caret Mode."
  :type 'cons)

(defcustom eaf-browser-keybinding
  '(("C--" . "zoom_out")
    ("C-=" . "zoom_in")
    ("C-0" . "zoom_reset")
    ("C-s" . "search_text_forward")
    ("C-r" . "search_text_backward")
    ("C-n" . "scroll_up")
    ("C-p" . "scroll_down")
    ("C-f" . "scroll_right")
    ("C-b" . "scroll_left")
    ("C-v" . "scroll_up_page")
    ("C-y" . "yank_text")
    ("C-w" . "kill_text")
    ("M-z" . "switch_to_input_mode")
    ("M-e" . "atomic_edit")
    ("M-c" . "caret_toggle_browsing")
    ("M-D" . "select_text")
    ("M-s" . "open_link")
    ("M-S" . "open_link_new_buffer")
    ("M-B" . "open_link_background_buffer")
    ("C-/" . "undo_action")
    ("M-_" . "redo_action")
    ("M-w" . "copy_text")
    ("M-f" . "history_forward")
    ("M-b" . "history_backward")
    ("M-q" . "delete_cookie")
    ("M-Q" . "delete_all_cookies")
    ("C-t" . "toggle_password_autofill")
    ("C-d" . "save_page_password")
    ("C-M-q" . "clear_history")
    ("C-M-i" . "import_chrome_history")
    ("C-M-s" . "import_safari_history")
    ("M-v" . "scroll_down_page")
    ("M-<" . "scroll_to_begin")
    ("M->" . "scroll_to_bottom")
    ("M-p" . "duplicate_page")
    ("M-t" . "new_blank_page")
    ("M-d" . "toggle_dark_mode")
    ("M-l" . "toggle_dark_mode_light_theme")
    ("SPC" . "insert_or_scroll_up_page")
    ("J" . "insert_or_select_left_tab")
    ("K" . "insert_or_select_right_tab")
    ("j" . "insert_or_scroll_up")
    ("k" . "insert_or_scroll_down")
    ("h" . "insert_or_scroll_left")
    ("l" . "insert_or_scroll_right")
    ("f" . "insert_or_open_link")
    ("F" . "insert_or_open_link_new_buffer")
    ("O" . "insert_or_open_link_new_buffer_other_window")
    ("B" . "insert_or_open_link_background_buffer")
    ("c" . "insert_or_caret_at_line")
    ("u" . "insert_or_scroll_down_page")
    ("d" . "insert_or_scroll_up_page")
    ("H" . "insert_or_history_backward")
    ("L" . "insert_or_history_forward")
    ("t" . "insert_or_new_blank_page")
    ("T" . "insert_or_recover_prev_close_page")
    ("i" . "insert_or_focus_input")
    ("I" . "insert_or_open_downloads_setting")
    ("r" . "insert_or_refresh_page")
    ("g" . "insert_or_scroll_to_begin")
    ("x" . "insert_or_close_buffer")
    ("G" . "insert_or_scroll_to_bottom")
    ("-" . "insert_or_zoom_out")
    ("=" . "insert_or_zoom_in")
    ("0" . "insert_or_zoom_reset")
    ("m" . "insert_or_save_as_bookmark")
    ("o" . "insert_or_open_browser")
    ("y" . "insert_or_download_youtube_video")
    ("Y" . "insert_or_download_youtube_audio")
    ("p" . "insert_or_toggle_device")
    ("P" . "insert_or_duplicate_page")
    ("1" . "insert_or_save_as_pdf")
    ("2" . "insert_or_save_as_single_file")
    ("3" . "insert_or_save_as_screenshot")
    ("v" . "insert_or_view_source")
    ("e" . "insert_or_edit_url")
    ("n" . "insert_or_export_text")
    ("N" . "insert_or_render_by_eww")
    ("," . "insert_or_switch_to_reader_mode")
    ("." . "insert_or_translate_text")
    (";" . "insert_or_translate_page")
    ("M-i" . "immersive_translation")
    ("C-M-c" . "copy_code")
    ("C-M-l" . "copy_link")
    ("C-a" . "select_all_or_input_text")
    ("M-u" . "clear_focus")
    ("C-j" . "open_downloads_setting")
    ("M-o" . "eval_js")
    ("M-O" . "eval_js_file")
    ("<escape>" . "eaf-browser-send-esc-or-exit-fullscreen")
    ("M-," . "eaf-send-down-key")
    ("M-." . "eaf-send-up-key")
    ("M-m" . "eaf-send-return-key")
    ("<f5>" . "refresh_page")
    ("<f12>" . "open_devtools")
    ("<C-return>" . "eaf-send-ctrl-return-sequence")
    ("C-<left>" . "eaf-send-ctrl-left-sequence")
    ("C-<right>" . "eaf-send-ctrl-right-sequence")
    ("C-<delete>" . "eaf-send-ctrl-delete-sequence")
    ("C-<backspace>" . "eaf-send-ctrl-backspace-sequence")
    )
  "The keybinding of EAF Browser."
  :type 'cons)

(defcustom eaf-browser-key-alias
  '(("C-a" . "<home>")
    ("C-e" . "<end>"))
  "The key alias of EAF Browser."
  :type 'cons)

(defun eaf--browser-update-position (position-percentage)
  "Format mode line position indicator to show the current position in percentage."
  (setq-local mode-line-position `(,position-percentage))
  (force-mode-line-update))

(defun eaf-browser-restore-buffers ()
  "EAF restore all opened EAF Browser buffers in the previous Emacs session.

This should be used after setting `eaf-browser-continue-where-left-off' to t."
  (interactive)
  (if eaf-browser-continue-where-left-off
      (let* ((browser-restore-file-path
              (concat eaf-config-location
                      (file-name-as-directory "browser")
                      (file-name-as-directory "history")
                      "restore.txt"))
             (browser-url-list
              (with-temp-buffer (insert-file-contents browser-restore-file-path)
                                (split-string (buffer-string) "\n" t))))
        (if (eaf-epc-live-p eaf-epc-process)
            (dolist (url browser-url-list)
              (eaf-open-browser url))
          (dolist (url browser-url-list)
            (push `(,url "browser" "") eaf--active-buffers))
          (when eaf--active-buffers (eaf-open-browser (nth 0 (car eaf--active-buffers))))))
    (user-error "Please set `eaf-browser-continue-where-left-off' to t first!")))

(defun eaf--browser-bookmark ()
  "Restore EAF buffer according to browser bookmark from the current file path or web URL."
  `((handler . eaf--bookmark-restore)
    (eaf-app . "browser")
    (defaults . ,(list eaf--bookmark-title))
    (filename . ,(eaf-get-path-or-url))))

(defun eaf--browser-chrome-bookmark (name url)
  "Restore EAF buffer according to chrome bookmark of given title and web URL."
  `((handler . eaf--bookmark-restore)
    (eaf-app . "browser")
    (defaults . ,(list name))
    (filename . ,url)))

(defun eaf--browser-bookmark-restore (bookmark)
  (eaf-open-browser (cdr (assq 'filename bookmark))))

(defalias 'eaf--browser-firefox-bookmark 'eaf--browser-chrome-bookmark)

(defvar eaf--firefox-bookmarks nil
  "Bookmarks that should be imported from firefox.")

(defun eaf--useful-firefox-bookmark? (uri)
  "Check whether uri is a website url."
  (or (string-prefix-p "http://" uri)
      (string-prefix-p "https://" uri)))

(defun eaf--firefox-bookmark-to-import? (title uri)
  "Check whether uri should be imported."
  (when (eaf--useful-firefox-bookmark? uri)
    (let ((old (gethash uri eaf--existing-bookmarks)))
      (when (or
             (not old)
             (and (string-equal old "") (not (string-equal title ""))))
        t))))

(defun eaf--firefox-bookmark-to-import (title uri)
  (puthash uri title eaf--existing-bookmarks)
  (add-to-list 'eaf--firefox-bookmarks (cons uri title)))

(defun eaf-import-firefox-bookmarks ()
  "Command to import firefox bookmarks."
  (interactive)
  (when (eaf-read-input "In order to import, you should first backup firefox's bookmarks to a json file. Continue?" "yes-or-no" "" "")
    (let ((fx-bookmark-file (read-file-name "Choose firefox bookmark file:")))
      (if (not (file-exists-p fx-bookmark-file))
          (message "Firefox bookmark file: '%s' is not exist." fx-bookmark-file)
        (setq eaf--firefox-bookmarks nil)
        (setq eaf--existing-bookmarks (eaf--load-existing-bookmarks))
        (let ((orig-bookmark-record-fn bookmark-make-record-function)
              (data (json-read-file fx-bookmark-file)))
          (cl-labels ((fn (item)
                        (pcase (alist-get 'typeCode item)
                          (1
                           (let ((title (alist-get 'title item ""))
                                 (uri (alist-get 'uri item)))
                             (when (eaf--firefox-bookmark-to-import? title uri)
                               (eaf--firefox-bookmark-to-import title uri))))
                          (2
                           (mapc #'fn (alist-get 'children item))))))
            (fn data)
            (dolist (bm eaf--firefox-bookmarks)
              (let ((uri (car bm))
                    (title (cdr bm)))
                (setq-local bookmark-make-record-function
                            #'(lambda () (eaf--browser-firefox-bookmark title uri)))
                (bookmark-set title)))
            (setq-local bookmark-make-record-function orig-bookmark-record-fn)
            (bookmark-save)
            (message "Import success.")))))))

(defun eaf--create-new-browser-buffer (new-window-buffer-id)
  "Function for creating a new browser buffer with the specified NEW-WINDOW-BUFFER-ID."
  (let ((eaf-buffer
         ;; Create a buffer which name look like first buffer (but
         ;; different). this can prevent mode-line flicker. the
         ;; buffer's name will be changed to title when title is
         ;; ready.
         (generate-new-buffer
          (concat (buffer-name (car (buffer-list))) " "))))
    (with-current-buffer eaf-buffer
      (eaf--gen-keybinding-map (eaf--get-app-bindings "browser"))
      (eaf-mode)
      (set (make-local-variable 'eaf--buffer-id) new-window-buffer-id)
      (set (make-local-variable 'eaf--buffer-url) "")
      (set (make-local-variable 'eaf--buffer-app-name) "browser"))
    (switch-to-buffer eaf-buffer)
    ;; When user open new window by click link, we should clean
    ;; minibuffer's message, for it may be show useless info.
    (message nil)))

(defun eaf-browser--duplicate-page-in-new-tab (url)
  "Duplicate a new tab for the dedicated URL."
  (eaf-open (eaf-wrap-url url) "browser" nil t))

(defun eaf-is-valid-web-url (url)
  "Return the same URL if it is valid."
  (when (and url
             ;; URL should not include blank char.
             (< (length (split-string url)) 2)
             ;; Use regexp matching URL.
             (or (and
                  (string-prefix-p "file://" url)
                  (string-suffix-p ".html" url))
                 ;; Normal url address.
                 (string-match "^\\(https?://\\)?[a-z0-9]+\\([-.][a-z0-9]+\\)*.+\\..+[a-z0-9.]\\{1,6\\}\\(:[0-9]{1,5}\\)?\\(/.*\\)?$" url)
                 ;; Localhost url.
                 (string-match "^\\(https?://\\)?\\(localhost\\|127.0.0.1\\):[0-9]+/?" url)))
    url))

(defun eaf-wrap-url (url)
  "Wraps URL with prefix http:// if URL does not include it."
  (if (or (string-prefix-p "http://" url)
          (string-prefix-p "https://" url)
          (string-prefix-p "file://" url)
          (string-prefix-p "chrome://" url))
      url
    (concat "http://" url)))

;;;###autoload
(defun eaf-open-browser-in-background (url &optional args)
  "Open browser with the specified URL and optional ARGS in background."
  (setq eaf--monitor-configuration-p nil)
  (let ((save-buffer (current-buffer)))
    (eaf-open-browser url args)
    (switch-to-buffer save-buffer))
  (setq eaf--monitor-configuration-p t))

;;;###autoload
(defun eaf-open-browser-with-history ()
  "A wrapper around `eaf-open-browser' that provides browser history candidates.

If URL is an invalid URL, it will use `eaf-browser-default-search-engine' to search URL as string literal.

This function works best if paired with a fuzzy search package."
  (interactive)
  (let* ((browser-history-file-path
          (concat eaf-config-location
                  (file-name-as-directory "browser")
                  (file-name-as-directory "history")
                  "log.txt"))
         (history-pattern "^\\(.+\\)ᛝ\\(.+\\)ᛡ\\(.+\\)$")
         (history-file-exists (file-exists-p browser-history-file-path))
         (history (completing-read
                   "[EAF/browser] Search || URL || History: "
                   (if history-file-exists
                       (mapcar
                        (lambda (h) (when (string-match history-pattern h)
                                  (format "[%s] ⇰ %s" (match-string 1 h) (match-string 2 h))))
                        (with-temp-buffer (insert-file-contents browser-history-file-path)
                                          (split-string (buffer-string) "\n" t)))
                     nil)))
         (history-url (eaf-is-valid-web-url (when (string-match "⇰\s\\(.+\\)$" history)
                                              (match-string 1 history)))))
    (cond (history-url (eaf-open-browser history-url))
          ((eaf-is-valid-web-url history) (eaf-open-browser history))
          (t (eaf-search-it history)))))

(defun eaf--create-search-url (search-string &optional search-engine use-user-engine)
  "Create a search-url for SEARCH-STRING using SEARCH-ENGINE.

SEARCH-ENGINE is defaulted to `eaf-browser-default-search-engine'.
When USE-USER-ENGINE is non-nil, user can choose a search engine defined in `eaf-browser-search-engines'"
  (let* ((real-search-engine (if use-user-engine
                                 (let ((all-search-engine (mapcar #'car eaf-browser-search-engines)))
                                   (completing-read
                                    (format "[EAF/browser] Select search engine (default %s): " eaf-browser-default-search-engine)
                                    all-search-engine nil t nil nil eaf-browser-default-search-engine))
                               (or search-engine eaf-browser-default-search-engine)))
         (link (or (cdr (assoc real-search-engine
                               eaf-browser-search-engines))
                   (error (format "[EAF/browser] Search engine %s is unknown to EAF!" real-search-engine))))
         (search-url (format link search-string)))
    search-url))

;;;###autoload
(defun eaf-search-it (&optional search-string search-engine)
  "Use SEARCH-ENGINE search SEARCH-STRING.

If called interactively, SEARCH-STRING is defaulted to symbol or region string.
The user can enter a customized SEARCH-STRING. SEARCH-ENGINE is defaulted
to `eaf-browser-default-search-engine' with a prefix arg, the user is able to
choose a search engine defined in `eaf-browser-search-engines'"
  (interactive)
  (let* ((current-symbol (if mark-active
                             (if (eq major-mode 'pdf-view-mode)
                                 (progn
                                   (declare-function pdf-view-active-region-text "pdf-view.el")
                                   (car (pdf-view-active-region-text)))
                               (buffer-substring (region-beginning) (region-end)))
                           (symbol-at-point)))
         (search-string (if search-string search-string
                          (let ((search-string (read-string (format "[EAF/browser] Search (%s): " current-symbol))))
                            (if (string-blank-p search-string) current-symbol
                              search-string))))
         (use-user-engine current-prefix-arg)
         (search-url (eaf--create-search-url search-string search-engine use-user-engine)))
    (eaf-open search-url "browser")))

(defun eaf-browser-send-esc-or-exit-fullscreen ()
  "Escape fullscreen status if browser current is fullscreen.
Otherwise send key 'esc' to browser."
  (interactive)
  (if eaf-fullscreen-p
      (eaf-call-async "eval_function" eaf--buffer-id "exit_fullscreen" "<escape>")
    (eaf-call-async "send_key" eaf--buffer-id "<escape>")))

(defun eaf-browser-is-loading ()
  "Return non-nil if current page is loading."
  (interactive)
  (when (and (string= eaf--buffer-app-name "browser")
             (string= (eaf-call-sync "execute_function" eaf--buffer-id "page_is_loading") "True"))))

(defun eaf--browser-get-window-width (&optional window)
  "Get WINDOW allocation."
  (let* ((window-edges (window-pixel-edges window))
         (x (nth 0 window-edges))
         (w (- (nth 2 window-edges) x)))
    w))

(defun eaf--browser-export-text (buffer-name html-text)
  (let ((eaf-export-text-buffer (get-buffer-create buffer-name)))
    (with-current-buffer eaf-export-text-buffer
      ;; Insert html text.
      (read-only-mode -1)
      (erase-buffer)
      (insert html-text)
      ;; Convert multiple blank lines to single line.
      (goto-char (point-min))
      (ignore-errors
        (while (re-search-forward "\\(^\\s-*$\\)\n" nil t)
          (replace-match "\n")
          (forward-char 1)))
      ;; Try to remove first blank line.
      (goto-char (point-min))
      (when (looking-at-p "[[:blank:]]*$")
        (kill-line))
      ;; Try olivetti mode.
      (let ((window-width (/ (eaf--browser-get-window-width) (window-font-width))))
        (when (featurep 'olivetti)
          (olivetti-mode 1)
          (olivetti-set-width (floor (* window-width 0.618)))))
      (read-only-mode 1))
    (switch-to-buffer eaf-export-text-buffer)))

(defun eaf--browser-render-by-eww (url filepath)
  (eww-open-file filepath)

  (setq-local header-line-format (format "EAF Browser: %s" url))

  ;; Try olivetti mode.
  (let ((window-width (/ (eaf--browser-get-window-width) (window-font-width))))
    (when (featurep 'olivetti)
      (olivetti-mode 1)
      (olivetti-set-width (floor (* window-width 0.618))))))

(defun eaf--atomic-edit (buffer-id focus-text)
  "EAF Browser: edit FOCUS-TEXT with Emacs's BUFFER-ID."
  (eaf-edit-buffer-popup buffer-id "eaf-%s-atomic-edit" "" focus-text))

(defun eaf-edit-buffer-cancel ()
  "Cancel EAF Browser focus text input and closes the buffer."
  (interactive)
  (kill-buffer)
  (delete-window)
  (message "[EAF/%s] Edit cancelled!" eaf--buffer-app-name))

(defun eaf--toggle-caret-browsing (caret-status)
  "Toggle caret browsing given CARET-STATUS."
  (if caret-status
      (eaf--gen-keybinding-map eaf-browser-caret-mode-keybinding t)
    (eaf--gen-keybinding-map eaf-browser-keybinding))
  (setq eaf--buffer-map-alist (list (cons t eaf-mode-map))))

(defun eaf-import-chrome-bookmarks ()
  "Command to import chrome bookmarks."
  (interactive)
  (when (eaf-read-input "Are you sure to import chrome bookmarks to EAF" "yes-or-no" "" "")
    (if (not (file-exists-p eaf-chrome-bookmark-file))
        (message "Chrome bookmark file: '%s' is not exist, check `eaf-chrome-bookmark-file` setting." eaf-chrome-bookmark-file)
      (let ((orig-bookmark-record-fn bookmark-make-record-function)
            (data (json-read-file eaf-chrome-bookmark-file)))
        (cl-labels ((fn (item)
                      (pcase (alist-get 'type item)
                        ("url"
                         (let ((name (alist-get 'name item))
                               (url (alist-get 'url item)))
                           (if (not (equal "chrome://bookmarks/" url))
                               (progn
                                 (setq-local bookmark-make-record-function
                                             #'(lambda () (eaf--browser-chrome-bookmark name url)))
                                 (bookmark-set name)))))
                        ("folder"
                         (mapc #'fn (alist-get 'children item))))))
          (fn (alist-get 'bookmark_bar (alist-get 'roots data)))
          (setq-local bookmark-make-record-function orig-bookmark-record-fn)
          (bookmark-save)
          (message "Import success."))))))

;;;###autoload
(defun eaf-open-browser (url &optional args)
  "Open EAF browser application given a URL and ARGS."
  (interactive "M[EAF/browser] URL: ")
  (eaf-open (eaf-wrap-url url) "browser" args))

(defun eaf-open-browser-same-window (url current-url &optional args)
  (setq current-url (url-unhex-string current-url))
  (catch 'found-rss-reader-buffer
    (eaf-for-each-eaf-buffer
     (when (string-equal eaf--buffer-url current-url)
       (select-window (get-buffer-window buffer))
       (eaf-open (eaf-wrap-url url) "browser" args)
       (throw 'found-rss-reader-buffer buffer)))))

;;;###autoload
(defun eaf-open-browser-other-window (url &optional args)
  "Open EAF browser application given a URL and ARGS in other window."
  (interactive "M[EAF/browser] URL: ")
  (when (< (length (window-list)) 2)
    (split-window-right))
  (other-window 1)
  (eaf-open (eaf-wrap-url url) "browser" args))

(defun eaf-open-url-at-point ()
  "Open URL at current point by EAF browser."
  (interactive)
  (eaf-open-browser (eaf-pick-url-under-cursor)))

(defun eaf-pick-url-under-cursor ()
  (if (eq major-mode 'org-mode)
      (let ((object (org-element-context)))
        (when (eq (car object) 'link)
          (org-element-property :raw-link object)))
    (browse-url-url-at-point)))

(defun eaf-toggle-proxy()
  "Toggle proxy to none or default proxy."
  (interactive)
  (eaf-call-sync "toggle_proxy"))

(defun eaf-get-mode-line-height ()
  (let ((mode-line-height (face-attribute 'mode-line :height)))
    (if (eq mode-line-height 'unspecified)
        1.0
      mode-line-height)))

(add-to-list 'eaf-app-binding-alist '("browser" . eaf-browser-keybinding))

(setq eaf-browser-module-path (concat (file-name-directory load-file-name) "buffer.py"))
(add-to-list 'eaf-app-module-path-alist '("browser" . eaf-browser-module-path))

(add-to-list 'eaf-app-bookmark-handlers-alist '("browser" . eaf--browser-bookmark))

(add-to-list 'eaf-app-bookmark-restore-alist '("browser" . eaf--browser-bookmark-restore))

(add-to-list 'eaf-app-extensions-alist '("browser" . eaf-browser-extension-list))

(provide 'eaf-browser)

;;; eaf-browser.el ends here
