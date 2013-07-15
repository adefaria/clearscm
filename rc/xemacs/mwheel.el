;;=============================================================================
;;                    scroll on  mouse wheel
;;=============================================================================
;; scroll on wheel of mouses
(define-key global-map 'button4
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-down 5)
       (select-window curwin)
       )))
(define-key global-map [(shift button4)]
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-down 1)
       (select-window curwin)
       )))
(define-key global-map [(control button4)]
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-down)
       (select-window curwin)
       )))
     
(define-key global-map 'button5
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-up 5)
       (select-window curwin)
       )))
(define-key global-map [(shift button5)]
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-up 1)
       (select-window curwin)
       )))
(define-key global-map [(control button5)]
  '(lambda (&rest args)
     (interactive)
     (let ((curwin (selected-window)))
       (select-window (car (mouse-pixel-position)))
       (scroll-up)
       (select-window curwin)
       )))