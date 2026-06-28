;;; -*- lexical-binding: t -*-

;;;; ----------------
;;;; Bootstrap
;;;; ----------------

;; Don't surface async native-compilation warnings from third-party
;; packages (e.g. expand-region referencing treesit-* funcs). They're
;; logged to *Native-Compile-Log* but won't pop up *Warnings*.
(setq native-comp-async-report-warnings-errors 'silent)

;; Load the custom file (only ever written by Customize) if it exists
(setq custom-file "~/.emacs.d/custom.el")
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

;; Point ssh at the GNOME keyring agent on Linux (used by Magit/git over ssh)
(when (eq system-type 'gnu/linux)
  (setenv "SSH_AUTH_SOCK"
          (format "/run/user/%d/gcr/ssh" (user-uid))))

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

;; Make sure package.el is available (at byte-compile time too)
(eval-when-compile
  (require 'package))

(unless (boundp 'package-archives)
  (require 'package))

(add-to-list 'package-archives '("melpa"        . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)

(package-initialize)

;; Refresh the package archive once, lazily, right before the first install of
;; the session. Keeps startup fast when everything is already installed, but
;; guarantees a fresh index whenever a package actually needs fetching — so a
;; stale cache can't point `:ensure' at a tarball MELPA has already rebuilt.
(defvar wv/package-refreshed nil
  "Non-nil once `package-refresh-contents' has run this session.")

(define-advice package-install (:before (&rest _) wv/refresh-once)
  (unless wv/package-refreshed
    (package-refresh-contents)
    (setq wv/package-refreshed t)))

;;;; ----------------
;;;; Packages
;;;; ----------------

;; Fix PATH inherited from shell
(use-package exec-path-from-shell
  :ensure t
  :config (exec-path-from-shell-initialize))

;; Adaptive GC — raise the threshold while working, collect when idle
(use-package gcmh
  :ensure t
  :config (gcmh-mode 1))

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

;; Search/navigation commands built on completing-read (preview + filtering)
(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)        ; enhanced buffer switcher
         ("M-y"   . consult-yank-pop)       ; browse the kill ring
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-g f" . consult-flymake)
         ("M-s l" . consult-line)           ; search lines in this buffer
         ("M-s L" . consult-line-multi)     ; ...across all buffers
         ("M-s r" . consult-ripgrep)        ; project-wide search
         ("M-s g" . consult-grep))
  :init
  ;; Route xref (find-references etc.) through consult's previewing UI
  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref))

;; Context actions on the thing at point / a minibuffer candidate
(use-package embark
  :ensure t
  :bind (("C-."   . embark-act)
         ("C-h B" . embark-bindings))
  :init
  ;; C-h after a prefix lists keys via completing-read instead of a help buffer
  (setq prefix-help-command #'embark-prefix-help-command))

;; Bridge embark and consult — e.g. embark-export a search to an editable buffer
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Git frontend
(use-package magit
  :ensure t
  :defer t)

;; Show git changes in the fringe, live, and keep them synced with magit
(use-package diff-hl
  :ensure t
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

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

;; In-buffer autocompletion
(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match t)
  :init
  (global-corfu-mode)
  :config
  ;; Show the highlighted candidate's docs in a side popup
  (setq corfu-popupinfo-delay '(0.5 . 0.2))
  (corfu-popupinfo-mode 1))

;; Extra completion-at-point sources (file paths, dabbrev) for corfu
(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;; Better popup window management (see also `display-buffer-alist' below)
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
  (add-to-list 'vterm-eval-cmds '("vterm-recenter-top" wv/vterm-recenter-top)))

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
(use-package agent-shell
  :ensure t)

;; Expand selection by semantic units
(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))

;; Jump to any visible position by typing a few chars then a hint label
(use-package avy
  :ensure t
  :bind (("C-;" . avy-goto-char-timer)
         :map isearch-mode-map
         ("C-'" . avy-isearch)))           ; label current isearch matches

;; Richer *Help* buffers (source, references, callers)
(use-package helpful
  :ensure t
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key]      . helpful-key)
         ([remap describe-command]  . helpful-command)
         ([remap describe-symbol]   . helpful-symbol)))

;; Depth-colored parentheses
(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;; Render color literals (#aabbcc, rgb()) in their color; on-demand elsewhere
(use-package rainbow-mode
  :ensure t
  :hook ((css-ts-mode scss-mode) . rainbow-mode))

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

;; Built-in quality-of-life modes
(savehist-mode 1)         ; persist minibuffer history across sessions
(recentf-mode 1)          ; track recently opened files (feeds consult-buffer)
(save-place-mode 1)       ; restore point when reopening a file
(repeat-mode 1)           ; repeat prefixed commands with the last key
(delete-selection-mode 1) ; typing replaces the active region

;; Larger read chunks speed up LSP (eglot) throughput
(setq read-process-output-max (* 1024 1024))

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

;; Side-window placement for sly-db (see also `popwin' config above)
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
;; prot/keyboard-quit-dwim is defined under Custom Functions
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
;;;; Custom Functions
;;;; ----------------

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

(defun wv/vterm-recenter-top (&rest args)
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

;;; Formatting & indentation (generic) ------------------------------

;; eglot tuning — autoshutdown idle servers, skip the event log for perf,
;; and let xref jump into out-of-project files the server points at.
(setq eglot-autoshutdown t
      eglot-events-buffer-config '(:size 0 :format full)
      eglot-extend-to-xref t)

;; C-c f formats and saves in every eglot-managed buffer.
(with-eval-after-load 'eglot
  (define-key eglot-mode-map (kbd "C-c f") #'wv/format-and-save))

;; Formatting — prettier for web buffers, the language server elsewhere.
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

;; Indentation widths — match prettier's defaults (tabWidth 2, spaces) so
;; interactive reindentation doesn't fight `wv/format-and-save'. These are the
;; generic fallback; a project `.editorconfig' overrides them when present
;; (via the built-in editorconfig-mode below), and prettier reads that same
;; file, so the two never disagree.
(setq-default js-indent-level              2  ; js-mode, js-ts-mode
              typescript-ts-mode-indent-offset 2
              json-ts-mode-indent-offset   2
              css-indent-offset            2  ; css-mode, css-ts-mode, scss
              indent-tabs-mode             nil) ; spaces, matching useTabs:false

;; Honor .editorconfig when a project ships one; otherwise the defaults above
;; apply. Built-in to Emacs 30 — no package needed.
(editorconfig-mode 1)

;;; Compilation (generic) -------------------------------------------

;; C-c C-c c -> compile, with a filetype-aware default command.
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

;;; C# --------------------------------------------------------------

;; csharp-ts-mode is built-in (Emacs 29+); no external package needed.
(add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-ts-mode))

;; Use csharp-ls as the LSP server.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) "csharp-ls")))

(defun wv/csharp-setup ()
  (electric-pair-local-mode 1)
  (eglot-ensure))

(add-hook 'csharp-mode-hook    #'wv/csharp-setup)
(add-hook 'csharp-ts-mode-hook #'wv/csharp-setup)

;;; Rust ------------------------------------------------------------

;; Format on save via eglot/rustfmt; C-c C-c r/t to run/test.
(use-package rust-mode
  :ensure t
  :init
  (setq rust-mode-treesitter-derive t)
  :config
  (add-hook 'rust-mode-hook    'eglot-ensure)
  (add-hook 'rust-ts-mode-hook 'eglot-ensure)
  (define-key rust-mode-map (kbd "C-c C-c r") 'rust-run)
  (define-key rust-mode-map (kbd "C-c C-c t") 'rust-test))

;;; Web — JavaScript / HTML / CSS -----------------------------------

(setq major-mode-remap-alist
      (append major-mode-remap-alist
              '((javascript-mode . js-ts-mode)
                (css-mode        . css-ts-mode)
                (mhtml-mode      . html-ts-mode))))

(add-hook 'js-ts-mode-hook   #'eglot-ensure)
(add-hook 'css-ts-mode-hook  #'eglot-ensure)
(add-hook 'html-ts-mode-hook #'eglot-ensure)

;;;; ----------------
;;;; Local Projects
;;;; ----------------
;; In-progress projects I'm dogfooding; only loaded where they exist.

;; Haystack — note-taking
(let ((haystack-dir "~/Documents/coding/elisp/haystack"))
  (when (file-directory-p haystack-dir)
    (add-to-list 'load-path haystack-dir)
    (when (require 'haystack nil t)
      (setq haystack-notes-directory "~/Documents/notes")
      (define-key global-map (kbd "C-c h") haystack-prefix-map)
      (which-key-add-key-based-replacements "C-c h" "haystack"))))

;; wv-novel — novel-writing tooling
(when (file-exists-p "~/.emacs.d/wv-novel.el")
  (load-file "~/.emacs.d/wv-novel.el"))
