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
;; enaqble melpa
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
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
  :ensure t)

;; paredit - S-exp editing package
(use-package paredit
  :ensure t
  :hook (emacs-lisp-mode . paredit-mode) ; autostart in elisp mode
  :hook (lisp-interaction-mode . paredit-mode) ; autostart in scratch buffer
  :hook (lisp-mode . paredit-mode)) ; autostart in generic lisp mode

(use-package sly
  :ensure t
  :config
  (setq inferior-lisp-program "/usr/bin/sbcl"))

(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
	 ("\\.md\\'" . markdown-mode)
	 ("\\.markdown\\'" . markdown-mode)))

(use-package fennel-mode
  :ensure t
  :mode ("\\.fnl\\'" . fennel-mode))

(use-package lua-mode
  :ensure t
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
(add-to-list 'default-frame-alist '(undecorated . t))

;; enable which key mode
(setq which-key-idle-delay 0.5)
(which-key-mode 1)

;; use y-n instead of yes-no for confirmation prompts
(setq use-short-answers t)

;; highlight current line when in gui mode
(when window-system (global-hl-line-mode t))

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

