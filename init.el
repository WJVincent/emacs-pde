;;; -*- lexical-binding: t -*-

;;;; ----------------
;;;; Bootstrap
;;;; ----------------

;; Don't surface async native-compilation warnings from third-party
;; packages (e.g. expand-region referencing treesit-* funcs). They're
;; logged to *Native-Compile-Log* but won't pop up *Warnings*.
(setq native-comp-async-report-warnings-errors 'silent)

;; Load custom file
(setq custom-file "~/.emacs.d/custom.el")
;; load the custom file after other packages
(when (file-exists-p custom-file)
  (load custom-file))

;; Start server if not already running
(require 'server)
(unless (server-running-p)
  (server-start))

;; Prevent Org's parser from crashing in non-Org buffers (9.7.11 bug)
(advice-add 'org-element-at-point :around
            (lambda (orig-fn &rest args)
              (if (derived-mode-p 'org-mode)
                  (apply orig-fn args)
                (ignore))))
;;;; ----------------
;;;; Tree-sitter
;;;; ----------------

(setq treesit-language-source-alist
      '((lua    "https://github.com/tree-sitter-grammars/tree-sitter-lua")
        (c      "https://github.com/tree-sitter/tree-sitter-c")
        (csharp "https://github.com/tree-sitter/tree-sitter-c-sharp")
        (html   "https://github.com/tree-sitter/tree-sitter-html")
        (css    "https://github.com/tree-sitter/tree-sitter-css")
        (make   "https://github.com/tree-sitter-grammars/tree-sitter-make")
        (org    "https://github.com/milisims/tree-sitter-org")
        (fennel "https://github.com/alexmozaidze/tree-sitter-fennel")
        (rust   "https://github.com/tree-sitter/tree-sitter-rust")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript")))

;;;; ----------------
;;;; Package Setup
;;;; ----------------

;; Ensure portability between OS implementations
(eval-when-compile
  (require 'package))

(unless (boundp 'package-archives)
  (require 'package))

(add-to-list 'package-archives '("melpa"        . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)

(package-initialize)

(unless (and (boundp 'package-archive-contents) package-archive-contents)
  (package-refresh-contents))

(when (eq system-type 'gnu/linux)
  (setenv "SSH_AUTH_SOCK"
          (format "/run/user/%d/gcr/ssh" (user-uid))))

;;;; ----------------
;;;; Packages
;;;; ----------------

;; Fix PATH inherited from shell
(use-package exec-path-from-shell
  :ensure t
  :config (exec-path-from-shell-initialize))

;; Theme
(use-package gruvbox-theme
  :ensure t
  :config (load-theme 'gruvbox-light-medium t))

;; Vertical minibuffer layout
(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode))

;; Minibuffer annotations
(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode))

;; Space-separated fuzzy matching for completion
(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless flex))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides nil))

;; Git frontend
(use-package magit
  :ensure t
  :defer t)

;; Structural S-expression editing
(use-package paredit
  :ensure t
  :defer t
  :hook (emacs-lisp-mode       . paredit-mode)
  :hook (lisp-interaction-mode . paredit-mode)
  :hook (lisp-mode             . paredit-mode))

;; Common Lisp IDE
(use-package sly
  :ensure t
  :defer t
  :config
  (setq inferior-lisp-program
        (if (eq system-type 'darwin)
            "/opt/homebrew/bin/sbcl"
          "/usr/bin/sbcl")))

;; Markdown editing
(use-package markdown-mode
  :ensure t
  :defer t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)))

;; Fennel (Lua Lisp)
(use-package fennel-mode
  :ensure t
  :defer t
  :mode ("\\.fnl\\'" . fennel-mode))

;; Lua
(use-package lua-mode
  :ensure t
  :defer t
  :mode ("\\.lua\\'" . lua-mode))

;; Org mode visual enhancements
(use-package org-modern
  :ensure t
  :hook (org-mode            . org-modern-mode)
  :hook (org-mode            . org-indent-mode)
  :hook (org-agenda-finalize . org-modern-agenda))

;; C#
(use-package csharp-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-ts-mode)))

;; In-buffer autocompletion
(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-quit-at-boundary nil)
  :init
  (global-corfu-mode))

(setq corfu-quit-no-match t)

;; Rust
(use-package rust-mode
  :ensure t
  :init
  (setq rust-mode-treesitter-derive t)
  :config
  (add-hook 'rust-mode-hook    'eglot-ensure)
  (add-hook 'rust-ts-mode-hook 'eglot-ensure)
  (define-key rust-mode-map (kbd "C-c C-c r") 'rust-run)
  (define-key rust-mode-map (kbd "C-c C-c t") 'rust-test))

;; Better popup window management
(use-package popwin
  :ensure t
  :config
  (popwin-mode 1)
  (setq popwin:special-display-config
        '(("*eldoc*"                 :position bottom :height 0.4 :noselect nil :stick t)
          ("*Help*"                  :position bottom :height 0.4 :noselect nil :stick t)
          ("*Messages*"              :position bottom :height 0.3 :noselect t)
          ("*Warnings*"              :position bottom :height 0.3 :noselect t)
          ("*eglot-help*"            :position bottom :height 0.4 :noselect nil :stick t)
          ("^\\*Flymake diagnostics" :regexp t :position bottom :height 0.4 :noselect nil :stick t)
	  ("^\\*sly-db" :regexp t :height 0.4 :noselect nil :stick t)
	  ("^\\*sly-description" :regexp t :height 0.4 :noselect nil :stick t))))

;; Terminal emulator
(use-package vterm
  :ensure t
  :config
  (add-to-list 'vterm-eval-cmds '("vterm-recenter-top" vterm-recenter-top)))

;; Claude Code IDE integration
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c SPC" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

;; keystroke viewer
(use-package command-log-mode
  :ensure t)

;; agent shell
(eval-when-compile
  (require 'json)
  (require 'map)
  (require 'org))

(use-package agent-shell
  :ensure t)

;; Haystack — in-progress local project, only present on some machines
(let ((haystack-dir "~/Documents/coding/elisp/haystack"))
  (when (file-directory-p haystack-dir)
    (add-to-list 'load-path haystack-dir)
    (when (require 'haystack nil t)
      (setq haystack-notes-directory "~/Documents/notes")
      (define-key global-map (kbd "C-c h") haystack-prefix-map)
      (which-key-add-key-based-replacements "C-c h" "haystack"))))

;; hledger
(with-eval-after-load 'hledger-mode
  (require 'org nil t)
  (require 'company nil t)
  (require 'async nil t)
  (require 'htmlize nil t))

(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))
;;;; ----------------
;;;; UI
;;;; ----------------

(tool-bar-mode   -1)
(menu-bar-mode   -1)
(scroll-bar-mode -1)
(column-number-mode 1)
(global-display-line-numbers-mode 1)

;; turn off gtk title bar
(if (eq system-type 'darwin)
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (add-to-list 'default-frame-alist '(undecorated . t))) ; Keep Fedora undecorated

(when window-system (global-hl-line-mode t))

(defun wv/set-font ()
  "Set the default font for the current system."
  (let* ((font-name "JetBrains Mono")
         (font-size (if (eq system-type 'darwin) 14 12))
         (font-spec (format "%s-%d" font-name font-size)))
    (when (member font-name (font-family-list))
      (set-frame-font font-spec nil t)
      (add-to-list 'default-frame-alist `(font . ,font-spec)))))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (wv/set-font))))
  (wv/set-font))

(defun wv/setup-jetbrains-mono-ligatures ()
  "Enable comprehensive JetBrains Mono ligatures via native composition."
  (let ((ligatures
         '("--"   "---"  "=="   "==="  "!="   "!=="  "=!="  "=:="  "=/="  "<="
           ">="   "&&"   "&&&"  "&="   "++"   "+++"  "***"  ";;"   "!!"   "??"
           "???"  "?:"   "?."   "?="   "<:"   ":<"   ":>"   ">:"   "<:<"  "<>"
           "<<<"  ">>>"  "<<"   ">>"   "||"   "-|"   "_|_"  "|-"   "||-"  "|="
           "||="  "##"   "###"  "####" "#{"   "#["   "]#"   "#("   "#?"   "#_"
           "#_("  "#:"   "#!"   "#="   "^="   "<$>"  "<$"   "$>"   "<+>"  "<+"
           "+>"   "<*>"  "<*"   "*>"   "</"   "</>"  "/>"   "<!--" "<#--" "-->"
           "->"   "->>"  "<<-"  "<-"   "<=<"  "=<<"  "<<="  "<==" "<=>"  "<==>"
           "==>"  "=>"   "=>>"  ">=>"  ">>="  ">>-"  ">-"   "-<"   "-<<"  ">->"
           "<-<"  "<-|"  "<=|"  "|=>"  "|->"  "<->"  "<<~"  "<~~"  "<~"   "<~>"
           "~~"   "~~>"  "~>"   "~-"   "-~"   "~@"   "[||]" "|]"   "[|"   "|}"
           "{|"   "[<"   ">]"   "|>"   "<|"   "||>"  "<||"  "|||>" "<|||" "<|>"
           "..."  ".."   ".="   "..<"  ".?"   "::"   ":::"  ":="   "::="  ":?"
           ":?>"  "//"   "///"  "/*"   "*/"   "/="   "//="  "/=="  "@_"   "__"
           "???"  ";;;")))
    (set-char-table-range composition-function-table
                          '(#x21 . #x7e)
                          (list (vector (regexp-opt ligatures) 0 'font-shape-gstring)))))

(add-hook 'prog-mode-hook #'wv/setup-jetbrains-mono-ligatures)

;;;; ----------------
;;;; Editor Settings
;;;; ----------------

(setq bookmark-save-flag 1)
(setq help-window-select t)
(setq use-short-answers t)
(setq read-extended-command-predicate #'command-completion-default-include-p)
(setq which-key-idle-delay 0.5)
(which-key-mode 1)

(windmove-default-keybindings)

;; Show eldoc in a dedicated buffer instead of the minibuffer
(setq eldoc-display-functions '(eldoc-display-in-buffer))

;; Redirect backups and autosaves to dedicated directories
(let ((backup-dir   "~/.emacs.d/tmp/backups")
      (auto-save-dir "~/.emacs.d/tmp/autosave"))
  (unless (file-directory-p backup-dir)    (make-directory backup-dir t))
  (unless (file-directory-p auto-save-dir) (make-directory auto-save-dir t))
  (setq backup-directory-alist         `(("." . ,backup-dir)))
  (setq auto-save-file-name-transforms `((".*" ,(concat auto-save-dir "/") t)))
  (setq create-lockfiles nil))

;; Open URLs externally, except HyperSpec which opens in eww
(setq browse-url-browser-function 'browse-url-default-browser)
(setq browse-url-handlers '(("hyperspec" . eww-browse-url)))

;; Add local info dir
(add-to-list 'Info-directory-list "~/.info/")

;; controls for popup buffers
(setq display-buffer-alist
      '(("\\*sly-db.*\\*"
         (display-buffer-in-side-window)
         (side . bottom)
         (slot . 0)
         (window-height . 0.3)
         (window-parameters . ((no-delete-other-windows . t)
                               (preserve-visibility . t))))))

;; auto-center more conservatively on pane resize
(setq scroll-step 1
      scroll-conservatively 101
      scroll-margin 0)

;;;; ----------------
;;;; Keybindings
;;;; ----------------

(global-set-key (kbd "C-c a")   'org-agenda)
(global-set-key (kbd "C-c c")   'org-capture)
(global-set-key (kbd "C-c B")   'ibuffer)
(global-set-key (kbd "C-c d")   #'eldoc-doc-buffer)
(define-key global-map (kbd "<escape>") 'prot/keyboard-quit-dwim)

;; Toggle between header and implementation file in C modes
(with-eval-after-load 'cc-mode
  (define-key c-mode-base-map (kbd "C-c o") 'ff-find-other-file))

(with-eval-after-load 'flymake
  (define-key flymake-mode-map (kbd "M-n")   #'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "M-p")   #'flymake-goto-prev-error)
  (define-key flymake-mode-map (kbd "C-c h") #'flymake-show-buffer-diagnostics))

(with-eval-after-load 'sly
  (define-key sly-mode-map (kbd "C-c h") 'sly-hyperspec-lookup)
  (define-key sly-mode-map (kbd "C-h f") 'sly-describe-function)
  (define-key sly-mode-map (kbd "C-h d") 'sly-documentation))

;;;; ----------------
;;;; Org Mode
;;;; ----------------

;; (setq org-agenda-files '("/home/wv/Documents/coding/city-builder/market_research.org"))

;; (setq org-capture-templates
;;       '(("g" "Game Research"
;;          entry
;;          (file+headline "/home/wv/Documents/coding/city-builder/docs_internal/market_research.org"
;;                         "Market Research")
;;          "* %^{Game Title} %^g
;; :PROPERTIES:
;; :OWNED: %^{Owned?|[ ]|[X]}
;; :PROGRESS: %^{Progress|BACKLOG|IN_PROGRESS|HOURS_100}
;; :STEAM_RATING: %^{Rating|Overwhelmingly Positive|Very Positive|Positive|Mostly Positive|Mixed|Mostly Negative|Negative}
;; :END:%?
;; ** UI Choices
;; ** Common Negative Reviews
;; ** Common Positive Reviews
;; ** Personal Thoughts
;; ")))

;; (setq org-custom-agenda-commands
;;       '(("r" "Research Dashboard"
;;          ((tags "OWNED=\"[X]\"+PROGRESS=\"HOURS_100\""
;;                 ((org-agenda-overriding-header "Deep Dive Analysis (100+ Hours played)")))
;;           (tags "OWNED=\"[X]\"+PROGRESS=\"BACKLOG\""
;;                 ((org-agenda-overriding-header "Unplayed Backlog")))
;;           (tags "STEAM_RATING=\"Overwhelmingly Positive\""
;;                 ((org-agenda-overriding-header "Top Rated Games")))))))

;; (with-eval-after-load 'org-agenda
;;   (setq org-agenda-custom-commands org-custom-agenda-commands))

;; (add-hook 'org-mode-hook
;;           (lambda ()
;;             (define-key org-mode-map (kbd "C-c <backtab>") 'wv/org-show-two-levels)))

;;;; ----------------
;;;; Custom Functions
;;;; ----------------

;; wv-novel — in-progress local project, only present on some machines
(when (file-exists-p "~/.emacs.d/wv-novel.el")
  (load-file "~/.emacs.d/wv-novel.el"))

(defun wv/org-show-two-levels ()
  "Show the first two levels of headings in the current Org buffer."
  (interactive)
  (org-content 2))

(defun prot/keyboard-quit-dwim ()
  "Do-What-I-Mean keyboard quit."
  (interactive)
  (cond
   ((derived-mode-p 'completion-list-mode) (delete-completion-window))
   ((lazy-highlight-active-p) (lazy-highlight-cleanup t))
   (regexp-search-ring (setq regexp-search-ring nil))
   (search-ring (setq search-ring nil))
   (t (keyboard-quit))))

(defun vterm-recenter-top (&rest args)
  "Recenter the vterm buffer to the top when called from the shell."
  (recenter 1))

(defun wv/org-insert-src-block (lang)
  "Insert a source block of a given LANG."
  (interactive "sLanguage: ")
  (insert (format "#+begin_src %s\n\n#+end_src" lang))
  (forward-line -1))

(defun wv/light-dark-toggle ()
  "Toggle between light/dark version of Gruvbox Medium"
  (interactive)
  (let* ((old-theme (car custom-enabled-themes))
	(new-theme (if (eq old-theme 'gruvbox-light-medium)
		       'gruvbox-dark-medium
		       'gruvbox-light-medium)))
    (mapc #'disable-theme custom-enabled-themes)
    (load-theme new-theme t)))

(defun wv/anchor-elapsed ()
  "Compute elapsed minutes between two hs: timestamps and insert below the second."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^hs: <\\([^>]+\\)>" nil t)
        (let ((start-time (org-time-string-to-time (concat "<" (match-string 1) ">"))))
          (if (re-search-forward "^hs: <\\([^>]+\\)>" nil t)
              (let* ((end-time (org-time-string-to-time (concat "<" (match-string 1) ">")))
                     (elapsed (round (/ (float-time (time-subtract end-time start-time)) 60))))
                (end-of-line)
                (insert (format "\nelapsed: %d" elapsed)))
            (message "wv/anchor-elapsed: no second hs: timestamp found")))
      (message "wv/anchor-elapsed: no hs: timestamp found"))))

;;;; ----------------
;;;; Language Support
;;;; ----------------

;; C# — use csharp-ls as the LSP server
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) "csharp-ls"))
  (define-key eglot-mode-map (kbd "C-c f") #'wv/format-and-save))

(defun wv/csharp-setup ()
  (electric-pair-local-mode 1)
  (eglot-ensure))

(add-hook 'csharp-mode-hook    #'wv/csharp-setup)
(add-hook 'csharp-ts-mode-hook #'wv/csharp-setup)

;; Formatting — prettier for web buffers, the language server elsewhere.
;; Bound to C-c f in eglot-managed buffers (see the eglot block above).
(defvar wv/prettier-modes
  '(js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
    css-mode css-ts-mode scss-mode
    mhtml-mode html-ts-mode
    json-mode json-ts-mode yaml-ts-mode markdown-mode)
  "Major modes whose buffers should be formatted with prettier.")

(defun wv/prettier-format-buffer ()
  "Format the current buffer with prettier, preserving point.
Honors any .prettierrc/.editorconfig in the file's directory."
  (interactive)
  (let ((prettier (executable-find "prettier")))
    (unless prettier (user-error "prettier not found in exec-path"))
    (let ((out (generate-new-buffer " *prettier-out*"))
          (errfile (make-temp-file "prettier-err")))
      (unwind-protect
          (let ((status (call-process-region
                         (point-min) (point-max) prettier nil
                         (list out errfile) nil
                         "--stdin-filepath" (or (buffer-file-name) (buffer-name)))))
            (if (eq status 0)
                (replace-buffer-contents out)
              (user-error "prettier failed: %s"
                          (with-temp-buffer
                            (insert-file-contents errfile)
                            (string-trim (buffer-string))))))
        (kill-buffer out)
        (delete-file errfile)))))

(defun wv/format-and-save ()
  "Format the current buffer, then save it.
Use prettier for `wv/prettier-modes', otherwise the eglot/LSP formatter."
  (interactive)
  (if (apply #'derived-mode-p wv/prettier-modes)
      (wv/prettier-format-buffer)
    (eglot-format-buffer))
  (save-buffer))

;; Web — JavaScript, HTML, CSS via eglot
(setq major-mode-remap-alist
      (append major-mode-remap-alist
              '((javascript-mode . js-ts-mode)
                (css-mode        . css-ts-mode)
                (mhtml-mode      . html-ts-mode))))

(add-hook 'js-ts-mode-hook   #'eglot-ensure)
(add-hook 'css-ts-mode-hook  #'eglot-ensure)
(add-hook 'html-ts-mode-hook #'eglot-ensure)

;; C-c C-c -> compile, with a filetype-aware default command.
(defvar wv/compile-commands
  '((js-ts-mode     . "node %s")
    (js-mode        . "node %s")
    (python-ts-mode . "python3 %s")
    (python-mode    . "python3 %s")
    (sh-mode        . "bash %s")
    (bash-ts-mode   . "bash %s"))
  "Alist mapping a major mode to a `compile-command' template.
%s is replaced with the buffer's (shell-quoted) file name.")

(defun wv/set-compile-command ()
  "Set a buffer-local `compile-command' from `wv/compile-commands'."
  (when-let* ((buffer-file-name)
              (template (alist-get major-mode wv/compile-commands)))
    (setq-local compile-command
                (format template
                        (shell-quote-argument
                         (file-name-nondirectory buffer-file-name))))))

(add-hook 'prog-mode-hook #'wv/set-compile-command)
(define-key prog-mode-map (kbd "C-c C-c c") #'compile)
