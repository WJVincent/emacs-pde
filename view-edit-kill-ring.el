(require 'cl-lib)

(defface kill-ring-tools-highlight-face
  '((t (:inherit highlight)))
  "Face for highlighting the current entry in kill-ring-tools."
  :group 'kill-ring-tools)

(defvar-local kill-ring-tools-highlight-overlay nil
  "Overlay used for highlighting the current entry.")

(defvar-local kill-ring-tools--current-filter ""
  "The current filter string for the kill-ring view.")

(defvar-local kill-ring-tools--viewer-buffer nil)

(defun kill-ring-tools-commit-add ()
  "Commit the content of the current buffer to the top of the kill-ring."
  (interactive)
  (if (y-or-n-p "Add this content to the kill ring? ")
      (let* ((full-content (buffer-substring-no-properties (point-min) (point-max)))
             (content (replace-regexp-in-string
                       "^;; Type new kill ring entry here.\\s-*\n;; Press C-c C-c to save, or C-q to abort.\\s-*\n?"
                       ""
                       full-content)))
        (if (string-blank-p content)
            (message "Cannot add an empty entry.")
          (progn
            (push content kill-ring)
            (with-current-buffer kill-ring-tools--viewer-buffer
              (kill-ring-tools--rebuild-buffer))
            (message "Entry added to kill ring.")
            (kill-buffer (current-buffer)))))
    (message "Commit aborted.")))

(defun kill-ring-tools-abort-add ()
  "Abort adding an entry and close the buffer."
  (interactive)
  (kill-buffer (current-buffer))
  (message "Add aborted."))

(defvar kill-ring-tools-add-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'kill-ring-tools-commit-add)
    (define-key map (kbd "C-q") 'kill-ring-tools-abort-add)
    map)
  "Keymap for kill-ring-tools-add-mode.")

(define-derived-mode kill-ring-tools-add-mode fundamental-mode "KillRingAdd"
  "Major mode for adding a new entry to the kill-ring.
Press C-c C-c to save the entry.
Press C-q to abort.
\\{kill-ring-tools-add-mode-map}"
  :map kill-ring-tools-add-mode-map)

(defun kill-ring-tools--rebuild-buffer (&optional position)
  "Erase and repopulate the current buffer with kill-ring contents.
Takes the current filter into account. Optionally restore cursor
near POSITION."
  (let ((inhibit-read-only t)
        (displayed-something nil)
        (original-index 0)
        (filter kill-ring-tools--current-filter))
    (erase-buffer)
    (unless (string-empty-p filter)
      (insert (propertize (format "Filter: \"%s\" (press 'c' to clear)\n\n" filter)
                          'face 'font-lock-comment-face)))
    (dolist (item kill-ring)
      (let ((case-fold-search t))
        (when (or (string-empty-p filter) 
                  (string-match-p (regexp-quote filter) item))
          (insert (format "----------- Entry %d -----------\n" original-index))
          (insert item)
          (insert "\n\n")
          (setq displayed-something t)))
      (setq original-index (1+ original-index)))
    (unless displayed-something
      (if (string-empty-p filter)
          (insert "Kill ring is empty.")
        (insert (format "No entries match filter: \"%s\"" filter))))
    (goto-char (or position (point-min)))
    (when displayed-something
      (when (and (not (string-empty-p filter))
                 (looking-at "^Filter:"))
        (forward-line 2))
      (unless (looking-at "^----------- Entry [0-9]+")
        (if (re-search-forward "^----------- Entry [0-9]+" nil t)
            (beginning-of-line)
          (goto-char (point-min))))
      (kill-ring-tools-highlight-current-entry))))

(defun kill-ring-tools-highlight-current-entry ()
  "Highlight the kill ring entry at point using an overlay."
  (when (overlayp kill-ring-tools-highlight-overlay)
    (delete-overlay kill-ring-tools-highlight-overlay))
  (save-excursion
    (beginning-of-line)
    (when (looking-at "^----------- Entry [0-9]+")
      (let* ((start (point))
             (end (save-excursion
                    (forward-line 1)
                    (if (re-search-forward "^----------- Entry [0-9]+" nil t)
                        (match-beginning 0)
                      (point-max)))))
        (setq kill-ring-tools-highlight-overlay (make-overlay start end))
        (overlay-put kill-ring-tools-highlight-overlay 'face 'kill-ring-tools-highlight-face)))))

(defun kill-ring-tools--remove-nth (n list)
  "Return a new list with the Nth element of LIST removed."
  (let ((i 0))
    (cl-loop for item in list
             unless (= i n)
             collect item
             do (cl-incf i))))

;;;###autoload
(defun kill-ring-tools-quit-window ()
  "Quit the kill-ring-tools window."
  (interactive)
  (quit-window))

;;;###autoload
(defun kill-ring-tools-delete-entry ()
  "Delete the kill-ring entry at point after confirmation."
  (interactive)
  (let ((entry-index
         (save-excursion
           (beginning-of-line)
           (when (looking-at "^----------- Entry \\([0-9]+\\)")
             (string-to-number (match-string 1))))))
    (if (numberp entry-index)
        (if (y-or-n-p (format "Delete entry %d from kill ring? " entry-index))
            (progn
              (setq kill-ring (kill-ring-tools--remove-nth entry-index kill-ring))
              (message "Entry %d deleted." entry-index)
              (let ((pos (point)))
                (kill-ring-tools--rebuild-buffer pos)))
          (message "Deletion cancelled."))
      (message "Not on a kill ring entry header."))))

;;;###autoload
(defun kill-ring-tools-add-entry ()
  "Open a buffer to add a new entry to the kill-ring."
  (interactive)
  (let ((viewer-buffer (current-buffer))
        (add-buffer (generate-new-buffer "*Kill Ring Add*")))
    (pop-to-buffer add-buffer
                   '((display-buffer-in-side-window)
                     (side . right)
                     (window-width . 0.5)))
    (with-current-buffer add-buffer
      (kill-ring-tools-add-mode)
      (setq-local kill-ring-tools--viewer-buffer viewer-buffer)
      (insert ";; Type new kill ring entry here.\n")
      (insert ";; Press C-c C-c to save, or C-q to abort.\n"))))

;;;###autoload
(defun kill-ring-tools-clear-filter ()
  "Clear the current filter and show all entries."
  (interactive)
  (setq kill-ring-tools--current-filter "")
  (kill-ring-tools--rebuild-buffer)
  (message "Filter cleared."))


(defun kill-ring-tools-filter ()
  "Filter the kill-ring view interactively."
  (interactive)
  (let ((original-filter kill-ring-tools--current-filter))
    (condition-case err
        (let ((new-filter (read-string "Filter: " original-filter)))
          (setq kill-ring-tools--current-filter new-filter)
          (kill-ring-tools--rebuild-buffer)
          (if (string-empty-p new-filter)
              (message "Filter cleared.")
            (message "Filter applied: \"%s\"" new-filter)))
      (quit
       (setq kill-ring-tools--current-filter original-filter)
       (kill-ring-tools--rebuild-buffer)
       (message "Filter cancelled.")))))

;;;###autoload
(defun kill-ring-tools-next-entry ()
  "Move point to the next kill-ring entry and highlight it."
  (interactive)
  (forward-line 1)
  (let ((next-pos (re-search-forward "^----------- Entry [0-9]+" nil t)))
    (unless next-pos
      (goto-char (point-min))
      (re-search-forward "^----------- Entry [0-9]+" nil t)))
  (beginning-of-line)
  (kill-ring-tools-highlight-current-entry))

;;;###autoload
(defun kill-ring-tools-previous-entry ()
  "Move point to the previous kill-ring entry and highlight it."
  (interactive)
  (let ((prev-pos (re-search-backward "^----------- Entry [0-9]+" nil t)))
    (unless prev-pos
      (goto-char (point-max))
      (re-search-backward "^----------- Entry [0-9]+" nil t)))
  (beginning-of-line)
  (kill-ring-tools-highlight-current-entry))

(defvar kill-ring-tools-view-mode-map (make-sparse-keymap)
  "Keymap for kill-ring-tools-view-mode.")

(define-key kill-ring-tools-view-mode-map (kbd "n") 'kill-ring-tools-next-entry)
(define-key kill-ring-tools-view-mode-map (kbd "p") 'kill-ring-tools-previous-entry)
(define-key kill-ring-tools-view-mode-map (kbd "d") 'kill-ring-tools-delete-entry)
(define-key kill-ring-tools-view-mode-map (kbd "a") 'kill-ring-tools-add-entry)
(define-key kill-ring-tools-view-mode-map (kbd "s") 'kill-ring-tools-filter)
(define-key kill-ring-tools-view-mode-map (kbd "c") 'kill-ring-tools-clear-filter)
(define-key kill-ring-tools-view-mode-map (kbd "q") 'kill-ring-tools-quit-window)

(define-derived-mode kill-ring-tools-view-mode special-mode "KillRingTools"
  "A major mode for viewing the kill-ring.
\\{kill-ring-tools-view-mode-map}"
  :map kill-ring-tools-view-mode-map
  (setq buffer-read-only t)
  (setq-local cursor-type 'box))

;;;###autoload
(defun kill-ring-tools-view ()
  "Display the contents of the kill-ring in a dedicated, transient buffer.
Use n/p to navigate, 'd' to delete, 'a' to add, 's' to filter, and 'q' to quit."
  (interactive)
  (let ((origin-window (selected-window)))
    (let ((kill-ring-buffer (get-buffer-create "*Kill Ring Tools*")))
      (with-current-buffer kill-ring-buffer
        (kill-ring-tools-view-mode)
        (setq-local kill-ring-tools-origin-window origin-window)
        (setq-local kill-ring-tools--current-filter "")
        (kill-ring-tools--rebuild-buffer))
      (pop-to-buffer kill-ring-buffer))))

(provide 'kill-ring-tools)
