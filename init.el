;;; -*- lexical-binding: t -*-

;; load the custom file
(setq custom-file "~/.emacs.d/custom.el")
(when (file-exists-p custom-file)
  (load custom-file))

;;;; -----------------
;;;; Package Settings
;;;; -----------------

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

;;;; ---------------
;;;; Emacs Settings
;;;; ---------------

;; turn tool-bar off
(tool-bar-mode -1)

;; turn menu-bar off
(menu-bar-mode -1)

;; turn scrol-bar off
(scroll-bar-mode -1)
 
;; enable which key mode
(setq which-key-idle-delay 0.5)
(which-key-mode 1)

;; use y-n instead of yes-no for confirmation prompts
(setq use-short-answers t)

;; highlight current line when in gui mode
(when window-system (global-hl-line-mode t))

;;;; -------------
;;;; Custom elisp 
;;;; -------------

;; load the functions that allow viewing and
;; editing the kill ring in a temp buffer
;; (C-c k) to launch the buffer 
(load-file "~/.emacs.d/view-edit-kill-ring.el")
