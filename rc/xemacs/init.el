(if (string-match "cygwin"
(downcase (shell-command-to-string "uname")))
(progn
 (setq exec-path (cons "C:/Cygwin/bin" exec-path))
 (setenv "PATH" (concat "C:/Cygwin/bin;" (getenv "PATH")))))

(setenv "CVS_RSH" "ssh")

;; NT-emacs assumes a Windows command shell, which you change here.
(setq process-coding-system-alist '(("bash" . undecided-unix)))
(setq w32-quote-process-args ?\")
(setq shell-file-name "bash")
(setenv "SHELL" shell-file-name) 
(setq explicit-shell-file-name shell-file-name) 

;; This removes unsightly ^M characters that would otherwise
(add-hook 'comint-output-filter-functions
          'comint-strip-ctrl-m)
(setq shell-command-switch "-cf")

(global-set-key "\C-x\C-c" 'kill-buffer)
(global-set-key "\C-x\C-n" 'save-buffers-kill-emacs)
(global-set-key "\C-x\C-z" 'suspend-emacs-or-iconify-frame)

(setq-default column-number-mode t)
(display-time)
(setq-default line-number-mode t)

(global-set-key 'kp-tab 'tab-to-tab-stop)
(set-default 'indent-tabs-mode  t)
(set-default 'tab-width 8)
(c-set-offset 'substatement-open 0)
(c-set-offset 'case-label '+)

; Preload common modes
(load-file "/usr/share/xemacs/xemacs-packages/lisp/sh-script/sh-script.el")
(load-file "~/.xemacs/clearcase.el")
(load-file "~/.xemacs/visual-basic-mode.el")
(autoload 'sh-mode		"sh-mode")
(autoload 'perl-mode		"perl-mode")
(autoload 'javascript-mode	"javascript-mode")
(autoload 'visual-basic-mode	"visual-basic-mode")

(defvar my-c-style
  '((c-auto-newline                 . nil)
    (c-toggle-auto-state            . 1)
    (c-basic-offset                 . 2)
    (c-block-comments-indent-p      . t)
    (c-comment-only-line-offset     . nil)
    (c-echo-syntactic-information-p . nil)
    (c-hanging-comment-ender-p      . t)
    (c-recognize-knr-p              . t) ; use nil if only have ANSI prototype
    (c-tab-always-indent            . t)
    (comment-column                 . 40)
    (comment-end                    . " */")
    (comment-multi-line             . t)
    (comment-start                  . "/* ")
    (c-hanging-comment-ender-p      . nil)
    (c-offsets-alist                . ((knr-argdecl-intro   . +)
                                       (case-label          . +)
                                       (knr-argdecl         . 0)
                                       (label               . 0)
                                       (statement-case-open . +)
                                       (statement-cont      . +)
                                       (substatement-open   . 0))))
  "my c-style for cc-mode")

(add-hook 'c-mode-common-hook
          '(lambda ()
             (c-add-style "MINE" my-c-style)
             (c-set-style "MINE")))
(load-default-sounds)

(load "recent-files") 
(recent-files-initialize) 

;; Set ftp program to use Windows FTP. Using Cygwin's ftp is problematic for a Windows
;; oriented XEmacs
;(setq efs-ftp-program-name "C:/Windows/System32/Ftp")

;; Set shell-file-name and shell-command-switch for Tramp
;(setq shell-file-name "cmd.exe")
;(setq shell-command-switch "/e:4096 /c")

;; Set default tramp-default-method to ssh as well as
;; insert ":" into shell-prompt-pattern
(setq tramp-default-method "ssh")
(setq shell-prompt-pattern "^[^#$%>:\n]*[#$%>:] *")

;; Set mail server
(set-variable 'smtpmail-smtp-server '"defaria.com")

;;default font and face properties. 
(progn
       (set-face-foreground 'default "black")
;;       (set-face-background 'default "#e4deb4")
       (set-face-background 'default "white")
       (set-face-font 'default "Lucida Console:Regular:10"))

;; Startup a certain size
(set-frame-height (selected-frame) 50)
(set-frame-width (selected-frame) 90)

;; Set background
;;(set-face-background-pixmap 'default
;; (expand-file-name "P:/Documents/pad.jpg")
;; (get-buffer "*info*"))

;; VC mode
;;require 'vc

;; Fix problem with Clearcase.el
(require 'timer)

;; Change comment-column to 0 for perl. comment-column is used for one
;; of the two types of comment lines that the perl mode supports -
;; full line comments and inline comments. The comment-column is used
;; for the inline comments, which I rarely use. Setting it to 0 means
;; don't try to align things. So I'll just align them myself.
(defun perl-zero-comment-column ()
   (setq comment-column 0)) (add-hook 'cperl-mode-hook 'perl-zero-comment-column) 

(global-set-key "\C-z" 'undo)
(mouse-avoidance-mode 'cat-and-mouse)
