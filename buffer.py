#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2018 Andy Stewart
#
# Author:     Andy Stewart <lazycat.manatee@gmail.com>
# Maintainer: Andy Stewart <lazycat.manatee@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from PyQt6.QtCore import QUrl, pyqtSlot
from PyQt6.QtGui import QColor
from core.utils import (touch, interactive, is_port_in_use,
                        eval_in_emacs, get_emacs_func_result, get_emacs_func_cache_result,
                        message_to_emacs, set_emacs_var,
                        translate_text, open_url_in_new_tab,
                        get_emacs_var, get_emacs_vars, get_emacs_config_dir, PostGui,
                        get_emacs_theme_background, get_emacs_theme_foreground)
from core.webengine import BrowserBuffer
import os
import re
import threading
import time
import urllib

class AppBuffer(BrowserBuffer):
    def __init__(self, buffer_id, url, arguments):
        BrowserBuffer.__init__(self, buffer_id, url, arguments, False)

        self.config_dir = get_emacs_config_dir()

        # When arguments is "temp_html_file", browser will load content of html file, then delete temp file.
        # Usually use for render html mail.
        if arguments == "temp_html_file":
            with open(url, "r") as html_file:
                self.buffer_widget.setHtml(html_file.read())
                if os.path.exists(url):
                    os.remove(url)
        else:
            self.buffer_widget.setUrl(QUrl(url))

        # Init emacs vars.
        (self.dark_mode_var,
         self.remember_history, self.blank_page_url,
         self.enable_adblocker, self.enable_autofill,
         self.aria2_auto_file_renaming, self.aria2_proxy_host, self.aria2_proxy_port,
         self.chrome_history_file,
         self.safari_history_file,
         self.translate_language,
         self.text_selection_color,
         self.dark_mode_theme
         ) = get_emacs_vars([
             "eaf-browser-dark-mode",
             "eaf-browser-remember-history",
             "eaf-browser-blank-page-url",
             "eaf-browser-enable-adblocker",
             "eaf-browser-enable-autofill",
             "eaf-browser-aria2-auto-file-renaming",
             "eaf-browser-aria2-proxy-host",
             "eaf-browser-aria2-proxy-port",
             "eaf-browser-chrome-history-file",
             "eaf-browser-safari-history-file",
             "eaf-browser-translate-language",
             "eaf-browser-text-selection-color",
             "eaf-browser-dark-mode-theme"])

        # Use thread to avoid slow down open speed.
        threading.Thread(target=self.load_history).start()

        self.autofill = PasswordDb(os.path.join(os.path.dirname(self.config_dir), "browser", "password.db"))
        self.pw_autofill_id = 0
        self.pw_autofill_raw = None

        self.readability_js = None

        self.buffer_widget.init_dark_mode_js(__file__,
                                             self.text_selection_color,
                                             self.dark_mode_theme,
                                             {
                                                 "brightness": 100,
                                                 "constrast": 90,
                                                 "sepia": 10,
                                                 "mode": 0,
                                                 "darkSchemeBackgroundColor": get_emacs_theme_background(),
                                                 "darkSchemeForegroundColor": get_emacs_theme_foreground()
     })

        self.close_page.connect(self.record_close_page)

        self.buffer_widget.open_url = self.open_url_or_search_string

        self.buffer_widget.titleChanged.connect(self.change_title)

        self.buffer_widget.translate_selected_text.connect(translate_text)

        self.buffer_widget.urlChanged.connect(self.set_adblocker)
        self.buffer_widget.urlChanged.connect(self.caret_exit)

        # Record url when url changed.
        self.buffer_widget.urlChanged.connect(self.update_url)

        # Draw progressbar.
        self.caret_browsing_js_raw = None
        self.progressbar_progress = 0
        self.progressbar_height = int(get_emacs_var("eaf-browser-progress-bar-height"))
        self.progressbar_color = QColor(get_emacs_var("eaf-browser-progress-bar-color"))
        self.buffer_widget.loadStarted.connect(self.start_progress)
        self.buffer_widget.loadProgress.connect(self.update_progress)
        self.is_loading = False

        # Update page position
        self.buffer_widget.web_page.scrollPositionChanged.connect(self.update_position)

        # Reset to default zoom when page init or page url changed.
        self.reset_default_zoom()
        self.buffer_widget.urlChanged.connect(lambda url: self.reset_default_zoom())

        # Reset zoom after page loading finish.
        # Otherwise page won't zoom if we call setUrl api in current page.
        self.buffer_widget.loadFinished.connect(lambda : self.buffer_widget.zoom_reset())

        self.buffer_widget.create_new_window = self.create_new_window

        self.start_loading_time = 0

    def load_history(self):
        self.history_list = []
        if self.remember_history:
            self.history_log_file_path = os.path.join(self.config_dir, "browser", "history", "log.txt")

            self.history_pattern = re.compile("^(.+)ᛝ(.+)ᛡ(.+)$")
            self.noprefix_url_pattern = re.compile("^(https?|file)://(.+)")
            self.nopostfix_url_pattern = re.compile("^[^#\?]*")
            self.history_close_file_path = os.path.join(self.config_dir, "browser", "history", "close.txt")
            touch(self.history_log_file_path)
            with open(self.history_log_file_path, "r", encoding="utf-8") as f:
                raw_list = f.readlines()
                for raw_his in raw_list:
                    his_line = re.match(self.history_pattern, raw_his)
                    if his_line is None: # Obsolete Old history format
                        old_his = re.match("(.*)\s((https?|file):[^\s]+)$", raw_his)
                        if old_his is not None:
                            self.history_list.append(HistoryPage(old_his.group(1), old_his.group(2), 1))
                    else:
                        self.history_list.append(HistoryPage(his_line.group(1), his_line.group(2), his_line.group(3)))

        self.buffer_widget.titleChanged.connect(self.record_history)

    def drawForeground(self, painter, rect):
        # Draw progress bar.
        if self.progressbar_progress > 0 and self.progressbar_progress < 100:
            painter.setBrush(self.progressbar_color)
            painter.drawRect(0, 0,
                             int(rect.width() * self.progressbar_progress * 1.0 / 100),
                             int(self.progressbar_height))

    @pyqtSlot()
    def start_progress(self):
        ''' Initialize the Progress Bar.'''
        self.is_loading = True

        self.start_loading_time = time.time()

        self.progressbar_progress = 0
        self.update()

    @pyqtSlot(int)
    def update_progress(self, progress):
        ''' Update the Progress Bar.'''
        self.dark_mode_js_load(progress)

        self.progressbar_progress = progress

        if progress < 100:
            # Update progress.
            self.caret_js_ready = False
            self.update()
        elif progress == 100:
            print("[EAF] Browser {} loading time: {}s".format(self.url, time.time() - self.start_loading_time))

            if self.is_loading:
                self.is_loading = False

            self.buffer_widget.load_marker_file()

            cursor_foreground_color = ""
            cursor_background_color = ""

            if self.caret_browsing_js_raw == None:
                self.caret_browsing_js_raw = self.buffer_widget.read_js_content("caret_browsing.js")

            self.caret_browsing_js = self.caret_browsing_js_raw.replace("%1", cursor_foreground_color).replace("%2", cursor_background_color)
            self.buffer_widget.eval_js(self.caret_browsing_js)
            self.caret_js_ready = True

            if self.dark_mode_is_enabled():
                if self.dark_mode_var == "follow":
                    cursor_foreground_color = self.theme_foreground_color
                    cursor_background_color = self.theme_background_color
                else:
                    cursor_foreground_color = "#FFF"
                    cursor_background_color = "#000"
            else:
                if self.dark_mode_var == "follow":
                    cursor_foreground_color = self.theme_foreground_color
                    cursor_background_color = self.theme_background_color
                else:
                    cursor_foreground_color = "#000"
                    cursor_background_color = "#FFF"

            self.after_page_load_hook() # Run after page load hook

    def after_page_load_hook(self):
        ''' Hook to run after update_progress hits 100. '''
        self.init_pw_autofill()

        if self.enable_adblocker:
            self.load_adblocker()

        # Update input focus state.
        self.is_focus()

    def update_position(self):
        mode_line_height = get_emacs_func_cache_result("eaf-get-mode-line-height", [])
        if mode_line_height > 0.1:
            position = self.buffer_widget.web_page.scrollPosition().y();
            view_height = self.buffer_widget.height()
            page_height = self.buffer_widget.web_page.contentsSize().height()
            pos_percentage = '%.1f%%' % ((position + view_height) / page_height * 100)
            eval_in_emacs("eaf--browser-update-position", [pos_percentage])

    def handle_input_response(self, callback_tag, result_content):
        ''' Handle input message.'''
        if not BrowserBuffer.handle_input_response(self, callback_tag, result_content):
            if callback_tag == "clear_history":
                self._clear_history()
            elif callback_tag == "import_chrome_history" or callback_tag == "import_safari_history":
                self._import_history(browser_name=callback_tag.split("_")[1])
            elif callback_tag == "delete_all_cookies":
                self._delete_all_cookies()
            elif callback_tag == "delete_cookie":
                self._delete_cookie()

    def try_start_aria2_daemon(self):
        ''' Try to start aria2 daemon.'''
        if not is_port_in_use(6800):
            with open(os.devnull, "w") as null_file:
                aria2_args = ["aria2c"]

                aria2_args.append("-d") # daemon
                aria2_args.append("-c") # continue download
                aria2_args.append("--auto-file-renaming={}".format(str(self.aria2_auto_file_renaming).lower()))
                aria2_args.append("-d {}".format(os.path.expanduser(self.download_path)))

                if self.aria2_proxy_host != "" and self.aria2_proxy_port != "":
                    aria2_args.append("--all-proxy")
                    aria2_args.append("http://{0}:{1}".format(self.aria2_proxy_host, self.aria2_proxy_port))

                aria2_args.append("--enable-rpc")
                aria2_args.append("--rpc-listen-all")

                import subprocess
                subprocess.Popen(aria2_args, stdout=null_file)

    @interactive(insert_or_do=True)
    def open_downloads_setting(self):
        ''' Open aria2 download manage page. '''
        self.try_start_aria2_daemon()
        index_file = os.path.join(os.path.dirname(__file__), "aria2-ng", "index.html")
        self.buffer_widget.open_url_new_buffer(QUrl.fromLocalFile(index_file).toString())

    def record_close_page(self, url):
        ''' Record closing pages.'''
        self.page_closed = True
        if self.remember_history and self.arguments != "temp_html_file" and url != "about:blank":
            touch(self.history_close_file_path)
            with open(self.history_close_file_path, "r") as f:
                close_urls = f.readlines()
                close_urls.append("{0}\n".format(url))
                open(self.history_close_file_path, "w").writelines(close_urls)

    @interactive(insert_or_do=True)
    def recover_prev_close_page(self):
        ''' Recover previous closed pages.'''
        if os.path.exists(self.history_close_file_path):
            with open(self.history_close_file_path, "r") as f:
                close_urls = f.readlines()
                if len(close_urls) > 0:
                    # We need use rstrip remove \n char from url record.
                    prev_close_url = close_urls.pop().rstrip()
                    open_url_in_new_tab(prev_close_url)
                    open(self.history_close_file_path, "w").writelines(close_urls)

                    message_to_emacs("Recovery {0}".format(prev_close_url))
                else:
                    message_to_emacs("No page need recovery.")
        else:
            message_to_emacs("No page need recovery.")

    def load_adblocker(self):
        self.buffer_widget.load_css(os.path.join(os.path.dirname(__file__), "adblocker.css"),'adblocker')

    @interactive
    def toggle_adblocker(self):
        ''' Change adblocker status.'''
        if self.enable_adblocker:
            self.enable_adblocker = False
            set_emacs_var("eaf-browser-enable-adblocker", False)
            self.buffer_widget.remove_css('adblocker', True)
            message_to_emacs("Successfully disabled adblocker!")
        elif not self.enable_adblocker:
            self.enable_adblocker = True
            set_emacs_var("eaf-browser-enable-adblocker", True)
            self.load_adblocker()
            message_to_emacs("Successfully enabled adblocker!")

    def update_url(self, url):
        self.url = self.buffer_widget.url().toString()

    def set_adblocker(self, url):
        if self.enable_adblocker and not self.page_closed:
            self.load_adblocker()

    def add_password_entry(self):
        if self.pw_autofill_raw == None:
            self.pw_autofill_raw = self.buffer_widget.read_js_content("pw_autofill.js")

        self.buffer_widget.eval_js(self.pw_autofill_raw.replace("%1", "''"))
        password, form_data = self.buffer_widget.execute_js("retrievePasswordFromPage();")
        if password != "":
            from urllib.parse import urlparse
            self.autofill.add_entry(urlparse(self.current_url).hostname, password, form_data)
            message_to_emacs("Successfully recorded this page's password!")
            return True
        else:
            message_to_emacs("There is no password present in this page!")
            return False

    def pw_autofill_gen_id(self, id):
        if self.pw_autofill_raw == None:
            self.pw_autofill_raw = self.buffer_widget.read_js_content("pw_autofill.js")

        from urllib.parse import urlparse
        result = self.autofill.get_entries(urlparse(self.url).hostname, id)
        new_id = 0
        for row in result:
            new_id = row[0]
            password = row[2]
            form_data = row[3]
            self.buffer_widget.eval_js(self.pw_autofill_raw.replace("%1", form_data))
            self.buffer_widget.eval_js('autofillPassword("%s");' % password)
            break
        return new_id

    def init_pw_autofill(self):
        if self.enable_autofill:
            self.pw_autofill_id = self.pw_autofill_gen_id(0)

    @interactive
    def save_page_password(self):
        ''' Record form data.'''
        if self.enable_autofill:
            self.add_password_entry()
        else:
            message_to_emacs("Password autofill is not enabled! Enable with `C-t` (default binding)")

    @interactive
    def toggle_password_autofill(self):
        ''' Toggle Autofill status for password data'''
        if not self.enable_autofill:
            set_emacs_var("eaf-browser-enable-autofill", True)
            self.pw_autofill_id = self.pw_autofill_gen_id(0)
            message_to_emacs("Successfully enabled autofill!")
            self.enable_autofill = True
        else:
            self.pw_autofill_id = self.pw_autofill_gen_id(self.pw_autofill_id)
            if self.pw_autofill_id == 0:
                set_emacs_var("eaf-browser-enable-autofill", False)
                message_to_emacs("Successfully disabled password autofill!")
                self.enable_autofill = False
            else:
                message_to_emacs("Successfully changed password autofill id!")

    def is_good_history(self, history, new_url, ignore_history_list):
        for ignore_history in ignore_history_list:
            match = re.search(ignore_history, history.url, re.IGNORECASE)
            if match:
                return False
        return history.url == new_url or history.hit > 1

    def _record_history(self, new_title, new_url):
        # Throw traceback info if algorithm has bug and protection of historical record is not erased.
        try:
            noprefix_new_url_match = re.match(self.noprefix_url_pattern, new_url)
            ignore_history_list = get_emacs_var("eaf-browser-ignore-history-list")
            if noprefix_new_url_match is not None:
                found_url = False
                found_parent = False
                for history in self.history_list:
                    noprefix_url_match = re.match(self.noprefix_url_pattern, history.url)
                    if noprefix_url_match is not None:
                        noprefix_url = noprefix_url_match.group(2)
                        noprefix_new_url = noprefix_new_url_match.group(2)
                        nopostfix_new_url_match = re.match(self.nopostfix_url_pattern, noprefix_new_url)

                        if nopostfix_new_url_match is not None and noprefix_url == nopostfix_new_url_match.group():
                            # increment parent url
                            history.hit += 0.25
                            found_parent = True
                            if found_url:
                                break
                        if noprefix_url == noprefix_new_url: # found_url unique url
                            history.title = new_title
                            history.url = new_url
                            history.hit += 0.5
                            found_url = True
                            if found_parent:
                                break

                if not found_url:
                    self.history_list.append(HistoryPage(new_title, new_url, 1))

            self.history_list.sort(key = lambda x: x.hit, reverse = True)

            self.history_list = [history for history in self.history_list if self.is_good_history(history, new_url, ignore_history_list)]

            with open(self.history_log_file_path, "w", encoding="utf-8") as f:
                f.writelines(map(lambda history: history.title + "ᛝ" + history.url + "ᛡ" + str(history.hit) + "\n", self.history_list))
        except Exception:
            import traceback
            message_to_emacs("Error in record_history: " + str(traceback.print_exc()))

    def record_history(self, new_title):
        ''' Record browser history.'''
        new_url = self.buffer_widget.filter_url(self.buffer_widget.get_url())
        if self.remember_history and self.buffer_widget.filter_title(new_title) != "" and \
           self.arguments != "temp_html_file" and new_title != "about:blank" and new_url != "about:blank":
            self._record_history(new_title, new_url)

    @interactive(insert_or_do=True)
    def new_blank_page(self):
        ''' Open new blank page.'''
        eval_in_emacs('eaf-open', [self.blank_page_url, "browser", "", 't'])

    @interactive(insert_or_do=True)
    def open_url_or_search_string(self, url):
        ''' Edit a URL or search a string.'''
        is_valid_url = get_emacs_func_result('eaf-is-valid-web-url', [url])
        if is_valid_url:
            wrap_url = get_emacs_func_result('eaf-wrap-url', [url])
            self.buffer_widget.setUrl(QUrl(wrap_url))
        else:
            search_url = get_emacs_func_result('eaf--create-search-url', [url])
            self.buffer_widget.setUrl(QUrl(search_url))

    def _clear_history(self):
        if os.path.exists(self.history_log_file_path):
            os.remove(self.history_log_file_path)
            message_to_emacs("Cleared browsing history.")
        else:
            message_to_emacs("There is no browsing history.")

    @interactive
    def clear_history(self):
        ''' Clear browsing history.'''
        self.send_input_message("Are you sure you want to clear all browsing history?", "clear_history", "yes-or-no")

    def _import_history(self, browser_name=None):
        import sqlite3

        if browser_name not in ["chrome", "safari"]:
            message_to_emacs("Failed to get browser_name")
            return

        if browser_name == "safari":
            dbpath = os.path.expanduser(self.safari_history_file)
        else:
            dbpath = os.path.expanduser(self.chrome_history_file)

        if not os.path.exists(dbpath):
            message_to_emacs("The chrome history file: '{}' not exist, please check your setting.".format(dbpath))
            return

        message_to_emacs("Importing from {}...".format(dbpath))

        conn = sqlite3.connect(dbpath)
        # Keep lastest entry in dict by last_visit_time asc order.
        if browser_name == "safari":
            cursor = conn.cursor()
            history_items = cursor.execute('SELECT id, url FROM history_items').fetchall()
            history_visits = cursor.execute('SELECT history_item, visit_time, title FROM history_visits order by visit_time asc').fetchall()

            max_visit_time = 0
            max_visit_save_file = os.path.join(os.path.dirname(self.config_dir), "browser", "safari_history_last_update_time.txt")
            if os.path.exists(max_visit_save_file):
                with open(max_visit_save_file, "r", encoding="utf-8") as f:
                    try:
                        max_visit_time = float(f.read())
                    except ValueError as e:
                        message_to_emacs("Failed to read safari_history_last_update_time.txt, error: " + str(e))
                        max_visit_time = 0

            _histories = {}
            histories = {}
            for id, url in history_items:
                _histories[id] = [url, '']

            for history_item, visit_time, title  in history_visits:
                if visit_time < max_visit_time:
                    continue

                if history_item not in _histories:
                    message_to_emacs("Parse safari history file error.")
                    return

                _histories[history_item][-1] = (title)

            max_visit_time = history_visits[-1][1]
            with open(max_visit_save_file, "w") as f:
                f.write(str(max_visit_time))

            for id, url in history_items:
                url, title = _histories[id]
                if title is not None and len(title) > 0:
                    histories[title] = url
        else:
            sql = 'select title, url from urls order by last_visit_time asc'
            # May fetch many by many not fetch all,
            # but this should called only once, so not important now.
            try:
                histories = conn.execute(sql).fetchall()
            except sqlite3.OperationalError as e:
                if e.args[0] == 'database is locked':
                    message_to_emacs("The chrome history file is locked, please close your chrome app first.")
                else:
                    message_to_emacs("Failed to read chrome history entries: {}.".format(e))
                return

        histories = dict(histories)  # Drop duplications with same title.
        total = len(histories)
        for i, (title, url) in enumerate(histories.items(), 1):
            self._record_history(title, url)
            message_to_emacs("Importing {} / {} ...".format(i, total))
        message_to_emacs("{} {} history entries imported.".format(total, browser_name))

    @interactive
    def import_safari_history(self):
        ''' Import history entries from safari history db.'''
        self.send_input_message("Are you sure you want to import all history from safari?", "import_safari_history", "yes-or-no")

    @interactive
    def import_chrome_history(self):
        ''' Import history entries from chrome history db.'''
        self.send_input_message("Are you sure you want to import all history from chrome?", "import_chrome_history", "yes-or-no")

    def _delete_all_cookies(self):
        ''' Delete all cookies.'''
        self.buffer_widget.delete_all_cookies()
        message_to_emacs("Delete all cookies.")

    @interactive
    def delete_all_cookies(self):
        ''' Delete all cookies.'''
        self.send_input_message("Are you sure you want to delete all browsing cookies?", "delete_all_cookies", "yes-or-no")

    def _delete_cookie(self):
        ''' Delete cookie of current site.'''
        self.buffer_widget.delete_cookie()
        message_to_emacs("Delete cookie of {}.".format(self.buffer_widget.url().host()))

    @interactive
    def delete_cookie(self):
        ''' Delete cookie of current site.'''
        self.send_input_message("Are you sure you want to delete cookie of current site?", "delete_cookie", "yes-or-no")

    def load_readability_js(self):
        if self.readability_js == None:
            self.readability_js = open(os.path.join(os.path.dirname(__file__),
                                                    "node_modules",
                                                    "@mozilla",
                                                    "readability",
                                                    "Readability.js"
                                                    ), encoding="utf-8").read()
        
        self.buffer_widget.eval_js(self.readability_js)
        
    @interactive(insert_or_do=True)
    def switch_to_reader_mode(self):
        if self.buffer_widget.execute_js("document.getElementById('readability-page-1') != null;"):
            message_to_emacs("Reader mode has been enable in current page.")
        else:
            self.load_readability_js()

            html = self.buffer_widget.execute_js("new Readability(document).parse().content;")
            if html == None:
                self.refresh_page()
                message_to_emacs("Cannot parse text content of current page, failed to switch reader mode.")
            else:
                self.buffer_widget.setHtml(get_emacs_var("eaf-browser-reader-mode-style") + html)

    @interactive(insert_or_do=True)
    def export_text(self):
        self.load_readability_js()

        text = self.buffer_widget.execute_js("new Readability(document).parse().textContent;")
        self.refresh_page()
        eval_in_emacs('eaf--browser-export-text', ["EAF-BROWSER-TEXT-" + self.url, text])
        
    @interactive(insert_or_do=True)
    def render_by_eww(self):
        self.load_readability_js()

        html = self.buffer_widget.execute_js("new Readability(document).parse().content;")
        if html == None:
            self.refresh_page()
            message_to_emacs("Cannot parse text content of current page, failed to render by eww.")
        else:
            import tempfile

            new_file, filename = tempfile.mkstemp(suffix=".html")
            with os.fdopen(new_file, 'w') as tmp:
                tmp.write(get_emacs_var("eaf-browser-reader-mode-style") + html)
            
            self.refresh_page()
            eval_in_emacs("eaf--browser-render-by-eww", [self.url, filename])

    def page_is_loading(self):
        return self.is_loading

    @interactive(insert_or_do=True)
    def translate_page(self):
        import locale
        system_language = locale.getdefaultlocale()[0].replace("_", "-")
        language = system_language if self.translate_language == "" else self.translate_language

        url = urllib.parse.quote(self.buffer_widget.url().toString(), safe='')

        open_url_in_new_tab("https://translate.google.com/translate?hl=en&sl=auto&tl={}&u={}".format(language, url))
        message_to_emacs("Translating page...")

    def get_new_window_buffer_id(self):
        ''' Return new browser window's buffer ID. '''
        import secrets

        return "{0}-{1}-{2}-{3}-{4}-{5}-{6}".format(
            secrets.token_hex(2),
            secrets.token_hex(2),
            secrets.token_hex(2),
            secrets.token_hex(2),
            secrets.token_hex(2),
            secrets.token_hex(2),
            secrets.token_hex(2))

    def create_new_window(self):
        ''' Create new browser window.'''
        # Generate buffer id same as eaf.el does.
        buffer_id = self.get_new_window_buffer_id()

        # Create buffer for create new browser window.
        app_buffer = self.create_buffer(buffer_id, "http://0.0.0.0", self.module_path, "")

        # Create emacs buffer with buffer id.
        eval_in_emacs('eaf--create-new-browser-buffer', [buffer_id])

        # Return new QWebEngineView for create new browser window.
        return app_buffer.buffer_widget

    def dark_mode_is_enabled(self):
        ''' Return bool of whether dark mode is enabled.'''
        dark_mode_var = get_emacs_var("eaf-browser-dark-mode")
        return (dark_mode_var == "force" or \
                dark_mode_var == True or \
                (dark_mode_var == "follow" and \
                 self.theme_mode == "dark")) and \
                 not self.url.startswith("devtools://")

    def init_web_page_background(self):
        self.buffer_widget.web_page.setBackgroundColor(QColor(get_emacs_theme_background()))

class HistoryPage():
    def __init__(self, title, url, hit):
        self.title = title
        self.url = url
        self.hit = float(hit)

class PasswordDb(object):
    def __init__(self, dbpath):
        import sqlite3

        self._conn = sqlite3.connect(dbpath)
        self._conn.execute("""
        CREATE TABLE IF NOT EXISTS autofill
        (id INTEGER PRIMARY KEY AUTOINCREMENT, host TEXT,
         password TEXT, form_data TEXT)
        """)

    def add_entry(self, host, password, form_data):
        result = self._conn.execute("""
        SELECT id, host, password, form_data FROM autofill
        WHERE host=? AND form_data=? ORDER BY id
        """, (host, str(form_data)))
        if len(list(result))>0:
            self._conn.execute("""
            UPDATE autofill SET password=?
            WHERE host=? and form_data=?
            """, (password, host, str(form_data)))
        else:
            self._conn.execute("""
            INSERT INTO autofill (host, password, form_data)
            VALUES (?, ?, ?)
            """, (host, password, str(form_data)))
            self._conn.commit()

    def get_entries(self, host, id):
        return self._conn.execute("""
        SELECT id, host, password, form_data FROM autofill
        WHERE host=? and id>? ORDER BY id
        """, (host, id))
