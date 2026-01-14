;;; -*- lexical-binding: t -*-

;; load the custom file
(setq custom-file "~/.emacs.d/custom.el")
(when (file-exists-p custom-file)
  (load custom-file))

(setq treesit-language-source-alist
       '((lua "https://github.com/tree-sitter-grammars/tree-sitter-lua")))
;;;; -----------------
;;;; Package Settings
;;;; -----------------

;; ensure portability between os implementations by prepping package before adding melpa
(eval-when-compile
  (require 'package))

(unless (boundp 'package-archives)
  (require 'package))

;; enaqble melpa
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)

;; Fix for macos pathing issue
(use-package exec-path-from-shell
  :ensure t
  :if (eq system-type 'darwin)
  :config
  (exec-path-from-shell-initialize))

;; theme
(use-package gruvbox-theme  
  :ensure t
  :config (load-theme 'gruvbox-dark-medium t))

;; vertical minibuffer layout
(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode))

;; minibuffer annotations
(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode))

;; match space separated characters
;; useful for searching M-x commands
(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)) ; set completion style to use orderless
  (setq completion-category-defaults nil)
  (setq completion-category-overrides nil))

;; magit best git
(use-package magit
  :ensure t
  :defer t)

;; paredit - S-exp editing package
(use-package paredit
  :ensure t
  :defer t
  :hook (emacs-lisp-mode . paredit-mode) ; autostart in elisp mode
  :hook (lisp-interaction-mode . paredit-mode) ; autostart in scratch buffer
  :hook (lisp-mode . paredit-mode)) ; autostart in generic lisp mode

(use-package sly
  :ensure t
  :defer t
  :config
  (setq inferior-lisp-program
	(if (eq system-type 'darwin)
	    "/opt/homebrew/bin/sbcl"
	    "/usr/bin/sbcl")))

(use-package markdown-mode
  :ensure t
  :defer t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
	 ("\\.md\\'" . markdown-mode)
	 ("\\.markdown\\'" . markdown-mode)))

(use-package fennel-mode
  :ensure t
  :defer t
  :mode ("\\.fnl\\'" . fennel-mode))

(use-package lua-mode
  :ensure t
  :defer t
  :mode (("\\.lua\\'" . lua-mode)))

;;;; ---------------
;;;; Emacs Settings
;;;; ---------------

;; turn tool-bar off
(tool-bar-mode -1)

;; turn menu-bar off
(menu-bar-mode -1)

;; turn scroll-bar off
(scroll-bar-mode -1)

;; turn off gtk title bar
(if (eq system-type 'darwin)
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
    (add-to-list 'default-frame-alist '(undecorated . t))) ; Keep Fedora undecorated

;; enable which key mode
(setq which-key-idle-delay 0.5)
(which-key-mode 1)

;; use y-n instead of yes-no for confirmation prompts
(setq use-short-answers t)

;; highlight current line when in gui mode
(when window-system (global-hl-line-mode t))

;; handle font differences for fedora/mac
(defun wv/set-font ()
  "Set the default font for the current system."
  (let* ((font-name "JetBrains Mono")
         ;; Mac (Retina) needs larger font size
         (font-size (if (eq system-type 'darwin) 14 12))
	 ;; Construct the font string "FontName-Size"
         (font-spec (format "%s-%d" font-name font-size)))
    ;; Only set the font if its actually installed on the system
    (when (member font-name (font-family-list))
      ;; Apply to current window
      (set-frame-font font-spec nil t)
      ;; Apply to template for all future windows
      (add-to-list 'default-frame-alist `(font . ,font-spec)))))

(wv/set-font)

(defun wv/setup-jetbrains-mono-ligatures ()
  "Enable comprehensive JetBrains Mono ligatures via native composition."
  (let ((ligatures 
         '(
	   "--" "---" "==" "===" "!=" "!==" "=!=" "=:=" "=/=" "<=" ">="
	   "&&" "&&&" "&=" "++" "+++" "***" ";;" "!!" "??" "???" "?:" "?."
	   "?=" "<:" ":<" ":>" ">:" "<:<" "<>" "<<<" ">>>" "<<" ">>" "||"
	   "-|" "_|_" "|-" "||-" "|=" "||=" "##" "###" "####" "#{" "#[" "]#"
	   "#(" "#?" "#_" "#_(" "#:" "#!" "#=" "^=" "<$>" "<$" "$>" "<+>"
	   "<+" "+>" "<*>" "<*" "*>" "</" "</>" "/>" "<!--" "<#--" "-->"
	   "->" "->>" "<<-" "<-" "<=<" "=<<" "<<=" "<==" "<=>" "<==>" "==>"
	   "=>" "=>>" ">=>" ">>=" ">>-" ">-" "-<" "-<<" ">->" "<-<" "<-|"
	   "<=|" "|=>" "|->" "<->" "<<~" "<~~" "<~" "<~>" "~~" "~~>" "~>"
	   "~-" "-~" "~@" "[||]" "|]" "[|" "|}" "{|" "[<" ">]" "|>" "<|"
	   "||>" "<||" "|||>" "<|||" "<|>" "..." ".." ".=" "..<" ".?" "::"
	   ":::" ":=" "::=" ":?" ":?>" "//" "///" "/*" "*/" "/=" "//="
	   "/==" "@_" "__" "???" ";;;")))
    
    ;; This tells Emacs to look for any of the above strings in the ASCII range
    ;; and let HarfBuzz handle the "shaping" (drawing the ligature)
    (set-char-table-range composition-function-table
                          '(#x21 . #x7e)
                          (list (vector (regexp-opt ligatures) 0 'font-shape-gstring)))))

;; Enable in all programming modes
(add-hook 'prog-mode-hook #'wv/setup-jetbrains-mono-ligatures);; Apply to all programming modes

;;;; -------------
;;;; Keybinds 
;;;; -------------

;; Bind ff-find-other-file in C-Mode
(with-eval-after-load 'cc-mode
  (define-key c-mode-base-map (kbd "C-c o") 'ff-find-other-file))

;;;; -------------
;;;; Custom elisp 
;;;; -------------

;; load the functions that allow viewing and
;; editing the kill ring in a temp buffer
;; (C-c k) to launch the buffer 
;; (load-file "~/.emacs.d/view-edit-kill-ring.el")

