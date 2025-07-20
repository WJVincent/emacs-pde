(define-derived-mode wv/kill-ring-edit-mode text-mode "KillRingEdit"
  "Major mode for editing the kill-ring.
In this mode, the buffer is editable with standard text editing commands.
When editing ensure that:

1. '--- Most Recent Kill ---' remains the topmost line.
2. Each list item is seperated by the '--- End of Entry ---' separator.
3. Any items manually added should follow the same format as pre-existing items.

Use C-c C-c to save changes back to the kill ring.
Use C-c C-k to cancel and close the buffer without saving.
"
  ;; Ensure the buffer is writable
  (setq-local buffer-read-only nil)
  (make-local-variable 'kill-ring))


(define-key wv/kill-ring-edit-mode-map (kbd "C-c C-c") 'wv/kill-ring-save-edits)
(define-key wv/kill-ring-edit-mode-map (kbd "C-c C-k") 'wv/kill-ring-cancel-edits)

(defun wv/kill-ring-cancel-edits ()
  "Cancel editing the kill ring and kill the buffer without saving."
  (interactive)
  (unless (string-equal (buffer-name) "*Kill Ring*")
    (error "This command can only be run in the *Kill Ring* buffer"))
  (kill-buffer (current-buffer))
  (message "Kill ring edit cancelled. No changes made."))


(defun wv/kill-ring-save-edits ()
  "parse the current buffer and save its contents to the kill-ring"
  (interactive)
  (unless (string-equal (buffer-name) "*Kill Ring*")
    (error "This command should only be run in the *Kill Ring* buffer"))
  (let ((new-kill-ring '())
	(separator "\n\n--- End of Entry ---\n\n"))
    (goto-char (point-min))
    (if (search-forward "--- Most Recent Kill ---" nil t)
	(progn
	  (forward-line 2)
	  (let* ((full-text (buffer-substring-no-properties (point) (point-max)))
		 (entries (split-string full-text separator t)))
	    (dolist (entry entries)
	      (when (string-match "^\\[[0-9]+\\]\n" entry)
		(let ((content (replace-match "" t t entry)))
		  (push content new-kill-ring))))
	    (setq-default kill-ring (nreverse new-kill-ring))
	    (message "Kill ring updated from buffer.")
	    (kill-buffer (current-buffer))))
      (error "Cannot find the kill ring header. Aborting save."))))

(defun wv/view-edit-kill-ring ()
  "open kill ring in an editable buffer and modify it like any other text buffer"
  (interactive)
  (with-current-buffer (get-buffer-create "*Kill Ring*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "--- Most Recent Kill ---\n\n")
      (let ((count 1))
	(dolist (item kill-ring)
	  (insert (format "[%d]\n" count))
	  (insert item)
	  (insert "\n\n--- End of Entry ---\n\n")
	  (setq count (1+ count)))))
    (wv/kill-ring-edit-mode)
    (switch-to-buffer "*Kill Ring*")
    (goto-char (point-min))))

(global-set-key (kbd "C-c k") 'wv/view-edit-kill-ring)
