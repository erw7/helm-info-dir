;;; helm-info-dir.el --- helm interface for info dir

;; Copyright (C) 2015 erw7.github@gmail.com

;; Author: erw7.github@gmail.com
;; URL: https://github.com/erw7/helm-summarye
;; Version: 0.01
;; Requires : ((helm "1.5.6") (info ""))

;; This file is NOT part of GNUS Emacs.

;;; Licence:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Usage:
;;  (autoload 'helm-info "helm-info-dir" nil t)

;;; Code:
(require 'helm)
(require 'helm-info)
(require 'info)

(defgroup helm-info-dir nil
  "Helm interface for info dir"
  :group 'helm)

(defun helm-info-dir-list-set (var value)
  "Set VAR (which should be `helm-info-dir-list') to VALUE.
and initilize `helm-default-info-index-list' variable."
  (set var value)
  (let (index-list)
    (dolist (elm value index-list)
      (push (nth 1 elm) index-list))
    (custom-set-variables '(helm-default-info-index-list index-list))))

(defun helm-info-dir-parse-info-dir ()
  "Parse the info dir files."
  (let ((info-list '()))
    (mapc
     (lambda (directory)
       (let ((dir-file (expand-file-name "dir" directory)))
         (when (file-readable-p dir-file)
           (with-temp-buffer
             (insert-file-contents dir-file)
             (while (re-search-forward "^* +\\([^:]+:\\) +(\\([^)]+\\))\\(?:[^.]*\\.[ \n]+\\(?:\\(?3:.*\\)\n\n\\|\\(?3:[^*]+\\)\\)\\)?" nil t)
               (let ((title (match-string 1))
                     (file (match-string 2))
                     (description (or (match-string 3) "")))
                 (add-to-list 'info-list (list title file
                                               (replace-regexp-in-string "[[:space:]\n][[:space:]\n]+" " " description)))))))))
     (or (eval (intern-soft "Info-directory-list"))
         (eval (intern-soft "Info-default-directory-list"))
         (when (getenv "INFOPATH")
           (split-string (getenv "INFOPATH") path-separator))))
    info-list))

(defcustom helm-info-dir-list
  (helm-info-dir-parse-info-dir)
  "List of dir to use in `helm-info'."
  :group 'helm-info-dir
  :type  '(repeat (list (choice string "title" choice string "file name" choice string "description")))
  :set   'helm-info-dir-list-set)

(defun helm-info-dir-init ()
  "Return a list of formated the info dir."
  (let ((helm-source '()))
    (mapc
     (lambda (elm)
       (add-to-list 'helm-source (format "%-20s %s" (car elm) (nth 2 elm))))
     helm-info-dir-list)
    (helm-init-candidates-in-buffer 'local (sort helm-source 'string<))))

(defun helm-info-dir-select (candidate)
  "Call the `helm-info-' function corresponding to the selected CANDIDATE info."
  (funcall
   (intern (concat "helm-info-" (helm-info-dir-select-info-file candidate)))))

(defun helm-info-dir-display-info-select (candidate)
  "Display the info file for the selected CANDIDATE info."
  (info (helm-info-dir-select-info-file candidate)))

(defun helm-info-dir-select-info-file (candidate)
  "Return file name for the selected CANDIDATE info."
  (string-match "^\\([^:]+:\\)" candidate)
    (nth 1 (assoc (match-string 1 candidate) helm-info-dir-list)))

;;;###autoload
(defun helm-info ()
  "Preconfigured `helm' for info dir."
  (interactive)
  (helm :sources '((name . "Helm info dir")
                   (candidates-in-buffer)
                   (init . (helm-info-dir-init))
                   (candidate-number-limit . 1000)
                   (action . (("helm-info" . helm-info-dir-select)
                              ("info" . helm-info-dir-display-info-select))))))

(provide 'helm-info-dir)

;;; helm-info-dir.el ends here
